include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WiFiInfo

$(TWEAK_NAME)_FILES = WiFiInfo.xm
$(TWEAK_NAME)_FRAMEWORKS = CydiaSubstrate UIKit Security
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = MobileWiFi
$(TWEAK_NAME)_LDFLAGS = -Wl,-segalign,4000
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

ARCHS = arm64e

include $(THEOS_MAKE_PATH)/tweak.mk