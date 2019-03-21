# XVim2

  XVim2 is a Vim plugin for Xcode. The plugin intends to offer a compelling Vim experience without the need to give up any Xcode features.
  
  - Xcode 9 or above, follow the installation instructions below.
  - Xcode 8 or below, you should use [XVim](https://github.com/XVimProject/XVim)
  - [Google Group for XVim developers](https://groups.google.com/d/forum/xvim-developers) has been created.

## INSTALL

  1. Sign Xcode with your own certificate. You can [read the instructions for how to do this](SIGNING_Xcode.md) and if you have questions or concerns about what this means you can [read the FAQ on why you need to resign Xcode to use XVim2](why_resign_xcode.md).
  
  2. Clone the repo. 
  ```bash
  $ git clone https://github.com/XVimProject/XVim2.git
  ```
  
  3. Confirm `xcode-select` points to your Xcode
  ```bash
  $ xcode-select -p
  /Applications/Xcode.app/Contents/Developer
  ```
  
  If this doesn't show your Xcode application path, use `xcode-select -s` to set.

  4. Check out a branch for your Xcode version. See [Branches and Releases](#branches-and-releases) section for more information.
  
  5. `make`
  ```bash
  $ cd XVim2
  $ make
  ```

  If you see something like 
  
  ```
  XVim hasn't confirmed the compatibility with your Xcode, Version X.X
  Do you want to compile XVim with support Xcode Version X.X at your own risk? 
  ```
  Press y if you want to use XVim with your Xcode version (even it is not confirmed it works)
  
  6. Create `.xvimrc` as you need. 

  7. Launch Xcode. You'll be asked if you load XVim. Press 'Yes' to it.
     If you press 'No' by mistake, close the Xcode and execute the following from a terminal

  ```
  defaults delete  com.apple.dt.Xcode DVTPlugInManagerNonApplePlugIns-Xcode-X.X     (X.X is your Xcode version)
  ```
    
  8. Relaunch Xcode.
    
## Branches and Releases
 
 - `master`: for the lastest GM Xcode.
             
 - `develop`: for the next beta Xcode and develop.

 - tags
   - `xcode10.1`
   - `xcode9.4`
   - `xcode9.3`
   - `xcode9.2`

 Please use appropriate tags or branches.

 Please pull request to the master branch for easy bugfix and typo, or 
     to develop branch for new feature or beta Xcode support.
     
## Uninstall
  ```bash
  $ make uninstall
  ```

### Manual uninstall 
Delete the following directory:
`$HOME/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/XVim2.xcplugin`

## Feature list
  See separate [FeatureList.md](Documents/FeatureList.md)

## Bug reports
  Unfortunately XVim sometimes crashes Xcode. We are working on eliminating all the bugs, but it's really hard work.
  All bug reports are appreciated, and they are especially helpful when they include the following information:

   * **Crash information**. Xcode shows threads stack trace when it crashes. Please copy the stack trace and include it in your report.
   * **The operations you performed to cause the crash**, e.g. the series of key strokes or mouse clicks you performed.
   * **The text you were manipulating**.
   * **Xcode version**.
   * **XVim version**. The version number of the revision you built.
  
  When it is hard to solve a problem with information above, take debug log according to the following movie please.
  
  [How to get XVim debug log](http://www.youtube.com/watch?v=50Bhu8setlc&feature=youtu.be)

  We appreciate if you write test case for the bug. Read "Write test" section in Documents/Developsers/PullRequest.md how to write test case. You do not need to update any source code but just write 7 items explained there in an issue you create.

## Contributing
  If you fix a bug by yourself and add new feature, see here.

  [Contributing.md](Documents/Contributing.md)

## Bountysource
  XVim supports Bountysource. If you want to solve your issue sooner make bounty on your issue is one option. A contributer should work on it preferentially (not guaranteed though). To make bounty visit following link and go to "Issue" tab. Select your issue and make bounty on it. 
  
  https://www.bountysource.com/teams/xvim

## Donations
  If you think the plugin is useful, please donate.
  There are two options you can take. Donate for Japan Earthquake and Tsunami Relief or back the project via [BountySource](https://www.bountysource.com/teams/xvim). There is no rule that you cannot take both :) .
  
### Japan Earthquake and Tsunami Relief
  Since I do not intend make money from this project, I am directing donations
  to the people suffering from the damage of the 2011 Tohoku earthquake and tsunami in Japan.

  Please donate directly through the Paypal donation site below, as
  this will put more money to good use by reducing the transfer fee.

  https://www.paypal-donations.com/pp-charity/web.us/campaign.jsp?cid=-12

  Since no messages are sent when you donate from the paypal link, you could also write a donation message on
  [Message Board]( https://github.com/JugglerShu/XVim/wiki/Donation-messages-to-XVim ).
  I(we) would really appreciate it, and it will really motivate me(us)!

### BountySource
  If you like to help and enhance the project directly consider backing this project via [BountySource](https://www.bountysource.com/teams/xvim). You can back the team (which means you support the entire project) or you can make bounty on a specific issue. (If you have any bugs to be fixed or features to be implemented not in issues yet you can make one.)
  
## Contributors
  See contributors page in github repository.
  https://github.com/XVimProject/XVim2/contributors

## License
  MIT License
