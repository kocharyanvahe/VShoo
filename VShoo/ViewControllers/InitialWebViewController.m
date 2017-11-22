//
//  InitialWebViewController.m
//

//
//  Created by Vahe Kocharyan on 7/10/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import "InitialWebViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "AFHTTPRequestOperationManager.h"
#import "AvatarViewController.h"
#import "SlideNavigationController.h"
#import "Utils.h"
#import "Requests.h"
#import "Reachability.h"
#import "AppDelegate.h"
#import "ASIFormDataRequest.h"

@interface InitialWebViewController () <UIWebViewDelegate, CLLocationManagerDelegate, ASIHTTPRequestDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (assign, nonatomic) CLLocationCoordinate2D currentLocation;
@property (copy, nonatomic) NSString *imei;
@property (strong, nonatomic) NSUserDefaults *defaults;
@property (strong, nonatomic) AppDelegate *appDelegate;


@property (copy, nonatomic) NSString *startWebViewURLString;

@end

@implementation InitialWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _appDelegate = [[UIApplication sharedApplication] delegate];
    [self.appDelegate registerPushNotificationService];
    _imei = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getDeviceToken:) name:@"DeviceTokenNotification" object:nil];
    _defaults = [NSUserDefaults standardUserDefaults];
    
    
    NSString *tmpSession = [self.defaults valueForKey:@"tsmSessionId"];
    if (tmpSession == nil || [tmpSession isEqualToString:@""]) {
        [self openVShooSignUpPage];
    }
}

#pragma mark -
#pragma mark Get Device Token

- (void)getDeviceToken:(NSNotification *)notification {
    //_deviceTok = [notification object];
    _deviceTok = [self.defaults objectForKey:@"device_token"];
    [self initLocationManager];
}

#pragma mark -
#pragma mark Init Location Manager

- (void)initLocationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    [_locationManager setDelegate:self];
    [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    } else {
        [self.locationManager startUpdatingLocation];
    }
    [self.locationManager startUpdatingLocation];
}

#pragma mark -
#pragma mark Location Manager delegate methods

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)location {
    CLLocation *startLocation = [location firstObject];
    _currentLocation = [startLocation coordinate];
    _locationManager.delegate = nil;
    [self.locationManager stopUpdatingLocation];
    [self startDeviceRequest];
}

#pragma mark -
#pragma mark Start Device Request

- (void)startDeviceRequest {
    BOOL initiallySent = [self.defaults boolForKey:@"initiallySentData"];
    if (!initiallySent) {
        NSString *networkType = [Utils getNetworkType];
        NSString *carrierName = [Utils getCarrierName];
        NSString *ipAddress = [Utils getIPAddress];
        NSString *currentDevice = [Utils platformString];
        NSTimeZone *timeZoneLocal = [NSTimeZone localTimeZone];
        NSString *timeZoneName = [timeZoneLocal name];
        CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
        CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
        CLLocationDegrees latitude = self.currentLocation.latitude;
        CLLocationDegrees longitude = self.currentLocation.longitude;
        NSLocale *locale = [NSLocale currentLocale];
        NSString *countryCode = [locale objectForKey:NSLocaleCountryCode];
        NSString *url = [Utils getFromPlistWithKey:@"StartDeviceAPK"];
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:url]];
        [request setDelegate:self];
        [request setRequestMethod:@"POST"];
        [request addPostValue:[NSNumber numberWithDouble:latitude] forKey:@"latitude"];
        [request addPostValue:[NSNumber numberWithDouble:longitude] forKey:@"longitude"];
        [request addPostValue:timeZoneName forKey:@"timeZone"];
        [request addPostValue:[NSNumber numberWithDouble:screenWidth] forKey:@"screenWidth"];
        [request addPostValue:[NSNumber numberWithDouble:screenHeight] forKey:@"screenHeight"];
        [request addPostValue:ipAddress forKey:@"ipV4"];
        [request addPostValue:self.imei forKey:@"imei"];
        [request addPostValue:networkType forKey:@"networkType"];
        [request addPostValue:carrierName forKey:@"networkOperatorName"];
        [request addPostValue:countryCode forKey:@"networkCountryISO"];
        [request addPostValue:@"Apple, Inc." forKey:@"deviceManufacturer"];
        [request addPostValue:currentDevice forKey:@"deviceModel"];
        [request addPostValue:@"(NULL)" forKey:@"imsi"];
        [request addPostValue:@"(NULL)" forKey:@"wlan0"];
        [request addPostValue:@"(NULL)" forKey:@"eth0"];
        [request addPostValue:@"(NULL)" forKey:@"dSTSavings"];
        [request addPostValue:@"(NULL)" forKey:@"ipV6"];
        [request startAsynchronous];
    } else {
        [self openVShooSignUpPage];
    }
}

- (void)requestFinished:(ASIHTTPRequest *)request {
    NSData *responseData = [request responseData];
    NSError *parserError = nil;
    NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&parserError];
    NSLog(@"JSON :%@", jsonResponse);
    if (jsonResponse) {
        NSString *status = [jsonResponse valueForKeyPath:@"responseDto.status"];
        if ([status isEqualToString:@"SUCCESS"]) {
            [self.defaults setBool:YES forKey:@"initiallySentData"];
            [self.defaults synchronize];
            [self openVShooSignUpPage];
        }
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    NSLog(@"ERROR :%@", [request error]);
    [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[[request error] localizedDescription] onFollowingViewController:self];
}

#pragma mark -
#pragma mark Open VShoo Sign Up page

- (void)openVShooSignUpPage {
    NSString *loginURL = nil;
    NSString *startWebViewUrl = [self.defaults objectForKey:@"startWebViewUrl"];
    if (!startWebViewUrl) {
        NSString *vshooSignUpPage = [Utils getFromPlistWithKey:@"VShooDomain"];
        NSString *availablePartitionURL = [Utils getFromPlistWithKey:@"AvailablePartitionURL"];
        loginURL = [NSString stringWithFormat:@"%@%@", vshooSignUpPage, availablePartitionURL];
    }
    else {
        NSString *customStartURL = [Utils getFromPlistWithKey:@"CustomStartURL"];
        loginURL = [NSString stringWithFormat:@"%@%@", startWebViewUrl, customStartURL];
    }
    
    NSURL *url = [NSURL URLWithString:loginURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:self.imei forHTTPHeaderField:@"imei"];
    [self.webView loadRequest:request];
}

#pragma mark -
#pragma mark WebView delegate methods

//- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
//    NSString *absoluteUrl = [[request URL] absoluteString];
//    NSLog(@"absolute :%@", absoluteUrl);
//    NSString *chosenUrl = [self.defaults objectForKey:@"chosenURL"];
//    if (!chosenUrl) {
//        if ([absoluteUrl rangeOfString:@"?url"].location != NSNotFound) {
//            NSRange range = [absoluteUrl rangeOfString:@"="];
//            NSString *nextUrl = [absoluteUrl substringFromIndex:range.location + 1];
//            [self.defaults setObject:nextUrl forKey:@"chosenURL"];
//            [self.defaults synchronize];
//            NSString *customStartURL = [Utils getFromPlistWithKey:@"CustomStartURL"];
//            NSString *urlStr = [NSString stringWithFormat:@"%@%@", nextUrl, customStartURL];
//            NSURL *url = [NSURL URLWithString:urlStr];
//            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//            [request addValue:self.imei forHTTPHeaderField:@"imei"];
//            [webView loadRequest:request];
//            NSLog(@"aaa :%@", url);
//        }
//    } else {
//        if ([absoluteUrl rangeOfString:@"jsp"].location != NSNotFound) {
//            
//            NSRange range = [absoluteUrl rangeOfString:@"?"];
//            NSString *initialSessionId = [absoluteUrl substringFromIndex:range.location + 1];
//            NSString *chosenUrl = [self.defaults objectForKey:@"chosenURL"];
//            NSString *sessionIdUrl = [Utils getFromPlistWithKey:@"GetSessionId"];
//            NSString *url = [NSString stringWithFormat:@"%@%@", chosenUrl, sessionIdUrl];
//            NSLog(@"URLLLLL :%@", url);
//            AFHTTPRequestOperationManager *operationManager = [AFHTTPRequestOperationManager manager];
//            [operationManager.requestSerializer setValue:initialSessionId forHTTPHeaderField:@"tsmSessionId"];
//            [operationManager POST:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//                NSDictionary *json = (NSDictionary *)responseObject;
//                NSLog(@"RES :%@", json);
//                NSString *status = [json valueForKeyPath:@"responseDto.status"];
//                if ([status isEqualToString:@"SUCCESS"]) {
//                    NSString *tsmSessionId = [json valueForKeyPath:@"sessionUser.tsmSessionId"];
//                    NSString *language = [json valueForKeyPath:@"sessionUser.language"];
//                    NSString *userAvatarImageUrl = [NSString stringWithFormat:@"https://www.vshoo.com/%@", [json valueForKeyPath:@"sessionUser.user_avatar_image_url"]];
//                    NSString *name = [NSString stringWithFormat:@"%@ %@", [json valueForKeyPath:@"sessionUser.name"], [json valueForKeyPath:@"sessionUser.lastname"]];
//                    NSLog(@"user_avatar_image_url :%@", userAvatarImageUrl);
//                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
//                        [self.defaults setObject:tsmSessionId forKey:@"tsmSessionId"];
//                        [self.defaults setObject:language forKey:@"language"];
//                        [self.defaults setObject:userAvatarImageUrl forKey:@"userAvatarUrl"];
//                        [self.defaults setObject:name forKey:@"user_name"];
//                        [self.defaults synchronize];
//                        [self.appDelegate setTsmSessionId:tsmSessionId];
//                        [self.appDelegate sendDeviceToken:self.deviceTok];
//                        dispatch_async(dispatch_get_main_queue(), ^{
//                            [self.appDelegate.window setRootViewController:[SlideNavigationController sharedInstance]];
//                        });
//                    });
//                } else if ([status isEqualToString:@"INTERNAL_ERROR"]) {
//                    NSString *errorMessage = [[json valueForKeyPath:@"responseDto.messages"] objectAtIndex:0];
//                    NSLog(@"errorMessage :%@", errorMessage);
//                    [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:errorMessage onFollowingViewController:self];
//                }
//            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//                NSLog(@"ERRORRRR :%@", error);
//                [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self];
//            }];
//        }
//    }
//    return YES;
//}



- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *absoluteUrl = [[request URL] absoluteString];
    NSLog(@"absolute :%@", absoluteUrl);
    if ([absoluteUrl rangeOfString:@"?url="].location != NSNotFound) {
        NSRange range = [absoluteUrl rangeOfString:@"="];
        NSString *nextUrl = [absoluteUrl substringFromIndex:range.location + 1];
        self.startWebViewURLString = nextUrl;
        
        NSString *customStartURL = [Utils getFromPlistWithKey:@"CustomStartURL"];
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", nextUrl, customStartURL];
        NSURL *url = [NSURL URLWithString:urlStr];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request addValue:self.imei forHTTPHeaderField:@"imei"];
        [webView loadRequest:request];
    }
    
    if ([absoluteUrl rangeOfString:@"jsp"].location != NSNotFound) {
        
        [self.defaults setObject:self.startWebViewURLString forKey:@"startWebViewUrl"];
        [self.defaults synchronize];
        
        NSRange range = [absoluteUrl rangeOfString:@"?"];
        NSString *initialSessionId = [absoluteUrl substringFromIndex:range.location + 1];
        NSString *url = @"https://www.vshoo.com/session_login_account.htm";
        NSLog(@"URLLLLL :%@", url);
        AFHTTPRequestOperationManager *operationManager = [AFHTTPRequestOperationManager manager];
        [operationManager.requestSerializer setValue:initialSessionId forHTTPHeaderField:@"tsmSessionId"];
        [operationManager POST:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSDictionary *json = (NSDictionary *)responseObject;
            NSLog(@"RES :%@", json);
            NSString *status = [json valueForKeyPath:@"responseDto.status"];
            if ([status isEqualToString:@"SUCCESS"]) {
                NSString *tsmSessionId = [json valueForKeyPath:@"sessionUser.tsmSessionId"];
                NSString *language = [json valueForKeyPath:@"sessionUser.language"];
                NSString *userAvatarImageUrl = [NSString stringWithFormat:@"https://www.vshoo.com/%@", [json valueForKeyPath:@"sessionUser.user_avatar_image_url"]];
                NSString *name = [NSString stringWithFormat:@"%@ %@", [json valueForKeyPath:@"sessionUser.name"], [json valueForKeyPath:@"sessionUser.lastname"]];
                NSLog(@"user_avatar_image_url :%@", userAvatarImageUrl);
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
                    [self.defaults setObject:tsmSessionId forKey:@"tsmSessionId"];
                    [self.defaults setObject:language forKey:@"language"];
                    [self.defaults setObject:userAvatarImageUrl forKey:@"userAvatarUrl"];
                    [self.defaults setObject:name forKey:@"user_name"];
                    [self.defaults synchronize];
                    [self.appDelegate setTsmSessionId:tsmSessionId];
                    [self.appDelegate sendDeviceToken:self.deviceTok];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.appDelegate.window setRootViewController:[SlideNavigationController sharedInstance]];
                    });
                });
            } else if ([status isEqualToString:@"INTERNAL_ERROR"]) {
                NSString *errorMessage = [[json valueForKeyPath:@"responseDto.messages"] objectAtIndex:0];
                NSLog(@"errorMessage :%@", errorMessage);
                [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:errorMessage onFollowingViewController:self];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"ERRORRRR :%@", error);
            [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self];
        }];
    }
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
