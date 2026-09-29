import 'dart:io';

import 'package:career_os/features/career/services/resume_text_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<String> extract(String name) => ResumeTextExtractor.extractFromFile('test/fixtures/$name');

  test('Chrome/Skia PDF (CID fonts + ToUnicode) keeps text and line order', () async {
    final text = await extract('sample_resume_chrome.pdf');
    final lines = text.split('\n');
    expect(lines.first, 'Priya Raman');
    expect(text, contains('priya.raman@example.com'));
    expect(text, contains('Senior Flutter Developer'));
    expect(text, contains('Led migration of the partner app to Flutter and Riverpod, cutting crash rate by 38%.'));
    expect(text, contains('Dart, Kotlin, Java, TypeScript, SQL, Flutter'));
    expect(text, contains('B.Tech in Computer Science, Anna University, 2019'));
    expect(text.indexOf('Experience'), lessThan(text.indexOf('Education')));
  });

  test('PDF 1.5 with object streams, FlateDecode and WinAnsi literals', () async {
    final text = await extract('sample_resume_objstm.pdf');
    expect(text.split('\n').first, 'Sam O’Neil');
    expect(text, contains('Data Engineer'));
    expect(text, contains('EXPERIENCE'));
    expect(text, contains('Built Spark pipelines processing 4TB/day'));
    expect(text, contains('Cut costs by 30%'));
  });

  test('DOCX paragraphs and list items', () async {
    final text = await extract('sample_resume.docx');
    expect(text.split('\n').first, 'Arjun Mehta');
    expect(text, contains('• Scaled payment ledger to 10K TPS using Go, Kafka and PostgreSQL.'));
    expect(text, contains('M.S. Computer Science, Georgia Tech, 2020'));
  });

  test('plain text and markdown pass through normalized', () {
    final text = ResumeTextExtractor.extractFromBytes(
      File('test/fixtures/sample_resume.html').readAsBytesSync(),
      fileName: 'resume.md',
    );
    expect(text, contains('Priya Raman'));
  });

  test('rejects non-PDF bytes and legacy .doc with a readable message', () {
    expect(
      () => ResumeTextExtractor.extractFromBytes(File('test/fixtures/sample_resume.docx').readAsBytesSync(), fileName: 'x.pdf'),
      throwsA(isA<ResumeExtractionException>()),
    );
    expect(
      () => ResumeTextExtractor.extractFromBytes(File('test/fixtures/sample_resume.docx').readAsBytesSync(), fileName: 'x.doc'),
      throwsA(isA<ResumeExtractionException>().having((e) => e.message, 'message', contains('.docx'))),
    );
  });
}
