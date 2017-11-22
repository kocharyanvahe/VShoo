//
//  ViewController.m
//  VShoo
//
//  Created by Vahe Kocharyan on 6/17/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <GoogleMaps/GoogleMaps.h>
#import <QuartzCore/QuartzCore.h>
#import "Reachability.h"
#import "Utils.h"
#import "UIStaff.h"
#import "PopupView.h"
#import "SliderSegmentedControl.h"
#import "SlideNavigationController.h"
#import "UIViewController+PopinView.h"
#import "EstimationViewController.h"
#import "EstimateOrderAlertViewController.h"
#import "OrderViewController.h"
#import "Requests.h"
#import "UIImage+Resize.h"
#import "UIImage+RoundedCorner.h"
#import "iCarousel.h"
#import "SCLAlertView.h"
#import "CarClasses.h"
#import "RateViewController.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "NSArray+Unique.h"
#import "InitialWebViewController.h"

@interface ViewController () <CLLocationManagerDelegate, GMSMapViewDelegate, SliderSegmentedControlDelegate, EstimateOrderAlertViewControllerDelegate, OrderViewControllerDelegate, UIAlertViewDelegate, iCarouselDataSource, iCarouselDelegate>

@property (strong, nonatomic) UISearchBar *pickupLocationBar;
@property (strong, nonatomic) Reachability *internetReachable;
@property (assign, nonatomic) BOOL isInternetReachable;
@property (strong, nonatomic) GMSMapView *mapView;
@property (strong, nonatomic) GMSCameraPosition *camera;
@property (strong, nonatomic) GMSMarker *pointMarker;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (assign, nonatomic) CLLocationCoordinate2D currentLocation;
@property (strong, nonatomic) UIView *vehicleSliderView;
@property (strong, nonatomic) NSArray *sliderVehicleImages;
@property (strong, nonatomic) UILabel *economyCarLabel;
@property (strong, nonatomic) UILabel *sedanCarLabel;
@property (strong, nonatomic) UILabel *limousineCarLabel;
@property (strong, nonatomic) UILabel *pickupCarLabel;
@property (strong, nonatomic) UILabel *suvCarLabel;
@property (copy, nonatomic) NSString *address;
@property (strong, nonatomic) UIStoryboard *mainStoryboard;
@property (assign, nonatomic) CLLocationCoordinate2D carPickupLocation;
@property (strong, nonatomic) UIImageView *bottomAvatarImageView;
@property (strong, nonatomic) UIImage *driverPic;
@property (strong, nonatomic) UIImage *vehiclePic;
@property (assign, nonatomic) BOOL isVehicleViewPopup;
@property (assign, nonatomic) BOOL isRotated;
@property (strong, nonatomic) UIButton *messageButton;
@property (copy, nonatomic) NSString *driverName;
@property (copy, nonatomic) NSString *driverPhoneNumber;
@property (assign, nonatomic) CGFloat startLat;
@property (assign, nonatomic) CGFloat startLong;
@property (strong, nonatomic) iCarousel *carouselView;
@property (strong, nonatomic) NSMutableArray *bottomCars;
@property (assign, nonatomic) NSUInteger currentClassId;
@property (assign, nonatomic) BOOL isAlreadyReceivedDriverInfo;
@property (strong, nonatomic) NSMutableArray *carsToDraw;
@property (assign, nonatomic) NSUInteger idleLoadedCounter;
@property (strong, nonatomic) UIImage *userImage;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) GMSMarker *carMarker;
@property (assign, nonatomic) BOOL isDriverOrdered;

@property (strong, nonatomic) EstimateOrderAlertViewController *estimateOrderAlertView;
@property (strong, nonatomic) EstimationViewController *estimationViewController;

@end

@implementation ViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self initPickupLocationBar];
        [self initMyLocationButton];
    });
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{ NSForegroundColorAttributeName: [UIColor blackColor] }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [UIStaff setupVShooLogoInNavItem:self.navigationItem];
    [self initInternetReachabilityNotification];
    [self initGoogleMapsView];
    [self initLocationManager];
    [self initBottomView];
    _isVehicleViewPopup = NO;
    _isRotated = NO;
    _showPopupView = NO;
    _isAlreadyReceivedDriverInfo = NO;
    _isDriverOrdered = NO;
    _currentClassId = 0;
    _idleLoadedCounter = 0;
    _mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    //_estimateOrderAlertView = [self.mainStoryboard instantiateViewControllerWithIdentifier:@"EstimateOrderAlertView"];
    _estimationViewController = [self.mainStoryboard instantiateViewControllerWithIdentifier:@"EstimationViewController"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushToEstimationViewController:) name:@"PushEstimationViewControllerNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orderAction:) name:@"OrderNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSearchBar:) name:@"RefreshSearchBarNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(afterOrderSuccessfullyAccepted) name:@"AfterOrderSuccessfullyAccepted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteNotificationRecieved:) name:kDidReceiveRemoteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showPriceViewNotification:) name:@"ShowPriceViewNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageReceivedNotification:) name:@"ReceivedMessageFromMainViewController" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(terminateTimerNotification:) name:@"TerminateTimerNotification" object:nil];
    NSString *userAvatarImageUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"userAvatarUrl"];
    [Requests downloadImage:userAvatarImageUrl andCallback:^(UIImage *image) {
        _userImage = image;
    } andFailCallBack:^(NSError *error) {
        NSLog(@"ERROR :%@", error);
    }];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _managedObjectContext = [appDelegate managedObjectContext];
    //_timer = [NSTimer timerWithTimeInterval:7.0f target:self selector:@selector(checkExistenceOfOrder) userInfo:nil repeats:YES];
    _timer = [NSTimer scheduledTimerWithTimeInterval:7.0f target:self selector:@selector(checkExistenceOfOrder) userInfo:nil repeats:YES];
    _sliderVehicleImages = @[[UIImage imageNamed:@"EconomyImage"], [UIImage imageNamed:@"SedanImage"], [UIImage imageNamed:@"LimousineImage"], [UIImage imageNamed:@"PickupImage"], [UIImage imageNamed:@"SUVImage"]];
}

#pragma mark -
#pragma mark - Received Message

- (void)messageReceivedNotification:(NSNotification *)notification {
    NSString *messageStr = [notification object];
    MessagesViewController *messagesViewController = [MessagesViewController messagesViewController];
    [messagesViewController setDelegateModal:self];
    [messagesViewController setUserImage:self.userImage];
    [messagesViewController setDriverImage:self.driverPic];
    [messagesViewController setDriverName:self.driverName];
    [CATransaction begin];
    [[self navigationController] pushViewController:messagesViewController animated:YES];
    [CATransaction setCompletionBlock:^{
        [messagesViewController createMessageWithText:messageStr];
    }];
    [CATransaction commit];
}

#pragma mark -
#pragma mark - Delete all data from Core Data

- (void)deleteAllObjectsInContext {
    NSLog(@"delete all objects");
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Messages"];
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *managedObject in results) {
        [self.managedObjectContext deleteObject:managedObject];
    }
}

#pragma mark -
#pragma mark Init Google Maps View

- (void)initGoogleMapsView {
    _camera = [GMSCameraPosition cameraWithLatitude:36.392546f longitude:-119.729004f zoom:16.0f];
    _mapView = [GMSMapView mapWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, self.view.bounds.size.height) camera:self.camera];
    [_mapView setDelegate:self];
    [_mapView setMyLocationEnabled:YES];
    [_mapView addObserver:self forKeyPath:@"myLocation" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    [self.view addSubview:_mapView];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"myLocation"]) {
        if (self.isDriverOrdered) {
            CLLocation *newLocation = [change objectForKey:NSKeyValueChangeNewKey];
            CLLocationCoordinate2D newCoordinates = [newLocation coordinate];
            [CATransaction begin];
            [CATransaction setAnimationDuration:2.0f];
            self.carMarker.position = newCoordinates;
            [CATransaction commit];
        }
    }
}

#pragma mark -
#pragma mark Internet Reachability Status

- (void)handleInternetReachabilityError:(NSNotification *)notification {
    NetworkStatus internetStatus = [self.internetReachable currentReachabilityStatus];
    switch (internetStatus) {
        case ReachableViaWiFi:
        case ReachableViaWWAN:
            self.isInternetReachable = YES;
            break;
        case NotReachable:
            self.isInternetReachable = NO;
            break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark - SlideNavigationController Methods

- (BOOL)slideNavigationControllerShouldDisplayLeftMenu {
    return YES;
}

#pragma mark -
#pragma mark Init Internet Reachability Notification

- (void)initInternetReachabilityNotification {
    _isInternetReachable = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInternetReachabilityError:) name:kReachabilityChangedNotification object:nil];
    _internetReachable = [Reachability reachabilityForInternetConnection];
    [_internetReachable startNotifier];
}

#pragma mark -
#pragma mark Init Pickup Location Bar

- (void)initPickupLocationBar {
    if (!_pickupLocationBar) {
        _pickupLocationBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0f, CGRectGetHeight(self.navigationController.navigationBar.frame) + 20.0f, self.view.bounds.size.width, 44.0f)];
        [UIStaff setupPickupLocationViewSettings:self.pickupLocationBar onView:self.view];
        [[NSNotificationCenter defaultCenter] addObserverForName:SlideNavigationControllerDidOpen object:nil queue:nil usingBlock:^(NSNotification *note) {
            if ([self.pickupLocationBar isFirstResponder]) {
                [self.pickupLocationBar resignFirstResponder];
            }
        }];
    }
}

#pragma mark -
#pragma mark Init My Location Button

- (void)initMyLocationButton {
    CGFloat x = self.view.bounds.size.width - 60.0f;
    CGFloat y = self.navigationController.navigationBar.bounds.size.height + 65.0f;
    UIImage *myLocationButtonImage = [UIImage imageNamed:@"MyLocation"];
    UIButton *myLocationButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [myLocationButton setFrame:CGRectMake(x, y, myLocationButtonImage.size.width, myLocationButtonImage.size.height)];
    [myLocationButton setImage:myLocationButtonImage forState:UIControlStateNormal];
    [myLocationButton addTarget:self action:@selector(myLocationButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:myLocationButton];
}

- (void)myLocationButtonPressed:(UIButton *)sender {
    [self changePointMarkerWithPosition:self.currentLocation];
    [self.mapView animateToCameraPosition:[GMSCameraPosition cameraWithTarget:self.currentLocation zoom:16.0f]];
}

#pragma mark - Demo delegate

- (void)didDismissMessagesViewController:(MessagesViewController *)vc {
    [self dismissViewControllerAnimated:YES completion:nil];
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
    [self.locationManager stopUpdatingLocation];
    [self.mapView clear];
    _currentLocation = [startLocation coordinate];
    self.locationManager.delegate = nil;
    _locationManager = nil;
    self.camera = [GMSCameraPosition cameraWithLatitude:self.currentLocation.latitude longitude:self.currentLocation.longitude zoom:16.0f];
    [self.mapView setCamera:self.camera];
    
    _pointMarker = [GMSMarker markerWithPosition:self.currentLocation];
    [_pointMarker setAppearAnimation:kGMSMarkerAnimationPop];
    [_pointMarker setIcon:[UIImage imageNamed:@"Pin"]];
    [_pointMarker setMap:self.mapView];
}

#pragma mark -
#pragma mark Google Maps Delegate methods

- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture {
    if ([self.pickupLocationBar isFirstResponder]) {
        [self.pickupLocationBar resignFirstResponder];
    }
    NSLog(@"willMove");
    [self.carouselView setScrollEnabled:NO];
}

- (void)mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position {
    [self changePointMarkerWithPosition:[position target]];
    if (self.showPopupView) {
        [mapView setSelectedMarker:self.pointMarker];
    } else {
        [mapView setSelectedMarker:nil];
    }
}

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position {
    _carPickupLocation = [position target];
    [self changePointMarkerWithPosition:self.carPickupLocation];
    if (self.showPopupView) {
        [mapView setSelectedMarker:self.pointMarker];
    }
    [self getAddressByLocation:self.carPickupLocation];
    if (self.carPickupLocation.latitude != 0 && self.carPickupLocation.longitude != 0) {
        if (self.idleLoadedCounter == 0) {
            self.idleLoadedCounter++;
        } else if (self.idleLoadedCounter > 0) {
            [self checkExistenceOfOrder];
        }
        NSLog(@"after :%lu", (unsigned long)self.idleLoadedCounter);
    }
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker {
    if (self.showPopupView) {
        [mapView setSelectedMarker:marker];
    }
    return YES;
}

- (UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(GMSMarker *)marker {
    if (self.showPopupView) {
        PopupView *popupView = [[[NSBundle mainBundle] loadNibNamed:@"PopupView" owner:self options:nil] objectAtIndex:0];
        return popupView;
    }
    return nil;
}

- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(GMSMarker *)marker {
    [self showPopupAlertView];
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    if ([self.pickupLocationBar isFirstResponder]) {
        [self.pickupLocationBar resignFirstResponder];
    }
    [self changePointMarkerWithPosition:coordinate];
    [self getAddressByLocation:coordinate];
    if (self.showPopupView) {
        [mapView setSelectedMarker:self.pointMarker];
    }
    [mapView animateToCameraPosition:[GMSCameraPosition cameraWithTarget:coordinate zoom:[mapView.camera zoom]]];
}

#pragma mark -
#pragma mark Change PointMarker position

- (void)changePointMarkerWithPosition:(CLLocationCoordinate2D)position {
    [self.pointMarker setPosition:position];
    [self.pointMarker setMap:self.mapView];
}

#pragma mark -
#pragma mark Find nearest way

- (void)getAddressByLocation:(CLLocationCoordinate2D)pickedLocation {
    NSString *directionUrl = [Utils getFromPlistWithKey:@"GoogleMapsDirectionURL"];
    NSString *url = [NSString stringWithFormat:directionUrl, pickedLocation.latitude, pickedLocation.longitude];
    [Requests sendPostRequest:url andCallback:^(NSDictionary *parsedResponse) {
        NSString *status = [parsedResponse valueForKey:@"status"];
        if ([status isEqualToString:@"OK"]) {
            _address = [[parsedResponse valueForKeyPath:@"results.formatted_address"] objectAtIndex:0];
            [self.pickupLocationBar setText:self.address];
        } else if ([status isEqualToString:@"ZERO_RESULTS"]) {
            [self.pickupLocationBar setText:nil];
        }
    } andFailCallBack:^(NSError *error) {
        NSLog(@"ERRORik 1: %ld, %@", (long)[error code], error);
        if ([error code] != -1011) {
            [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self];
        }
    }];
}

#pragma mark -
#pragma mark Popup alert view

- (void)showPopupAlertView {
    NSString *currentiOSPlatform = [Utils platformString];
    NSString *title = KKLocalizedString(@"Order/Estimate");
    NSString *message = KKLocalizedString(@"You can customize your ride by tapping on Estimate button. Also, you can make a quick order.");
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    CGFloat width = screenWidth - (screenWidth * 10.0f)/100.0f;
    CGFloat height = 0.0f;
    if ([currentiOSPlatform isEqualToString:@"iPhone 4/4S"]) {
        height = screenHeight - (screenHeight * 40.0f)/100.0f;
    } else if ([currentiOSPlatform isEqualToString:@"iPhone 5/5S/5C"]) {
        height = screenHeight - (screenHeight * 50.0f)/100.0f;
    } else if ([currentiOSPlatform isEqualToString:@"iPhone 6"]) {
        height = screenHeight - (screenHeight * 55.0f)/100.0f;
    } else if ([currentiOSPlatform isEqualToString:@"iPhone 6+"]) {
        height = screenHeight - (screenHeight * 60.0f)/100.0f;
    } else if ([currentiOSPlatform isEqualToString:@"iPad"] || [currentiOSPlatform isEqualToString:@"iPad 2"] || [currentiOSPlatform isEqualToString:@"iPad Mini"] || [currentiOSPlatform isEqualToString:@"iPad 3"] ||
               [currentiOSPlatform isEqualToString:@"iPad 4"] || [currentiOSPlatform isEqualToString:@"iPad Air"] || [currentiOSPlatform isEqualToString:@"iPad Mini Retina"] || [currentiOSPlatform isEqualToString:@"iPad Air 2"]) {
        height = screenHeight - (screenHeight * 60.0f)/100.0f;
    }
    NSString *pickedAddress = [self.pickupLocationBar text];
    EstimateOrderAlertViewController *estimateOrderAlertView = [self.mainStoryboard instantiateViewControllerWithIdentifier:@"EstimateOrderAlertView"];
    [estimateOrderAlertView setDelegate:self];
    [estimateOrderAlertView setPopinTransitionDirection:BKTPopinTransitionDirectionTop];
    [estimateOrderAlertView setPopinTransitionStyle:BKTPopinTransitionStyleSnap];
    [estimateOrderAlertView setPreferedPopinContentSize:CGSizeMake(width, height)];
    BKTBlurParameters *blurParameters = [[BKTBlurParameters alloc] init];
    [blurParameters setAlpha:1.0f];
    [blurParameters setRadius:8.0f];
    [blurParameters setSaturationDeltaFactor:1.8f];
    [blurParameters setTintColor:[UIColor colorWithRed:215.0f/255.0f green:215.0f/255.0f blue:215.0f/255.0f alpha:0.3f]];
    [estimateOrderAlertView setBlurParameters:blurParameters];
    [estimateOrderAlertView setPopinOptions:[estimateOrderAlertView popinOptions] | BKTPopinIgnoreKeyboardNotification];
    [estimateOrderAlertView setContentWidth:width];
    [estimateOrderAlertView setContentHeight:height];
    [estimateOrderAlertView setAlertTitle:title];
    [estimateOrderAlertView setAlertBody:message];
    if (![pickedAddress isEqualToString:@""]) {
        [estimateOrderAlertView setLocationAddress:pickedAddress];
    }
    [estimateOrderAlertView.view setBackgroundColor:[UIColor clearColor]];
    [self.navigationController presentPopinController:estimateOrderAlertView animated:YES completion:nil];
}

- (void)pushToEstimationViewController:(NSNotification *)notification {
    [self.navigationController pushViewController:self.estimationViewController animated:YES];
}

#pragma mark -
#pragma mark Order Action

- (void)orderAction:(NSNotification *)notification {
    NSUInteger index = [self.carouselView currentItemIndex];
    NSUInteger currentCarClassId = [[self.bottomCars objectAtIndex:index] classId];
    UIImage *currentCarImage = [[self.bottomCars objectAtIndex:index] classImage];
    NSString *currentCarTypeName = [[self.bottomCars objectAtIndex:index] className];
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    CGFloat width = screenWidth - (screenWidth * 10.0f)/100.0f;
    CGFloat height = screenHeight - (screenHeight * 60.0f)/100.0f;
    OrderViewController *orderViewController = [self.mainStoryboard instantiateViewControllerWithIdentifier:@"OrderViewController"];
    [orderViewController setDelegate:self];
    [orderViewController setPopinTransitionDirection:BKTPopinTransitionDirectionRight];
    [orderViewController setPopinTransitionStyle:BKTPopinTransitionStyleSnap];
    [orderViewController setPreferedPopinContentSize:CGSizeMake(width, height)];
    BKTBlurParameters *blurParameters = [[BKTBlurParameters alloc] init];
    [blurParameters setAlpha:1.0f];
    [blurParameters setRadius:8.0f];
    [blurParameters setSaturationDeltaFactor:1.8f];
    [blurParameters setTintColor:[UIColor colorWithRed:215.0f/255.0f green:215.0f/255.0f blue:215.0f/255.0f alpha:0.3f]];
    [orderViewController setBlurParameters:blurParameters];
    [orderViewController setPopinOptions:[orderViewController popinOptions] | BKTPopinIgnoreKeyboardNotification];
    [orderViewController setContentWidth:width];
    [orderViewController setContentHeight:height];
    [orderViewController setCurrentCarClassId:currentCarClassId];
    [orderViewController setCurrentCarTypeImage:currentCarImage];
    [orderViewController setCurrentCarClassName:currentCarTypeName];
    [orderViewController setLat:self.carPickupLocation.latitude];
    [orderViewController setLng:self.carPickupLocation.longitude];
    [orderViewController setCurrentStartAddress:[self.pickupLocationBar text]];
    [orderViewController setMyAddress:[notification object]];
    [orderViewController.view setBackgroundColor:[UIColor clearColor]];
    [self.navigationController presentPopinController:orderViewController animated:YES completion:nil];
}

#pragma mark -
#pragma mark Init Bottom View

- (void)initBottomView {
    if (!_vehicleSliderView) {
        CGFloat y = self.view.bounds.size.height;
        CGFloat height = y - (y * 85.0f)/100.0f;
        _vehicleSliderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, y, [self.view bounds].size.width, height)];
        [_vehicleSliderView setBackgroundColor:[UIColor colorWithRed:88.0f/255.0f green:89.0f/255.0f blue:90.0f/255.0f alpha:1.0f]];
        [self.view addSubview:_vehicleSliderView];
    }
}

#pragma mark -
#pragma mark Check Existence of Order

- (void)checkExistenceOfOrder {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *sessionId = [defaults objectForKey:@"tsmSessionId"];
    NSString *url = [Utils getFromPlistWithKey:@"GetCustomerStatus"];
    if ([self.bottomCars count] > 0) {
        self.currentClassId = [[self.bottomCars objectAtIndex:[self.carouselView currentItemIndex]] classId];
    }
    NSLog(@"BBB :%lu", (unsigned long)self.currentClassId);
    NSDictionary *params = @{ @"sessionId": sessionId, @"latitude": [NSNumber numberWithDouble:self.carPickupLocation.latitude], @"longitude": [NSNumber numberWithDouble:self.carPickupLocation.longitude], @"selectedCarClassId": [NSNumber numberWithUnsignedInteger:self.currentClassId] };
    [Requests sendPostRequest:url withParameters:params andCallback:^(NSDictionary *response) {
        NSLog(@"Responsessssss :%@", response);
        NSString *result = [response valueForKey:@"result"];
        if ([result isEqualToString:@"OK"]) {
            BOOL isOrdered = [[response valueForKey:@"isOrdered"] boolValue];
            self.isDriverOrdered = isOrdered;
            BOOL isExistAvailableVehicle = [[response valueForKey:@"isExistAvailableVehicle"] boolValue];
            __block SCLAlertView *alert = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                alert = [[SCLAlertView alloc] init];
            });
            if (!isOrdered) {
                if ([[response allKeys] containsObject:@"carClasses"]) {
                    NSArray *carClasses = [response objectForKey:@"carClasses"];
                    NSArray *cars = [response objectForKey:@"cars"];
                    if ([carClasses count] > 0) {
                        _showPopupView = YES;
                        [self drawSliderSegmentedControl:carClasses];
                    }
                    if ([cars count] > 0) {
                        [self drawCars:cars];
                        [self.mapView setSelectedMarker:self.pointMarker];
                    }
                } else {
                    if (isExistAvailableVehicle) {
                        _showPopupView = NO;
                        if (!self.isVehicleViewPopup) {
                            [self drawViewWithSelectedDriverWithDriverData:response];
                        }
                        [self.mapView setSelectedMarker:nil];
                    } else {
                        NSLog(@"4444");
                        static dispatch_once_t onceToken;
                        dispatch_once(&onceToken, ^{
                            NSString *message = [response valueForKey:@"message"];
                            [alert showNotice:self.navigationController title:KKLocalizedString(@"Message") subTitle:message closeButtonTitle:KKLocalizedString(@"OK") duration:0.0f];
                        });
                        NSLog(@"isVehicleViewPopup :%d, isAlreadyReceivedDriverInfo :%d", self.isVehicleViewPopup, self.isAlreadyReceivedDriverInfo);
                        if (self.isVehicleViewPopup) {
                            if (!self.isAlreadyReceivedDriverInfo) {
                                self.showPopupView = NO;
                                [self popUpAndDownVehicleView:NO];
                                [[_vehicleSliderView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
                            }
                        }
                        if (!isExistAvailableVehicle) {
                            NSLog(@"sorry");
                            if ([self.carsToDraw count] > 0) {
                                for (GMSMarker *marker in self.carsToDraw) {
                                    marker.map = nil;
                                }
                                [self.carsToDraw removeAllObjects];
                            }
                        }
                    }
                }
            } else if ([result isEqualToString:@"Please, log in or check account status"]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"TerminateTimerNotification" object:nil];
                InitialWebViewController *initialWebViewController = [self.mainStoryboard instantiateViewControllerWithIdentifier:@"InitialWebViewController"];
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
                    [defaults removeObjectForKey:@"tsmSessionId"];
                    [defaults removeObjectForKey:@"language"];
                    [defaults removeObjectForKey:@"userAvatarUrl"];
                    [defaults removeObjectForKey:@"user_name"];
                    [defaults synchronize];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [appDelegate.window setRootViewController:initialWebViewController];
                    });
                });
            } else {
                NSLog(@"Draw view with selected driver");
                _showPopupView = NO;
                if (isExistAvailableVehicle) {
                    NSLog(@"gag1");
                    if (!self.isAlreadyReceivedDriverInfo) {
                        NSLog(@"gag2");
                        [self drawViewWithSelectedDriverWithDriverData:response];
                        _isAlreadyReceivedDriverInfo = YES;
                    }
                    [self.mapView setSelectedMarker:nil];
                } else {
                    NSLog(@"aaa");
                    static dispatch_once_t onceToken;
                    dispatch_once(&onceToken, ^{
                        NSString *message = [response valueForKey:@"message"];
                        [alert showNotice:self.navigationController title:KKLocalizedString(@"Message") subTitle:message closeButtonTitle:KKLocalizedString(@"OK") duration:0.0f];
                    });
                    if (self.isVehicleViewPopup) {
                        NSLog(@"vle1");
                        if (!self.isAlreadyReceivedDriverInfo) {
                            NSLog(@"vle2");
                            self.showPopupView = NO;
                            [self popUpAndDownVehicleView:NO];
                            [[_vehicleSliderView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
                        }
                    }
                }
            }
        }
    } andFailCallBack:^(NSError *error) {
        NSLog(@"ERRORSSS :%@", error);
    }];
}

#pragma mark -
#pragma mark After Order successfully accepted

- (void)afterOrderSuccessfullyAccepted {
    [self.mapView setSelectedMarker:nil];
    if (!self.isAlreadyReceivedDriverInfo) {
        [self popUpAndDownVehicleView:NO];
        [[_vehicleSliderView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self checkExistenceOfOrder];
    }
}

#pragma mark -
#pragma mark Draw Slider Segmented Control

- (void)drawSliderSegmentedControl:(NSArray *)cars {
    NSLog(@"CARSSSS :%@", cars);
    [self.carouselView setScrollEnabled:NO];
    if (self.showPopupView) {
        [self.mapView setSelectedMarker:self.pointMarker];
    }
    if (!_bottomCars) {
        _bottomCars = [NSMutableArray array];
    }
    if ([self.bottomCars count] > 0) {
        [_bottomCars removeAllObjects];
    }
    NSUInteger arrayCount = [cars count];
    if (arrayCount > 0) {
        for (NSUInteger i = 0; i < arrayCount; ++i) {
            NSString *url = [[cars objectAtIndex:i] valueForKey:@"classImage"];
            [Requests downloadImage:url andCallback:^(UIImage *image) {
                NSUInteger carClassId = [[[cars objectAtIndex:i] valueForKey:@"classId"] unsignedIntegerValue];
                NSString *type = [[cars objectAtIndex:i] valueForKey:@"className"];
                CarClasses *carClasses = [[CarClasses alloc] init];
                [carClasses setClassId:carClassId];
                [carClasses setClassName:type];
                [carClasses setClassImage:image];
                if (![self.bottomCars containsObject:carClasses]) {
                    [_bottomCars addObject:carClasses];
                }
                if ([self.bottomCars count] > 0) {
                    if (arrayCount == [self.bottomCars count]) {
                        NSArray *sortedArray = [self.bottomCars sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                            if ([obj1 classId] > [obj2 classId]) {
                                return (NSComparisonResult)NSOrderedDescending;
                            } else if ([obj1 classId] < [obj2 classId]) {
                                return (NSComparisonResult)NSOrderedAscending;
                            }
                            return (NSComparisonResult)NSOrderedSame;
                        }];
                        _bottomCars = [NSMutableArray arrayWithArray:sortedArray];
                        if (!_carouselView) {
                            _carouselView = [[iCarousel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.vehicleSliderView.bounds.size.width, self.vehicleSliderView.bounds.size.height)];
                            [_carouselView setDataSource:self];
                            [_carouselView setDelegate:self];
                            [_carouselView setBackgroundColor:[self.vehicleSliderView backgroundColor]];
                            [_carouselView setType:iCarouselTypeInvertedTimeMachine];
                        }
                        [_vehicleSliderView addSubview:_carouselView];
                        [self.carouselView setScrollEnabled:YES];
                        [self.carouselView reloadData];
                        _isAlreadyReceivedDriverInfo = NO;
                        [self popUpAndDownVehicleView:YES];
                    }
                }
            } andFailCallBack:^(NSError *error) {
                NSLog(@"ERROR :%@", error);
            }];
        }
    } else {
        NSLog(@"ffffffdddd");
    }
}

#pragma mark -
#pragma mark - Draw Cars in Map View

- (void)drawCars:(NSArray *)cars {
    NSLog(@"mtav");
    if (!_carsToDraw) {
        _carsToDraw = [NSMutableArray array];
    }
    if ([self.carsToDraw count] > 0) {
        for (GMSMarker *marker in self.carsToDraw) {
            marker.map = nil;
        }
    }
    [self.carsToDraw removeAllObjects];
    NSString *carClassImageUrl = nil;
    CLLocationDegrees latitude = 0.0f;
    CLLocationDegrees longitude = 0.0f;
    if ([cars count] > 0) {
        //NSLog(@"fffffeeee :%@", cars);
        for (NSUInteger i = 0; i < [cars count]; ++i) {
            NSLog(@"cars count :%lu, %@", (unsigned long)[cars count], cars);
            carClassImageUrl = [[cars objectAtIndex:i] objectForKey:@"carClassImg"];
            latitude = [[[cars objectAtIndex:i] objectForKey:@"latitude"] doubleValue];
            longitude = [[[cars objectAtIndex:i] objectForKey:@"longitude"] doubleValue];
            [Requests downloadImage:carClassImageUrl andCallback:^(UIImage *carImage) {
                if (carImage) {
                    GMSMarker *carMarker = [GMSMarker markerWithPosition:CLLocationCoordinate2DMake(latitude, longitude)];
                    [carMarker setIcon:carImage];
                    [carMarker setMap:self.mapView];
                    if (![self.carsToDraw containsObject:carMarker]) {
                        [self.carsToDraw addObject:carMarker];
                        NSLog(@"fffffeeeeqqqq");
                    }
                }
            } andFailCallBack:^(NSError *error) {
                NSLog(@"err :%@", error);
            }];
        }
    } else {
        NSLog(@"eee :%@", cars);
    }
}

#pragma mark -
#pragma mark Draw view with selected driver

- (void)drawViewWithSelectedDriverWithDriverData:(NSDictionary *)data {
    NSLog(@"data :%@", data);
    UIImage *bottomAvatarBackgroundImage = [UIImage imageNamed:@"BottomAvatarImage"];
    CGFloat bottomAvatarBackgroundX = self.vehicleSliderView.frame.size.width - (self.vehicleSliderView.frame.size.width * 98.75f)/100.0f;
    CGFloat bottomAvatarBackgroundY = self.vehicleSliderView.frame.size.height / 2.0f - bottomAvatarBackgroundImage.size.height / 2.0f;
    CGRect bottomAvatarFrame = CGRectMake(bottomAvatarBackgroundX, bottomAvatarBackgroundY, bottomAvatarBackgroundImage.size.width, bottomAvatarBackgroundImage.size.height);
    UIImageView *bottomAvatarBackgroundView = [[UIImageView alloc] initWithImage:bottomAvatarBackgroundImage];
    [bottomAvatarBackgroundView setFrame:bottomAvatarFrame];
    [bottomAvatarBackgroundView setUserInteractionEnabled:YES];
    [_vehicleSliderView addSubview:bottomAvatarBackgroundView];
    UIImage *emptyAvatarImage = [UIImage imageNamed:@"EmptyAvatarImage"];
    if (!_bottomAvatarImageView) {
        CGRect frame = CGRectMake(bottomAvatarBackgroundView.bounds.size.width/2.0f - emptyAvatarImage.size.width/2.0f, bottomAvatarBackgroundView.bounds.size.height/2.0f - emptyAvatarImage.size.height/2.0f, emptyAvatarImage.size.width + 1.0f, emptyAvatarImage.size.height + 1.0f);
        _bottomAvatarImageView = [[UIImageView alloc] initWithFrame:frame];
        [_bottomAvatarImageView setUserInteractionEnabled:YES];
    }
    [_bottomAvatarImageView setImage:emptyAvatarImage];
    [bottomAvatarBackgroundView addSubview:_bottomAvatarImageView];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bottomAvatarTapAction:)];
    [_bottomAvatarImageView addGestureRecognizer:tapGesture];
    
    NSString *driverAvatarPhotoURL = [data valueForKey:@"driverPhoto"];
    NSLog(@"fffff :%@", driverAvatarPhotoURL);
    NSString *carImageURL = [data valueForKey:@"carImage"];
    NSString *carName = [data valueForKey:@"carName"];
    NSString *carNumber = [data valueForKey:@"carNumber"];
    _driverName = [data valueForKey:@"driverName"];
    _driverPhoneNumber = [data valueForKey:@"driverPhoneNumber"];
    _startLat = [[data objectForKey:@"startLatitude"] floatValue];
    _startLong = [[data objectForKey:@"startLongitude"] floatValue];
    if (![driverAvatarPhotoURL isEqualToString:@""] && ![carImageURL isEqualToString:@""]) {
        [Requests downloadImage:driverAvatarPhotoURL andCallback:^(UIImage *driverPhoto) {
            if (driverPhoto) {
                [Requests downloadImage:carImageURL andCallback:^(UIImage *carPhoto) {
                    if (carPhoto) {
                        [self setImagesOn:self.bottomAvatarImageView with:driverPhoto andCarPhoto:carPhoto];
                    }
                    if (!self.isVehicleViewPopup) {
                        [self popUpAndDownVehicleView:YES];
                    }
                } andFailCallBack:^(NSError *error) {
                    NSLog(@"ERROR 1 :%@", error);
                    [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self];
                }];
            }
        } andFailCallBack:^(NSError *error) {
            NSLog(@"ERROR 2 :%@", error);
            [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self];
        }];
    }
    UIImage *carNumberBackgroundImage = [UIImage imageNamed:@"CarNumberImage"];
    UIImageView *carNumberBackgroundView = [[UIImageView alloc] initWithImage:carNumberBackgroundImage];
    CGFloat carNumberBackgroundX = bottomAvatarFrame.origin.x + bottomAvatarBackgroundImage.size.width + 5.0f;
    CGFloat carNumberBackgroundY = self.vehicleSliderView.frame.size.height/2.0f - carNumberBackgroundImage.size.height/2.0f - 2.0f;
    CGRect carNumberBackgroundFrame = CGRectMake(carNumberBackgroundX, carNumberBackgroundY, carNumberBackgroundImage.size.width, carNumberBackgroundImage.size.height);
    [carNumberBackgroundView setFrame:carNumberBackgroundFrame];
    [_vehicleSliderView addSubview:carNumberBackgroundView];
    
    CGFloat carNameLabelWidth = carNumberBackgroundView.bounds.size.width - (carNumberBackgroundView.bounds.size.width * 8.0f)/100.0f;
    CGFloat carNameLabelHeight = carNumberBackgroundView.bounds.size.height - (carNumberBackgroundView.bounds.size.height * 75.0f)/100.0f;
    CGFloat carNameLabelY = carNumberBackgroundView.bounds.size.height/2.0f - carNameLabelHeight;
    UILabel *carNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(6.5f, carNameLabelY, carNameLabelWidth, carNameLabelHeight)];
    [carNameLabel setTextAlignment:NSTextAlignmentCenter];
    [carNameLabel setFont:[UIFont boldSystemFontOfSize:15.0f]];
    [carNameLabel setTextColor:[UIColor colorWithRed:86.0f/255.0f green:87.0f/255.0f blue:87.0f/255.0f alpha:1.0f]];
    [carNameLabel setShadowColor:[UIColor colorWithRed:144.0f/255.0f green:142.0f/255.0f blue:128.0f/255.0f alpha:1.0f]];
    [carNameLabel setShadowOffset:CGSizeMake(1.0f, 1.0f)];
    [carNameLabel setText:carName];
    [carNumberBackgroundView addSubview:carNameLabel];
    
    CGFloat carNumberLabelHeight = carNumberBackgroundView.bounds.size.height - (carNumberBackgroundView.bounds.size.height * 65.0f)/100.0f;
    CGFloat carNumberLabelY = carNumberLabelHeight + carNumberLabelHeight/2.0f;
    UILabel *carNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(6.5f, carNumberLabelY, carNameLabelWidth, carNumberLabelHeight)];
    [carNumberLabel setTextAlignment:NSTextAlignmentCenter];
    [carNumberLabel setFont:[UIFont fontWithName:@"Mandatory" size:20.0f]];
    [carNumberLabel setTextColor:[UIColor colorWithRed:236.0f/255.0f green:236.0f/255.0f blue:236.0f/255.0f alpha:1.0f]];
    [carNumberLabel setShadowColor:[UIColor colorWithRed:173.0f/255.0f green:83.0f/255.0f blue:64.0f/255.0f alpha:1.0f]];
    [carNumberLabel setShadowOffset:CGSizeMake(0.0f, 1.5f)];
    [carNumberLabel setText:carNumber];
    [carNumberBackgroundView addSubview:carNumberLabel];
    
    UIImage *phoneImage = [UIImage imageNamed:@"PhoneImage"];
    CGFloat phoneImageViewX = self.vehicleSliderView.frame.size.width - (self.vehicleSliderView.frame.size.width * 18.0f)/100.0f;
    CGFloat phoneImageViewY = self.vehicleSliderView.frame.size.height/2.0f - phoneImage.size.height/2.0f;
    UIButton *phoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [phoneButton setImage:phoneImage forState:UIControlStateNormal];
    [phoneButton setFrame:CGRectMake(phoneImageViewX, phoneImageViewY, phoneImage.size.width, phoneImage.size.height)];
    [phoneButton addTarget:self action:@selector(phoneButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [_vehicleSliderView addSubview:phoneButton];
    
    CGFloat x = self.view.bounds.size.width - (self.view.bounds.size.width * 30.0f)/100.0f;
    CGFloat y = self.view.bounds.size.height - (self.view.bounds.size.height * 30.0f)/100.0f;
    _messageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_messageButton setFrame:CGRectMake(x, y, 80.0f, 80.0f)];
    [_messageButton.layer setCornerRadius:40.0f];
    [_messageButton.layer setBorderWidth:7.0f];
    [_messageButton.layer setBorderColor:[[UIColor colorWithRed:228.0f/255.0f green:229.0f/255.0f blue:230.0f/255.0f alpha:1.0f] CGColor]];
    [_messageButton.layer setMasksToBounds:YES];
    [_messageButton setImage:[UIImage imageNamed:@"SMSButton"] forState:UIControlStateNormal];
    [_messageButton setImage:[UIImage imageNamed:@"SMSButtonPressed"] forState:UIControlStateHighlighted];
    [_messageButton addTarget:self action:@selector(messageAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_messageButton];
    
    UIImage *cancelButtonImage = [UIImage imageNamed:@"CancelOrderButtonImage"];
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        [cancelButton setSemanticContentAttribute:UISemanticContentAttributeForceRightToLeft];
    }
    [cancelButton setTitleColor:[UIColor colorWithRed:242.0f/255.0f green:108.0f/255.0f blue:79.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor colorWithRed:145.0f/255.0f green:55.0f/255.0f blue:32.0f/255.0f alpha:1.0f] forState:UIControlStateHighlighted];
    [cancelButton setTitle:@"Cancel " forState:UIControlStateNormal];
    [cancelButton setImage:cancelButtonImage forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelOrderAction) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton sizeToFit];
    UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
    [self.navigationItem setRightBarButtonItem:cancelButtonItem];
}

- (void)setImagesOn:(UIImageView *)bottomAvatarImageView with:(UIImage *)driverPhoto andCarPhoto:(UIImage *)vehiclePhoto {
    CGFloat appropriateSize = 150.0f;
    CGSize croppingSize = CGSizeMake(appropriateSize, appropriateSize);
    if (driverPhoto.size.width > appropriateSize && driverPhoto.size.height > appropriateSize) {
        driverPhoto = [driverPhoto resizedImage:croppingSize interpolationQuality:kCGInterpolationHigh];
    }
    if (vehiclePhoto.size.width > appropriateSize && vehiclePhoto.size.height > appropriateSize) {
        vehiclePhoto = [vehiclePhoto resizedImage:croppingSize interpolationQuality:kCGInterpolationHigh];
    }
    driverPhoto = [driverPhoto roundedCornerImage:55 borderSize:0];
    vehiclePhoto = [vehiclePhoto roundedCornerImage:70 borderSize:0];
    [bottomAvatarImageView setImage:driverPhoto];
    if (driverPhoto && vehiclePhoto) {
        if (!self.isRotated) {
            [self shakingAnimation];
        }
    }
    _driverPic = driverPhoto;
    _vehiclePic = vehiclePhoto;
}

#pragma mark -
#pragma Shaking Animation for non rotated bottom avatar image

- (void)shakingAnimation {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
    [animation setAutoreverses:YES];
    [animation setRepeatCount:INFINITY];
    [animation setDuration:0.75f];
    [animation setFromValue:@(0)];
    [animation setToValue:@(M_SQRT1_2)];
    [self.bottomAvatarImageView.layer addAnimation:animation forKey:nil];
}

#pragma mark -
#pragma mark Bottom Avatar Image View tap action

- (void)bottomAvatarTapAction:(UITapGestureRecognizer *)gesture {
    UIImageView *imageView = nil;
    if ([[gesture view] isKindOfClass:[UIImageView class]]) {
        imageView = (UIImageView *)[gesture view];
    }
    if (self.driverPic && self.vehiclePic) {
        [self transform:imageView];
    }
}

#pragma mark -
#pragma mark 3D Transform Animation

- (void)transform:(UIImageView *)imageView {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
    [animation setDelegate:self];
    [animation setValue:@"fullTransformAnimation" forKey:@"FullyTransformAnimation"];
    [animation setAutoreverses:NO];
    [animation setRemovedOnCompletion:NO];
    [animation setFillMode:kCAFillModeForwards];
    [animation setDuration:0.5f];
    [animation setFromValue:@(0)];
    if (!self.isRotated) {
        [animation setToValue:@(M_PI)];
        self.isRotated = YES;
    } else {
        [animation setToValue:@(-M_PI)];
        self.isRotated = NO;
    }
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = 1.0f/500.0f;
    [imageView.layer addAnimation:animation forKey:@"rotation"];
    [imageView.layer setTransform:transform];
}

- (void)animationDidStart:(CAAnimation *)anim {
    NSString *value = [anim valueForKey:@"FullyTransformAnimation"];
    if ([value isEqualToString:@"fullTransformAnimation"]) {
        [UIImageView transitionWithView:self.bottomAvatarImageView duration:0.75f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            if (self.isRotated) {
                [self.bottomAvatarImageView setImage:self.vehiclePic];
            } else {
                [self.bottomAvatarImageView setImage:self.driverPic];
            }
        } completion:nil];
    }
}

#pragma mark -
#pragma mark Popup vehicle view

- (void)popUpAndDownVehicleView:(BOOL)isUp {
    CGRect vehicleFrame = [self.vehicleSliderView frame];
    CGFloat screenHeight = self.view.bounds.size.height;
    CGFloat appropriateY = 0.0f;
    if (isUp) {
        appropriateY = screenHeight - (screenHeight * 15.0f)/100.0f;
        self.isVehicleViewPopup = YES;
    } else {
        appropriateY = screenHeight;
        self.isVehicleViewPopup = NO;
    }
    vehicleFrame.origin.y = appropriateY;
    [UIView animateWithDuration:0.5f animations:^{
        [self.vehicleSliderView setFrame:vehicleFrame];
    }];
}

#pragma mark -
#pragma mark Phone Button Pressed

- (void)phoneButtonPressed {
    if (![self.driverPhoneNumber isEqualToString:@""]) {
        NSString *title = KKLocalizedString(@"Make a call");
        NSString *message = [NSString stringWithFormat:KKLocalizedString(@"Are you sure you want to call to %@ ?"), self.driverName];
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *callAction = [UIAlertAction actionWithTitle:KKLocalizedString(@"Call") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [alertController dismissCurrentPopinControllerAnimated:YES completion:^{
                    [self makePhoneCall];
                }];
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:KKLocalizedString(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [alertController dismissViewControllerAnimated:YES completion:nil];
            }];
            [alertController addAction:callAction];
            [alertController addAction:cancelAction];
            [self presentViewController:alertController animated:YES completion:nil];
        } else if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:KKLocalizedString(@"Cancel") otherButtonTitles:KKLocalizedString(@"Call"), nil];
            [alertView setTag:1];
            [alertView show];
        }
    }
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSUInteger tag = [alertView tag];
    if (tag == 1) {
        if (buttonIndex == 1) {
            [self makePhoneCall];
        }
    } else if (tag == 2) {
        if (buttonIndex == 1) {
            [self sendOrderCancelationRequest];
        }
    }
}

#pragma mark -
#pragma mark Make a phone call

- (void)makePhoneCall {
    NSString *phoneNumber = [@"tel://" stringByAppendingString:self.driverPhoneNumber];
    NSURL *url = [NSURL URLWithString:phoneNumber];
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark -
#pragma mark Message Action

- (void)messageAction {
    MessagesViewController *messagesViewController = [MessagesViewController messagesViewController];
    [messagesViewController setDelegateModal:self];
    [messagesViewController setUserImage:self.userImage];
    [messagesViewController setDriverImage:self.driverPic];
    [messagesViewController setDriverName:self.driverName];
    [self.navigationController pushViewController:messagesViewController animated:YES];
}

#pragma mark -
#pragma mark Cancel order action

- (void)cancelOrderAction {
    NSString *title = KKLocalizedString(@"Message");
    NSString *message = KKLocalizedString(@"Are you sure ?");
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:KKLocalizedString(@"Yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [alertController dismissCurrentPopinControllerAnimated:YES completion:^{
                [self sendOrderCancelationRequest];
            }];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:KKLocalizedString(@"No") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [alertController dismissViewControllerAnimated:YES completion:nil];
        }];
        [alertController addAction:yesAction];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    } else if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:KKLocalizedString(@"No") otherButtonTitles:KKLocalizedString(@"Yes"), nil];
        [alertView setTag:2];
        [alertView show];
    }
}

#pragma mark -
#pragma mark Send order cancelation request

- (void)sendOrderCancelationRequest {
    NSString *sessionId = [[NSUserDefaults standardUserDefaults] objectForKey:@"tsmSessionId"];
    NSString *url = [Utils getFromPlistWithKey:@"FinishingOrder"];
    NSDictionary *params = @{ @"sessionId": sessionId, @"latitude": [NSNumber numberWithFloat:self.startLat], @"longitude": [NSNumber numberWithFloat:self.startLong], @"distance": [NSNumber numberWithInteger:0] };
    [Requests sendPostRequest:url withParameters:params andCallback:^(NSDictionary *response) {
        NSString *result = [response valueForKey:@"result"];
        if ([result isEqualToString:@"OK"]) {
            [self removingItems];
            [self deleteAllObjectsInContext];
        }
    } andFailCallBack:^(NSError *error) {
        NSLog(@"error :%@", error);
        [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self];
    }];
}

#pragma mark -
#pragma mark Removing items from main view

- (void)removingItems {
    [self popUpAndDownVehicleView:NO];
    [[_vehicleSliderView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.navigationItem setRightBarButtonItem:nil];
    [_messageButton removeFromSuperview];
    _messageButton = nil;
    [self checkExistenceOfOrder];
}

#pragma mark -
#pragma mark iCarousel methods

- (NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel {
    if (self.bottomCars != nil && [self.bottomCars count] > 0) {
        return [self.bottomCars count];
    }
    return 0;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view {
    UIImageView *carImageView = nil;
    UILabel *carTypeLabel = nil;
    if (view == nil) {
        UIImage *carCircleImage = [UIImage imageNamed:@"CircleCarImage"];
        view = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, carCircleImage.size.width, carCircleImage.size.height)];
        [(UIImageView *)view setImage:carCircleImage];
        [view setContentMode:UIViewContentModeCenter];
        CGFloat width = view.bounds.size.width - (view.bounds.size.width * 30.0f)/100.0f;
        CGFloat height = view.bounds.size.height - (view.bounds.size.height * 70.0f)/100.0f;
        CGFloat x = view.center.x - width/2.0f;
        CGFloat y = view.center.y - height;
        carImageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, width, height)];
        [carImageView setTag:1];
        [view addSubview:carImageView];
        carTypeLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y + 25.0f, width, height)];
        [carTypeLabel setTextAlignment:NSTextAlignmentCenter];
        [carTypeLabel setTextColor:[UIColor colorWithRed:52.0f/255.0f green:53.0f/255.0f blue:53.0f/255.0f alpha:1.0f]];
        [carTypeLabel setFont:[UIFont fontWithName:@"Mandatory" size:12.0f]];
        [carTypeLabel setTag:2];
        [view addSubview:carTypeLabel];
    } else {
        carImageView = (UIImageView *)[view viewWithTag:1];
        carTypeLabel = (UILabel *)[view viewWithTag:2];
    }
    [carTypeLabel setText:[[self.bottomCars objectAtIndex:index] className]];
    [carImageView setImage:[[self.bottomCars objectAtIndex:index] classImage]];
    return view;
}

- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value {
    if (option == iCarouselOptionSpacing) {
        return value * 0.1f;
    }
    return value;
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index {
    _currentClassId = [[self.bottomCars objectAtIndex:index] classId];
}

- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel {
    NSUInteger currentItemIndex = [carousel currentItemIndex];
    NSLog(@"QQQQWWWWW :%@", self.bottomCars);
    _currentClassId = [[self.bottomCars objectAtIndex:currentItemIndex] classId];
}

#pragma mark -
#pragma mark Refresh Search Bar

- (void)refreshSearchBar:(NSNotification *)notification {
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{ NSForegroundColorAttributeName: [UIColor blackColor] }];
}

#pragma mark -
#pragma mark Push Notification Recieved

- (void)remoteNotificationRecieved:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSLog(@"userInfo 2 :%@", userInfo);
    NSUInteger statusCode = [[userInfo valueForKey:@"statusCode"] unsignedIntegerValue];
    NSString *title = KKLocalizedString(@"Message");
    NSString *message = [userInfo valueForKeyPath:@"aps.alert"];
    SCLAlertView *alert = [[SCLAlertView alloc] init];
    __weak __typeof(self)weakSelf = self;
    switch (statusCode) {
        case kDriverAcceptedOrder: {
            if (!self.isAlreadyReceivedDriverInfo) {
                [self popUpAndDownVehicleView:NO];
                [[_vehicleSliderView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
                [self checkExistenceOfOrder];
            }
            [self deleteAllObjectsInContext];
        }
        break;
        case kDriverCancel: {
            [alert showNotice:self.navigationController title:title subTitle:message closeButtonTitle:@"OK" duration:0.0f];
            [alert alertIsDismissed:^{
                [weakSelf deleteAllObjectsInContext];
            }];
        }
            break;
        case kDriverNotAccept: {
            [alert showNotice:self.navigationController title:title subTitle:message closeButtonTitle:@"OK" duration:0.0f];
            [alert alertIsDismissed:^{
                [weakSelf deleteAllObjectsInContext];
            }];
        }
            break;
        case kDriverParking:
        case kDriverInProgress:
        case kDriverExtraStop:
        case kDriverTollRoad:
        case kDriverHotZone:
        case kDriverSetDestination:
            [alert showNotice:self.navigationController title:title subTitle:message closeButtonTitle:@"OK" duration:0.0f];
        break;
        case kDriverAtLocation:
            [alert showInfo:self.navigationController title:title subTitle:message closeButtonTitle:@"OK" duration:0.0f];
        break;
        case kDriverCustomerDidNotShow:
            [alert showWarning:self.navigationController title:title subTitle:message closeButtonTitle:@"OK" duration:0.0f];
        break;
        case kDriverCompleteOrder: {
            BOOL isCashOnly = [[userInfo valueForKey:@"cashOnly"] boolValue];
            NSString *fullMessage = nil;
            if (isCashOnly) {
                fullMessage = [NSString stringWithFormat:KKLocalizedString(@"%@%@ %@ you need to pay by cash."), message, [userInfo valueForKey:@"currency"], [userInfo valueForKey:@"amount"]];
            } else {
                fullMessage = [NSString stringWithFormat:KKLocalizedString(@"%@%@ %@ you will be charged from your wallet."), message, [userInfo valueForKey:@"currency"], [userInfo valueForKey:@"amount"]];
            }
            [self deleteAllObjectsInContext];
            [self showRateViewWithMessage:fullMessage];
        }
        break;
        default:
            break;
    }
}

- (void)showPriceViewNotification:(NSNotification *)notification {
    NSString *fullMessage = [notification object];
    SCLAlertView *alert = [[SCLAlertView alloc] init];
    __weak typeof(self) weakSelf = self;
    [alert showSuccess:self.navigationController title:KKLocalizedString(@"Message") subTitle:fullMessage closeButtonTitle:KKLocalizedString(@"Finish") duration:0.0f];
    [alert alertIsDismissed:^{
        _isAlreadyReceivedDriverInfo = NO;
        [weakSelf removingItems];
    }];
}

- (void)showRateViewWithMessage:(NSString *)message {
    RateViewController *rateViewController = [self.mainStoryboard instantiateViewControllerWithIdentifier:@"RateViewController"];
    [rateViewController setPopinTransitionStyle:BKTPopinTransitionStyleSpringySlide];
    [rateViewController setPopinOptions:BKTPopinDefault];
    [rateViewController setPopinAlignment:BKTPopinAlignementOptionRight];
    [rateViewController setMessage:message];
    BKTBlurParameters *blurParameters = [[BKTBlurParameters alloc] init];
    [blurParameters setAlpha:1.0f];
    [blurParameters setRadius:8.0f];
    [blurParameters setSaturationDeltaFactor:1.8f];
    [blurParameters setTintColor:[UIColor colorWithRed:215.0f/255.0f green:215.0f/255.0f blue:215.0f/255.0f alpha:0.3f]];
    [rateViewController setBlurParameters:blurParameters];
    [rateViewController setPopinOptions:[rateViewController popinOptions] | BKTPopinIgnoreKeyboardNotification];
    [rateViewController setPopinTransitionDirection:BKTPopinTransitionDirectionRight];
    [rateViewController setPreferedPopinContentSize:CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height)];
    [self.navigationController presentPopinController:rateViewController animated:YES completion:nil];
}
/*
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return toInterfaceOrientation = UIInterfaceOrientationPortrait;
}*/

- (BOOL)shouldAutorotate {
    return UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_carouselView setDelegate:nil];
    [_carouselView setDataSource:nil];
    _carouselView = nil;
    [self.mapView removeObserver:self forKeyPath:@"myLocation"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_timer invalidate];
    _timer = nil;
}

- (void)terminateTimerNotification:(NSNotification *)notification {
    [_timer invalidate];
    _timer = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
