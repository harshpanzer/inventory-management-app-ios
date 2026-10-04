import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'inventory.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            barcode TEXT NOT NULL,
            name TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            dateSubmitted TEXT NOT NULL -- <-- ADDED: Date column
          )
        ''');
      },
    );
  }

  Future<int> insertItem(Item item) async {
    final db = await instance.database;
    return await db.insert('items', item.toMap());
  }

  Future<List<Item>> getItems() async {
    final db = await instance.database;
    final maps = await db.query('items');
    return maps.map((map) => Item.fromMap(map)).toList();
  }

  Future<int> deleteItem(int id) async {
    final db = await instance.database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }
  /// Export the database file via Share sheet (Google Drive, WhatsApp, Email, local storage)
  Future<void> exportDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inventory.db'); // Make sure this matches your DB filename
    final file = File(path);

    if (await file.exists()) {
      await Share.shareXFiles([XFile(file.path)], text: 'Inventory Database Backup');
    }
  }

  /// Pick a .db file and restore it by replacing current database file
  Future<bool> importDatabaseFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      File sourceFile = File(result.files.single.path!);

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'inventory.db'); // Make sure this matches your DB filename

      // Close the current DB before overwriting
      if (_database != null && _database!.isOpen) {
        await _database!.close();
        _database = null;
      }

      // Overwrite current database file
      await sourceFile.copy(path);
      return true;
    }
    return false;
  }
}