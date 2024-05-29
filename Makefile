ARCHS = arm64 arm64e

export TARGET = iphone:14.5
export SDKVERSION = 14.5

export THEOS_PACKAGE_SCHEME = rootless

export iP = 192.168.1.102
export Port = 22
export Pass = alpine
export Bundle = com.apple.springboard


export DEBUG = 1
 
include $(THEOS)/makefiles/common.mk


ADDITIONAL_CFLAGS += -DTHEOS_LEAN_AND_MEAN -Wno-shorten-64-to-32


include $(THEOS_MAKE_PATH)/tweak.mk


SUBPROJECTS += xpcToolStrapd
SUBPROJECTS += libxpcToolStrap


include $(THEOS_MAKE_PATH)/aggregate.mk

before-package::
		$(ECHO_NOTHING) chmod 755 $(CURDIR)/.theos/_/DEBIAN/*  $(ECHO_END)
		$(ECHO_NOTHING) chmod 755 $(CURDIR)/.theos/_/DEBIAN  $(ECHO_END)


install6::
		install6.exec