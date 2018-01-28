# XVim2

  XVim2(または 'Xcode 9以降向けXVim')はXcode用Vimプラグインです。XVimはXcodeの機能を損なうことなく、Vimの操作感を提供することを目指しています。

  - Xcode 9 ユーザーは、以下のインストール手順にしたがってください。
  - Xcode 8 以下のユーザーは [XVim](https://github.com/XVimProject/XVim) をご利用ください。
  - [Google Group for XVim developers](https://groups.google.com/d/forum/xvim-developers) が作成されました。

## インストール

  1. 自己署名証明書でXcodeを署名します。 署名方法は [SIGNING_Xcode.md](SIGNING_Xcode.md) を参照してください。

  2. ソースコードをダウンロード、あるいはリポジトリをクローンします。
  ```bash
  $ git clone https://github.com/XVimProject/XVim2.git
  ```

  3. `xcode-select` がどこのXcodeを指しているか確認します。
  ```bash
  $ xcode-select -p
  /Applications/Xcode.app/Contents/Developer
  ```

  Xcodeのアプリケーションパスが表示されない場合は、 `xcode-select -s` を使いセットしてください。

  4. makeを実行します。
  ```bash
  $ make
  ```

  もし次のような確認を求められたら、
  
  ```
  XVim hasn't confirmed the compatibility with your Xcode, Version X.X
  Do you want to compile XVim with support Xcode Version X.X at your own risk? 
  ```
  自身のXcodeバージョンでXVimを使いたければ y を押してください (例えそれが動作していなくても)。

  5. 必要に応じて `.xvimrc` を作成します。

  6. Xcodeを起動します。XVimのロードについて尋ねられるでしょうから 'Yes' を選択します。
     もし誤って 'No' 押した時は、Xcodeを閉じてターミナルから次のコマンドを実行します。

  ```
  defaults delete  com.apple.dt.Xcode DVTPlugInManagerNonApplePlugIns-Xcode-X.X     (X.X is your Xcode version)
  ```

  7. Xcodeを再起動します。

## ブランチとリリース
 XVimにはいくつかのブランチとリリースがあります。通常はリリースの一つをダウンロードし、利用してください。
 以下はそれぞれのリリースとブランチの説明です。

 - リリース(タグ) : リリースはマスターブランチ上のtagです。これらのtag上のコード、ドキュメント類はすべて整った状態になっています。通常のXVimユーザーであればリリースの一つをご利用ください。
 - masterブランチ : 最も安定したブランチです。致命的なバグの修正や、'develop'ブランチで開発された機能が'master'ブランチにマージされます。リリースに致命的なバグがある場合には最新の'master'を試してみてください。
 - developブランチ: 新たな機能や致命的でないバグの修正はこのブランチにマージされます。試験的な機能を利用したい場合にはこのブランチを使用してください。

 他のブランチは'develop'ブランチにマージされる一時的な開発やバグ修正用のものです。Pull Requestは'develop'ブランチにするようにしてください。


## アンインストール
  ```bash
  $ make uninstall
  ```

### 手動でのアンインストール
  以下のディレクトリを削除してください

    $HOME/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/XVim2.xcplugin

## 機能一覧
  別ファイルを参照ください。[FeatureList.md](Documents/Users/FeatureList.md)

## バグ報告
  残念ながらXVimの影響でXcodeがクラッシュしてしまうことがあります。すべてのバグを取り除こうとしていますが、非常に難しいのが現状です。
  以下の情報のバグレポートがあると非常に助かります。

   * クラッシュ情報(クラッシュ時にスタックトレースが表示されます。それをコピーしてください。)
   * クラッシュ時の操作(一連のキー操作やクリック)
   * 編集していたテキスト
   * Xcodeのバージョン
   * XVimのバージョン(リリースバージョンやコミットの番号)
  
  もし上記情報で問題の難しい場合には以下の動画に従ってデバッグログの取得をお願いするかもしれません。
  
  [How to get XVim debug log](http://www.youtube.com/watch?v=50Bhu8setlc&feature=youtu.be)


  テストケースを書いていただけるとさらに助かります。Documents/Developsers/PullRequest.md hの"Write test"セクションにテストケースの書き方が書かれています。ソースコードを修正する必要はなくここで説明されている7つの項目をIssueに書くだけです。

## Bountysource
  XVimでは、Bountysourceを利用しています。
  Issue をなるべく早く解決したい場合、賞金をかけることは一つの選択肢になるでしょう。
  (必ずしも保障はされませんが) コントリビューターは賞金のかかったIssueに優先的に対応します。
  賞金をかけるには、以下のリンク先の"Issues"タブへ進み、対象のIssueを選択します。

  https://www.bountysource.com/teams/xvim

## コントリビューション
  別ファイルを参照ください。[CONTRIBUTING.md](.github/CONTRIBUTING.md)

## 寄付
  もし、このプラグインを気に入っていただけたら寄付をしていただけると嬉しいです。
  寄付方法は、「東北地方太平洋沖地震」からの復興支援もしくは[XVimProjectへのBountySource](https://www.bountysource.com/teams/xvim)経由での支援の二種類があります
  (もちろん両方も選択することもできます)。

### 東北地方太平洋沖地震

  もともとこのプロジェクトはお金を稼ぐために始めたものではないため、
  2011年の東北地方太平洋沖地震の被災者の方々へそのまま寄付しています。

  寄付は、以下のURLから直接お願いします。
  こちらを一度経由すると手数料がかかってしまうため、このようにしています。

  https://www.paypal-donations.com/pp-charity/web.us/campaign.jsp?cid=-12

  上記Paypalリンクから寄付を行った場合、こちらにはなんのメッセージも送信されません。
  [メッセージボード][donation-messageboard]に寄付した旨を書いていただけると、
  私を含めコントリビュータのモチベーションに繋がります。

  [donation-messageboard]: https://github.com/JugglerShu/XVim/wiki/Donation-messages-to-XVim

### Bountysource
  BountySourceでは、チーム (プロジェクト全体) を支援したり、あるいは特定のIssueに賞金をかけることができます
  (もし、修正して欲しいバグや実装して欲しい機能がIssueとして存在していなければ、新たにIssueを作成してください)。

## コントリビュータ
  以下のコントリビュータのページを御覧ください

  https://github.com/XVimProject/XVim2/contributors

## ライセンス
  MIT License

