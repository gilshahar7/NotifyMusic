FINALPACKAGE = 1
GO_EASY_ON_ME = 1
ARCHS = armv7 arm64 arm64e
VALID_ARCHS = armv7 armv7s arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NotifyMusic
NotifyMusic_FILES = Tweak.xm
NotifyMusic_FRAMEWORKS = UIKit
NotifyMusic_PRIVATE_FRAMEWORKS = MediaRemote
NotifyMusic_LIBRARIES = bulletin

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += notifymusicprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
