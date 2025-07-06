import 'package:flutter/material.dart';

/*
  フォントファミリー変更後は全体通知
 */
class CommonModel extends ChangeNotifier {
  // 初期フォント
  String _fontFamily = 'Nosutaru';
  String get fontFamily => _fontFamily;
  void changeFont(String newFont) {
    _fontFamily = newFont;
    notifyListeners();
  }
}
