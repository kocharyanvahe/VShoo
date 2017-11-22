//
//  NSArray+Unique.m
//  VShoo
//
//  Created by Vahe Kocharyan on 11/30/15.
//  Copyright © 2015 ConnectTo. All rights reserved.
//

#import "NSArray+Unique.h"

@implementation NSArray (Unique)

- (NSArray *)arrayByDroppingDuplicates {
    NSMutableArray *tmp = [NSMutableArray array];
    for (id item in self)
        if (![tmp containsObject:item]) {
            [tmp addObject:item];
        }
    return [NSArray arrayWithArray:tmp];
}

@end
