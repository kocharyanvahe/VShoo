//
//  Utils.m
//  VShoo
//
//  Created by Vahe Kocharyan on 6/17/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import "Utils.h"
#import <sys/sysctl.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <netdb.h>
#import <sys/socket.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#include <sys/utsname.h>
#import "Reachability.h"

NSString *KKLocalizedString(NSString *key) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *appLanguage = [defaults objectForKey:@"language"];
    NSString *path = [[NSBundle mainBundle] pathForResource:appLanguage ofType:@"lproj"];
    NSBundle *languageBundle = [NSBundle bundleWithPath:path];
    NSString *str = [languageBundle localizedStringForKey:key value:@"" table:nil];
    return str;
}

@implementation Utils

+ (NSString *)getFromPlistWithKey:(NSString *)key {
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"URLs" ofType:@"plist"];
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSString *returnedValue = [plist valueForKey:key];
    return returnedValue;
}

+ (void)showSimpleAlertsWithTitle:(NSString *)title andMessage:(NSString *)message onFollowingViewController:(UIViewController *)viewController {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:KKLocalizedString(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [alertController dismissViewControllerAnimated:YES completion:nil];
        }];
        [alertController addAction:okAction];
        [viewController presentViewController:alertController animated:YES completion:nil];
    } else if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:KKLocalizedString(@"OK") otherButtonTitles:nil, nil];
        [alertView show];
    }
}

#pragma mark -
#pragma mark Platform detection

+ (NSString *)platform {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

+ (NSString *)platformString {
    NSString *platform = [self platform];
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4/4S";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"iPhone 4/4S";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4/4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5/5S/5C";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5/5S/5C";
    if ([platform isEqualToString:@"iPhone5,3"])    return @"iPhone 5/5S/5C";
    if ([platform isEqualToString:@"iPhone5,4"])    return @"iPhone 5/5S/5C";
    if ([platform isEqualToString:@"iPhone6,1"])    return @"iPhone 5/5S/5C";
    if ([platform isEqualToString:@"iPhone6,2"])    return @"iPhone 5/5S/5C";
    if ([platform isEqualToString:@"iPhone7,1"])    return @"iPhone 6";
    if ([platform isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([platform isEqualToString:@"iPhone8,1"])    return @"iPhone 6+";
    if ([platform isEqualToString:@"iPhone8,2"])    return @"iPhone 6+";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4";
    if ([platform isEqualToString:@"iPad4,1"])      return @"iPad Air";
    if ([platform isEqualToString:@"iPad4,2"])      return @"iPad Air";
    if ([platform isEqualToString:@"iPad4,4"])      return @"iPad Mini Retina";
    if ([platform isEqualToString:@"iPad4,5"])      return @"iPad Mini Retina";
    if ([platform isEqualToString:@"iPad5,4"])      return @"iPad Air 2";
    return platform;
}

#pragma mark -
#pragma mark Get IP Address

+ (NSString *)getIPAddress {
    NSString *address = NULL;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if (temp_addr -> ifa_addr -> sa_family == AF_INET) {
                address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr -> ifa_addr) -> sin_addr)];
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    return address;
}

#pragma mark -
#pragma mark Get Network Type

+ (NSString *)getNetworkType {
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    NetworkStatus internetStatus = [reach currentReachabilityStatus];
    switch (internetStatus) {
        case ReachableViaWWAN:
            return @"3G";
            break;
        case ReachableViaWiFi:
            return @"WiFi";
        default:
            break;
    }
    return nil;
}

#pragma mark -
#pragma mark Get Carrier Name

+ (NSString *)getCarrierName {
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    return [carrier carrierName];
}

#pragma mark -
#pragma mark Make a rounded image

+ (UIImage *)makeRoundedImage:(UIImage *)image radius:(CGFloat)radius {
    CALayer *imageLayer = [CALayer layer];
    [imageLayer setFrame:CGRectMake(0.0f, 0.0f, image.size.width, image.size.height)];
    [imageLayer setContents:(id _Nullable)[image CGImage]];
    [imageLayer setMasksToBounds:YES];
    [imageLayer setCornerRadius:radius];
    UIGraphicsBeginImageContext([image size]);
    [imageLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return roundedImage;
}

+ (UIImage *)imageWithRoundedCornersSize:(CGFloat)cornerRadius usingImage:(UIImage *)originalImage {
    CGRect frame = CGRectMake(0.0f, 0.0f, originalImage.size.width, originalImage.size.height);
    UIGraphicsBeginImageContextWithOptions(originalImage.size, NO, 1.0f);
    [[UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:cornerRadius] addClip];
    [originalImage drawInRect:frame];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)resizeImage:(UIImage *)originalImage scaledToSize:(CGSize)newSize {
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        if ([[UIScreen mainScreen] scale] == 2.0f) {
            UIGraphicsBeginImageContextWithOptions(newSize, YES, 2.0f);
        } else {
            UIGraphicsBeginImageContext(newSize);
        }
    } else {
        UIGraphicsBeginImageContext(newSize);
    }
    [originalImage drawInRect:CGRectMake(0.0f, 0.0f, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)newSize {
    float width = newSize.width;
    float height = newSize.height;
    UIGraphicsBeginImageContext(newSize);
    CGRect rect = CGRectMake(0.0f, 0.0f, width, height);
    float widthRatio = image.size.width / width;
    float heightRatio = image.size.height / height;
    float divisor = widthRatio > heightRatio ? widthRatio : heightRatio;
    width = image.size.width / divisor;
    height = image.size.height / divisor;
    rect.size.width  = width;
    rect.size.height = height;
    float offset = (width - height) / 2.0f;
    if (offset > 0.0f) {
        rect.origin.y = offset;
    } else {
        rect.origin.x = -offset;
    }
    [image drawInRect:rect];
    UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return smallImage;
}

@end
