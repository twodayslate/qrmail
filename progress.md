###THEOS

[Getting started wiki](http://iphonedevwiki.net/index.php/Theos/Getting_Started)

Bash fix for i5 devices: http://www.jailbreakqa.com/questions/174539/how-to-get-theos-for-ios-6  
     iPhone 5's have a problem with perl so [this](https://github.com/DHowett/theos/issues/53) dirty hack can potentially fix the problem  
Installing a GCC toolchain:

     wget http://apt.saurik.com/debs/libgcc_4.2-20080410-1-6_iphoneos-arm.deb
     dpkg -i libgcc_4.2-20080410-1-6_iphoneos-arm.deb
     
Install perl: 

     wget http://coredev.nl/cydia/coredev.pub
     apt-key add coredev.pub
     echo 'deb http://coredev.nl/cydia iphone main' > /etc/apt/sources.list.d/coredev.nl.list
     apt-get update
     apt-get install perl
     
https://code.google.com/p/iphonedevonlinux/wiki/Installation  
https://code.google.com/p/apiexplorer/

##Installation

http://iosopendev.com/

To create a Couria tweak create CaptainHook Tweak via Xcode
