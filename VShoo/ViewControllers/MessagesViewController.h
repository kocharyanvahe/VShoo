//
//  MessagesViewController.h
//  VShoo
//
//  Created by Vahe Kocharyan on 7/2/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import "JSQMessagesViewController.h"
#import "JSQMessages.h"
#import "MessagesModelData.h"
#import "NSUserDefaults+Settings.h"

@class MessagesViewController;

@protocol MessagesViewControllerDelegate <NSObject>

- (void)didDismissMessagesViewController:(MessagesViewController *)vc;

@end

@interface MessagesViewController : JSQMessagesViewController <UIActionSheetDelegate>

@property (weak, nonatomic) id<MessagesViewControllerDelegate> delegateModal;
@property (strong, nonatomic) MessagesModelData *messagesModelData;
@property (strong, nonatomic) UIImage *userImage;
@property (strong, nonatomic) UIImage *driverImage;
@property (copy, nonatomic) NSString *driverName;

- (void)createMessageWithText:(NSString *)msg;

@end
