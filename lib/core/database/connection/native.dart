import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

LazyDatabase connect() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'career_os.sqlite'));

    // Workaround for older Android devices needing sqlite3 libs loaded explicitly
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    return NativeDatabase.createInBackground(file);
  });
}

