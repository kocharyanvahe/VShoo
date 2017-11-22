//
//  ViewController.h
//  VShoo
//
//  Created by Vahe Kocharyan on 6/17/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessagesViewController.h"

@interface ViewController : UIViewController <MessagesViewControllerDelegate>

@property (copy, nonatomic) NSString *selectedLanguage;
@property (assign, nonatomic) BOOL isOrdered;
@property (assign, nonatomic) CLLocationCoordinate2D startLocation;
@property (assign, nonatomic) BOOL showPopupView;

- (void)messageAction;

@end
