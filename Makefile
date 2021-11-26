include $(THEOS)/makefiles/common.mk

TARGET = iphone:clang:11.2:11.0
export ARCHS = arm64 arm64e

BUNDLE_NAME = CCDNDTimer
CCDNDTimer_BUNDLE_EXTENSION = bundle
CCDNDTimer_FILES = CCDNDTimer.xm
CCDNDTimer_PRIVATE_FRAMEWORKS = ControlCenterUIKit
CCDNDTimer_INSTALL_PATH = /Library/ControlCenter/Bundles/
CCDNDTimer_CFLAGS = -fobjc-arc

after-install::
	install.exec "killall -9 SpringBoard"

include $(THEOS_MAKE_PATH)/bundle.mk