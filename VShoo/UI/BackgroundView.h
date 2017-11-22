//
//  BackgroundView.h
//  VShoo
//
//  Created by Vahe Kocharyan on 9/9/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BackgroundView : UIView

@property (copy, nonatomic) NSString *pickedAddress;
@property (copy, nonatomic) NSString *carTypeName;
@property (strong, nonatomic) UIImage *carImage;

@end
