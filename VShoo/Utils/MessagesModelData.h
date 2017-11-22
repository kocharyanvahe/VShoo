//
//  MessagesModelData.h
//  VShoo
//
//  Created by Vahe Kocharyan on 7/2/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "JSQMessages.h"

//static NSString * const kJSQDemoAvatarDisplayNameSquires = @"Jesse Squires";
//static NSString * const kJSQDemoAvatarDisplayNameCook = @"Tim Cook";
//static NSString * const kJSQDemoAvatarDisplayNameJobs = @"Jobs";
//static NSString * const kJSQDemoAvatarDisplayNameWoz = @"Steve Wozniak";

//static NSString * const kJSQDemoAvatarIdSquires = @"053496-4509-289";
//static NSString * const kJSQDemoAvatarIdCook = @"468-768355-23123";
//static NSString * const kJSQDemoAvatarIdJobs = @"707-8956784-57";
//static NSString * const kJSQDemoAvatarIdWoz = @"309-41802-93823";

static NSString * const kJSQDemoUserId = @"me";
static NSString * const kJSQDemoDriverId = @"driver";

@interface MessagesModelData : NSObject

- (void)addPhotoMediaMessage;
- (void)addLocationMediaMessageCompletion:(JSQLocationMediaItemCompletionBlock)completion;
- (void)addVideoMediaMessage;
- (void)loadInitialStaff;

@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSDictionary *avatars;
@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;
@property (strong, nonatomic) NSDictionary *users;
@property (strong, nonatomic) UIImage *userImage;
@property (strong, nonatomic) UIImage *driverImage;

@end
