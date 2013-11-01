## Important Links

[Couria](https://github.com/Qusic/WhatsAppForCouria)

[iPhone Headers](https://github.com/hbang/headers) [Older iPhone Headers](https://github.com/rpetrich/iphoneheaders)
[More headers](https://github.com/nst/iOS-Runtime-Headers/tree/master/PrivateFrameworks/Message.framework)

## Implementation

Options: 

1. Initiate hidden MFMailControlViewController and send it
2. Disassemble MessagesUI.framework

###sendMessage function

    Given by cykey
    
    -(void)send:(id)send;
    -(void)sendMessage;
    -(BOOL)deliverMessage;
    -(BOOL)deliverMessageRemotely;

are all in: MessageUI/MailComposeController.h

[MailDelivery.h](https://github.com/nst/iOS-Runtime-Headers/blob/master/PrivateFrameworks/Message.framework/MFMailDelivery.h)
[MessageWriter](https://github.com/nst/iOS-Runtime-Headers/blob/d576a9cc197412e81aa87624b755e59b4f00e3cd/PrivateFrameworks/Message.framework/MessageWriter.h)

###getMessages function

[MSNotificationObserver](https://github.com/nst/iOS-Runtime-Headers/blob/master/PrivateFrameworks/MailServices.framework/MSNotificationObserver.h)

## Useful Links?
[How to set notification number](http://stackoverflow.com/questions/8682051/ios-application-how-to-clear-notifications)
[Accessing the addressbook](http://zcentric.com/2008/09/19/access-the-address-book/)
[Recent contacts](http://forums.macrumors.com/showthread.php?t=835559)
[Mobile Substrate Tutorial](http://xsellize.com/topic/197822-ms-mobile-substrate-advanced-tutorial/)
http://www.cydiasubstrate.com/


Useful links: 
http://iphonedevwiki.net/index.php/Message.framework  
https://developer.apple.com/library/ios/DOCUMENTATION/AddressBook/Reference/AddressBook_iPhoneOS_Framework/AddressBook_iPhoneOS_Framework.pdf  
http://iphonedevwiki.net/index.php/MailAccount  
