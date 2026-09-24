import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

export 'package:open_file/open_file.dart' show OpenResult, ResultType;

class ResumeFileResult {
  final String fileName;
  final String localPath;
  final int fileSizeBytes;

  const ResumeFileResult({
    required this.fileName,
    required this.localPath,
    required this.fileSizeBytes,
  });
}

class ResumeStorageHelper {
  static const _uuid = Uuid();

  /// Picks a resume file (PDF, DOCX, DOC, TXT) and copies it to app storage
  static Future<ResumeFileResult?> pickAndSaveResume() async {
    try {
      final pickedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'txt'],
      );

      if (pickedFile == null) {
        return null; // User cancelled
      }

      final originalPath = pickedFile.path;
      final originalName = pickedFile.name;

      if (originalPath == null) {
        return null;
      }

      final sourceFile = File(originalPath);
      if (!await sourceFile.exists()) {
        throw Exception('Selected file could not be found.');
      }

      // App documents directory -> resumes/
      final appDir = await getApplicationDocumentsDirectory();
      final resumesDir = Directory(p.join(appDir.path, 'resumes'));
      if (!await resumesDir.exists()) {
        await resumesDir.create(recursive: true);
      }

      final sanitizedName = originalName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final uniqueFileName = '${_uuid.v4().substring(0, 8)}_$sanitizedName';
      final destinationPath = p.join(resumesDir.path, uniqueFileName);

      final savedFile = await sourceFile.copy(destinationPath);
      final size = await savedFile.length();

      return ResumeFileResult(
        fileName: originalName,
        localPath: savedFile.path,
        fileSizeBytes: size,
      );
    } catch (e) {
      debugPrint('Error picking/saving resume: $e');
      rethrow;
    }
  }

  /// Opens a resume file using system default viewer
  static Future<OpenResult> openResume(String localPath) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        return OpenResult(
          type: ResultType.fileNotFound,
          message: 'Resume file does not exist at local path: $localPath',
        );
      }
      return await OpenFile.open(localPath);
    } catch (e) {
      return OpenResult(
        type: ResultType.error,
        message: 'Could not open resume file: $e',
      );
    }
  }

  /// Deletes a resume file from local storage
  static Future<bool> deleteResumeFile(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting resume file: $e');
      return false;
    }
  }

  /// Checks if file exists
  static Future<bool> fileExists(String localPath) async {
    try {
      return await File(localPath).exists();
    } catch (_) {
      return false;
    }
  }
}

