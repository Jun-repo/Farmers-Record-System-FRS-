import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  String? _customDatabasePath;

  DatabaseHelper._init();

  void setCustomDatabasePath(String path) {
    _customDatabasePath = path;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path;
    if (_customDatabasePath != null) {
      path = _customDatabasePath!;
    } else {
      String dbPath = await getDatabasesPath();
      path = join(dbPath, 'farmer_db.db');
    }

    await Directory(dirname(path)).create(recursive: true);
    bool dbExists = await File(path).exists();

    return await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: dbExists ? null : _createDB, // Skip creation if it exists
      ),
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE respondents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_picture TEXT,
        first_name TEXT NOT NULL,
        middle_name TEXT,
        last_name TEXT NOT NULL,
        suffix TEXT,
        age INTEGER NOT NULL,
        gender TEXT,
        address TEXT,
        spouse TEXT,
        spouse_birthdate TEXT, 
        spouse_age INTEGER,    
        spouse_gender TEXT     
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        respondent_id INTEGER,
        product_name TEXT NOT NULL,
        area_hectares_every_product REAL,
        crop_harvest_date_every_product TEXT,
        crop_harvest_income_every_product INTEGER,
        total_income_per_year_every_product INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (respondent_id) REFERENCES respondents (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE admins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_picture TEXT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertAdmin(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('admins', row);
  }

  Future<int> insertRespondent(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('respondents', row);
  }

  Future<int> insertProduct(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('products', row);
  }

  Future<List<Map<String, dynamic>>> queryAllRespondents() async {
    final db = await database;
    return await db.query('respondents');
  }

  Future<List<Map<String, dynamic>>> queryProductsByRespondent(
      int respondentId) async {
    final db = await database;
    return await db.query(
      'products',
      where: 'respondent_id = ?',
      whereArgs: [respondentId],
    );
  }

  Future<List<Map<String, dynamic>>> queryAllProducts() async {
    final db = await database;
    return await db.query('products');
  }

  Future<int> updateRespondent(Map<String, dynamic> respondent) async {
    final db = await database;
    return await db.update(
      'respondents',
      respondent,
      where: 'id = ?',
      whereArgs: [respondent['id']],
    );
  }

  Future<int> updateProduct(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update(
      'products',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteRespondent(int id) async {
    final db = await database;
    return await db.delete('respondents', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProductsByRespondentId(int respondentId) async {
    final db = await database;
    return await db.delete('products',
        where: 'respondent_id = ?', whereArgs: [respondentId]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await database;
    _database = null;
    await db.close();
  }
}
