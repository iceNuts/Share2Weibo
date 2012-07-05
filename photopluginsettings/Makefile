GO_EASY_ON_ME=1
include theos/makefiles/common.mk

BUNDLE_NAME = photopluginsettings
photopluginsettings_FILES = photopluginsettings.mm photopluginauthorize.mm photopluginsupport.mm photopluginauthorizecode.mm purchaseChecker.mm
photopluginsettings_INSTALL_PATH = /Library/PreferenceBundles
photopluginsettings_FRAMEWORKS = UIKit Foundation
photopluginsettings_PRIVATE_FRAMEWORKS = Preferences AppSupport

photopluginsettings_LDFLAGS= -lsqlite3

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/photopluginsettings.plist$(ECHO_END)
