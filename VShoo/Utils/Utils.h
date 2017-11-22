//
//  Utils.h
//  VShoo
//
//  Created by Vahe Kocharyan on 6/17/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NSString *KKLocalizedString(NSString *key);

@interface Utils : NSObject

+ (NSString *)getFromPlistWithKey:(NSString *)key;
+ (void)showSimpleAlertsWithTitle:(NSString *)title andMessage:(NSString *)message onFollowingViewController:(UIViewController *)viewController;
+ (NSString *)platformString;
+ (NSString *)getIPAddress;
+ (NSString *)getNetworkType;
+ (NSString *)getCarrierName;
+ (UIImage *)makeRoundedImage:(UIImage *)image radius:(CGFloat)radius;
+ (UIImage *)imageWithRoundedCornersSize:(CGFloat)cornerRadius usingImage:(UIImage *)originalImage;
+ (UIImage *)resizeImage:(UIImage *)originalImage scaledToSize:(CGSize)newSize;
+ (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)newSize;

@end
