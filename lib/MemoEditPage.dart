import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';

class MemoEditPage extends StatefulWidget {
  final Database database;
  final List<Map<String, dynamic>> bunruiList;
  final int? initialBunruiId;
  final Map<String, dynamic>? memo;
  final int? maebunruiId;

  MemoEditPage({
    required this.database,
    required this.bunruiList,
    this.initialBunruiId,
    this.memo,
    this.maebunruiId,
  });

  @override
  _MemoEditPageState createState() => _MemoEditPageState();
}

class _MemoEditPageState extends State<MemoEditPage> {
  TextEditingController _controller = TextEditingController();
  int? _selectedBunruiId;
  int? _maebunruiId;
  @override
  void initState() {
    super.initState();
    _selectedBunruiId = widget.memo?['bunrui_id'] ?? widget.initialBunruiId;
    _controller.text = widget.memo?['contant'] ?? '';
    _maebunruiId = widget.maebunruiId;
  }

  Future<void> _saveMemo() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      await widget.database.update(
        'tbl_containts',
        {
          'contant': text,
          'updated_at': DateTime.now().toIso8601String(),
          'bunrui_id': _selectedBunruiId,
        },
        where: 'containts_id = ?',
        whereArgs: [widget.memo!['containts_id']],
      );
    }
    Navigator.pop(context, {'bunrui_id': _maebunruiId});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.memo != null ? 'メモを編集' : 'メモを追加',
          style: TextStyle(
          // fontFamily: 'Nosutaru',
          fontSize: 20,
        ),),
        leading: BackButton(
          onPressed: _saveMemo,
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
              value: _selectedBunruiId,
              decoration: InputDecoration(labelText: '分類'),
              items: widget.bunruiList.map((bunrui) {
                return DropdownMenuItem<int>(
                  value: bunrui['bunrui_id'],
                  child: Text(bunrui['bunrui_name'],
                    style: TextStyle(
                      // fontFamily: 'Nosutaru',  // カスタムフォントの指定
                      fontSize: 20,            // フォントサイズの指定
                    ),),
                );
              }).toList(),
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
                    hintText: '編集メモを入力してください',
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