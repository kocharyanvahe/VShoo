//
//  AppDelegate.h
//  VShoo
//
//  Created by Vahe Kocharyan on 6/17/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) UIWindow *window;
@property (copy, nonatomic) NSString *tsmSessionId;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (void)registerPushNotificationService;
- (void)setupAvatarMenu;
- (void)sendDeviceToken:(NSString *)deviceToken;

@end
