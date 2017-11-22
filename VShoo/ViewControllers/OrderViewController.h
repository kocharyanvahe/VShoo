//
//  OrderViewController.h
//  VShoo
//
//  Created by Vahe Kocharyan on 9/8/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@protocol OrderViewControllerDelegate <NSObject>

@end

@interface OrderViewController : UIViewController

@property (weak, nonatomic) id<OrderViewControllerDelegate> delegate;
@property (assign, nonatomic) CGFloat contentWidth;
@property (assign, nonatomic) CGFloat contentHeight;
@property (copy, nonatomic) NSString *myAddress;
@property (assign, nonatomic) NSUInteger currentCarClassId;
@property (strong, nonatomic) UIImage *currentCarTypeImage;
@property (copy, nonatomic) NSString *currentCarClassName;
@property (assign, nonatomic) CLLocationDegrees lat;
@property (assign, nonatomic) CLLocationDegrees lng;
@property (copy, nonatomic) NSString *currentStartAddress;

@end
