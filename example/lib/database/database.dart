import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'tables.dart';

class DatabaseProvider {
  static final Future<Database> database = _createDatabase();

  static Future<Database> _createDatabase() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, "stored.db");
    return await openDatabase(
      path,
      version: 1,
      onCreate: (database, version) async {
        for (String description in getTableDescriptions()) {
          await database.execute("CREATE TABLE $description");
        }
      },
    );
  }
}
