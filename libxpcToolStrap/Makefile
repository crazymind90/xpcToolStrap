ARCHS = arm64e arm64

THEOS_PACKAGE_SCHEME=rootless

export SDKVERSION = 14.5

include $(THEOS)/makefiles/common.mk

export LIBRARY_NAME = libxpcToolStrap

libxpcToolStrap_FILES = libxpcToolStrap.mm
libxpcToolStrap_CFLAGS = -Wno-objc-designated-initializers  
libxpcToolStrap_CODESIGN_FLAGS = -S../ent.plist
libxpcToolStrap_INSTALL_PATH = /usr/lib
libxpcToolStrap_CFLAGS += -DXINA_SUPPORT

include $(THEOS_MAKE_PATH)/library.mk

include $(THEOS_MAKE_PATH)/aggregate.mk



