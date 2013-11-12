//
//  qwikMailViewController.m
//  ttest
//
//  Created by Zac Gorak on 11/4/13.
//  Copyright (c) 2013 PRNDL Development Studios, LLC. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import "qwikMailViewController.h"


#import "Message.framework/Headers/MessageWriter.h"
#import "MIME.framework/Headers/MutableMessageHeaders.h"
#import "Message.framework/Headers/OutgoingMessage.h"
#import "Message.framework/Headers/MFMailDelivery.h"
#import "Message.framework/Headers/MailAccount.h"
#import "Message.framework/Headers/LocalAccount.h"
#import "Message.framework/Headers/Account.h"

@interface qwikMailViewController ()
@end

@implementation qwikMailViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setPercentDone:(double)percent { NSLog(@"inside setPercentDone",NULL); }

-(IBAction)sendMail:(id)sender {
    // Do Something
    NSLog(@"inside sendMail %@",sender);
    
    NSArray *emails = [MailAccount activeAccounts];
    MailAccount *mail = emails[1];
    
    NSLog(@"EMAIL [MailAccount activeAccounts] = %@",[MailAccount activeAccounts]);
    NSLog(@"EMAIL [MailAccount activeAccounts][0] = %@",mail);
    NSLog(@"EMAIL [activeAccounts displayName] = %@",[mail displayName]);
    NSLog(@"EMAIL [defaultDeliveryAccount password] = %@",[emails[1] password]);
    NSLog(@"EMAIL [defaultDeliveryAccount passwordFromKeychain] = %@",[emails[1] passwordFromKeychain]);
    NSLog(@"EMAIL [defaultDeliveryAccount passwordFromStoredUserInfo = %@",[emails[1] passwordFromStoredUserInfo]);
    NSLog(@"EMAIL [activeAccounts emailAddresses] = %@",[mail emailAddresses]); //list of all email address associated with account (
//    "zac@gorak.us",
//    "zachary.gorak@usma.edu",
//    "eggzacly@gmail.com"
//	)
    NSLog(@"EMAIL [activeAccounts displayUsername] = %@",[mail displayUsername]); //zac@gorak.us
    NSLog(@"EMAIL [activeAccounts fullUserName] = %@",[mail fullUserName]); // Zac Gorak
    NSLog(@"EMAIL [MailAccount defaultDeliveryAccount] = %@",[MailAccount defaultDeliveryAccount]);
    NSLog(@"EMAIL [defaultDeliveryAccount password] = %@",[[MailAccount defaultDeliveryAccount] password]);
    NSLog(@"EMAIL [defaultDeliveryAccount passwordFromKeychain] = %@",[[MailAccount defaultDeliveryAccount] passwordFromKeychain]);
    NSLog(@"EMAIL [defaultDeliveryAccount passwordFromStoredUserInfo = %@",[[MailAccount defaultDeliveryAccount] passwordFromStoredUserInfo]);
    NSLog(@"EMAIL [defaultDeliveryAccount domain] = %@",[[MailAccount defaultDeliveryAccount] domain]);
    
    
    NSString *email = [mail emailAddresses][0];
    //[_textView resignFirstResponder];
    //[_progressHUD showInView:[self view]];
    
        MessageWriter *messageWriter = [[MessageWriter alloc] init];
        MutableMessageHeaders *headers = [[MutableMessageHeaders alloc] init];
        
        NSString *subject =  @"Subject";
        [headers setHeader:subject forKey:@"subject"];
        [headers setAddressListForTo:[NSArray arrayWithObjects:@"zac@gorak.us", nil]];
        [headers setAddressListForSender:[NSArray arrayWithObjects:email, nil]];
        
        OutgoingMessage *message = [messageWriter createMessageWithString:@"Body" headers:headers];
        MFMailDelivery *messageDelivery = [MFMailDelivery newWithMessage:message];
        
        [messageDelivery setDelegate:self];
        [messageDelivery deliverAsynchronously];
        
//        [messageWriter release];
//        [headers release];
//        [message release];
//        [messageDelivery release];
}

@end
