import 'dart:io';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'MemoCreatePage.dart';
import 'MemoEditPage.dart';
import 'DatabaseHelper.dart';
import 'SettingsPage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class MemoListPage extends StatefulWidget {
  @override
  _MemoListPageState createState() => _MemoListPageState();
}

class _MemoListPageState extends State<MemoListPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Map<String, dynamic>> _memos = [];
  List<Map<String, dynamic>> _bunruiList = [];
  int? _selectedBunruiId;
  String? _selectedBunruiName;
  bool _isLoading = true; // ローディング状態を管理

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // データベースの初期化は DatabaseHelper 内で行われる
      // まず分類リストをロード
      final bunruiData = await _dbHelper.loadBunrui();
      // 次にメモリストをロード
      final memoData = await _dbHelper.loadMemos(bunruiList: bunruiData);

      if (mounted) {
        setState(() {
          _bunruiList = bunruiData;
          _memos = memoData['memos'];
          _selectedBunruiName = memoData['bunruiName'];
          // 初期は全件なのでnull
          _selectedBunruiId = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // エラーハンドリング (例: SnackBarで表示)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('データの読み込みに失敗しました: $e')),
      );
      print("Error initializing data: $e");
    }
  }

  /**
   * 分類一覧再取得処理
   */
  Future<void> _refreshBunruiList() async {
    try {
      final bunruiData = await _dbHelper.loadBunrui();
      if (mounted) {
        setState(() {
          _bunruiList = bunruiData;
        });
      }
    } catch (e) {
      print("Error refreshing bunrui list: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分類リストの更新に失敗しました: $e')),
      );
    }
  }
  /**
   * メモ一覧再取得処理
   */
  Future<void> _refreshMemos({int? bunruiId}) async {
    setState(() {
      _isLoading = true; // メモ読み込み中
    });
    try {
      final memoData = await _dbHelper.loadMemos(bunruiList: _bunruiList, bunruiId: bunruiId);
      if (mounted) {
        setState(() {
          _memos = memoData['memos'];
          _selectedBunruiId = bunruiId;
          _selectedBunruiName = memoData['bunruiName'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print("Error refreshing memos: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('メモの読み込みに失敗しました: $e')),
      );
    }
  }

  /**
   * バックアップ用dbファイルエクスポート処理
   */
  Future<void> _exportDatabase() async {
    final directoryPath =
    await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOAD);
    // ios用
    // final directoryPath = await getApplicationDocumentsDirectory();
    try {
      final String originalPath = await _dbHelper.getDatabasePath();
      final File originalDbFile = File(originalPath);
      if (!await originalDbFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('データベースファイルが見つかりません。')),
        );
        return;
      }
      final String timestamp = DateTime.now().toIso8601String().replaceAll(
          ':', '-').replaceAll('.', '-');
      final String newFileName = 'memo_backup_$timestamp.db';
      final String filePath = '$directoryPath/$newFileName';
      final File newDbFile = await originalDbFile.copy(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'データベースをエクスポートしました: ${newDbFile.path}'),
          action: SnackBarAction(
            label: '共有',
            onPressed: () {
              Share.shareXFiles([XFile(newDbFile.path)],
                  text: 'データベースのバックアップ');
            },
          ),
        ),
      );
      print('Database exported to: ${newDbFile.path}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エクスポートに失敗しました: $e')),
      );
      print('Error exporting database: $e');
    }
  }

  /**
   * 分類内のメモ削除処理　iconゴミ箱押下
   */
  Future<void> _deleteMemosInSelectedBunrui() async {
    if (_selectedBunruiId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('確認'),
        content: Text('この分類のメモを全て削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('削除')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dbHelper.deleteMemosInBunrui(_selectedBunruiId!);
        await _refreshMemos(bunruiId: _selectedBunruiId); // データを再読み込み
      } catch (e) {
        print("Error deleting memos in bunrui: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('メモの削除に失敗しました: $e')),
        );
      }
    }
  }

  /**
   * メモ削除処理
   */
  Future<void> _deleteMemo(int id) async {
    try {
      await _dbHelper.deleteMemo(id);
      await _refreshMemos(bunruiId: _selectedBunruiId); // データを再読み込み
    } catch (e) {
      print("Error deleting memo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('メモの削除に失敗しました: $e')),
      );
    }
  }

  /**
   * 分類削除処理
   */
  Future<void> _deleteBunrui(int bunruiId) async {
    final confirm = await showDialog<bool>(
      // ... (showDialog の部分は変更なし) ...
      context: context,
      builder: (context) => AlertDialog(
        title: Text('分類の削除'),
        content: Text('この分類を削除しますか？\n関連するメモも削除されます。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('削除')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dbHelper.deleteBunruiAndMemos(bunruiId);
        await _refreshBunruiList();
        if (_selectedBunruiId == bunruiId) {
          await _refreshMemos();
        } else {
          await _refreshMemos(bunruiId: _selectedBunruiId); // 現在の分類を維持 (もしあれば)
        }
      } catch (e) {
        print("Error deleting bunrui: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分類の削除に失敗しました: $e')),
        );
      }
    }
  }

  /**
   * 分類新規作成処理 ドロワー icon "+" 押下
   */
  Future<void> _showAddBunruiDialog() async {
    TextEditingController controller = TextEditingController(); // _ を削除（ローカル変数なので）

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('新しい分類を作成'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: '分類名を入力'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  try {
                    await _dbHelper.insertBunrui(name);
                    await _refreshBunruiList(); // 分類リストを再読み込み
                  } catch (e) {
                    print("Error adding bunrui: $e");
                    // ここでもエラー表示を検討
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('分類の追加に失敗しました: $e')),
                    );
                  }
                }
                Navigator.pop(context);
              },
              child: Text('追加'),
            ),
          ],
        );
      },
    );
  }

  /*
    dbファイル選択インポート処理
   */
  Future<void> _importDatabase() async {
    try {
      // ダウンロードフォルダのパスを取得
      final directoryPath = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOAD);
      print("Download directory path: $directoryPath");

      if (directoryPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ダウンロードフォルダが見つかりませんでした。')),
        );
        return;
      }

      // ファイルピッカーでダウンロードフォルダを選択
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,  // 任意のファイルタイプを選択
        initialDirectory: directoryPath,  // ダウンロードフォルダを初期ディレクトリに設定
      );

      if (result == null) {
        // ユーザーがファイルを選択しなかった場合
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('インポートするファイルが選択されませんでした。')),
        );
        return;
      }

      // ファイルが選択された場合
      String? selectedFilePath = result.files.single.path;

      if (selectedFilePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('選択したファイルのパスが無効です。')),
        );
        return;
      }

      // assets/フォルダのパスを取得
      final directory = await getApplicationDocumentsDirectory();  // ユーザーのドキュメントディレクトリ
      final assetsDir = Directory('${directory.path}/assets');

      // assets/ディレクトリが存在しない場合は作成
      if (!await assetsDir.exists()) {
        await assetsDir.create(recursive: true);
      }

      // 新しいファイル名を設定（例えばファイル名に日時を追加）
      final String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final String newFileName = 'memo.db';
      // final newFilePath = '${assetsDir.path}/$newFileName';

      final String originalPath = await _dbHelper.getDatabasePath();
      final File originalDbFile = File(originalPath);
      // ファイルをassetsディレクトリにコピー
      File selectedFile = File(selectedFilePath);
      await selectedFile.copy(originalPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('データベースをインポートしました: $originalPath')),
      );

      print('File imported to: $originalPath');

      await _refreshMemos(); // bunruiIdなしで全件表示

      // 追加でDBのインポートなど必要な処理を実施
      // 例: 新しいDBをロードし、アプリのデータを更新するなど
      // await _dbHelper.loadDatabase(newFilePath);

    } catch (e) {
      print("Error importing database: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('インポートに失敗しました: $e')),
      );
    }
  }



  @override
  void dispose() {
    _dbHelper.close(); // DatabaseHelper のインスタンス経由で close を呼び出す
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        // タイトルバー
        appBar: AppBar(title: Text('simple memo',
          style: TextStyle(
          fontSize: 20,
        ),)),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedBunruiName ?? 'simple memo',
          style: TextStyle(
          fontSize: 20,
        ),),
        actions: [
          if (_selectedBunruiId != null)
          IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: _deleteMemosInSelectedBunrui,
            tooltip: '分類内のメモを全削除',
          ),
          IconButton(
            icon: Icon(Icons.ios_share),
            onPressed: _exportDatabase,
            tooltip: 'データベースをエクスポート',
          ),
          Row(
            // アイコンを右端に揃える
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              // 追加ボタン
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () async {
                  // MemoEditPage に渡す database インスタンスは DatabaseHelper 経由で取得
                  final db = await _dbHelper.database;
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MemoCreatePage(
                        database: db, // 取得したdbインスタンスを渡す
                        bunruiList: _bunruiList,
                        initialBunruiId: _selectedBunruiId,
                      ),
                    ),
                  );

                  if (result is Map<String, dynamic> && result.containsKey('bunrui_id')) {
                    await _refreshMemos(bunruiId: result['bunrui_id']);
                    await _refreshBunruiList();
                  } else if (result == 'deleted' || result == 'updated') {
                    await _refreshMemos(bunruiId: _selectedBunruiId);
                    await _refreshBunruiList();
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.get_app),  // インポートアイコン
                onPressed: _importDatabase,  // インポート処理
                tooltip: 'データベースをインポート',
              ),
              // 歯車アイコン
              IconButton(
                icon: Icon(Icons.settings),  // 歯車アイコン
                onPressed: () {
                  // 歯車アイコンが押された時に設定ページに遷移
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsPage(),  // SettingsPageに遷移
                    ),
                  );
                },
              ),
            ],
          )
        ],
      ),
      /*
         ドロワー表示
       */
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 80,
              child: DrawerHeader(
                // ... (DrawerHeader の内容は変更なし) ...
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(color: Colors.blue),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    icon: Icon(Icons.add_circle, color: Colors.white, size: 30),
                    onPressed: _showAddBunruiDialog,
                  ),
                ),
              ),
            ),
            ListTile(
              title: Text('📋 全件表示'),
              onTap: () async {
                // 先にドロワーを閉じる
                Navigator.pop(context);
                // bunruiIdなしで全件表示
                await _refreshMemos();
              },
            ),
            ..._bunruiList.map((bunrui) => ListTile(
              leading: Icon(Icons.folder, color: Colors.grey[700]),
              title: Text(bunrui['bunrui_name']),
              onTap: () async {
                Navigator.pop(context);
                final bunruiId = bunrui['bunrui_id'];
                await _refreshMemos(bunruiId: bunruiId);
              },
              onLongPress: () async {
                await _deleteBunrui(bunrui['bunrui_id']);
              },
            )),
          ],
        ),
      ),
      body: _memos.isEmpty
          ? Center(child: Text('メモがありません'))
          : ListView.builder(
        itemCount: _memos.length,
        itemBuilder: (context, index) {
          final memo = _memos[index];
          return GestureDetector(
            onLongPress: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('削除確認'),
                  content: Text('このメモを削除しますか？'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text('キャンセル')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: Text('削除')),
                  ],
                ),
              );
              if (confirm == true) {
                await _deleteMemo(memo['containts_id']);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
                ),
              ),
              child: ListTile(
                title: Text(
                  _shortenText(memo['contant'] ?? memo['content']), // カラム名を確認してください
                ),
                onTap: () async {
                  final db = await _dbHelper.database;
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MemoEditPage(
                        database: db,
                        bunruiList: _bunruiList,
                        // 名前: 渡すもの
                        initialBunruiId: memo['bunrui_id'],
                        maebunruiId: _selectedBunruiId,
                        memo: memo,
                      ),
                    ),
                  );

                  if (result is Map<String, dynamic> && result.containsKey('bunrui_id')) {
                    await _refreshMemos(bunruiId: result['bunrui_id']);
                    await _refreshBunruiList();
                  } else if (result == 'deleted' || result == 'updated') {
                    await _refreshMemos(bunruiId: _selectedBunruiId);
                    await _refreshBunruiList();
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
  /*
    一覧に表示する文字数を制限処理
   */
  String _shortenText(String? text) {
    if (text == null || text.isEmpty) return '';
    String clean = text.replaceAll('\n', ' ').replaceAll('\r', ' ');
    if (clean.length <= 20) {
      return clean;
    } else {
      return '${clean.substring(0, 20)}…';
    }
  }
}