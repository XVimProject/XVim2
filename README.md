# XVim2

  XVim2 is a Vim plugin for Xcode intending to offer a compelling Vim experience without the need to give up any Xcode features.
  
  - Xcode 9 or above, follow the installation instructions below.
  - Xcode 8 or below, you should use [XVim](https://github.com/XVimProject/XVim)
  - [Google Group for XVim developers](https://groups.google.com/d/forum/xvim-developers) has been created.

 Use https://github.com/XVimProject/XcodeIssues to keep track **Xcode** Vim keybinding issues

## Install

  1. Clone the repo:
  ```bash
  $ git clone https://github.com/XVimProject/XVim2.git
  $ cd XVim2
  ```
  
  2. Confirm `xcode-select` points to your Xcode:
  ```bash
  $ xcode-select -p
  /Applications/Xcode.app/Contents/Developer
  ```
  
  If this doesn't show your Xcode application path, use `xcode-select -s /path/to/Xcode.app/Contents/Developer` to set the correct path.

  3. `git checkout` a branch for your Xcode version. See [Branches and Releases](#branches-and-releases) section for more information.
  
  4. `make`:
  ```bash
  $ make
  ```

  5. XVim2 support some code injection system to load XVim2 into Xcode.

  - [Xcode plugin system](#xcode-plugin-system)
  - [SIMBL plugin system](#simbl-plugin-system)

  6. Create `.xvimrc` as you need.

### Xcode plugin system

  NOTE: This method have issue for sign-in to Apple ID via Xcode on Big Sur. [#340](/issues/340)

  1. Sign Xcode with your own certificate. You can [read the instructions for how to do this](SIGNING_Xcode.md) and if you have questions or concerns about what this means you can [read the FAQ on why you need to resign Xcode to use XVim2](why_resign_xcode.md).

  If you see something like the following:
  ```
  XVim hasn't confirmed the compatibility with your Xcode, Version X.X
  Do you want to compile XVim with support Xcode Version X.X at your own risk? 
  ```
  Press `y` to use XVim with your Xcode version (even if XVim is not confirmed to work with that version of Xcode).
  
  2. Launch Xcode, where you'll be asked if you want to load XVim. Press 'Yes' to do so.
     If you press 'No' by mistake, close Xcode and execute the following from a terminal:

  ```
  defaults delete  com.apple.dt.Xcode DVTPlugInManagerNonApplePlugIns-Xcode-X.X     (X.X is your Xcode version)
  ```
  Then relaunch Xcode and choose 'Yes' to load XVim.
    
### SIMBL plugin system

  NOTE: SIMBL plugin system required disabling some security feature to work on recently macOS.

  1. Setup [MacForge](https://github.com/MacEnhance/MacForge) with disabling Library-Validation and System Integrity Protection (SIP).

  2. Reboot your mac to take effect disabling Library-Validation.

  3. make:
  ```bash
  $ make simbl
  ```

### Compatibility matrix


<table>
<tr>
  <th>Xcode</th>
  <th>OS security configuration</th>
  <th>loading system</th>
  <th>x64</th>
  <th>arm64</th>
</tr>
<tr>
  <td>re-codesign (occur <a href="https://github.com/XVimProject/XVim2/issues/340">Apple ID login problem on BigSur</a>)</td>
  <td>any</td>
  <td rowspan=2>Xcode Plugin</td>
  <td>✅</td>
  <td>✅</td>
</tr>
<tr>
  <td rowspan=2>original</td>
  <td rowspan=2>disable Library-Validation and SIP</td>
  <td>✅</td>
  <td>✅</td>
</tr>
<tr>
  <td>SIMBL</td>
  <td>✅</td>
  <td>MacForge 1.1.0 not yet support M1</td>
</tr>
</table>
Tested on macOS 11.2.3, Xcode 12.4

## Branches and Releases
 
 - `master`: for the lastest GM Xcode.
             
 - `develop`: for the next beta Xcode and develop.

 - tags
   - `xcode11.7`
   - `xcode11.5`
   - `xcode11.2`
   - `xcode10.3`
   - `xcode10.2`
   - `xcode10.1`
   - `xcode9.4`
   - `xcode9.3`
   - `xcode9.2`

 Please use appropriate tags or branches.

 For easy bugfixes and typo fixes, please open a pull request to the `master` branch. 
 For a new feature or adding support for a beta version of Xcode, please open a pull request
 to the `develop` branch.
     
## Uninstall
  ```bash
  $ make uninstall
  ```

### Manual uninstall 
Delete the following directories:
- `$HOME/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/XVim2.xcplugin`
- `/Library/Application\ Support/MacEnhance/Plugins/XVim2.bundle`

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
   * **.xvimrc**. If you have it.
  
  When it is hard to solve a problem with information above, take debug log according to the following movie please.
  
  [How to get XVim debug log](http://www.youtube.com/watch?v=50Bhu8setlc&feature=youtu.be)

  We appreciate if you write test case for the bug. Read "Write test" section in Documents/Developsers/PullRequest.md how to write test case. You do not need to update any source code but just write 7 items explained there in an issue you create.

## Contributing
  If you fix a bug by yourself and add new feature, see here.

  [Contributing.md](Documents/Contributing.md)

## Bountysource
  XVim supports Bountysource. If you want to solve your issue sooner make bounty on your issue is one option. A contributer should work on it preferentially (not guaranteed though). To make bounty visit following link and go to "Issue" tab. Select your issue and make bounty on it. 
  
  https://www.bountysource.com/teams/xvimproject (XVim2)
  https://www.bountysource.com/teams/xvim (XVim)

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
