//
//  mfcAppDelegate.h
//  MailForCouria
//
//  Created by Zachary Gorak on 8/5/13.
//  Copyright (c) 2013 Zachary Gorak. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface mfcAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
