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

export TWEAK_NAME = xpcToolStrapApps xpcToolStrapSB

xpcToolStrapApps_FILES = xpcToolStrapApps.xm
xpcToolStrapApps_CFLAGS = -std=c++11 
xpcToolStrapApps_LDFLAGS += -framework CoreServices
xpcToolStrapApps_CODESIGN_FLAGS = -S../ent.plist


xpcToolStrapSB_FILES = xpcToolStrapSB.xm
xpcToolStrapSB_CFLAGS = -std=c++11 
xpcToolStrapSB_LDFLAGS += -framework CoreServices
xpcToolStrapSB_CODESIGN_FLAGS = -S../ent.plist

ADDITIONAL_CFLAGS += -DTHEOS_LEAN_AND_MEAN -Wno-shorten-64-to-32


include $(THEOS_MAKE_PATH)/tweak.mk

  
before-package::
		$(ECHO_NOTHING) chmod 755 $(CURDIR)/.theos/_/DEBIAN/*  $(ECHO_END)
		$(ECHO_NOTHING) chmod 755 $(CURDIR)/.theos/_/DEBIAN  $(ECHO_END)


install6::
		install6.exec