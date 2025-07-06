import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'CommonModel.dart';
import 'MemoListPage.dart';


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CommonModel(),
      child: MemoApp(),
    ),
  );
}

class MemoApp extends StatelessWidget {
  const MemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CommonModel>(
      builder: (context, commonModel, child) {
        return MaterialApp(
          title: 'Memo DB Viewer',
          debugShowCheckedModeBanner: false,
          home: MemoListPage(),
          // fontFamily, fontSize全体共通設定
          theme: ThemeData(
            fontFamily: commonModel.fontFamily,
            textTheme: TextTheme(
              headlineLarge: TextStyle(fontSize: 32),
              headlineMedium: TextStyle(fontSize: 28),
              headlineSmall: TextStyle(fontSize: 24),
              bodyLarge: TextStyle(fontSize: 18),
              bodyMedium: TextStyle(fontSize: 16),
              displayLarge: TextStyle(fontSize: 48),
              displayMedium: TextStyle(fontSize: 40),
              bodySmall: TextStyle(fontSize: 14),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: commonModel.fontFamily,
            textTheme: TextTheme(
              bodyLarge: TextStyle(fontSize: 18),
              bodyMedium: TextStyle(fontSize: 16),
              bodySmall: TextStyle(fontSize: 14),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey[900],
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontFamily: commonModel.fontFamily,
              ),
            ),
          ),

          themeMode: ThemeMode.system,
        );
      },
    );
  }
}
