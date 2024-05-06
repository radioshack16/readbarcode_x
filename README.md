# readbarcode_x
Read barcode NW-7 on receipts

## 概要
- バーコードを含むレシートのPNG画像からバーコード部を抜き出してデコードします。
- 100均ショップのCANDOのレシートのみを対象とします。
- バーコードのフォーマットとしては NW-7 です。
- きわめて実験的なプログラムです。

## 目的
- 個人的な別の用途(会計処理ソフトへの入力テキスト生成)に利用すること
- バーコードをデコードするときにこのようにすればわりとロバストに行えるのではないか、おもしろいのではないかと
考えたことを実装して確かめること  
を目的としています。

## 注意
- 汎用的に便利に使えるコマンドを狙って作成したものではありません。
- 処理の記述はまずはわかりやすさをむねとし、多くの場所でナイーブな記述としています。
- スキャナでスキャンした画像を対象とします。カメラで撮影したものは対象外です。

## 開発・動作環境
- Windows 10 Pro
- ruby 3.2.3 (2024-01-18 revision 52bb2ac0a6) [x64-mingw-ucrt]
- Git Bash (git version 2.43.0.windows.1)

## 前提とする入力画像ファイル
- PNG format のみ
- CANDO のレシートをスキャンしたもの
- grayscale: 0..255
- 密度: 300 [dpi]
- scanner: Cannon製 DR-C230
  
## 前提とするバーコードフォーマット
(試したレシートがそうなっていた)
- format: NW-7
- stop/end character: 'a'
- デコード対象キャラクタ: 9bit長のもののみから構成されていること
- デジットチェック: 処理していない。デジットチェックが使用されているのか否か不明。

## 入力画像例
<img src="img_png_sample/Image_20230630T122723-001-mosaic.png" width="20%">
注意: コミットするにあたりマスク処理していますが、実使用時にはマスク処理は不要です。

## 動作例
コマンド入力
```bash
$ ./readbarcode_nw7.rb img_png_sample/Image_20230630T122723-001-mosaic.png
```
出力
```bash
a2023063020000002a
```
- 左右の 'a'(start および stop キャラクタ)が検出され、
- 2023年06月30日を示す"20230630"が正しくデコードされています。
- マスク処理した箇所はデコードできず '2', '0' になっています。

## 処理の流れ
1. PNG ファイルを読む
2. そこからバーコード部を検出してバーコード信号とする
3. バーコード信号からクロック信号を抽出する
4. バーコード信号を帯域制限する
5. クロック信号から最適サンプル位置を求めその位置で4.のバーコード信号をリサンプルする
6. リサンプルした信号上で左右のシンクパターン検出してその位置を決定する
7. 左右のシンク間の信号を各9bit受信データに区切る
8. 各9bit受信データそれぞれについて最もユークリッド距離の短いコードを選択してデコード結果とする。

## 各部の信号波形
 TBD

## ロバストと言える点
- サーマルプリンタのヘッドがダメになって印刷結果として数本が白線の固定値になってもデコードすることができている。
- 具体的にはサンプル画像では6本程度の白線となっているがそれでもデコードできている(マスク処理前画像にて実験)。

## 課題
- 帯域制限が適当。現時点 \[1 2 1\] としている。
- デジットチェックの処理をしていない。

以上
