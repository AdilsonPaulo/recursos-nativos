import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;

class DbUtil {
  static Future<sql.Database> openDatabaseConnection() async {
    final databasePath = await sql.getDatabasesPath();
    final pathToDatabase = path.join(databasePath, 'places.db');

    return sql.openDatabase(
      pathToDatabase,
      onCreate: (db, version) {
        return db.execute(
            'CREATE TABLE places (id TEXT PRIMARY KEY, title TEXT, image TEXT, location TEXT, creationDate TEXT)');
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < newVersion) {
          db.execute('ALTER TABLE places ADD COLUMN creationDate TEXT');
        }
      },
      version: 3,
    );
  }

  static Future<void> insert(String table, Map<String, dynamic> data) async {
    final db = await DbUtil.openDatabaseConnection();
    await db.insert(
      table,
      data,
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getData(String table) async {
    final db = await DbUtil.openDatabaseConnection();
    return db.query(table);
  }

  static Future<void> update(
      String table, Map<String, dynamic> data, String id) async {
    final db = await DbUtil.openDatabaseConnection();
    await db.update(
      table,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> delete(String table, String id) async {
    final db = await DbUtil.openDatabaseConnection();
    await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> clearTable(String table) async {
    final db = await DbUtil.openDatabaseConnection();
    await db.delete(table);
  }

  static Future<int> countRecords(String table) async {
    final db = await DbUtil.openDatabaseConnection();
    return sql.Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $table')) ??
        0;
  }
}
