export TARGET = iphone:clang:14.5:14.5
INSTALL_TARGET_PROCESSES = SpringBoard
export ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ccdndsbhook

ccdndsbhook_FILES = Tweak.xm
ccdndsbhook_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
