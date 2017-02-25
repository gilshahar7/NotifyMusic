ARCHS = armv7 arm64
VALID_ARCHS = armv7 armv7s arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NotifyMusic
NotifyMusic_FILES = Tweak.xm
NotifyMusic_FRAMEWORKS = UIKit
NotifyMusic_LIBRARIES = bulletin

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += notifymusicprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
