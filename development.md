## Important Links

[Couria](https://github.com/Qusic/WhatsAppForCouria)

[iPhone Headers](https://github.com/hbang/headers) [Older iPhone Headers](https://github.com/rpetrich/iphoneheaders)


## Implementation

Options: 

1. Initiate hidden MFMailControlViewController and send it
2. Disassemble MessagesUI.framework

###sendMessage function

    -(void)send:(id)send;
    -(void)sendMessage;
    -(BOOL)deliverMessage;
    -(BOOL)deliverMessageRemotely;

are all in: MessageUI/MailComposeController.h
