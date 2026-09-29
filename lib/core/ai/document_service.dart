import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../constants/app_constants.dart';
import 'ai_service.dart';

enum DocFormat { pdf, docx }

class GeneratedDoc {
  final String path;
  final String markdown;
  const GeneratedDoc(this.path, this.markdown);
}

/// Long-form documents: Gemini writes Markdown, which is rendered on-device
/// to PDF or DOCX, saved under app documents, and opened.
class DocumentService {
  final AiService ai;
  DocumentService(this.ai);

  static const _system =
      'You write polished professional documents. Output GitHub-flavored Markdown only: # / ## / ### headings, '
      'paragraphs, "- " bullets, "1. " numbered lists and **bold**. No tables, images, code fences or HTML. '
      'Never invent facts, numbers, names or links that are not in the provided context; leave a [placeholder] instead.';

  Future<GeneratedDoc> create({required String title, required String prompt, DocFormat format = DocFormat.pdf}) async {
    final markdown = await ai.longForm(prompt, system: _system);
    final bytes = format == DocFormat.pdf ? await markdownToPdf(markdown, title: title) : markdownToDocx(markdown);
    final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'documents'));
    await dir.create(recursive: true);
    final slug = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    final stamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final file = File(p.join(dir.path, '${slug.isEmpty ? 'document' : slug}_$stamp.${format.name}'));
    await file.writeAsBytes(bytes);
    return GeneratedDoc(file.path, markdown);
  }

  static Future<OpenResult> open(String path) => OpenFile.open(path);

  // ------------------------------------------------------------------ PDF

  /// Android ships Roboto; using it gets ₹, – and curly quotes right, which
  /// the PDF standard Helvetica can't encode.
  static Future<(pw.Font?, pw.Font?)> _systemFonts() async {
    Future<pw.Font?> load(String path) async {
      try {
        final f = File(path);
        if (!await f.exists()) return null;
        return pw.Font.ttf(ByteData.sublistView(await f.readAsBytes()));
      } catch (_) {
        return null;
      }
    }

    return (await load('/system/fonts/Roboto-Regular.ttf'), await load('/system/fonts/Roboto-Bold.ttf'));
  }

  static pw.TextSpan _inline(String text, {required bool unicode}) {
    final t = unicode ? text : text.replaceAll('₹', 'Rs. ').replaceAll(RegExp('[–—]'), '-').replaceAll(RegExp('[‘’]'), "'").replaceAll(RegExp('[“”]'), '"');
    final spans = <pw.TextSpan>[];
    final parts = t.split('**');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(pw.TextSpan(text: parts[i], style: i.isOdd ? const pw.TextStyle(fontWeight: pw.FontWeight.bold) : null));
    }
    return pw.TextSpan(children: spans);
  }

  static Future<Uint8List> markdownToPdf(String markdown, {required String title}) async {
    final (regular, bold) = await _systemFonts();
    final unicode = regular != null;
    final doc = pw.Document(title: title, author: AppConstants.appName);
    final accent = PdfColor.fromHex('#00B386');
    final widgets = <pw.Widget>[];

    for (final raw in markdown.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        widgets.add(pw.SizedBox(height: 6));
      } else if (line.startsWith('# ')) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.RichText(text: _inline(line.substring(2), unicode: unicode), textScaleFactor: 1.9),
        ));
        widgets.add(pw.Container(height: 2, width: 48, color: accent, margin: const pw.EdgeInsets.only(bottom: 10)));
      } else if (line.startsWith('## ')) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
          child: pw.RichText(text: _inline('**${line.substring(3)}**', unicode: unicode), textScaleFactor: 1.35),
        ));
      } else if (line.startsWith('### ')) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6, bottom: 2),
          child: pw.RichText(text: _inline('**${line.substring(4)}**', unicode: unicode), textScaleFactor: 1.1),
        ));
      } else if (RegExp(r'^\s*[-*] ').hasMatch(line)) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 10, bottom: 3),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Container(width: 4, height: 4, margin: const pw.EdgeInsets.only(top: 5, right: 8), decoration: pw.BoxDecoration(color: accent, shape: pw.BoxShape.circle)),
            pw.Expanded(child: pw.RichText(text: _inline(line.replaceFirst(RegExp(r'^\s*[-*] '), ''), unicode: unicode))),
          ]),
        ));
      } else if (RegExp(r'^\s*\d+\. ').hasMatch(line)) {
        final m = RegExp(r'^\s*(\d+)\. (.*)').firstMatch(line)!;
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 10, bottom: 3),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.SizedBox(width: 18, child: pw.Text('${m.group(1)}.')),
            pw.Expanded(child: pw.RichText(text: _inline(m.group(2)!, unicode: unicode))),
          ]),
        ));
      } else {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.RichText(text: _inline(line, unicode: unicode)),
        ));
      }
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(48, 48, 48, 56),
      theme: regular == null ? null : pw.ThemeData.withFont(base: regular, bold: bold ?? regular),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ),
      build: (_) => widgets,
    ));
    return doc.save();
  }

  // ----------------------------------------------------------------- DOCX

  static String _esc(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

  static String _runs(String text, {bool allBold = false, int? sizeHalfPts}) {
    final parts = text.split('**');
    final sb = StringBuffer();
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      final bold = allBold || i.isOdd;
      sb.write('<w:r><w:rPr>${bold ? '<w:b/>' : ''}${sizeHalfPts != null ? '<w:sz w:val="$sizeHalfPts"/>' : ''}</w:rPr>'
          '<w:t xml:space="preserve">${_esc(parts[i])}</w:t></w:r>');
    }
    return sb.toString();
  }

  /// Minimal but valid WordprocessingML package.
  static Uint8List markdownToDocx(String markdown) {
    final body = StringBuffer();
    for (final raw in markdown.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) continue;
      if (line.startsWith('# ')) {
        body.write('<w:p><w:pPr><w:spacing w:after="160"/></w:pPr>${_runs(line.substring(2), allBold: true, sizeHalfPts: 36)}</w:p>');
      } else if (line.startsWith('## ')) {
        body.write('<w:p><w:pPr><w:spacing w:before="200" w:after="80"/></w:pPr>${_runs(line.substring(3), allBold: true, sizeHalfPts: 28)}</w:p>');
      } else if (line.startsWith('### ')) {
        body.write('<w:p>${_runs(line.substring(4), allBold: true, sizeHalfPts: 24)}</w:p>');
      } else if (RegExp(r'^\s*[-*] ').hasMatch(line)) {
        body.write('<w:p><w:pPr><w:ind w:left="360"/></w:pPr>${_runs('• ${line.replaceFirst(RegExp(r'^\s*[-*] '), '')}')}</w:p>');
      } else {
        body.write('<w:p>${_runs(line)}</w:p>');
      }
    }
    const contentTypes = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
        '</Types>';
    const rels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        '</Relationships>';
    final document = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>$body'
        '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134"/></w:sectPr>'
        '</w:body></w:document>';
    final archive = Archive()
      ..addFile(ArchiveFile.bytes('[Content_Types].xml', utf8.encode(contentTypes)))
      ..addFile(ArchiveFile.bytes('_rels/.rels', utf8.encode(rels)))
      ..addFile(ArchiveFile.bytes('word/document.xml', utf8.encode(document)));
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }
}

final documentServiceProvider = Provider<DocumentService>((ref) => DocumentService(ref.watch(aiServiceProvider)));
