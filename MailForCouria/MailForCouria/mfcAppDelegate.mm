//
//  WhatsAppForCouria.mm
//  WhatsAppForCouria
//
//  Created by Qusic on 8/3/13.
//  Copyright (c) 2013 Qusic. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <substrate.h>
#import <sys/sysctl.h>
//#import "CaptainHook/CaptainHook.h"
#import "Couria.h"

#define MailForCouriaIdentifier "zac.gorak.mailforcouria"
#define SpringBoardIdentifier @"com.apple.springboard"
#define BackBoardIdentifier @"com.apple.backboardd"
#define MailIdentifier @"com.apple.mail"
#define GmailIdentifier @"google.gmail"
#define UserDefaultsPlist @"/var/mobile/Library/Preferences/zac.gorak.mailforcouria.plist"
#define UserDefaultsChangedNotification CFSTR("zac.gorak.mailforcouria.UserDefaultsChanged")
#define ApplicationDidExitNotification CFSTR("zac.gorak.mailforcouria.ApplicationDidExit")
#define UserIDKey @"UserID"
#define MessageKey @"Message"
#define KeepAliveKey @"KeepAlive"

typedef NS_ENUM(SInt32, CouriaWhatsAppServiceMessageID) {
    GetNickname,
    GetAvatar,
    GetMessages,
    GetContacts,
    SendMessage,
    MarkRead
};

#pragma mark - Headers

@interface CouriaWhatsAppMessage : NSObject <CouriaMessage, NSSecureCoding>
@property(retain) NSString *text;
@property(retain) id media;
@property(assign) BOOL outgoing;
@end

@interface CouriaWhatsAppDataSource : NSObject <CouriaDataSource>
@end

@interface CouriaWhatsAppDelegate : NSObject <CouriaDelegate>
@end

@interface UIApplication (Private)
- (BOOL)launchApplicationWithIdentifier:(NSString *)identifier suspended:(BOOL)suspended;
@end

@interface BBBulletin : NSObject
@property(retain, nonatomic) NSDictionary *context;
@end

#ifdef __cplusplus
extern "C" {
#endif
    int xpc_connection_get_pid(id connection);
#ifdef __cplusplus
}
#endif

typedef NS_ENUM(NSUInteger, BKSProcessAssertionReason)
{
    kProcessAssertionReasonAudio = 1,
    kProcessAssertionReasonLocation,
    kProcessAssertionReasonExternalAccessory,
    kProcessAssertionReasonFinishTask,
    kProcessAssertionReasonBluetooth,
    kProcessAssertionReasonNetworkAuthentication,
    kProcessAssertionReasonBackgroundUI,
    kProcessAssertionReasonInterAppAudioStreaming,
    kProcessAssertionReasonViewServices
};

typedef NS_OPTIONS(NSUInteger, ProcessAssertionFlags)
{
    ProcessAssertionFlagNone = 0,
    ProcessAssertionFlagPreventSuspend         = 1 << 0,
    ProcessAssertionFlagPreventThrottleDownCPU = 1 << 1,
    ProcessAssertionFlagAllowIdleSleep         = 1 << 2,
    ProcessAssertionFlagWantsForegroundResourcePriority  = 1 << 3
};

@interface BKSProcessAssertion : NSObject
@property(readonly, assign, nonatomic) BOOL valid;
- (id)initWithPID:(int)pid flags:(unsigned)flags reason:(unsigned)reason name:(id)name withHandler:(id)handler;
- (id)initWithBundleIdentifier:(id)bundleIdentifier flags:(unsigned)flags reason:(unsigned)reason name:(id)name withHandler:(id)handler;
@end

@interface BKApplication : NSObject
@property(readonly, assign, nonatomic) NSString *bundleIdentifier;
@end

@interface BKWorkspaceServer : NSObject
- (void)applicationDidExit:(BKApplication *)application withInfo:(id)info;
@end

@interface WAContact : NSObject
@property(retain, nonatomic) NSString *fullName;
@end

@interface WAPhone : NSObject
@property(retain, nonatomic) WAContact *contact;
@property(retain, nonatomic) NSString* whatsAppID;
@end

@interface WAGroupInfo : NSObject
@property(retain, nonatomic) NSString *picturePath;
@end

@interface WAChatSession : NSObject
@property(retain, nonatomic) NSString *contactJID;
@property(retain, nonatomic) NSString *partnerName;
@property(retain, nonatomic) WAGroupInfo *groupInfo;
@property(retain, nonatomic) NSNumber *unreadCount;
@end

@interface WAMediaItem : NSObject
@property(retain, nonatomic) NSNumber *mediaSaved;
@property(retain, nonatomic) NSString *mediaLocalPath;
@end

@interface WAGroupMember : NSObject
@property(retain, nonatomic) NSString *contactName;
@end

typedef NS_ENUM(NSInteger, WhatsAppMessageType) {
    TextMessage  = 0,
    PhotoMessage = 1,
    MovieMessage = 2
};

@interface WAMessage : NSObject
@property(retain, nonatomic) NSString *text;
@property(retain, nonatomic) NSNumber *messageType;
@property(retain, nonatomic) WAMediaItem *mediaItem;
@property(retain, nonatomic) NSNumber *isFromMe;
@property(retain, nonatomic) NSDate *messageDate;
@property(retain, nonatomic) NSNumber *groupEventType;
@property(retain, nonatomic) WAGroupMember *groupMember;
@end

@class NSManagedObjectID;

@interface WAContactsStorage : NSObject
- (NSArray *)favorites;
- (WAContact *)contactForJID:(NSString *)jid;
- (WAPhone *)phoneWithObjectID:(NSManagedObjectID *)objectID;
- (UIImage *)profilePictureForJID:(NSString *)jid;
@end

@interface WAChatStorage : NSObject
- (NSArray *)chatSessionsWithBroadcast:(BOOL)broadcast;
- (WAChatSession *)existingChatSessionForJID:(NSString *)jid;
- (WAChatSession *)createChatSessionForContact:(WAContact *)contact JID:(NSString *)jid;
- (NSArray *)messagesForSession:(WAChatSession *)session startOffset:(NSUInteger)offset limit:(NSUInteger)limit;
- (void)storeModifiedChatSession:(WAChatSession *)session;
- (WAMessage *)messageWithText:(NSString *)text inChatSession:(WAChatSession *)chatSession isBroadcast:(BOOL)broadcast;
- (WAMessage *)messageWithImage:(UIImage *)image inChatSession:(WAChatSession *)chatSession error:(NSError **)error;
- (WAMessage *)messageWithMovieURL:(NSURL *)movieURL inChatSession:(WAChatSession *)chatSession copyFile:(BOOL)file error:(NSError **)error;
@end

@interface ChatManager : NSObject
@property(readonly, assign, nonatomic) WAContactsStorage *contactsStorage;
@property(readonly, assign, nonatomic) WAChatStorage *storage;
+ (ChatManager *)sharedManager;
@end

#pragma mark - Globals

static NSDictionary *userDefaults;
static WAContactsStorage *contactsStorage;
static WAChatStorage *chatStorage;

#pragma mark - Functions

static CFMessagePortRef remotePort()
{
    static CFMessagePortRef port;
    if (!(port != NULL && CFMessagePortIsValid(port))) {
        port = CFMessagePortCreateRemote(kCFAllocatorDefault, CFSTR(MailForCouriaIdentifier));
    }
    return port;
}

static BOOL appIsRunning()
{
    CFMessagePortRef port = remotePort();
    return port != NULL && CFMessagePortIsValid(port);
}

static void launchApp()
{
    static BKSProcessAssertion *processAssertion;
    if ([userDefaults[KeepAliveKey]boolValue] && !appIsRunning()) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
            [[UIApplication sharedApplication]launchApplicationWithIdentifier:MailIdentifier suspended:YES];
            processAssertion = [[BKSProcessAssertion alloc]initWithBundleIdentifier:MailIdentifier flags:(ProcessAssertionFlagPreventSuspend | ProcessAssertionFlagPreventThrottleDownCPU | ProcessAssertionFlagAllowIdleSleep) reason:kProcessAssertionReasonBackgroundUI name:@WhatsAppForCouriaIdentifier withHandler:NULL];
        });
    }
}

static int PIDForProcessNamed(NSString *passedInProcessName)
{
    int pid = 0;
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t miblen = 4;
    size_t size;
    int st = sysctl(mib, miblen, NULL, &size, NULL, 0);
    struct kinfo_proc * process = NULL;
    struct kinfo_proc * newprocess = NULL;
    do {
        size += size / 10;
        newprocess = (kinfo_proc *)realloc(process, size);
        if (!newprocess) {
            if (process) {
                free(process);
            }
            return 0;
        }
        process = newprocess;
        st = sysctl(mib, miblen, process, &size, NULL, 0);
    } while (st == -1 && errno == ENOMEM);
    if (st == 0) {
        if (size % sizeof(struct kinfo_proc) == 0) {
            int nprocess = size / sizeof(struct kinfo_proc);
            if (nprocess) {
                for (int i = nprocess - 1; i >= 0; i--) {
                    NSString * processName = [[NSString alloc] initWithFormat:@"%s", process[i].kp_proc.p_comm];
                    if ([processName rangeOfString:passedInProcessName].location != NSNotFound) {
                        pid = process[i].kp_proc.p_pid;
                    }
                }
                free(process);
            }
        }
    }
    return pid;
}

static void userDefaultsChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    userDefaults = [NSDictionary dictionaryWithContentsOfFile:UserDefaultsPlist];
    launchApp();
}

static void applicationDidExitCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    launchApp();
}

static CFDataRef messagePortCallback(CFMessagePortRef local, SInt32 messageId, CFDataRef data, void *info)
{
    CFDataRef returnData = NULL;
    switch (messageId) {
        case GetNickname: {
            NSString *userIdentifier = [[NSString alloc]initWithData:(__bridge NSData *)data encoding:NSUTF8StringEncoding];
            NSString *nickname = nil;
            if ([userIdentifier hasSuffix:@"@g.us"]) {
                nickname = [chatStorage existingChatSessionForJID:userIdentifier].partnerName;
            } else {
                nickname = [contactsStorage contactForJID:userIdentifier].fullName;
            }
            if (nickname == nil) {
                nickname = userIdentifier;
            }
            returnData = (__bridge_retained CFDataRef)[nickname dataUsingEncoding:NSUTF8StringEncoding];
            break;
        }
        case GetAvatar: {
            NSString *userIdentifier = [[NSString alloc]initWithData:(__bridge NSData *)data encoding:NSUTF8StringEncoding];
            UIImage *avatar = nil;
            if ([userIdentifier hasSuffix:@"@g.us"]) {
                avatar = [UIImage imageWithContentsOfFile:[[NSString stringWithFormat:@"~/Library/%@.thumb",[chatStorage existingChatSessionForJID:userIdentifier].groupInfo.picturePath]stringByExpandingTildeInPath]];
                if (avatar == nil) {
                    avatar = [UIImage imageNamed:@"GroupChat.png"];
                }
            } else {
                avatar = [contactsStorage profilePictureForJID:userIdentifier];
                if (avatar == nil) {
                    avatar = [UIImage imageNamed:@"EmptyContact.png"];
                }
            }
            returnData = (__bridge_retained CFDataRef)UIImagePNGRepresentation(avatar);
            break;
        }
        case GetMessages: {
            NSString *userIdentifier = [[NSString alloc]initWithData:(__bridge NSData *)data encoding:NSUTF8StringEncoding];
            NSArray *messages = [chatStorage messagesForSession:[chatStorage existingChatSessionForJID:userIdentifier] startOffset:0 limit:15];
            if (messages.count > 0) {
                NSMutableArray *whatsappMessages = [NSMutableArray array];
                for (WAMessage *message in messages) {
                    if (message.groupEventType.integerValue != 0) {
                        continue;
                    }
                    CouriaWhatsAppMessage *whatsappMessage = [[CouriaWhatsAppMessage alloc]init];
                    switch (message.messageType.integerValue) {
                        case TextMessage: {
                            whatsappMessage.text = message.text;
                            break;
                        }
                        case PhotoMessage: {
                            WAMediaItem *mediaItem = message.mediaItem;
                            if (mediaItem.mediaSaved.boolValue) {
                                whatsappMessage.text = @"";
                                whatsappMessage.media = [UIImage imageWithContentsOfFile:[[NSString stringWithFormat:@"~/Library/%@",mediaItem.mediaLocalPath]stringByExpandingTildeInPath]];
                            } else {
                                whatsappMessage.text = @"[Not Downloaded Photo]";
                            }
                            break;
                        }
                        case MovieMessage: {
                            WAMediaItem *mediaItem = message.mediaItem;
                            if (mediaItem.mediaSaved.boolValue) {
                                whatsappMessage.text = @"";
                                whatsappMessage.media = [NSURL fileURLWithPath:[[NSString stringWithFormat:@"~/Library/%@",mediaItem.mediaLocalPath]stringByExpandingTildeInPath]];
                            } else {
                                whatsappMessage.text = @"[Not Downloaded Movie]";
                            }
                            break;
                        }
                    }
                    if (message.groupMember != nil) {
                        whatsappMessage.text = [NSString stringWithFormat:@"%@: %@", message.groupMember.contactName, whatsappMessage.text];
                    }
                    whatsappMessage.outgoing = message.isFromMe.boolValue;
                    [whatsappMessages insertObject:whatsappMessage atIndex:0];
                }
                returnData = (__bridge_retained CFDataRef)[NSKeyedArchiver archivedDataWithRootObject:whatsappMessages];
            }
            break;
        }
        case GetContacts: {
            NSString *keyword = [[NSString alloc]initWithData:(__bridge NSData *)data encoding:NSUTF8StringEncoding];
            NSMutableArray *contacts = [NSMutableArray array];
            if (keyword.length == 0) {
                NSArray *chatSessions = [chatStorage chatSessionsWithBroadcast:NO];
                for (WAChatSession *chatSession in chatSessions) {
                    [contacts addObject:chatSession.contactJID];
                }
            } else {
                NSArray *favorites = contactsStorage.favorites;
                for (NSDictionary *favorite in favorites) {
                    WAPhone *phone = [contactsStorage phoneWithObjectID:favorite[@"objectID"]];
                    NSString *fullName = phone.contact.fullName;
                    NSString *whatsAppID = phone.whatsAppID;
                    if ([fullName rangeOfString:keyword options:NSCaseInsensitiveSearch].location != NSNotFound || [whatsAppID rangeOfString:keyword options:NSCaseInsensitiveSearch].location != NSNotFound) {
                        [contacts addObject:[NSString stringWithFormat:@"%@@s.whatsapp.net", whatsAppID]];
                    }
                }
            }
            returnData = (__bridge_retained CFDataRef)[NSKeyedArchiver archivedDataWithRootObject:contacts];
            break;
        }
        case SendMessage: {
            NSDictionary *messageDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)data];
            NSString *userIdentifier = messageDictionary[UserIDKey];
            CouriaWhatsAppMessage *message = messageDictionary[MessageKey];
            NSString *text = message.text;
            id media = message.media;
            WAChatSession *chatSession = [chatStorage existingChatSessionForJID:userIdentifier];
            if (chatSession == nil) {
                WAContact *contact = [contactsStorage contactForJID:userIdentifier];
                chatSession = [chatStorage createChatSessionForContact:contact JID:userIdentifier];
            }
            if (text.length > 0) {
                [chatStorage messageWithText:text inChatSession:chatSession isBroadcast:NO];
            }
            if (media != nil) {
                if ([media isKindOfClass:UIImage.class]) {
                    [chatStorage messageWithImage:media inChatSession:chatSession error:nil];
                } else if ([media isKindOfClass:NSURL.class]) {
                    [chatStorage messageWithMovieURL:media inChatSession:chatSession copyFile:YES error:nil];
                }
            }
            break;
        }
        case MarkRead: {
            NSString *userIdentifier = [[NSString alloc]initWithData:(__bridge NSData *)data encoding:NSUTF8StringEncoding];
            WAChatSession *chatSession = [chatStorage existingChatSessionForJID:userIdentifier];
            chatSession.unreadCount = @(0);
            [chatStorage storeModifiedChatSession:chatSession];
            break;
        }
    }
    return returnData;
}

#pragma mark - Implementations

@implementation CouriaWhatsAppMessage

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    if (self) {
        _text = [aDecoder decodeObjectOfClass:NSString.class forKey:@"Text"];
        _outgoing = [[aDecoder decodeObjectOfClass:NSNumber.class forKey:@"Outgoing"]boolValue];
        _media = [aDecoder decodeObjectOfClasses:[NSSet setWithObjects:UIImage.class, NSURL.class, nil] forKey:@"Media"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_text forKey:@"Text"];
    [aCoder encodeObject:@(_outgoing) forKey:@"Outgoing"];
    if ([_media isKindOfClass:UIImage.class] || [_media isKindOfClass:NSURL.class]) {
        [aCoder encodeObject:_media forKey:@"Media"];
    }
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

@end

@implementation CouriaWhatsAppDataSource

- (NSString *)getUserIdentifier:(BBBulletin *)bulletin
{
//    if (!appIsRunning()) {
//        return nil;
//    }
//    NSString *notificationType = bulletin.context[@"notificationType"];
//    NSDictionary *userInfo = bulletin.context[@"userInfo"];
//    NSString *userIdentifier = nil;
//    if ([notificationType isEqualToString:@"AppNotificationLocal"]) {
//        userIdentifier = userInfo[@"jid"];
//    } else if ([notificationType isEqualToString:@"AppNotificationRemote"]) {
//        NSString *u = userInfo[@"aps"][@"u"];
//        if ([u rangeOfString:@"-"].location == NSNotFound) {
//            userIdentifier = [NSString stringWithFormat:@"%@@s.whatsapp.net", u];
//        } else {
//            userIdentifier = [NSString stringWithFormat:@"%@@g.us", u];
//        }
//    }
    
    NSString *userIdentifier = nil;
    return userIdentifier;
}

- (NSString *)getNickname:(NSString *)userIdentifier
{
//    if (!appIsRunning()) {
//        return nil;
//    }
//    CFDataRef data = (__bridge CFDataRef)[userIdentifier dataUsingEncoding:NSUTF8StringEncoding];
//    CFDataRef returnData = NULL;
//    CFMessagePortSendRequest(remotePort(), GetNickname, data, 30, 30, kCFRunLoopDefaultMode, &returnData);
//    NSString *nickname = [[NSString alloc]initWithData:(__bridge NSData *)returnData encoding:NSUTF8StringEncoding]
    
    NSString *nickname = nil;
    return nickname;
}

- (UIImage *)getAvatar:(NSString *)userIdentifier
{
//    if (!appIsRunning()) {
//        return nil;
//    }
//    CFDataRef data = (__bridge CFDataRef)[userIdentifier dataUsingEncoding:NSUTF8StringEncoding];
//    CFDataRef returnData = NULL;
//    CFMessagePortSendRequest(remotePort(), GetAvatar, data, 30, 30, kCFRunLoopDefaultMode, &returnData);
//    UIImage *avatar = [UIImage imageWithData:(__bridge NSData *)returnData];
    
    UIImage *avatar = nil;
    return avatar;
}

- (NSArray *)getMessages:(NSString *)userIdentifier
{
//    if (!appIsRunning()) {
//        return nil;
//    }
//    CFDataRef data = (__bridge CFDataRef)[userIdentifier dataUsingEncoding:NSUTF8StringEncoding];
//    CFDataRef returnData = NULL;
//    CFMessagePortSendRequest(remotePort(), GetMessages, data, 30, 30, kCFRunLoopDefaultMode, &returnData);
//    NSArray *messages = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)returnData];
//    
    NSArray *messages = nil;
    return messages;
}

- (NSArray *)getContacts:(NSString *)keyword
{
//    if (!appIsRunning()) {
//        return nil;
//    }
//    CFDataRef data = (__bridge CFDataRef)[keyword dataUsingEncoding:NSUTF8StringEncoding];
//    CFDataRef returnData = NULL;
//    CFMessagePortSendRequest(remotePort(), GetContacts, data, 30, 30, kCFRunLoopDefaultMode, &returnData);
//    NSArray *contacts = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)returnData];
//    
    NSArray *contacts = nil;
    return contacts;
}

@end

@implementation CouriaWhatsAppDelegate

- (void)sendMessage:(id<CouriaMessage>)message toUser:(NSString *)userIdentifier
{
//    if (!appIsRunning()) {
//        return;
//    }
//    CouriaWhatsAppMessage *whatsappMessage = [[CouriaWhatsAppMessage alloc]init];
//    whatsappMessage.text = message.text;
//    whatsappMessage.media = message.media;
//    whatsappMessage.outgoing = message.outgoing;
//    CFDataRef data = (__bridge CFDataRef)[NSKeyedArchiver archivedDataWithRootObject:@{UserIDKey: userIdentifier, MessageKey: whatsappMessage}];
//    CFMessagePortSendRequest(remotePort(), SendMessage, data, 30, 30, NULL, NULL);
}

- (void)markRead:(NSString *)userIdentifier
{
//    if (!appIsRunning()) {
//        return;
//    }
//    CFDataRef data = (__bridge CFDataRef)[userIdentifier dataUsingEncoding:NSUTF8StringEncoding];
//    CFMessagePortSendRequest(remotePort(), MarkRead, data, 30, 30, NULL, NULL);
}

- (BOOL)canSendPhoto
{
    return YES;
}

- (BOOL)canSendMovie
{
    return YES;
}

@end

#pragma mark - Service

@interface CouriaWhatsAppService : NSObject
@end

@implementation CouriaWhatsAppService

+ (void)start
{
    static CouriaWhatsAppService *service;
    static CFMessagePortRef localPort;
    if (service == nil) {
        service = [[CouriaWhatsAppService alloc]init];
        localPort = CFMessagePortCreateLocal(kCFAllocatorDefault, CFSTR(MailForCouriaIdentifier), messagePortCallback, NULL, NULL);
        CFRunLoopSourceRef source = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, localPort, 0);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
        ChatManager *chatManager = [NSClassFromString(@"ChatManager")sharedManager];
        contactsStorage = chatManager.contactsStorage;
        chatStorage = chatManager.storage;
    }
}

@end

#pragma mark - Hooks

static int (*original_XPConnectionHasEntitlement)(id connection, NSString *entitlement);
static int optimized_XPConnectionHasEntitlement(id connection, NSString *entitlement)
{
    if (xpc_connection_get_pid(connection) == PIDForProcessNamed(@"SpringBoard") && [entitlement isEqualToString:@"com.apple.multitasking.unlimitedassertions"]) {
        return 1;
    } else {
        return original_XPConnectionHasEntitlement(connection, entitlement);
    }
}

CHDeclareClass(BKWorkspaceServer)
CHOptimizedMethod(2, self, void, BKWorkspaceServer, applicationDidExit, BKApplication *, application, withInfo, id ,info)
{
    CHSuper(2, BKWorkspaceServer, applicationDidExit, application, withInfo, info);
    if ([application.bundleIdentifier isEqualToString:WhatsAppIdentifier]) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), ApplicationDidExitNotification, NULL, NULL, TRUE);
    }
}

#pragma mark - Constructor

CHConstructor
{
    @autoreleasepool {
        NSString *applicationIdentifier = [NSBundle mainBundle].bundleIdentifier;
        if ([applicationIdentifier isEqualToString:SpringBoardIdentifier]) {
            Couria *couria = [NSClassFromString(@"Couria") sharedInstance];
            [couria registerDataSource:[CouriaWhatsAppDataSource new] delegate:[CouriaWhatsAppDelegate new] forApplication:WhatsAppIdentifier];
            CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, userDefaultsChangedCallback, UserDefaultsChangedNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
            CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, applicationDidExitCallback, ApplicationDidExitNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), UserDefaultsChangedNotification, NULL, NULL, TRUE);
        } else if ([applicationIdentifier isEqualToString:BackBoardIdentifier]) {
            dlopen("/System/Library/PrivateFrameworks/XPCObjects.framework/XPCObjects", RTLD_LAZY);
            MSHookFunction(((int *)MSFindSymbol(NULL, "_XPCConnectionHasEntitlement")), (int *)optimized_XPConnectionHasEntitlement, (int **)&original_XPConnectionHasEntitlement);
            CHLoadLateClass(BKWorkspaceServer);
            CHHook(2, BKWorkspaceServer, applicationDidExit, withInfo);
        } else if ([applicationIdentifier isEqualToString:WhatsAppIdentifier]) {
            [CouriaWhatsAppService start];
        }
    }
}