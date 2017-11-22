//
//  Requests.h
//  VShoo
//
//  Created by Vahe Kocharyan on 6/17/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Requests : NSObject

+ (void)sendPostRequest:(NSString *)url andCallback:(void (^)(NSDictionary *))callBack andFailCallBack:(void (^)(NSError *))failedCallBack;
+ (void)sendPostRequest:(NSString *)url andCallback:(void (^)(NSDictionary *))callBack andFailCallBack:(void (^)(NSError *))failedCallBack withCompletionBlock:(void (^)(void))completion;
+ (void)sendPostRequest:(NSString *)url withParameters:(NSDictionary *)parameters andCallback:(void (^)(NSDictionary *))callBack andFailCallBack:(void (^)(NSError *))failedCallBack;
+ (void)downloadImage:(NSString *)urlStr andCallback:(void (^)(UIImage *))callBack andFailCallBack:(void (^)(NSError *))failedCallBack;

@end
