//
//  CarClasses.h
//  VShoo
//
//  Created by Vahe Kocharyan on 11/12/15.
//  Copyright © 2015 ConnectTo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CarClasses : NSObject

@property (assign, nonatomic) NSUInteger classId;
@property (strong, nonatomic) UIImage *classImage;
@property (copy, nonatomic) NSString *className;

@end
