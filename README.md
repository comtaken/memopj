# TIPS

## 認識デバイス確認~インストール

転送なしにすると認識する
```
flutter devices
flutter build apk --release --no-tree-shake-icons
flutter install

```

## アイコン作成

```
flutter pub run flutter_launcher_icons:main
```

## ライブラリ追加

```
flutter pub add LIBNAME
```

## widget
ChangeNotifierProvider
状態管理を行うクラスをアプリ全体から使えるよう提供する
```
create:(_) => CommonModel()
```
Consumar
ChangeNotifierProviderで提供された状態を監視する。
ChangeNotifierの状態が変化したときに特定のウィジェットを再ビルドすることができる。
```
Consumer<CommonModel>(
  builder: (context, commonModel, child) {
    return Text(commonModel.someValue);
  },
)
```