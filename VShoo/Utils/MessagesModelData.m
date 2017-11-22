//
//  MessagesModelData.m
//  VShoo
//
//  Created by Vahe Kocharyan on 7/2/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import "MessagesModelData.h"
#import "NSUserDefaults+Settings.h"
#import <CoreData/CoreData.h>
#import "Messages.h"
#import "AppDelegate.h"

@interface MessagesModelData ()

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation MessagesModelData

- (instancetype)init {
    if (self = [super init]) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        _managedObjectContext = [appDelegate managedObjectContext];
        NSEntityDescription *messagesEntity = [NSEntityDescription entityForName:@"Messages" inManagedObjectContext:self.managedObjectContext];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:messagesEntity];
        NSError *error = nil;
        NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
        if (!error) {
            if ([results count] == 0) {
                _messages = [NSMutableArray array];
            } else {
                NSArray *encodedObjs = [NSArray array];
                for (NSUInteger i = 0; i < [results count]; ++i) {
                    encodedObjs = [NSKeyedUnarchiver unarchiveObjectWithData:[[results objectAtIndex:i] messages]];
                }
                _messages = [NSMutableArray arrayWithArray:encodedObjs];
            }
        }
    }
    return self;
}

- (void)loadInitialStaff {
    JSQMessagesAvatarImage *userImg = [JSQMessagesAvatarImageFactory avatarImageWithImage:self.userImage diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
    JSQMessagesAvatarImage *driverImg = [JSQMessagesAvatarImageFactory avatarImageWithImage:self.driverImage diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
    _avatars = @{ kJSQDemoUserId: userImg, kJSQDemoDriverId: driverImg };
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
}

- (void)addPhotoMediaMessage {
    JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:[UIImage imageNamed:@"goldengate"]];
    JSQMessage *photoMessage = [JSQMessage messageWithSenderId:kJSQDemoUserId displayName:@"aaa" media:photoItem];
    [self.messages addObject:photoMessage];
}

- (void)addLocationMediaMessageCompletion:(JSQLocationMediaItemCompletionBlock)completion {
    CLLocation *ferryBuildingInSF = [[CLLocation alloc] initWithLatitude:37.795313f longitude:-122.393757f];
    JSQLocationMediaItem *locationItem = [[JSQLocationMediaItem alloc] init];
    [locationItem setLocation:ferryBuildingInSF withCompletionHandler:completion];
    JSQMessage *locationMessage = [JSQMessage messageWithSenderId:kJSQDemoUserId displayName:@"bbb" media:locationItem];
    [self.messages addObject:locationMessage];
}

- (void)addVideoMediaMessage {
    NSURL *videoURL = [NSURL URLWithString:@"file://"];
    JSQVideoMediaItem *videoItem = [[JSQVideoMediaItem alloc] initWithFileURL:videoURL isReadyToPlay:YES];
    JSQMessage *videoMessage = [JSQMessage messageWithSenderId:kJSQDemoUserId displayName:@"ccc" media:videoItem];
    [self.messages addObject:videoMessage];
}

@end
