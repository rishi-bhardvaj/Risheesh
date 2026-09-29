import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Pulls plain text out of a resume file on-device, with no native plugins.
///
/// * `.txt` / `.md` are decoded as UTF-8.
/// * `.docx` is unzipped and `word/document.xml` is flattened to paragraphs.
/// * `.pdf` goes through [PdfTextExtractor], which handles the encodings
///   produced by Word, Google Docs, LaTeX and Chrome "Save as PDF".
///   Scanned (image-only) PDFs have no text layer and return empty.
class ResumeTextExtractor {
  static const supportedExtensions = ['pdf', 'docx', 'txt', 'md'];

  static Future<String> extractFromFile(String path) async {
    final bytes = await File(path).readAsBytes();
    return extractFromBytes(bytes, fileName: path);
  }

  static String extractFromBytes(Uint8List bytes, {required String fileName}) {
    final ext = fileName.split('.').last.toLowerCase();
    final String text;
    switch (ext) {
      case 'pdf':
        text = PdfTextExtractor(bytes).extract();
      case 'docx':
        text = DocxTextExtractor.extract(bytes);
      case 'txt':
      case 'md':
      case 'markdown':
        text = utf8.decode(bytes, allowMalformed: true);
      case 'doc':
        throw const ResumeExtractionException(
          'Legacy .doc files can’t be read on-device. Save it as PDF or .docx, or paste the text.',
        );
      default:
        throw ResumeExtractionException('Unsupported file type: .$ext');
    }
    return normalize(text);
  }

  /// Collapses whitespace per line, fixes ligatures/bullets, and drops the
  /// empty lines PDF layout tends to leave behind.
  static String normalize(String text) {
    const replacements = {
      'ﬀ': 'ff', 'ﬁ': 'fi', 'ﬂ': 'fl', 'ﬃ': 'ffi', 'ﬄ': 'ffl',
      '•': '•', '●': '•', '▪': '•', '': '•', '‣': '•',
      ' ': ' ', '–': '–', '—': '—', '\r\n': '\n', '\r': '\n',
    };
    var s = text;
    replacements.forEach((k, v) => s = s.replaceAll(k, v));
    final lines = s.split('\n').map((l) => l.replaceAll(RegExp(r'[ \t]+'), ' ').trim()).toList();
    final out = <String>[];
    for (final l in lines) {
      if (l.isEmpty && (out.isEmpty || out.last.isEmpty)) continue;
      out.add(l);
    }
    return out.join('\n').trim();
  }
}

class ResumeExtractionException implements Exception {
  final String message;
  const ResumeExtractionException(this.message);

  @override
  String toString() => message;
}

/// Minimal ZIP reader (stored + deflate) for pulling `word/document.xml`.
class DocxTextExtractor {
  static String extract(Uint8List bytes) {
    final xml = _readZipEntry(bytes, 'word/document.xml');
    if (xml == null) throw const ResumeExtractionException('Not a valid .docx file');
    final doc = utf8.decode(xml, allowMalformed: true);
    final buffer = StringBuffer();
    for (final p in RegExp(r'<w:p[ >].*?</w:p>', dotAll: true).allMatches(doc)) {
      final para = p.group(0)!;
      final runs = RegExp(r'<w:t(?: [^>]*)?>(.*?)</w:t>|<w:tab/>|<w:br/>', dotAll: true)
          .allMatches(para)
          .map((m) => m.group(1) ?? (m.group(0) == '<w:tab/>' ? '\t' : '\n'))
          .join();
      final isListItem = para.contains('<w:numPr>');
      buffer.writeln(isListItem && runs.trim().isNotEmpty ? '• ${_xmlDecode(runs)}' : _xmlDecode(runs));
    }
    return buffer.toString();
  }

  static String _xmlDecode(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');

  static Uint8List? _readZipEntry(Uint8List data, String name) {
    final bd = ByteData.sublistView(data);
    // End of central directory record: scan backwards for its signature.
    var eocd = -1;
    for (var i = data.length - 22; i >= 0 && i >= data.length - 65557; i--) {
      if (bd.getUint32(i, Endian.little) == 0x06054b50) {
        eocd = i;
        break;
      }
    }
    if (eocd < 0) return null;
    final entries = bd.getUint16(eocd + 10, Endian.little);
    var p = bd.getUint32(eocd + 16, Endian.little);
    for (var n = 0; n < entries && p + 46 <= data.length; n++) {
      if (bd.getUint32(p, Endian.little) != 0x02014b50) return null;
      final method = bd.getUint16(p + 10, Endian.little);
      final compSize = bd.getUint32(p + 20, Endian.little);
      final nameLen = bd.getUint16(p + 28, Endian.little);
      final extraLen = bd.getUint16(p + 30, Endian.little);
      final commentLen = bd.getUint16(p + 32, Endian.little);
      final localOffset = bd.getUint32(p + 42, Endian.little);
      final entryName = utf8.decode(data.sublist(p + 46, p + 46 + nameLen));
      if (entryName == name) {
        final lNameLen = bd.getUint16(localOffset + 26, Endian.little);
        final lExtraLen = bd.getUint16(localOffset + 28, Endian.little);
        final start = localOffset + 30 + lNameLen + lExtraLen;
        final raw = data.sublist(start, start + compSize);
        if (method == 0) return raw;
        if (method == 8) return Uint8List.fromList(ZLibDecoder(raw: true).convert(raw));
        return null;
      }
      p += 46 + nameLen + extraLen + commentLen;
    }
    return null;
  }
}

/// Text-layer extractor for PDF 1.x.
///
/// Walks every object (including those packed in `/ObjStm` object streams),
/// inflates FlateDecode streams, builds font name -> ToUnicode CMap tables,
/// then interprets the text operators (Tj, TJ, ', ", Td, TD, Tm, T*) of each
/// page content stream in page order.
class PdfTextExtractor {
  final Uint8List bytes;
  final _objects = <int, String>{}; // object number -> body (latin1)
  final _streams = <int, Uint8List>{}; // object number -> decoded stream

  PdfTextExtractor(this.bytes);

  String extract() {
    final src = latin1.decode(bytes);
    if (!src.startsWith('%PDF')) throw const ResumeExtractionException('Not a PDF file');
    if (src.contains('/Encrypt')) {
      throw const ResumeExtractionException('This PDF is password-protected. Export an unprotected copy or paste the text.');
    }
    _indexObjects(src);

    final buffer = StringBuffer();
    for (final page in _pagesInOrder()) {
      final fonts = _fontsFor(page);
      for (final content in _contentStreams(page)) {
        buffer.write(_runContent(latin1.decode(content), fonts));
        buffer.write('\n');
      }
    }
    final text = buffer.toString();
    if (text.trim().length < 20) {
      throw const ResumeExtractionException(
        'No selectable text found. This looks like a scanned PDF; paste the text instead.',
      );
    }
    return text;
  }

  // ---------------------------------------------------------------- objects

  void _indexObjects(String src) {
    final objRe = RegExp(r'(\d+)\s+(\d+)\s+obj\b');
    for (final m in objRe.allMatches(src)) {
      final objNum = int.parse(m.group(1)!);
      final start = m.end;
      final end = src.indexOf('endobj', start);
      if (end < 0) continue;
      final body = src.substring(start, end);
      _objects[objNum] = body;
      final streamIdx = body.indexOf('stream');
      if (streamIdx >= 0 && body.substring(0, streamIdx).contains('<<')) {
        var dataStart = start + streamIdx + 6;
        if (src.codeUnitAt(dataStart) == 0x0D) dataStart++;
        if (src.codeUnitAt(dataStart) == 0x0A) dataStart++;
        final dict = body.substring(0, streamIdx);
        var dataEnd = src.lastIndexOf('endstream', end);
        final len = RegExp(r'/Length\s+(\d+)(?!\s+\d+\s+R)').firstMatch(dict);
        if (len != null) {
          final l = int.parse(len.group(1)!);
          if (dataStart + l <= end) dataEnd = dataStart + l;
        }
        if (dataEnd <= dataStart) continue;
        final raw = bytes.sublist(dataStart, dataEnd);
        final decoded = _decodeStream(dict, raw);
        if (decoded != null) {
          _streams[objNum] = decoded;
          if (dict.contains('/ObjStm')) _unpackObjectStream(dict, decoded);
        }
      }
    }
  }

  Uint8List? _decodeStream(String dict, Uint8List raw) {
    if (!dict.contains('/Filter')) return raw;
    if (dict.contains('/FlateDecode')) {
      try {
        return Uint8List.fromList(ZLibDecoder().convert(raw));
      } catch (_) {
        try {
          return Uint8List.fromList(ZLibDecoder(raw: true).convert(raw.sublist(2)));
        } catch (_) {
          return null;
        }
      }
    }
    return null; // DCT/JBIG2 images etc. carry no text
  }

  void _unpackObjectStream(String dict, Uint8List data) {
    final n = int.tryParse(RegExp(r'/N\s+(\d+)').firstMatch(dict)?.group(1) ?? '');
    final first = int.tryParse(RegExp(r'/First\s+(\d+)').firstMatch(dict)?.group(1) ?? '');
    if (n == null || first == null) return;
    final text = latin1.decode(data);
    final header = text.substring(0, first).trim().split(RegExp(r'\s+')).map(int.tryParse).toList();
    for (var i = 0; i + 1 < header.length && i ~/ 2 < n; i += 2) {
      final objNum = header[i];
      final offset = header[i + 1];
      if (objNum == null || offset == null) continue;
      final start = first + offset;
      final end = (i + 3 < header.length && header[i + 3] != null) ? first + header[i + 3]! : text.length;
      if (start < text.length && end <= text.length && start <= end) {
        _objects.putIfAbsent(objNum, () => text.substring(start, end));
      }
    }
  }

  // ------------------------------------------------------------------ pages

  List<int> _pagesInOrder() {
    final catalog = _objects.entries.where((e) => RegExp(r'/Type\s*/Catalog').hasMatch(e.value)).firstOrNull;
    final rootRef = catalog == null ? null : RegExp(r'/Pages\s+(\d+)\s+\d+\s+R').firstMatch(catalog.value);
    final pages = <int>[];
    void walk(int objNum, int depth) {
      final body = _objects[objNum];
      if (body == null || depth > 32) return;
      if (RegExp(r'/Type\s*/Page(?!s)').hasMatch(body)) {
        pages.add(objNum);
        return;
      }
      final kids = RegExp(r'/Kids\s*\[([^\]]*)\]').firstMatch(body);
      if (kids == null) return;
      for (final k in RegExp(r'(\d+)\s+\d+\s+R').allMatches(kids.group(1)!)) {
        walk(int.parse(k.group(1)!), depth + 1);
      }
    }

    if (rootRef != null) walk(int.parse(rootRef.group(1)!), 0);
    if (pages.isEmpty) {
      // Broken page tree: fall back to every page object in file order.
      pages.addAll(_objects.entries.where((e) => RegExp(r'/Type\s*/Page(?!s)').hasMatch(e.value)).map((e) => e.key));
    }
    return pages;
  }

  List<Uint8List> _contentStreams(int page) {
    final body = _objects[page]!;
    final single = RegExp(r'/Contents\s+(\d+)\s+\d+\s+R').firstMatch(body);
    if (single != null) {
      final objNum = int.parse(single.group(1)!);
      // /Contents may point at an array object rather than a stream.
      final arrayBody = _objects[objNum];
      if (!_streams.containsKey(objNum) && arrayBody != null && arrayBody.trim().startsWith('[')) {
        return _refs(arrayBody).map((r) => _streams[r]).whereType<Uint8List>().toList();
      }
      final s = _streams[objNum];
      return s == null ? const [] : [s];
    }
    final array = RegExp(r'/Contents\s*\[([^\]]*)\]').firstMatch(body);
    if (array == null) return const [];
    return _refs(array.group(1)!).map((r) => _streams[r]).whereType<Uint8List>().toList();
  }

  Iterable<int> _refs(String s) => RegExp(r'(\d+)\s+\d+\s+R').allMatches(s).map((m) => int.parse(m.group(1)!));

  /// Resource font name (e.g. "F1") -> font object number, following
  /// inherited and indirect /Resources.
  Map<String, int> _fontsFor(int page) {
    final fonts = <String, int>{};
    String? resources(int obj, int depth) {
      final body = _objects[obj];
      if (body == null || depth > 16) return null;
      final indirect = RegExp(r'/Resources\s+(\d+)\s+\d+\s+R').firstMatch(body);
      if (indirect != null) return _objects[int.parse(indirect.group(1)!)];
      final idx = body.indexOf('/Resources');
      if (idx >= 0) return body.substring(idx);
      final parent = RegExp(r'/Parent\s+(\d+)\s+\d+\s+R').firstMatch(body);
      return parent == null ? null : resources(int.parse(parent.group(1)!), depth + 1);
    }

    final res = resources(page, 0);
    if (res == null) return fonts;
    String? fontDict;
    final indirectFont = RegExp(r'/Font\s+(\d+)\s+\d+\s+R').firstMatch(res);
    if (indirectFont != null) {
      fontDict = _objects[int.parse(indirectFont.group(1)!)];
    } else {
      final start = res.indexOf('/Font');
      if (start >= 0) fontDict = _balancedDict(res, res.indexOf('<<', start));
    }
    if (fontDict == null) return fonts;
    for (final m in RegExp(r'/([^\s/<>\[\]()]+)\s+(\d+)\s+\d+\s+R').allMatches(fontDict)) {
      fonts[m.group(1)!] = int.parse(m.group(2)!);
    }
    return fonts;
  }

  String? _balancedDict(String s, int start) {
    if (start < 0) return null;
    var depth = 0;
    for (var i = start; i < s.length - 1; i++) {
      if (s[i] == '<' && s[i + 1] == '<') {
        depth++;
        i++;
      } else if (s[i] == '>' && s[i + 1] == '>') {
        depth--;
        i++;
        if (depth == 0) return s.substring(start, i + 1);
      }
    }
    return null;
  }

  // ------------------------------------------------------------------ fonts

  final _fontCache = <int, _PdfFont>{};

  _PdfFont _font(int objNum) => _fontCache.putIfAbsent(objNum, () {
        final body = _objects[objNum] ?? '';
        final toUnicode = RegExp(r'/ToUnicode\s+(\d+)\s+\d+\s+R').firstMatch(body);
        final cmapStream = toUnicode == null ? null : _streams[int.parse(toUnicode.group(1)!)];
        final cmap = cmapStream == null ? null : _CMap.parse(latin1.decode(cmapStream));
        final isType0 = body.contains('/Type0');
        final widths = <int, double>{};
        double? defaultWidth;

        if (isType0) {
          var descBody = '';
          final direct = RegExp(r'/DescendantFonts\s*\[\s*(\d+)\s+\d+\s+R').firstMatch(body);
          final indirect = RegExp(r'/DescendantFonts\s+(\d+)\s+\d+\s+R').firstMatch(body);
          if (direct != null) {
            descBody = _objects[int.parse(direct.group(1)!)] ?? '';
          } else if (indirect != null) {
            final arr = _objects[int.parse(indirect.group(1)!)] ?? '';
            final ref = RegExp(r'(\d+)\s+\d+\s+R').firstMatch(arr);
            if (ref != null) descBody = _objects[int.parse(ref.group(1)!)] ?? '';
          }
          defaultWidth = double.tryParse(RegExp(r'/DW\s+(\d+(?:\.\d+)?)').firstMatch(descBody)?.group(1) ?? '') ?? 1000;
          final w = _arrayValue(descBody, 'W');
          if (w != null) _parseCidWidths(w, widths);
        } else {
          final first = int.tryParse(RegExp(r'/FirstChar\s+(\d+)').firstMatch(body)?.group(1) ?? '');
          final w = _arrayValue(body, 'Widths');
          if (first != null && w != null) {
            final values = RegExp(r'-?\d+(?:\.\d+)?').allMatches(w).map((m) => double.parse(m.group(0)!)).toList();
            for (var i = 0; i < values.length; i++) {
              widths[first + i] = values[i];
            }
          }
        }
        return _PdfFont(
          cmap: cmap,
          codeBytes: cmap?.codeBytes ?? (isType0 ? 2 : 1),
          widths: widths,
          defaultWidth: defaultWidth,
        );
      });

  /// Value of `/Key [ ... ]` or `/Key n 0 R` (pointing at an array object).
  String? _arrayValue(String body, String key) {
    final ref = RegExp('/$key' r'\s+(\d+)\s+\d+\s+R').firstMatch(body);
    if (ref != null) return _objects[int.parse(ref.group(1)!)];
    final idx = body.indexOf(RegExp('/$key' r'\s*\['));
    if (idx < 0) return null;
    final start = body.indexOf('[', idx);
    var depth = 0;
    for (var i = start; i < body.length; i++) {
      if (body[i] == '[') depth++;
      if (body[i] == ']' && --depth == 0) return body.substring(start + 1, i);
    }
    return null;
  }

  /// CID /W arrays mix `c [w1 w2 ...]` and `cFirst cLast w` entries.
  static void _parseCidWidths(String w, Map<int, double> out) {
    final tokens = RegExp(r'\[|\]|-?\d+(?:\.\d+)?').allMatches(w).map((m) => m.group(0)!).toList();
    var i = 0;
    while (i < tokens.length) {
      final c = int.tryParse(tokens[i]);
      if (c == null) {
        i++;
        continue;
      }
      if (i + 1 < tokens.length && tokens[i + 1] == '[') {
        var j = i + 2;
        var code = c;
        while (j < tokens.length && tokens[j] != ']') {
          out[code++] = double.parse(tokens[j]);
          j++;
        }
        i = j + 1;
      } else if (i + 2 < tokens.length) {
        final last = int.tryParse(tokens[i + 1]);
        final width = double.tryParse(tokens[i + 2]);
        if (last != null && width != null && last - c < 0x10000) {
          for (var k = c; k <= last; k++) {
            out[k] = width;
          }
        }
        i += 3;
      } else {
        break;
      }
    }
  }

  // --------------------------------------------------------- content stream

  /// Interprets text operators, placing every shown string at its absolute
  /// page position (CTM x text matrix) so line breaks and word gaps come out
  /// right whether a PDF writes one glyph, one word or one line per operator.
  String _runContent(String content, Map<String, int> fonts) {
    final out = StringBuffer();
    final tokens = _PdfLexer(content).tokens();
    final operands = <Object>[];
    _PdfFont? font;
    double fontSize = 10;

    // Graphics state: only scale + translation are tracked (no rotation).
    var ctm = const _Affine(1, 1, 0, 0);
    final stack = <_Affine>[];
    // Text line matrix (text space origin of the current line) and text matrix scale.
    var lineX = 0.0, lineY = 0.0, tmScaleX = 1.0, tmScaleY = 1.0;
    // Pen position within the current line (text space units).
    var penX = 0.0;

    double lastY = double.nan; // absolute y of the previous glyph run
    double lastEndX = double.nan; // absolute x where the previous run ended
    var last = '\n';

    void emit(String text) {
      if (text.isEmpty) return;
      out.write(text);
      last = text[text.length - 1];
    }

    void show(_Str str) {
      final (text, advance) = _PdfFont.decode(font, str);
      final absX = ctm.e + ctm.a * (lineX + penX * tmScaleX);
      final absY = ctm.f + ctm.d * lineY;
      final em = (fontSize * tmScaleY * ctm.d).abs().clamp(1.0, 500.0);
      if (!lastY.isNaN && (absY - lastY).abs() > em * 0.5) {
        if (last != '\n') emit('\n');
      } else if (!lastEndX.isNaN && absX - lastEndX > em * 0.2 && last != ' ' && last != '\n') {
        emit(' ');
      }
      emit(text);
      penX += advance / 1000 * fontSize;
      lastY = absY;
      lastEndX = ctm.e + ctm.a * (lineX + penX * tmScaleX);
    }

    void nextLine(double tx, double ty) {
      lineX += tx * tmScaleX;
      lineY += ty * tmScaleY;
      penX = 0;
    }

    double n(int i) => operands.length > i && operands[i] is num ? (operands[i] as num).toDouble() : 0;

    for (final t in tokens) {
      if (t is! _Op) {
        operands.add(t);
        continue;
      }
      switch (t.name) {
        case 'q':
          stack.add(ctm);
        case 'Q':
          if (stack.isNotEmpty) ctm = stack.removeLast();
        case 'cm':
          if (operands.length >= 6) ctm = ctm.then(n(0), n(3), n(4), n(5));
        case 'BT':
          lineX = lineY = penX = 0;
          tmScaleX = tmScaleY = 1;
        case 'Tf':
          if (operands.length >= 2 && operands[operands.length - 2] is _Name) {
            final obj = fonts[(operands[operands.length - 2] as _Name).value];
            font = obj == null ? null : _font(obj);
            final size = operands.last;
            if (size is num && size != 0) fontSize = size.toDouble().abs();
          }
        case 'Td':
        case 'TD':
          if (operands.length >= 2) nextLine(n(0), n(1));
        case 'Tm':
          if (operands.length >= 6) {
            tmScaleX = n(0).abs() > 0 ? n(0) : 1;
            tmScaleY = n(3).abs() > 0 ? n(3) : 1;
            lineX = n(4);
            lineY = n(5);
            penX = 0;
          }
        case 'T*':
          nextLine(0, -fontSize * 1.2);
        case 'Tj':
          if (operands.isNotEmpty && operands.last is _Str) show(operands.last as _Str);
        case "'":
        case '"':
          nextLine(0, -fontSize * 1.2);
          if (operands.isNotEmpty && operands.last is _Str) show(operands.last as _Str);
        case 'TJ':
          if (operands.isNotEmpty && operands.last is List) {
            for (final part in operands.last as List) {
              if (part is _Str) {
                show(part);
              } else if (part is num) {
                // Numbers shift the pen left by n/1000 em; a big negative
                // shift is a word gap in PDFs that don't draw spaces.
                if (part < -200 && last != ' ' && last != '\n') emit(' ');
                penX -= part / 1000 * fontSize;
                lastEndX = ctm.e + ctm.a * (lineX + penX * tmScaleX);
              }
            }
          }
      }
      operands.clear();
    }
    return out.toString();
  }
}

/// Scale + translation part of a PDF transformation matrix.
class _Affine {
  final double a, d, e, f;
  const _Affine(this.a, this.d, this.e, this.f);

  /// Pre-multiplies a `cm` matrix [ma 0 0 md me mf] onto this one.
  _Affine then(double ma, double md, double me, double mf) => _Affine(ma * a, md * d, me * a + e, mf * d + f);
}

class _Op {
  final String name;
  const _Op(this.name);
}

class _Name {
  final String value;
  const _Name(this.value);
}

class _Str {
  final List<int> bytes;
  final bool hex;
  const _Str(this.bytes, {required this.hex});

  static int _winAnsi(int b) => switch (b) {
        0x91 => 0x2018, 0x92 => 0x2019, 0x93 => 0x201C, 0x94 => 0x201D,
        0x95 => 0x2022, 0x96 => 0x2013, 0x97 => 0x2014, 0x85 => 0x2026,
        _ => b,
      };
}

class _PdfFont {
  final _CMap? cmap;
  final int codeBytes;
  final Map<int, double> widths;
  final double? defaultWidth;

  const _PdfFont({this.cmap, required this.codeBytes, required this.widths, this.defaultWidth});

  /// Decodes a shown string to Unicode plus its advance in 1/1000 em.
  /// Without a font, bytes are read as WinAnsi and each glyph as 0.5 em.
  static (String, double) decode(_PdfFont? font, _Str str) {
    final bytes = str.bytes;
    final size = font?.codeBytes ?? 1;
    final sb = StringBuffer();
    var advance = 0.0;
    for (var i = 0; i + size <= bytes.length; i += size) {
      var code = 0;
      for (var j = 0; j < size; j++) {
        code = (code << 8) | bytes[i + j];
      }
      final mapped = font?.cmap?.lookup(code);
      if (mapped != null) {
        sb.write(mapped);
      } else if (size == 1) {
        sb.writeCharCode(_Str._winAnsi(code));
      }
      advance += font?.widths[code] ?? font?.defaultWidth ?? 500;
    }
    var text = sb.toString();
    // Two-byte hex strings with no usable CMap are usually UTF-16BE.
    if (text.isEmpty && str.hex && bytes.length.isEven && bytes.isNotEmpty && bytes.first == 0) {
      text = String.fromCharCodes([for (var i = 0; i + 1 < bytes.length; i += 2) (bytes[i] << 8) | bytes[i + 1]]);
    }
    return (text, advance);
  }
}

/// ToUnicode CMap: bfchar / bfrange tables, with code width from the
/// codespace range (1 byte for simple fonts, 2 for Identity-H CID fonts).
class _CMap {
  final Map<int, String> _map;
  final int codeBytes;

  _CMap(this._map, this.codeBytes);


  static _CMap parse(String src) {
    final map = <int, String>{};
    var codeBytes = 1;
    final cs = RegExp(r'begincodespacerange\s*<([0-9A-Fa-f]+)>').firstMatch(src);
    if (cs != null) codeBytes = (cs.group(1)!.length / 2).ceil();

    String hexToUnicode(String hex) {
      final units = <int>[];
      for (var i = 0; i + 4 <= hex.length; i += 4) {
        units.add(int.parse(hex.substring(i, i + 4), radix: 16));
      }
      if (hex.length == 2) units.add(int.parse(hex, radix: 16));
      return String.fromCharCodes(units);
    }

    for (final block in RegExp(r'beginbfchar(.*?)endbfchar', dotAll: true).allMatches(src)) {
      for (final m in RegExp(r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]*)>').allMatches(block.group(1)!)) {
        map[int.parse(m.group(1)!, radix: 16)] = hexToUnicode(m.group(2)!);
      }
    }
    for (final block in RegExp(r'beginbfrange(.*?)endbfrange', dotAll: true).allMatches(src)) {
      final body = block.group(1)!;
      for (final m in RegExp(r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*(<[0-9A-Fa-f]*>|\[[^\]]*\])').allMatches(body)) {
        final lo = int.parse(m.group(1)!, radix: 16);
        final hi = int.parse(m.group(2)!, radix: 16);
        final dst = m.group(3)!;
        if (hi < lo || hi - lo > 0xFFFF) continue;
        if (dst.startsWith('[')) {
          final items = RegExp(r'<([0-9A-Fa-f]*)>').allMatches(dst).toList();
          for (var i = 0; i < items.length && lo + i <= hi; i++) {
            map[lo + i] = hexToUnicode(items[i].group(1)!);
          }
        } else {
          final hex = dst.substring(1, dst.length - 1);
          if (hex.isEmpty) continue;
          final base = int.parse(hex.substring(hex.length - 4 < 0 ? 0 : hex.length - 4), radix: 16);
          final prefix = hex.length > 4 ? hexToUnicode(hex.substring(0, hex.length - 4)) : '';
          for (var c = lo; c <= hi; c++) {
            map[c] = prefix + String.fromCharCode(base + (c - lo));
          }
        }
      }
    }
    return _CMap(map, codeBytes);
  }

  String? lookup(int code) => _map[code];
}

/// Tokenizer for PDF content streams: numbers, names, strings (literal and
/// hex), arrays, and operators. Dictionaries and inline images are skipped.
class _PdfLexer {
  final String s;
  int i = 0;

  _PdfLexer(this.s);

  List<Object> tokens() {
    final out = <Object>[];
    final stack = <List<Object>>[];
    void add(Object t) => stack.isEmpty ? out.add(t) : stack.last.add(t);

    while (i < s.length) {
      final c = s[i];
      if (' \t\r\n\f\x00'.contains(c)) {
        i++;
      } else if (c == '%') {
        while (i < s.length && s[i] != '\n' && s[i] != '\r') {
          i++;
        }
      } else if (c == '(') {
        add(_Str(_literal(), hex: false));
      } else if (c == '<' && i + 1 < s.length && s[i + 1] == '<') {
        _skipDict();
      } else if (c == '<') {
        add(_Str(_hex(), hex: true));
      } else if (c == '[') {
        stack.add(<Object>[]);
        i++;
      } else if (c == ']') {
        i++;
        if (stack.isNotEmpty) {
          final arr = stack.removeLast();
          add(arr);
        }
      } else if (c == '/') {
        i++;
        final start = i;
        while (i < s.length && !' \t\r\n\f/[]()<>{}%'.contains(s[i])) {
          i++;
        }
        add(_Name(s.substring(start, i)));
      } else if ('+-.0123456789'.contains(c)) {
        final start = i;
        i++;
        while (i < s.length && '.0123456789'.contains(s[i])) {
          i++;
        }
        add(num.tryParse(s.substring(start, i)) ?? 0);
      } else {
        final start = i;
        while (i < s.length && !' \t\r\n\f/[]()<>{}%'.contains(s[i])) {
          i++;
        }
        if (i == start) {
          i++;
          continue;
        }
        final op = s.substring(start, i);
        if (op == 'BI') {
          // Inline image: skip binary data up to "EI".
          final end = s.indexOf(RegExp(r'\sEI\s'), i);
          i = end < 0 ? s.length : end + 4;
          continue;
        }
        stack.clear();
        out.add(_Op(op));
      }
    }
    return out;
  }

  void _skipDict() {
    var depth = 0;
    while (i < s.length - 1) {
      if (s[i] == '<' && s[i + 1] == '<') {
        depth++;
        i += 2;
      } else if (s[i] == '>' && s[i + 1] == '>') {
        depth--;
        i += 2;
        if (depth == 0) return;
      } else {
        i++;
      }
    }
    i = s.length;
  }

  List<int> _literal() {
    final out = <int>[];
    var depth = 0;
    i++; // (
    while (i < s.length) {
      final c = s[i];
      if (c == '\\') {
        i++;
        if (i >= s.length) break;
        final e = s[i];
        switch (e) {
          case 'n':
            out.add(10);
          case 'r':
            out.add(13);
          case 't':
            out.add(9);
          case 'b':
            out.add(8);
          case 'f':
            out.add(12);
          case '\r':
          case '\n':
            break; // line continuation
          default:
            if ('01234567'.contains(e)) {
              var oct = e;
              while (oct.length < 3 && i + 1 < s.length && '01234567'.contains(s[i + 1])) {
                i++;
                oct += s[i];
              }
              out.add(int.parse(oct, radix: 8) & 0xFF);
            } else {
              out.add(e.codeUnitAt(0));
            }
        }
        i++;
      } else if (c == '(') {
        depth++;
        out.add(c.codeUnitAt(0));
        i++;
      } else if (c == ')') {
        if (depth == 0) {
          i++;
          break;
        }
        depth--;
        out.add(c.codeUnitAt(0));
        i++;
      } else {
        out.add(c.codeUnitAt(0));
        i++;
      }
    }
    return out;
  }

  List<int> _hex() {
    i++; // <
    final start = i;
    while (i < s.length && s[i] != '>') {
      i++;
    }
    var hex = s.substring(start, i).replaceAll(RegExp(r'\s'), '');
    i++; // >
    if (hex.length.isOdd) hex += '0';
    return [for (var k = 0; k + 1 < hex.length; k += 2) int.tryParse(hex.substring(k, k + 2), radix: 16) ?? 0];
  }
}
