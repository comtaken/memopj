import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';

class MemoCreatePage extends StatefulWidget {
  final Database database;
  final List<Map<String, dynamic>> bunruiList;
  final int? initialBunruiId;

  const MemoCreatePage({
    Key? key,
    required this.database,
    required this.bunruiList,
    this.initialBunruiId,
  }) : super(key: key);

  @override
  _MemoCreatePageState createState() => _MemoCreatePageState();
}

class _MemoCreatePageState extends State<MemoCreatePage> {
  TextEditingController _controller = TextEditingController();
  int? _selectedBunruiId;

  @override
  void initState() {
    super.initState();
    // _selectedBunruiId = widget.initialBunruiId;
    _selectedBunruiId = 1;
  }

  Future<void> _saveMemo() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      await widget.database.insert('tbl_containts', {
        'contant': text,
        'bunrui_id': _selectedBunruiId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      Navigator.pop(context, {'bunrui_id': null});
    }else{
      Navigator.pop(context, {'bunrui_id': null});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('新規メモ',
          style: TextStyle(
            // fontFamily: 'Nosutaru',  // カスタムフォントの指定
            fontSize: 20,            // フォントサイズの指定
          ),),
        leading: BackButton(
          onPressed: _saveMemo,
          // onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: () {
              final text = _controller.text;
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('メモがコピーされました')),
              );
            },
            tooltip: 'コピー',
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveMemo,
            tooltip: '保存',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: '分類'),
              value: _selectedBunruiId,
              items: [
                ...widget.bunruiList.map((bunrui) => DropdownMenuItem(
                  child: Text(
                    bunrui['bunrui_name'],
                    style: TextStyle(
                      // fontFamily: 'Nosutaru',
                      fontSize: 20,
                    ),
                  ),
                  value: bunrui['bunrui_id'],
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedBunruiId = value;
                });
              },
            ),
            SizedBox(height: 16),
            Expanded(
              child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '新規メモを入力してください',
                  ),
                  textAlignVertical: TextAlignVertical.top
              ),
            ),
          ],
        ),
      ),
    );
  }
}