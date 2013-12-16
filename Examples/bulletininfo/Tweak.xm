/* How to Hook with Logos
Hooks are written with syntax similar to that of an Objective-C @implementation.
You don't need to #include <substrate.h>, it will be done automatically, as will
the generation of a class list and an automatic constructor.

%hook ClassName

// Hooking a class method
+ (id)sharedInstance {
	return %orig;
}

// Hooking an instance method with an argument.
- (void)messageName:(int)argument {
	%log; // Write a message about this call, including its class, name and arguments, to the system log.

	%orig; // Call through to the original function with its original arguments.
	%orig(nil); // Call through to the original function with a custom argument.

	// If you use %orig(), you MUST supply all arguments (except for self and _cmd, the automatically generated ones.)
}

// Hooking an instance method with no arguments.
- (id)noArguments {
	%log;
	id awesome = %orig;
	[awesome doSomethingElse];

	return awesome;
}

// Always make sure you clean up after yourself; Not doing so could have grave consequences!
%end
*/

#import <substrate.h>

@interface BBBulletin
	- (id)context;
	- (id)recordID;
@end
	
@interface MFMailMessageLibrary
	- (id)messageWithMessageID:(id)arg1 inMailbox:(id)arg2;
	- (id)allMailboxURLStrings;
	- (unsigned int)totalCountForMailbox:(id)arg1;
	- (id)oldestMessageInMailbox:(id)arg1;
	- (unsigned int)mailboxIDForURLString:(id)arg1;
	- (id)messagesWithMessageIDHeader:(id)arg1;
	- (id)getDetailsForAllMessagesFromMailbox:(id)arg1;
	- (id)messageWithLibraryID:(unsigned int)arg1 options:(unsigned int)arg2 inMailbox:(id)arg3;
	- (id)conversationIDsOfMessagesInSameThreadAsMessageWithLibraryID:(unsigned int)arg1 messageIDHash:(long long)arg2;
	- (id)bodyDataForMessage:(id)arg1;
	- (id)headerDataForMessage:(id)arg1;
@end
	
@interface MailAccount
	- (id)activeAccounts;
	- (id)library;
	- (id)primaryMailboxUid;
	- (id)uniqueId;
@end
	
@interface PLUUIDString
	- (id)initWithUUID:arg1;
@end

@interface MailboxUid
	- (id)uniqueId;
@end

@interface LibraryMessage
	- (id)messageID;
	- (id)messageStore;
	- (id)copyMessageInfo;
	- (id)subject;
	- (id)preferredEmailAddressToReplyWith;
	- (id)messageStore;
	- (id)path;
	- (id)URL;
	- (id)firstSender;
	- (id)senders;
	- (id)headerData;
	- (id)bodyData;
@end

@interface LibraryStore
	- (id)messageForMessageID:(id)arg1 options:(unsigned int)arg2;
	- (id)copyOfMessageInfos;
	- (id)copyOfAllMessages;
	- (id)_cachedBodyForMessage:(id)arg1 valueIfNotPresent:(id)arg2;
	- (id)_cachedBodyDataForMessage:(id)arg1 valueIfNotPresent:(id)arg2;
	- (id)bodyDataForMessage:(id)arg1 isComplete:(char *)arg2 isPartial:(char *)arg3 downloadIfNecessary:(BOOL)arg4;
	- (id)headersForMessage:(id)arg1 fetchIfNotAvailable:(BOOL)arg2;
@end

@interface MessageDetails
	- (id)messageID;
	- (id)externalID;
	- (id)copyMessageInfo;
@end
	
// @interface MSNotificationObserver
// 	- (id)messagesForAccountIDs:(id)arg1 count:(unsigned int)arg2 cutOffDates:(id)arg3;
// @end
	
%hook SBBulletinBannerController
	- (void)_queueBulletin:(BBBulletin *)arg1 {
		%orig;
		%log;
		NSLog(@"bulletin context: %@",[arg1.context objectForKey:@"com.apple.mobilemail.accountReference"]); //acountID
		NSLog(@"bulletin recordID: %@",arg1.recordID); //Match ID
		NSString *libID = [arg1.recordID componentsSeparatedByString:@"&"][0];
		libID = [libID stringByReplacingOccurrencesOfString:@"x-apple-mail-message-id:" withString:@""];
		NSString *exmid = [arg1.recordID componentsSeparatedByString:@"&"][1];
		NSLog(@"libID: %@",libID);
		NSLog(@"exmid: %@",exmid);
		// get mail account, get library from mail account, get message from library
		MailAccount *mail = [objc_getClass("MailAccount") activeAccounts][1];
		NSLog(@"mail: %@",mail);
		MFMailMessageLibrary *libr = [mail library];
		NSLog(@"library: %@",libr);
		// - (id)messageWithMessageID:(id)arg1 options:(unsigned int)arg2 inMailbox:(id)arg3;
		MailboxUid *inbox = [mail primaryMailboxUid];
		NSLog(@"inbox: %@",inbox);
		NSLog(@"inbox uniquID: %@", [inbox uniqueId]);
		//PLUUIDString *mb = [objc_getClass("PLUUIDString") initWithUUID:[inbox uniqueId]];
		NSString *mid = arg1.recordID;
		NSString *midwo = [mid stringByReplacingOccurrencesOfString:@"x-apple-mail-message-id:" withString:@""];
		id mes = [libr messageWithMessageID:libID inMailbox:@"1"];
		NSLog(@"Message: %@",mes);
		mes = [libr messageWithMessageID:libID inMailbox:@"3"];
		NSLog(@"Message: %@",mes);
		mes = [libr messageWithMessageID:exmid inMailbox:@"INBOX"];
		NSLog(@"Message: %@",mes);
		mes = [libr messageWithMessageID:exmid inMailbox:@"/INBOX"];
		NSLog(@"Message: %@",mes);
		mes = [libr messageWithMessageID:@"33431" inMailbox:@"imap://zac%40gorak.us@imap.gmail.com/INBOX"];
		NSLog(@"Message: %@",mes);
		mes = [libr messageWithMessageID:exmid inMailbox:@"imap://zac%40gorak.us@imap.gmail.com/INBOX"];
		NSLog(@"Message: %@",mes);
		NSLog(@"allMailboxURLStrings: %@",[libr allMailboxURLStrings]);
		NSLog(@"totalCountForMailbox: %u",[libr totalCountForMailbox:@"imap://zac%40gorak.us@imap.gmail.com/INBOX"]);
		NSLog(@"oldestMessageInMailbox: %@",[libr oldestMessageInMailbox:@"imap://zac%40gorak.us@imap.gmail.com/INBOX"]);
		NSLog(@"mailboxIDForURLString: %u",[libr mailboxIDForURLString:@"imap://zac%40gorak.us@imap.gmail.com/INBOX"]);
		NSLog(@"messageWithMessageIDHeader: %@",[libr messagesWithMessageIDHeader:mid]);
		NSLog(@"messageWithMessageIDHeader: %@",[libr messagesWithMessageIDHeader:midwo]);
		NSLog(@"messageWithMessageIDHeader: %@",[libr messagesWithMessageIDHeader:@"4501"]);
		for(MessageDetails *m in [libr getDetailsForAllMessagesFromMailbox:@"imap://zac%40gorak.us@imap.gmail.com/INBOX"]) {
			NSMutableString* logMsg = [NSMutableString stringWithFormat:@"%@ mid %@ eid %@ copyMessageInfo %@",m,[m messageID],[m externalID],[m copyMessageInfo]];
			NSLog(@"%@",logMsg);
		}
		int lid = libID.intValue;
		NSLog(@"lid: %u",lid);
		LibraryMessage *mes_one = [libr messageWithLibraryID:lid options:1 inMailbox:@"imap://zac%40gorak.us@imap.gmail.com/INBOX"];
		NSLog(@"messageWithLibraryID: %@",mes_one);
		NSLog(@"messaeWithLibraryID messageID: %@",[mes_one messageID]);
		NSLog(@"messaeWithLibraryID firstSender: %@",[mes_one firstSender]);
		NSLog(@"messaeWithLibraryID senders: %@",[mes_one senders]);
		NSLog(@"messaeWithLibraryID bodyData: %@",[mes_one bodyData]);
		NSLog(@"messaeWithLibraryID headerData: %@",[mes_one headerData]);
		LibraryStore *st = [mes_one messageStore];
		NSLog(@"messageWithLibraryID messageStore copy of MessageInfos: %@",[st copyOfMessageInfos]);
		NSLog(@"messageWithLibraryID copyMessageInfo: %@",[mes_one copyMessageInfo]);
		NSLog(@"messageWithLibraryID subject: %@",[mes_one subject]);
		NSLog(@"messageWithLibraryID URL: %@",[mes_one URL]);
		NSLog(@"messageWithLibraryID path: %@",[mes_one path]);
		id xampleVariableHooked = MSHookIvar<NSMutableDictionary *>(mes_one, "metadata");
		NSLog(@"messageWithLibraryID metadata: %@",xampleVariableHooked);
		xampleVariableHooked = MSHookIvar<NSMutableDictionary *>(mes_one, "info");
		NSLog(@"messageWithLibraryID info: %@",xampleVariableHooked);
		NSLog(@"messageWithLibraryID messageStore copyOfAllMessages: %@",[st copyOfAllMessages]);
		
		NSLog(@"messageWithLibraryID messageStore _cachedBodyForMessage: %@",[st _cachedBodyForMessage:mes_one valueIfNotPresent:@"Not present"]);
		NSLog(@"messageWithLibraryID messageStore _cachedBodyDataForMessage: %@",[st _cachedBodyDataForMessage:mes_one valueIfNotPresent:@"Not present"]);
		
		NSLog(@"messageWithLibraryID messageStore _cachedBodyForMessage: %@",[st _cachedBodyForMessage:exmid valueIfNotPresent:@"Not present"]);
		//NSLog(@"messageWithLibraryID messageStore _cachedBodyDataForMessage: %@",[st _cachedBodyDataForMessage:exmid valueIfNotPresent:@"Not present"]);
		NSLog(@"messageWithLibraryID messageStore _cachedBodyForMessage: %@",[st _cachedBodyForMessage:libID valueIfNotPresent:@"Not present"]);
		//NSLog(@"messageWithLibraryID messageStore _cachedBodyDataForMessage: %@",[st _cachedBodyDataForMessage:libID valueIfNotPresent:@"Not present"]);
		
		//- (id)headersForMessage:(id)arg1 fetchIfNotAvailable:(BOOL)arg2;
		NSLog(@"ls headersForMessage: %@",[st headersForMessage:mes_one fetchIfNotAvailable:TRUE]);
		// - (id)bodyDataForMessage:(id)arg1 isComplete:(char *)arg2 isPartial:(char *)arg3 downloadIfNecessary:(BOOL)arg4;
		char temp[] = "1";
		NSLog(@"ls bodyDataForMessage: %@",[st bodyDataForMessage:mes_one isComplete:temp isPartial:temp downloadIfNecessary:TRUE]);
		
		NSLog(@"messageWithLibraryID preferredEmailAddressToReplyWith: %@",[mes_one preferredEmailAddressToReplyWith]);
		
		NSLog(@"bodyDataForMessage: %@",[libr bodyDataForMessage:mes_one]);
		NSLog(@"headerDataForMessage: %@",[libr headerDataForMessage:mes_one]);
		
		//NSLog(@"stuff: %@",[objc_getClass("MSNotificationObserver") messagesForAccountIDs:[mail uniqueId] count:10 cutOffDates:Nil]);
		
	}
%end
	
// %hook MFMailMessageLibrary
// 	- (id)messageWithMessageID:(id)arg1 inMailbox:(id)arg2 { %log; return %orig; }
// 	- (id)messageWithMessageID:(id)arg1 options:(unsigned int)arg2 inMailbox:(id)arg3 {%log; return %orig;}
// 	- (id)messagesWithMessageIDHeader:(id)arg1 {%log; return %orig;}
// 	- (id)headerDataForMessage:(id)arg1 {%log; return %orig;}
// %end
	
// 	
// %hook MSNotificationObserver
// 	- (void)_didReceiveNotificationData:(id)arg1 {
// 		%orig;
// 		%log;
// 	}
// %end