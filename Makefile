include $(THEOS)/makefiles/common.mk

export TARGET = iphone:clang:14.5:14.5
export ARCHS = arm64 arm64e

BUNDLE_NAME = CCDNDTimer
CCDNDTimer_BUNDLE_EXTENSION = bundle
CCDNDTimer_FILES = CCDNDTimer.xm
CCDNDTimer_PRIVATE_FRAMEWORKS = ControlCenterUIKit
CCDNDTimer_INSTALL_PATH = /Library/ControlCenter/Bundles/
CCDNDTimer_CFLAGS = -fobjc-arc

after-install::
	install.exec "sbreload || killall -9 SpringBoard"
	
include $(THEOS_MAKE_PATH)/bundle.mk
SUBPROJECTS += ccdndsbhook
include $(THEOS_MAKE_PATH)/aggregate.mk
