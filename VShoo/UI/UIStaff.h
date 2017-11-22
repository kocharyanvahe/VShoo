//
//  UIStaff.h
//  VShoo
//
//  Created by Vahe Kocharyan on 6/18/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIStaff : NSObject

+ (void)setupVShooLogoInNavItem:(UINavigationItem *)navItem;
+ (void)setupPickupLocationViewSettings:(UISearchBar *)searchBar onView:(UIView *)superView;
+ (void)setImage:(UIImage *)image onTextField:(UITextField *)textField;
+ (void)putCursorOnFrontIn:(UISearchBar *)searchBar;
+ (void)putCursorToFrontIn:(UITextField *)textField;

@end
