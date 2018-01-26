# XVim2

  XVim2是Xcode的Vim插件。该插件在提供Vim强大功能的同时完全不影响Xcode既有功能。
  
  - Xcode 9 用户请按照本说明安装。  
  - Xcode 8 或者更早的用户可以使用 [XVim](https://github.com/XVimProject/XVim)。  
  - [Google XVim 开发者小组](https://groups.google.com/d/forum/xvim-developers) 已经创建。  

## 安装

  1. 用自己的证书签名Xcode。你可以查看 [Xcode签名.md](SIGNING_Xcode.md)。  
  
  2. 下载源码或者克隆仓库。  
  ```bash
  $ git clone https://github.com/XVimProject/XVim2.git
  ```
  
  3. 确认`xcode-select`指向你的Xcode。  
  ```bash
  $ xcode-select -p
  /Applications/Xcode.app/Contents/Developer
  ```
  
  如果未正确显示Xcode路径，请使用`xcode-select -s`进行设置。  
  
  4. `make`
  ```bash
  $ cd XVim2; make
  ```

  如果你看到类似的东西  
  
  ```
  XVim hasn't confirmed the compatibility with your Xcode, Version X.X
  Do you want to compile XVim with support Xcode Version X.X at your own risk? 
  ```
  如果你想用你的Xcode版本的XVim按 y（即使它未确定能有效工作）。  
  
  5. 你需要创建`.xvimrc`。

  6. 启动Xcode。加载XVim会被询问。按'Yes'。  
     如果您误按了'No'，请关闭Xcode并从终端执行以下操作  

  ```
  defaults delete  com.apple.dt.Xcode DVTPlugInManagerNonApplePlugIns-Xcode-X.X     (X.X is your Xcode version)
  ```
    
  7. 重启Xcode.
    
## 分支和发布  
 XVim有少量的分支和发布。通常你只需要下载使用单个'releases'。  
 以下是关于每个版本和分支的说明。  
 
 - Releases(tags) : Releases是master分支上的标签。该标签上的所有代码和文档都是好用的。通常XVim的用户都应该使用这些Releases标签。  
 - master : 最稳定的分支。'develop'分支中修复的关键错误和稳定功能都被合并到'master'分支中。如果您发现发布版本中存在严重错误，请尝试使用最新的'master'分支。  
 - develop : 新功能和非关键错误修复被合并到这个分支。如果你想尝试使用新特性使用该分支。  

 任何其他分支都是临时用于开发功能或错误修复的分支，最终它们都将被合并到'develop'分支中。  
 任何拉请求都应该被安排到'develop'分支。  

## 卸载  

```bash
$ make uninstall
```

### 手动卸载  

删除以下目录：  
    $HOME/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/XVim2.xcplugin

## 特性清单  

  查看 [特性列表.md](Documents/Users/FeatureList.md)

## 错误报告
  非常不幸，XVim有时会使Xcode崩溃。我们正在努力消除所有的错误，但这真的很难。  
  当你提交错误报告会对我们帮助很大，它具有以下信息:  

   * 崩溃信息（ Xcode在崩溃时显示线程堆栈跟踪。复制它们。)  
   * 你导致崩溃的操作 （ 一系列的键盘输入和鼠标点击 ）  
   * 你正在操作的文本信息  
   * Xcode 版本  
   * XVim 版本 ( 你构建的版本号 )  
  
  以上信息难以描述你的问题时，请按照这个视频打开调试日志。  
  
  [如何获得XVim调试日志](http://www.youtube.com/watch?v=50Bhu8setlc&feature=youtu.be)

  我们感谢您编写的错误的测试用例。在 Documents/Developsers/PullRequest.md 查看 "Write test" 章节是如何编写测试用例。你不需要更热任何源代码，只需要在你创建的issue上编写 7 个解释项。

## Bountysource
  XVim现已支持Bountysource。如果你想早日解决你的issue，可以选择你的issue上增加赏金。贡献者会优先解决它 （ 不保证 ）。使用下面的链接增加赏金标签到"Issue"。选择你的issue然后追加赏金。  
  
  https://www.bountysource.com/teams/xvim  

## 贡献指南
  查看详细 [贡献手册.md](.github/CONTRIBUTING.md)

## 捐赠
  如果您认为该插件很有用，请捐赠。  
  有两种可选择的方式。 为日本地震和海啸救济捐赠或者捐赠该项目 [BountySource](https://www.bountysource.com/teams/xvim). 没有明确规定你不能同时选择两者 :)   
  
### 日本地震和海啸救济
  因为我不打算从这个项目赚钱，
  我建议直接捐款给受到日本2011年东北地震和海啸损害的人们。  

  请通过下面的Paypal直接捐款， 这样可以减少转让费用。  

  https://www.paypal-donations.com/pp-charity/web.us/campaign.jsp?cid=-12

  由于当您从PayPal链接捐赠时没有消息被发送，你也可以写一个捐赠信息
  [Message Board]( https://github.com/JugglerShu/XVim/wiki/Donation-messages-to-XVim ).  
  我 (我们) 会非常感谢它，这能非常激励我 (我们)。  

### BountySource
  如果你想帮助和提高项目，可以考虑直接使用 [BountySource](https://www.bountysource.com/teams/xvim)。 你可以支持该团队 (这意味着你支持整个项目) 或者你可以在特定的问题上追加赏金。(如果你有任何需要修复的问题或者未完善的功能不在issue上，你可以编写一个。)
  
## 贡献者
  请参阅github存储库中的贡献者页面。
  https://github.com/XVimProject/XVim2/contributors

## 许可
  MIT License
