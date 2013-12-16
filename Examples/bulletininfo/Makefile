THEOS_DEVICE_IP=192.168.0.101

include theos/makefiles/common.mk

TWEAK_NAME = bulletinInfo
bulletinInfo_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
