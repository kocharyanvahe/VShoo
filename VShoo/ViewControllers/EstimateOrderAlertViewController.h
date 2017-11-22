//
//  EstimateOrderAlertViewController.h
//  VShoo
//
//  Created by Vahe Kocharyan on 9/7/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EstimateOrderAlertViewControllerDelegate <NSObject>

@end

@interface EstimateOrderAlertViewController : UIViewController

@property (weak, nonatomic) id<EstimateOrderAlertViewControllerDelegate> delegate;
@property (assign, nonatomic) CGFloat contentWidth;
@property (assign, nonatomic) CGFloat contentHeight;
@property (copy, nonatomic) NSString *alertTitle;
@property (copy, nonatomic) NSString *alertBody;
@property (copy, nonatomic) NSString *locationAddress;

@end
