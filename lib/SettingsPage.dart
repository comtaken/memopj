import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'CommonModel.dart';

/**
 * 設定変更処理
 */
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Nosutaru',style:TextStyle(
              fontFamily: 'Nosutaru',  // カスタムフォントの指定
            ),),
            onTap: () {
              Provider.of<CommonModel>(context, listen: false).changeFont('Nosutaru');
              Navigator.pop(context);  // 設定画面を閉じる
            },
          ),
          ListTile(
            title: Text('Roboto',style:TextStyle(
              fontFamily: 'Roboto',  // カスタムフォントの指定
            ),),
            onTap: () {
              Provider.of<CommonModel>(context, listen: false).changeFont('Roboto');
              Navigator.pop(context);  // 設定画面を閉じる
            },
          ),

          ListTile(
            title: Text('misakiGothic2nd',style:TextStyle(
              fontFamily: 'misakiGothic2nd',  // カスタムフォントの指定
            ), ),
            onTap: () {
              Provider.of<CommonModel>(context, listen: false).changeFont('misakiGothic2nd');
              Navigator.pop(context);  // 設定画面を閉じる
            },
          ),
          ListTile(
            title: Text('PixelMplus12',style:TextStyle(
              fontFamily: 'PixelMplus12',  // カスタムフォントの指定
            ), ),
            onTap: () {
              Provider.of<CommonModel>(context, listen: false).changeFont('PixelMplus12');
              Navigator.pop(context);  // 設定画面を閉じる
            },
          ),
          // 他のフォントオプションを追加できます
        ],
      ),
    );
  }
}
