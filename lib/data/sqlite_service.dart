import 'dart:io';

import 'package:renters_io_taws/models/product_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';

class SqliteService {
  Future<Database> initializeDB() async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, "database.db");

    // Check if the database exists
    var exists = await databaseExists(path);

    if (!exists) {
      print("Creating new copy from asset");
      // Make sure the parent directory exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy from asset
      ByteData data = await rootBundle.load(join("assets", "database.db"));
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      // Write and flush the bytes written
      await File(path).writeAsBytes(bytes, flush: true);
    } else {
      print("Opening existing database");
    }

    return await openDatabase(
      path,
      onCreate: (database, version) async {
        await database.execute(
          "CREATE TABLE Products (id VARCHAR(36) PRIMARY KEY, name VARCHAR(255) NOT NULL, category TEXT NOT NULL CHECK(category IN ('metal', 'plastic', 'wood', 'glass', 'paper')), quantity INT NOT NULL, price DECIMAL(10, 2) NOT NULL, infractionCost DECIMAL(10, 2) NOT NULL, imageRoute VARCHAR(255) NOT NULL)",
        );
      },
      version: 1,
      readOnly: false,
    );
  }

  Future<int> createProduct(ProductModel product) async {
    final Database db = await initializeDB();
    final id = await db.insert(
      'Products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  Future<List<ProductModel>> getProducts() async {
    final Database db = await initializeDB();
    final List<Map<String, dynamic>> maps = await db.query('Products');

    return List.generate(maps.length, (i) {
      return ProductModel.fromMap(maps[i]);
    });
  }

  Future<void> deleteProduct(String id) async {
    final db = await initializeDB();

    await db.delete(
      'Products',
      where: "id = ?",
      whereArgs: [id],
    );
  }
}