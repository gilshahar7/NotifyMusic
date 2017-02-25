ARCHS = armv7 arm64
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = notifymusicprefs
notifymusicprefs_FILES = nmpRootListController.m
notifymusicprefs_INSTALL_PATH = /Library/PreferenceBundles
notifymusicprefs_FRAMEWORKS = UIKit
notifymusicprefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/notifymusicprefs.plist$(ECHO_END)
