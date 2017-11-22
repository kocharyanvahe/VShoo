//
//  AppDelegate.m
//  VShoo
//
//  Created by Vahe Kocharyan on 6/17/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import "AppDelegate.h"
#import <GoogleMaps/GoogleMaps.h>
#import <GooglePlus/GooglePlus.h>
#import "AvatarViewController.h"
#import "SlideNavigationController.h"
#import "InitialWebViewController.h"
#import "Utils/Utils.h"
#import "Categories/NSUserDefaults+Settings.h"
#import "Requests.h"
#import "ViewControllers/ViewController.h"

@interface AppDelegate ()

@property (strong, nonatomic) UIStoryboard *storyboard;
@property (strong, nonatomic) NSUserDefaults *defaults;
@property (strong, nonatomic) InitialWebViewController *initialWebViewController;

@end

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [NSUserDefaults saveIncomingAvatarSetting:YES];
    [NSUserDefaults saveOutgoingAvatarSetting:YES];
    [self setupGoogleMaps];
    [self chooseViewController];
    [self setupAvatarMenu];
    return YES;
}

- (void)chooseViewController {
    _storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    _defaults = [NSUserDefaults standardUserDefaults];
    _tsmSessionId = [self.defaults objectForKey:@"tsmSessionId"];
    if (self.tsmSessionId) {
        [self registerPushNotificationService];
    } else {
        _initialWebViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"InitialWebViewController"];
        self.window.rootViewController = self.initialWebViewController;
        [self.window makeKeyAndVisible];
    }
}

#pragma mark -
#pragma mark Setup Avatar Menu

- (void)setupAvatarMenu {
    AvatarViewController *avatarViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AvatarViewController"];
    [[SlideNavigationController sharedInstance] setLeftMenu:avatarViewController];
    UIImage *userAvatarImage = [UIImage imageNamed:@"UserAvatar"];
    UIButton *avatarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [avatarButton setFrame:CGRectMake(0.0f, 0.0f, userAvatarImage.size.width, userAvatarImage.size.height)];
    [avatarButton setImage:userAvatarImage forState:UIControlStateNormal];
    [avatarButton addTarget:[SlideNavigationController sharedInstance] action:@selector(toggleLeftMenu) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:avatarButton];
    [SlideNavigationController sharedInstance].leftBarButtonItem = leftBarButtonItem;
}

#pragma mark -
#pragma mark Setup Google Maps

- (void)setupGoogleMaps {
    NSString *googleMapsApiKey = [Utils getFromPlistWithKey:@"GoogleMapsAPIKey"];
    [GMSServices provideAPIKey:googleMapsApiKey];
}

#pragma mark -
#pragma mark Push Notification Implementation

- (void)registerPushNotificationService {
    UIApplication *application = [UIApplication sharedApplication];
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    } else {
        [application registerForRemoteNotificationTypes:(UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound)];
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *deviceTokenString = [deviceToken description];
    deviceTokenString = [deviceTokenString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    deviceTokenString = [deviceTokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
    [defaults setObject:deviceTokenString forKey:@"device_token"];
    [defaults synchronize];
    if (self.tsmSessionId) {
        [self sendDeviceToken:deviceTokenString];
    } else {
        [self.initialWebViewController setDeviceTok:deviceTokenString];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceTokenNotification" object:deviceTokenString];
    }
}

- (void)sendDeviceToken:(NSString *)deviceToken {
    NSString *url = [Utils getFromPlistWithKey:@"SendDeviceData"];
    if (!deviceToken) {
        deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"device_token"];
    }
    NSLog(@"deviceToken :%@, sessionID :%@", deviceToken, self.tsmSessionId);
    NSDictionary *parameters = @{ @"deviceType": @"1", @"sessionId": self.tsmSessionId, @"deviceKey": deviceToken };
    [Requests sendPostRequest:url withParameters:parameters andCallback:^(NSDictionary *response) {
        NSString *result = [response valueForKey:@"result"];
        if ([result isEqualToString:@"OK"]) {
            //[[NSNotificationCenter defaultCenter] postNotificationName:@"CheckExistenceOfOrder" object:nil];
        }
    } andFailCallBack:^(NSError *error) {
        [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self.window.rootViewController];
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"userInfo :%@", userInfo);
    NSUInteger statusCode = [[userInfo valueForKey:@"statusCode"] unsignedIntegerValue];
    switch (statusCode) {
        case kDriverChat: {
            NSString *message = [userInfo valueForKeyPath:@"aps.alert"];
            NSArray *viewControllers = [[[[UIApplication sharedApplication] keyWindow] rootViewController] childViewControllers];
            if ([viewControllers count] > 1) {
                for (UIViewController *currentViewController in viewControllers) {
                    if ([currentViewController isKindOfClass:[MessagesViewController class]]) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReceivedMessage" object:message];
                    }
                }
            } else {
                if ([[viewControllers objectAtIndex:0] isKindOfClass:[ViewController class]]) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReceivedMessageFromMainViewController" object:message];
                }
            }
        }
        break;
        case kDriverCancel:
        case kDriverNotAccept:
        case kDriverAcceptedOrder:
        case kDriverAtLocation:
        case kDriverCustomerDidNotShow:
        case kDriverInProgress:
        case kDriverParking:
        case kDriverExtraStop:
        case kDriverTollRoad:
        case kDriverCompleteOrder:
        case kDriverHotZone:
        case kDriverSetDestination:
            [[NSNotificationCenter defaultCenter] postNotificationName:kDidReceiveRemoteNotification object:nil userInfo:userInfo];
        break;
        default:
            break;
    }
    /*
    UIApplicationState appState = [application applicationState];
    if (appState == UIApplicationStateInactive || appState == UIApplicationStateBackground) {
        NSLog(@"background");
    } else {
        NSLog(@"active");
    }*/
}

#pragma mark -
#pragma mark - Core Data stack

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.example.CoreDataExample" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"VShoo" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"VShoo.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark -
#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [GPPURLHandler handleURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
