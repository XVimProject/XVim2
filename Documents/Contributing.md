## Contributions
  Any suggestions, bug reports are welcome.  
  XVim2 depends highly Xcode's structure and Apple will modify Xcode's structure every year. So new feature requests depend on Xcode's structure is not recommended. 
  
  If you want to add a feature or fix bugs by yourself the following videos are good help for you.
 - [How to get debug log](http://www.youtube.com/watch?v=50Bhu8setlc)
 - [How to debug XVim](http://www.youtube.com/watch?v=AbC6f86VW9A)
 - [How to write a test case](http://www.youtube.com/watch?v=kn-kkRTtRcE)

Watch the videos mentioned earlier for a full tutorial on developing, debugging and testing XVim. Here is a very simple guide to get you started.

### Debugging
  1. Make sure you have Xcode.app installed at /Applications/Xcode.app, if that's true just open XVim.xcodeproj and Run (CMD + R). You can ignore the rest steps.
  2. If you have Xcode installed at a different path, follow these steps.
  3. Open XVim.xcodeproj
  4. Got to Edit Scheme... => Run => Executable => Other => Choose The Xcode.app you installed to.
  5. Run (CMD + R)

### Run Unit Tests
  1. In your .xvimrc, add a line "set debug", which tells XVim to run in debug mode.
  2. Open XVim.xcodeproj, a debug instance of Xcode shows up.
  3. In the debug Xcode instance, create a random small disposable project (say HelloWorld.xcodeproj) if you have don't this already.
  4. Open HelloWorld.xcodeproj using debug Xcode instance.
  5. Go to XVim menu, there should be an item "test categories"
  6. Choose a category to run
  7. A separate window shows up and unit tests are run inside that window.
  8. Results will be shown when all the tests in that category are completed.
