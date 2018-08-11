# FAQ - Why do I need to resign Xcode to use XVim2 🤔?

## TL;DR

When you download Xcode from Apple (either from the Mac AppStore or the downloads page) it is [signed](https://developer.apple.com/support/code-signing/). From Xcode 8 onwards, you need to replace this signature to load many plugins (like XVim2).  

This is because in 2016 Apple [announced](https://developer.apple.com/videos/play/wwdc2016/414) a new replacement for plugins called [Source Editor Extensions](https://developer.apple.com/documentation/xcodekit), which would be the only permitted approach for loading third-party tools into Xcode (such as XVim2). This meant that many existing plugins would no longer work after Xcode 8. Apple probably decided to do this for a number of reasons with the main one being to patch security vulnerabilities highlighted by the [XcodeGhost malware](https://en.wikipedia.org/wiki/XcodeGhost), which used the old plugin system as part of its attack vector. 

Apple's decision meant that any existing plugins would have to be rewritten to support the new Source Editor Extensions system, however, in many instances this is not yet possible because the extension system does not yet provide enough access via APIs for plugins to replicate their existing feature sets. _Many features are simply not yet achievable in the new extension system_ 😔 but hopefully they will be one day.

Replacing the existing Xcode signature currently bypasses the restriction for versions of Xcode newer than Xcode 8 and allows them to still load old plugins like XVim2. If you don't replace the signature, Xcode will quietly refuse to load the plugin and it will not work. 

That's the TL;DR 👍. 

If you want to know a bit more detail, then read on... .

## How did Xcode plugins like Xvim2 work before?

Before 2016, Apple allowed developers to create plugins for Xcode to extend its features. The vast majority of created plugins were useful, safe and provided developers with ways to improve their development process. 

When you installed a new plugin and launched Xcode you would be presented with an option asking if you wanted to load the plugin, which essentially meant that you were injecting additional, unsigned, third-party code into the IDE to augment its behaviour. 

The advantages of this were that is was very flexible, plugin creators had a lot of freedom with what they could implement and we could all add awesome features to our IDE 🎉. However, there were disadvantages to this approach as well and Apple realised this and decided to change how this process worked.

## What changed?

At Apple's Worldwide Developers Conference (WWDC) in 2016 Apple announced that they would no longer be supporting unsigned plugins from within Xcode and instead announced a replacement called Source Editor Extensions as a new way for plugin creators to extend the features of Xcode. From Xcode 8 onwards, plugins would no longer load when you opened Xcode unless they were extensions.

## Can I use a Source Editor Extension version of plugins like XVim2 instead?

And here's where the real issue comes in. 

The first thing plugin creators started to do was investigate this new approach and to assess what would be required to convert their plugins to extensions. The issue is that extensions are much more limited than the original plugins in terms of what they allow plugin creators to do. *Many features in existing plugins simply cannot be replicated using the new extension system*. XVim2 is one of many plugins affected by this at the moment. That's not to say it won't potentially improve over time but Apple would need to add new APIs to provide additional access for extensions before many existing plugins could be migrated to the new approach.

However, *replacing the signature from Xcode still enables the old plugins to work*. 

## Why did Apple change this?

In their [WWDC video](https://developer.apple.com/videos/play/wwdc2016/414), Apple listed stability, speed and security as major factors. The main reason is probably due to a security vulnerability announced in 2015 called [XcodeGhost](https://en.wikipedia.org/wiki/XcodeGhost). 

XcodeGhost is malware that managed to infect around 4000 apps that had been published in the iTunes AppStore. One of the ways it achieves this is via the original plugin loading system. It seems that the malware is injected into Xcode and then these versions of Xcode were shared among developers who unknowingly used it to build and distribute their apps. When the developer builds their app for distribution, the malware would inject malicious code into the app without either Apple or the developer realising. 

It's thought that some developers in China would prefer not to use Apple's official sources for obtaining their copies of Xcode, perhaps due to very slow network speeds, so instead they would share alternative copies of Xcode without realising that these versions came bundled with the malware. Developers using these versions of Xcode would then compile their apps, which would automatically become infected, before submitting them to the AppStore.

If you're interested, you can [read exactly how the XcodeGhost attack vector works](https://researchcenter.paloaltonetworks.com/2015/09/novel-malware-xcodeghost-modifies-xcode-infects-apple-ios-apps-and-hits-app-store/).

Apple realised that part of the attack vector for XcodeGhost was that it exploited the unsigned plugin system that thousands of other enormously useful tools relied upon. So Apple prohibited code injection via plugins in Xcode 8 and provided Source Editor Extensions as an alternative method for plugin creators. This is definitely a move in the right direction with regards to improving security for end users but the downside is the replacement tools (extensions) are not yet capable of replicating many existing plugin features. 

## So why do I need to resign my Xcode version to use XVim2?

Simply put, when you download Xcode officially from Apple the Xcode app is signed with a signature. If you try to load a plugin using a signed version of Xcode 8 or newer it will not work. 

This is not just true for XVim2. It's also true for thousands of other plugins.  The very popular plugin manager [Alcatraz](https://github.com/alcatraz/Alcatraz/issues/475) no longer supports versions of Xcode after Xcode 8 for this same reason.

At this point there are two options:

1. Use a Source Editor Extension version of the plugin instead, or
2. Strip the signature from your version of Xcode.

## Is it safe for me to replace Xcode's signature?

There will be a differing opinion on this. However I think it's recommended that you always download Xcode from official Apple sources (either their [website](https://support.apple.com/downloads) or via the Mac AppStore) and you at least keep an original, official, signed copy of Xcode around for when you compile your app for distribution. You won't be able to use any old plugins, including XVim2, in this version of Xcode.

Either way, if you are concerned, be a responsible developer and investigate the potential risks to your end users.

Hopefully the extensions system will improve over time 💪. For now, it's probably a good idea for us to [create bug reports](https://developer.apple.com/bug-reporting/) and [radars](https://openradar.appspot.com/) to request the additional features we would like to see in the extension system.

