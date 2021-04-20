xcodebuild:=xcodebuild -configuration
xcode_plugin_path:=$(HOME)/Library/Application Support/Developer/Shared/Xcode/Plug-ins
simbl_plugin_path:=/Library/Application Support/MacEnhance/Plugins

ifdef BUILDLOG
REDIRECT=>> $(BUILDLOG)
endif

.PHONY: release debug clean clean-release clean-debug simbl move-to-simbl uninstall uuid build-test

release: uuid
	$(xcodebuild) Release $(REDIRECT)

debug: uuid
	$(xcodebuild) Debug $(REDIRECT)

unit-test:
	$(xcodebuild) Release GCC_PREPROCESSOR_DEFINITIONS=UNIT_TEST=1 $(REDIRECT)

clean: clean-release clean-debug

clean-release:
	$(xcodebuild) Release clean

clean-debug:
	$(xcodebuild) Debug clean

simbl: release move-to-simbl

move-to-simbl:
	rm -rf "$(simbl_plugin_path)/XVim2.bundle"; \
	if [ -d "$(simbl_plugin_path)" ]; then \
		mv "$(xcode_plugin_path)/XVim2.xcplugin" "$(simbl_plugin_path)/XVim2.bundle"; \
		printf "\nInstall to SIMBL plugin directory succeeded.\n"; \
	else \
		printf "\n$(simbl_plugin_path) directory not found.\n"; \
		printf "\nPlease setup MacForge.\n"; \
	fi;

uninstall:
	rm -rf "$(xcode_plugin_path)/XVim2.xcplugin"; \
	rm -rf "$(simbl_plugin_path)/XVim2.bundle";

uuid:
	@xcode_path=`xcode-select -p`; \
	uuid=`defaults read "$${xcode_path}/../Info" DVTPlugInCompatibilityUUID`; \
	xcode_version=`defaults read "$${xcode_path}/../Info" CFBundleShortVersionString`; \
	grep $${uuid} XVim2/Info.plist > /dev/null ; \
	if [ $$? -ne 0 ]; then \
		printf "XVim hasn't confirmed the compatibility with your Xcode, Version $${xcode_version}\n"; \
		printf "Do you want to compile XVim with support Xcode Version $${xcode_version} at your own risk? (y/N)"; \
		read -r -n 1 in; \
		if [[ $$in != "" &&  ( $$in == "y" || $$in == "Y") ]]; then \
			plutil -insert DVTPlugInCompatibilityUUIDs.0 -string $${uuid} XVim2/Info.plist; \
		fi ;\
		printf "\n"; \
	fi ;

# Build with all the available Xcode in /Applications directory
build-test:
	@> build.log; \
    xcode_path=`xcode-select -p`; \
	for xcode in /Applications/Xcode*.app; do \
		sudo xcode-select -s "$$xcode"; \
		echo Building with $$xcode >> build.log; \
		"$(MAKE)" -C . BUILDLOG=build.log; \
	done; \
	sudo xcode-select -s $${xcode_path}; \
