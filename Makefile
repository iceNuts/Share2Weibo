GO_EASY_ON_ME=1
include theos/makefiles/common.mk

TWEAK_NAME = photopluginactivator
photopluginactivator_FILES = Gesture.xm sqlService.m photoPicker.mm
photopluginactivator_FRAMEWORKS= Twitter UIKit Foundation
photopluginactivator_PRIVATE_FRAMEWORKS= AppSupport
SUBPROJECTS= photopluginsettings photosplugin 

photopluginactivator_LDFLAGS = libactivator.dylib -lsqlite3

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
