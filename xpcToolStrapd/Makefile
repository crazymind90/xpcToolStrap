ARCHS = arm64e arm64

THEOS_PACKAGE_SCHEME=rootless

include $(THEOS)/makefiles/common.mk

export THEOS_PACKAGE_SCHEME = rootless

TOOL_NAME = xpcToolStrapd
xpcToolStrapd_FILES = $(wildcard *.mm)
xpcToolStrapd_INSTALL_PATH = /usr/local/libexec
xpcToolStrapd_CODESIGN_FLAGS = -S../ent.plist
ADDITIONAL_CFLAGS += -DTHEOS_LEAN_AND_MEAN -Wno-shorten-64-to-32


include $(THEOS_MAKE_PATH)/tool.mk
