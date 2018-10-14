# XVim2

  XVim2はXcodeのためのVimプラグインです。   
  Xcodeの機能を損なうことなく、Vimの操作感を提供することを目指しています。
  
  - Xcode 9以上の場合は、以下のインストール手順に従ってください。
  - Xcode 8以下の場合は、[XVim](https://github.com/XVimProject/XVim)をお使い下さい。
  - [Google Group for XVim developers](https://groups.google.com/d/forum/xvim-developers)が作成されました。

## インストール

  1. 自己署名証明書でXcodeをサインして下さい。  
  署名方法に関しては[こちら](SIGNING_Xcode.md)をお読み下さい。  
  その際、何をしているのか疑問に思うことや懸念点がある場合は[XVim2使用に関するFAQ](why_resign_xcode.md)をお読み下さい。
  
  2. レポジトリのクローン
  ```bash
  $ git clone https://github.com/XVimProject/XVim2.git
  ```
  
  3. Xcodeのインストールを `xcode-select` で確認
  ```bash
  $ xcode-select -p
  /Applications/Xcode.app/Contents/Developer
  ```

  4. お使いのXcodeバージョンに合わせたブランチのチェックアウト(詳しくは「ブランチとリリース」セクションにて)
  
  もし、上記コマンドでXcodeのパスが表示されなければ、 `xcode-select -s` を使って設定して下さい。
  
  5. `make`
  ```bash
  $ cd XVim2
  $ make
  ```

  下記の様な表示が出ましたら、
  
  ```
  XVim hasn't confirmed the compatibility with your Xcode, Version X.X
  Do you want to compile XVim with support Xcode Version X.X at your own risk? 
  ```
  もし、お使いのXcodeバージョンでお使いになりたい場合は y を押して進めて下さい。  
  (確認はしていませんが、動きます。)
  
  6. 必要であれば `.xvimrc` を作ります。

  7. Xcodeを起動します。 XVimをロードするか聴かれるので 'Yes' を選択して下さい。  
     もし、間違えて 'No' を選択してしまった場合は、Xcodeを閉じて下記コマンドをterminalで実行して下さい。

  ```
  defaults delete  com.apple.dt.Xcode DVTPlugInManagerNonApplePlugIns-Xcode-X.X     (X.XはXcodeのバージョンです)
  ```
    
  8. Xcodeの再起動
    
## ブランチとリリース
 
 - `master`  : 最新のGM版(最終Beta版)Xcode用
             
 - `develop` : 次のbeta版Xcode及び開発用

 - タグ
   - `xcode9.2`
   - `xcode9.4`

適切なブランチまたはタグをお使い下さい。

 typoや簡単なバグ修正に関しては `master` ブランチに、  
 新機能やbeta版Xcodeのサポートに関しては `develop` ブランチにプルリクエストを送って下さい。
     
## アンインストール
  ```bash
  $ make uninstall
  ```

### 手動アンインストール
下記ディレクトリを削除して下さい。
```
$HOME/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/XVim2.xcplugin
```

## 機能リスト
 別ファイル[FeatureList.md](Documents/Users/FeatureList.md)をご覧ください。

## バグレポート
  残念ながらたまにXVimが原因でXcodeがクラッシュしてしまう事があります。  
  我々は全てのバグを取り除ける様に尽力していますが、非常に難しいのが現状です。  
  下記の様なバグレポートをお送りいただけると助かります。

   * クラッシュ情報 (クラッシュ時にスタックトレースが表示されますので、そちらをコピーしてください)
   * クラッシュまでの手順詳細 (一連のキー操作やクリック)
   * 編集していたテキスト
   * Xcodeバージョン 
   * XVimバージョン (リリースバージョンやコミット番号)
  
  もし、上記情報の解決が難しい場合は下記動画に従ってデバッグログを取得いただけますでしょうか。

  [How to get XVim debug log](http://www.youtube.com/watch?v=50Bhu8setlc&feature=youtu.be)

  また、バグに関するテストケースを書いていていただけると助かります。  
  `Documents/Developsers/PullRequest.md` 内の "Write test" セクションにテストケースの書き方が書かれています。  
  ソースコードを修正していただく必要はございません。  
  作成いただいたIssueにここで説明されている7つの項目をお書きいただくだけです。

## コントリビューション
  もし自分自身でバグ修正をしたり、新機能を追加した場合は下記をご覧ください。

  [Contributing.md](Documents/Contributing.md)

## Bountysource
  XVimはBountysourceをサポートしています。  
  もし、ご自身の問題をより早く解決したい場合は賞金をかけることは一つの選択肢になるでしょう。  
  コントリビュータは(保証はされていませんが)優先的に取り組むはずです。  
  賞金をかける場合は、以下のリンクより "Issue"タブに進み、ご自身の問題を選択し賞金をかけてください。  
  
  https://www.bountysource.com/teams/xvim

## 寄付
  このプラグインを気に入っていただけたら、寄付をしていただけると嬉しいです。  
  寄付方法は、「東北地方太平洋沖地震」からの復興支援、もしくはXVim2への[BountySource](https://www.bountysource.com/teams/xvim)経由での支援の二種類があります。  
  もちろん両方に支援いただくことも可能です :)
  
### 東北地方太平洋沖地震
  もともとこのプロジェクトはお金を稼ぐために始めたものではありませんので、  寄付金は全て2011年の東北地方太平洋沖地震の被災者の方々へ寄付しています。  
  手数料などを省くため、下記サイトから直接Paypalによる寄付をお願いします。

  https://www.paypal-donations.com/pp-charity/web.us/campaign.jsp?cid=-12

  上記Paypalリンクから寄付をしていただいても、こちらにはいかなるメッセージも送信されません。  
  [メッセージボード]( https://github.com/JugglerShu/XVim/wiki/Donation-messages-to-XVim )に寄付した旨のメッセージを書いていだけると
  私を含めコントリビューのモチベーションに繋がります。

### BountySource
　もしこのプロジェクトの拡散を手伝っていただける場合は、[BountySource](https://www.bountysource.com/teams/xvim)経由で直接支援いただけると幸いです。 
  このプロジェクト全体をご支援いただくことも出来ますし、直すべき問題や実装すべき機能がある場合は個別の問題に賞金をかけることも出来ます。
  
## コントリビュータ
  GitHubレポジトリのコントリビュータページをご参照ください。  
  https://github.com/XVimProject/XVim2/contributors

## ライセンス
  MIT License
