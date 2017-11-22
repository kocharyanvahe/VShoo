//
//  Requests.m
//  VShoo
//
//  Created by Vahe Kocharyan on 6/17/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import "Requests.h"
#import "AFHTTPRequestOperationManager.h"

@implementation Requests

+ (void)sendPostRequest:(NSString *)url andCallback:(void (^)(NSDictionary *))callBack andFailCallBack:(void (^)(NSError *))failedCallBack {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *json = (NSDictionary *)responseObject;
        callBack(json);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failedCallBack(error);
    }];
}

+ (void)sendPostRequest:(NSString *)url andCallback:(void (^)(NSDictionary *))callBack andFailCallBack:(void (^)(NSError *))failedCallBack withCompletionBlock:(void (^)(void))completion {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *json = (NSDictionary *)responseObject;
        callBack(json);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failedCallBack(error);
    }];
}

+ (void)sendPostRequest:(NSString *)url withParameters:(NSDictionary *)parameters andCallback:(void (^)(NSDictionary *))callBack andFailCallBack:(void (^)(NSError *))failedCallBack {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.securityPolicy.allowInvalidCertificates = NO;
    AFJSONRequestSerializer *serializerRequest = [AFJSONRequestSerializer serializer];
    [serializerRequest setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    AFJSONResponseSerializer *serializerResponse = [AFJSONResponseSerializer serializer];
    serializerResponse.readingOptions = NSJSONReadingAllowFragments;
    serializerResponse.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    manager.requestSerializer = serializerRequest;
    manager.responseSerializer = serializerResponse;
    [manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *json = (NSDictionary *)responseObject;
        callBack(json);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failedCallBack(error);
    }];
}

+ (void)downloadImage:(NSString *)urlStr andCallback:(void (^)(UIImage *))callBack andFailCallBack:(void (^)(NSError *))failedCallBack {
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [requestOperation setResponseSerializer:[AFImageResponseSerializer serializer]];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (responseObject) {
            UIImage *image = (UIImage *)responseObject;
            callBack(image);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failedCallBack(error);
    }];
    [requestOperation start];
}

@end
