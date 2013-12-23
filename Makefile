THEOS_DEVICE_IP=192.168.1.14

include theos/makefiles/common.mk

TWEAK_NAME = qrmail
qrmail_FILES = Tweak.xm
qrmail_FRAMEWORKS = UIKit, MessageUI

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
