// <Warning>: -[<MSNotificationObserver: 0x226c1850> _didReceiveNotificationData:{
// 	    MSNotificationKeyEventType = MSNotificationEventMessagesSummariesFetched;
// 	    MSNotificationKeyMessages =     (
// 	                {
// 	            MSResultsKeyAccountReference = "E927125D-2F83-43CE-8401-A3B7BE3BAFE6";
// 	            MSResultsKeyBodySummary = testbody;
// 	            MSResultsKeyDateReceived = "2013-12-08 03:35:12 +0000";
// 	            MSResultsKeyMessageReference = "x-apple-mail-message-id:3895&A5121DF9-D2C0-4F3C-844F-910FEC36E922";
// 	            MSResultsKeySender = "Zac Gorak <zac@gorak.us>";
// 	            MSResultsKeyStatus = 1;
// 	            MSResultsKeySubject = testsub;
// 	            "_MSResultsKeySuppressionContexts" =             (
// 	                "imap://zac%40gorak.us@imap.gmail.com/INBOX",
// 	                "-883122841690135081"
// 	            );
// 	        }
// 	    );

#import <substrate.h>

//LLAdditions

@interface UIAlertView (Undocumented)
- (void)setSubtitle:(id)subtitle;
-(void)setTaglineText:(id)text;
@end

@interface MutableMessageHeaders
- (void)setHeader:(id)header forKey:(id)key;
- (void)setAddressList:(id)list forKey:(id)key;
- (void)setAddressListForTo:(id)arg1;
- (void)setAddressListForSender:(id)arg1;
@end

@interface MessageWriter
-(id)createMessageWithString:(id)string headers:(id)headers;
@end

@interface MFMailDelivery
+ (id)newWithMessage:(id)arg1;
- (void)setDelegate:(id)arg1;
- (int)deliverSynchronously;
- (void)deliverAsynchronously;
@end

@interface OutgoingMessage
@end

@interface MessageLibrary
- (id)messageWithMessageID:(id)arg1 inMailbox:(id)arg2;
- (id)messageWithLibraryID:(unsigned int)arg1 options:(unsigned int)arg2 inMailbox:(id)arg3;
@end

@interface LibraryMessage
- (id)preferredEmailAddressToReplyWith;
@end

@interface MailAccount
+(NSArray*)activeAccounts;
-(MessageLibrary*)library;
@end

static id subject = nil;
static id from = nil;
static id replyas = nil;

%hook MSNotificationObserver

- (void)_didReceiveNotificationData:(id)arg1 {
	
	id type = [arg1 objectForKey:@"MSNotificationKeyEventType"];
	NSLog(@"type: %@",type);
	if([type isEqual:@"MSNotificationEventMessagesSummariesFetched"])
	{
		id message = [arg1 objectForKey:@"MSNotificationKeyMessages"];
		[message retain];
		NSLog(@"messages: %@", message);
		from = [message[0] objectForKey:@"MSResultsKeySender"];
		[from retain];
		subject = [message[0] objectForKey:@"MSResultsKeySubject"];
		[subject retain];
		id body = [message[0] objectForKey:@"MSResultsKeyBodySummary"];
		NSLog(@"from: %@",from);
		NSLog(@"subject: %@",subject);
		NSLog(@"body: %@",body);
		
		id key = [message[0] objectForKey:@"MSResultsKeyMessageReference"];
		NSString *libID = [key componentsSeparatedByString:@"&"][0];
		libID = [libID stringByReplacingOccurrencesOfString:@"x-apple-mail-message-id:" withString:@""];
		NSString *exmid = [key componentsSeparatedByString:@"&"][1];
		id mid = [message[0] objectForKey:@"_MSResultsKeySuppressionContexts"][1];
		id folder = [message[0] objectForKey:@"_MSResultsKeySuppressionContexts"][0];
		
		NSLog(@"key = %@",key);
		NSLog(@"library ID = %@",libID);
		NSLog(@"external message ID = %@",exmid);
		NSLog(@"message id = %@",mid);
		NSLog(@"inbox folder = %@", folder);
		
		for (MailAccount* account in [objc_getClass("MailAccount") activeAccounts]) {
		    NSLog(@"account = %@",account);
			MessageLibrary *libr = [account library];
			NSLog(@"library = %@",libr);
			id mes = [libr messageWithMessageID:mid inMailbox:folder];
			NSLog(@"Message = %@",mes);
            LibraryMessage *mes_one = [libr messageWithLibraryID:libID.intValue options:1 inMailbox:folder];
			replyas = [mes_one preferredEmailAddressToReplyWith];
		    [replyas retain];
			// do stuff
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{ 
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:subject message:body delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Reply",nil];
			alert.alertViewStyle = UIAlertViewStylePlainTextInput;
			[alert setSubtitle:from];
			[alert setTaglineText:[@"Replying as " stringByAppendingString:replyas]];
			[alert show];
			[alert release];
		});		
	}

// 	//taglineText for replying as?

	%orig;
}

%new
-(void)setPercentDone:(double)percent { NSLog(@"inside setPercentDone and actually sending mail!",NULL); }

%new
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if(buttonIndex == 0) {
		NSLog(@"button 0 (cancel) pressed %d",nil);
	}
	else if(buttonIndex == 1) {
		NSLog(@"button 1 (send) pressed",nil);
		id body = [alertView textFieldAtIndex:0].text;
		NSLog(@"from: %@",from);
		NSLog(@"subject: %@",subject);
		NSLog(@"body: %@",body);
		
		MessageWriter *messageWriter = [[%c(MessageWriter) alloc] init];
        MutableMessageHeaders *headers = [[%c(MutableMessageHeaders) alloc] init];

        [headers setHeader:subject forKey:@"subject"];
        [headers setAddressListForTo:[NSArray arrayWithObjects:from, nil]];
        [headers setAddressListForSender:[NSArray arrayWithObjects:replyas, nil]];

        OutgoingMessage *message = [messageWriter createMessageWithString:body headers:headers];
        MFMailDelivery *messageDelivery = [%c(MFMailDelivery) newWithMessage:message];

        [messageDelivery setDelegate:self];
        [messageDelivery deliverAsynchronously];
	}

    //NSLog(@"%@", [alertView textFieldAtIndex:0].text);
}

%end