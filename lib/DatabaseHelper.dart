import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  Database? _database;
  ↓↓↓↓↓↓↓↓↓↓↓↓↓ファイル名設定↓↓↓↓↓↓↓↓↓↓↓↓↓
  static const String _databaseName = "";

  Future<String> getDatabasePath() async {
    final dbPath = await getApplicationDocumentsDirectory();
    return p.join(dbPath.path, _databaseName);
  }

  // データベースインスタンスを返すように変更
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = p.join(dbPath.path, 'memo.db');

    if (!File(path).existsSync()) {
      ByteData data = await rootBundle.load('assets/memo.db');
      List<int> bytes =
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes);
    }
    // openDatabase の結果 (Database インスタンス) を返す
    return await openDatabase(path);
  }

  // 分類リストを返す
  Future<List<Map<String, dynamic>>> loadBunrui() async {
    final db = await database; // データベースインスタンスを取得
    final bunruiData = await db.query('tbl_bunrui', orderBy: 'bunrui_id');
    return bunruiData;
  }

  // メモリストと選択された分類名を返す (Mapでラップする)
  Future<Map<String, dynamic>> loadMemos({
    required List<Map<String, dynamic>> bunruiList, // 分類リストを引数で受け取る
    int? bunruiId,
  }) async {
    final db = await database; // データベースインスタンスを取得
    List<Map<String, dynamic>> data;
    String? bunruiName;

    if (bunruiId != null) {
      data = await db.query(
        'tbl_containts',
        where: 'bunrui_id = ?',
        whereArgs: [bunruiId],
        orderBy: 'containts_id DESC',
      );
      // bunruiList は外部から渡される想定
      final selected = bunruiList.firstWhere(
            (b) => b['bunrui_id'] == bunruiId,
        orElse: () => {'bunrui_name': '不明な分類'},
      );
      bunruiName = selected['bunrui_name'];
    } else {
      data = await db.query('tbl_containts', orderBy: 'containts_id DESC');
      bunruiName = null; // 全件表示の場合は分類名は null
    }
    return {'memos': data, 'bunruiName': bunruiName};
  }

  // データベースを閉じるメソッドも用意しておくと良いでしょう
  Future<void> close() async {
    final db = _database; // ローカル変数に代入してnullチェックを容易に
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // --- 以下は MemoListPage に残る CRUD 操作で使うメソッド ---
  // 必要に応じてこれらも DatabaseHelper に移すことも可能です
  // その場合は、Database インスタンスを引数で受け取るか、
  // このクラス内で database getter を使用します。

  Future<void> deleteMemosInBunrui(int bunruiId) async {
    final db = await database;
    await db.delete(
      'tbl_containts',
      where: 'bunrui_id = ?',
      whereArgs: [bunruiId],
    );
  }

  Future<void> deleteMemo(int containtsId) async {
    final db = await database;
    await db.delete(
      'tbl_containts',
      where: 'containts_id = ?',
      whereArgs: [containtsId],
    );
  }

  Future<void> deleteBunruiAndMemos(int bunruiId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('tbl_containts', where: 'bunrui_id = ?', whereArgs: [bunruiId]);
      await txn.delete('tbl_bunrui', where: 'bunrui_id = ?', whereArgs: [bunruiId]);
    });
  }

  Future<void> insertBunrui(String name) async {
    final db = await database;
    await db.insert('tbl_bunrui', {
      'bunrui_name': name,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}