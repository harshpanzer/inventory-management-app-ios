import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
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
    if (kIsWeb) {
      // Use IndexedDB implementation for web
      databaseFactory = databaseFactoryFfiWeb;
    }

    String path = kIsWeb
        .toString()
        .contains('true') // web path check
        ? 'inventory.db'
        : join(await getDatabasesPath(), 'inventory.db');

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
            dateSubmitted TEXT NOT NULL
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
    final maps = await db.query('items', orderBy: 'id DESC');
    return maps.map((map) => Item.fromMap(map)).toList();
  }

  Future<int> deleteItem(int id) async {
    final db = await instance.database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  /// Export raw database file (Mobile only)
  Future<void> exportDatabaseFile() async {
    if (kIsWeb) return;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inventory.db');
    final file = File(path);

    if (await file.exists()) {
      await Share.shareXFiles([XFile(file.path)], text: 'Inventory Database Backup');
    }
  }

  /// Import raw database file (Mobile only)
  Future<bool> importDatabaseFile() async {
    if (kIsWeb) return false;
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null && result.files.single.path != null) {
      File sourceFile = File(result.files.single.path!);
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'inventory.db');

      if (_database != null && _database!.isOpen) {
        await _database!.close();
        _database = null;
      }

      await sourceFile.copy(path);
      return true;
    }
    return false;
  }
}