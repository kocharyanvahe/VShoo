//
//  HomeWorkMapViewController.m
//  VShoo
//
//  Created by Vahe Kocharyan on 7/24/15.
//  Copyright (c) 2015 ConnectTo. All rights reserved.
//

#import "HomeWorkMapViewController.h"
#import "UIViewController+PopinView.h"
#import "SlideNavigationController.h"
#import "AvatarViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <GoogleMaps/GoogleMaps.h>
#import "Utils.h"
#import "UIStaff.h"
#import "Requests.h"

@interface HomeWorkMapViewController () <UISearchBarDelegate, CLLocationManagerDelegate, GMSMapViewDelegate>

@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (assign, nonatomic) CLLocationCoordinate2D currentLocation;
@property (strong, nonatomic) GMSMapView *mapView;
@property (strong, nonatomic) GMSCameraPosition *camera;
@property (strong, nonatomic) GMSMarker *pin;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

@end

@implementation HomeWorkMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initContentView];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self initLocationManager];
    });
}

#pragma mark -
#pragma mark - Init Location Manager

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
    _currentLocation = [startLocation coordinate];
    _camera = [GMSCameraPosition cameraWithLatitude:self.currentLocation.latitude longitude:self.currentLocation.longitude zoom:16.0f];
    [self initGoogleMapsView];
}

#pragma mark -
#pragma mark Init Google Maps View

- (void)initGoogleMapsView {
    if (!_mapView) {
        NSString *currentiOSDevice = [Utils platformString];
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
        CGFloat height = 0.0f;
        if ([currentiOSDevice isEqualToString:@"iPhone 4/4S"] || [currentiOSDevice isEqualToString:@"iPhone 5/5S/5C"]) {
            height = screenHeight - 350.0f;
        } else if ([currentiOSDevice isEqualToString:@"iPhone 6"]) {
            height = screenHeight - 364.0f;
        } else if ([currentiOSDevice isEqualToString:@"iPhone 6+"]) {
            NSLog(@"iPhone 6+");
            height = screenHeight - 374.0f;
        } else if ([currentiOSDevice isEqualToString:@"iPad"] || [currentiOSDevice isEqualToString:@"iPad 2"] || [currentiOSDevice isEqualToString:@"iPad Mini"] || [currentiOSDevice isEqualToString:@"iPad 3"] ||
                   [currentiOSDevice isEqualToString:@"iPad 4"] || [currentiOSDevice isEqualToString:@"iPad Air"] || [currentiOSDevice isEqualToString:@"iPad Mini Retina"] || [currentiOSDevice isEqualToString:@"iPad Air 2"]) {
            height = screenHeight - 374.0f;
        }
        _mapView = [GMSMapView mapWithFrame:CGRectMake(0.0f, 87.0f, self.contentView.bounds.size.width, height) camera:self.camera];
        [_mapView setDelegate:self];
        [_mapView setMyLocationEnabled:YES];
        [_mapView setCamera:self.camera];
        [_contentView addSubview:_mapView];
    }
    [_activityIndicator stopAnimating];
    [_searchBar becomeFirstResponder];
    _activityIndicator = nil;
    if (_pin) {
        _pin.map = nil;
        _pin = nil;
    }
    _pin = [GMSMarker markerWithPosition:self.currentLocation];
    [_pin setAppearAnimation:kGMSMarkerAnimationPop];
    [_pin setIcon:[UIImage imageNamed:@"HomeWorkPin"]];
    [_pin setMap:self.mapView];
}

#pragma mark -
#pragma mark Init Content view

- (void)initContentView {
    if (!_contentView) {
        UIImage *cancelButtonImage = [UIImage imageNamed:@"HomeWorkCancel"];
        UIImage *cancelButtonPressedImage = [UIImage imageNamed:@"HomeWorkCancelPressed"];
        UIImage *acceptButtonImage = [UIImage imageNamed:@"HomeWorkAcceptButton"];
        UIImage *acceptButtonPressedImage = [UIImage imageNamed:@"HomeWorkAcceptPressedButton"];
        
        CGFloat contentViewX = cancelButtonImage.size.width/2.0f;
        CGFloat contentViewY = cancelButtonImage.size.height/2.0f;
        CGFloat width = self.preferedPopinContentSize.width - contentViewX - acceptButtonImage.size.width/2.0f;
        
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(contentViewX, contentViewY, width, self.preferedPopinContentSize.height - (self.preferedPopinContentSize.height * 20.0f)/100.0f)];
        [_contentView setBackgroundColor:[UIColor clearColor]];
        [self.view addSubview:_contentView];
        
        UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [cancelButton setFrame:CGRectMake(0.0f, 0.0f, cancelButtonImage.size.width, cancelButtonImage.size.height)];
        [cancelButton setImage:cancelButtonImage forState:UIControlStateNormal];
        [cancelButton setImage:cancelButtonPressedImage forState:UIControlStateHighlighted];
        [cancelButton addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:cancelButton];
        
        UIButton *acceptButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [acceptButton setFrame:CGRectMake(self.contentView.bounds.size.width, 0.0f, acceptButtonImage.size.width, acceptButtonImage.size.height)];
        [acceptButton setImage:acceptButtonImage forState:UIControlStateNormal];
        [acceptButton setImage:acceptButtonPressedImage forState:UIControlStateHighlighted];
        [acceptButton addTarget:self action:@selector(acceptAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:acceptButton];
        
        UINavigationBar *navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.contentView.bounds.size.width, 44.0f)];
        [navigationBar setBarTintColor:[UIColor colorWithRed:242.0f/255.0f green:108.0f/255.0f blue:79.0f/255.0f alpha:1.0f]];
        [navigationBar setTranslucent:NO];
        [navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
        
        UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:self.navigationTitle];
        [navigationBar setItems:@[navItem] animated:YES];
        [_contentView addSubview:navigationBar];
        
        _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0f, 44.0f, self.contentView.bounds.size.width, 44.0f)];
        [_searchBar setDelegate:self];
        [_searchBar setSearchBarStyle:UISearchBarStyleMinimal];
        [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor] }];
        [_contentView addSubview:_searchBar];
        
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [_activityIndicator setFrame:CGRectMake(self.contentView.bounds.size.width/2.0f - 20.0f, self.contentView.bounds.size.height/2.0f - 20.0f, 30.0f, 30.0f)];
        [_contentView addSubview:_activityIndicator];
        [_activityIndicator startAnimating];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:SlideNavigationControllerDidClose object:nil queue:nil usingBlock:^(NSNotification *note) {
            if ([self.searchBar isFirstResponder]) {
                [self.searchBar resignFirstResponder];
            }
        }];
        [[NSNotificationCenter defaultCenter] addObserverForName:SlideNavigationControllerDidOpen object:nil queue:nil usingBlock:^(NSNotification *note) {
            if (![self.searchBar isFirstResponder]) {
                [self.searchBar becomeFirstResponder];
            }
        }];
    }
}

#pragma mark -
#pragma mark Google Maps Delegate methods

- (void)mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position {
    [self changePointMarkerWithPosition:[position target]];
}

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position {
    [self changePointMarkerWithPosition:[position target]];
    [mapView setSelectedMarker:self.pin];
    [self getAddressByLocation:[position target]];
}

#pragma mark -
#pragma mark Find nearest way

- (void)getAddressByLocation:(CLLocationCoordinate2D)pickedLocation {
    NSString *directionUrl = [Utils getFromPlistWithKey:@"GoogleMapsDirectionURL"];
    NSString *url = [NSString stringWithFormat:directionUrl, pickedLocation.latitude, pickedLocation.longitude];
    [Requests sendPostRequest:url andCallback:^(NSDictionary *parsedResponse) {
        NSString *status = [parsedResponse valueForKey:@"status"];
        if ([status isEqualToString:@"OK"]) {
            NSString *address = [[parsedResponse valueForKeyPath:@"results.formatted_address"] objectAtIndex:0];
            NSString *sep = @",,";
            NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:sep];
            NSArray *temp = [address componentsSeparatedByCharactersInSet:set];
            NSString *cityName = nil;
            if ([temp[1] rangeOfString:@" "].location != NSNotFound) {
                cityName = [[temp[1] componentsSeparatedByCharactersInSet:[[NSCharacterSet letterCharacterSet] invertedSet]] componentsJoinedByString:@""];
            } else {
                cityName = temp[1];
            }
            NSString *updatedAddress = [NSString stringWithFormat:@"%@, %@,%@", temp[0], cityName, temp[2]];
            NSLog(@"updated :%@", updatedAddress);
            [self.searchBar setText:updatedAddress];
            [UIStaff putCursorOnFrontIn:self.searchBar];
        } else if ([status isEqualToString:@"ZERO_RESULTS"]) {
            [self.searchBar setText:nil];
        }
    } andFailCallBack:^(NSError *error) {
        NSLog(@"ERROR :%@", error);
        [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self];
    }];
}

#pragma mark -
#pragma mark Change PointMarker position

- (void)changePointMarkerWithPosition:(CLLocationCoordinate2D)position {
    [self.pin setPosition:position];
    [self.pin setMap:self.mapView];
}

#pragma mark -
#pragma mark UISearchBar delegate methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *typedAddress = [searchBar text];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        if ([typedAddress containsString:@" "]) {
            typedAddress = [typedAddress stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        }
    } else if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        if ([typedAddress rangeOfString:@" "].location != NSNotFound) {
            typedAddress = [typedAddress stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        }
    }
    NSString *placesAPIKey = [Utils getFromPlistWithKey:@"PlacesAPIKey"];
    NSString *googlePlacesAPIURL = [Utils getFromPlistWithKey:@"GooglePlacesAPIURL"];
    NSString *url = [NSString stringWithFormat:googlePlacesAPIURL, typedAddress, placesAPIKey];
    [Requests sendPostRequest:url andCallback:^(NSDictionary *response) {
        NSString *status = [response valueForKey:@"status"];
        if ([status isEqualToString:@"OK"]) {
            NSString *addressDescription = [[response valueForKeyPath:@"predictions.description"] objectAtIndex:0];
            NSString *placeId = [[response valueForKeyPath:@"predictions.place_id"] objectAtIndex:0];
            [searchBar setText:addressDescription];
            [UIStaff putCursorOnFrontIn:searchBar];
            if (placeId) {
                NSString *getLocationByPlaceIdURL = [Utils getFromPlistWithKey:@"GetLocationByPlaceID"];
                NSString *url = [NSString stringWithFormat:getLocationByPlaceIdURL, placeId, placesAPIKey];
                [Requests sendPostRequest:url andCallback:^(NSDictionary *response) {
                    NSString *status = [response valueForKey:@"status"];
                    if ([status isEqualToString:@"OK"]) {
                        CLLocationDegrees latitude = [[response valueForKeyPath:@"result.geometry.location.lat"] doubleValue];
                        CLLocationDegrees longitude = [[response valueForKeyPath:@"result.geometry.location.lng"] doubleValue];
                        CLLocationCoordinate2D pickedLocation = CLLocationCoordinate2DMake(latitude, longitude);
                        CGFloat zoomLevel = [self.mapView.camera zoom];
                        [self changePointMarkerWithPosition:pickedLocation];
                        [self.mapView setCamera:[GMSCameraPosition cameraWithTarget:pickedLocation zoom:zoomLevel]];
                    } else if ([status isEqualToString:@"ZERO_RESULTS"]) {
                        [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:KKLocalizedString(@"Cannot find") onFollowingViewController:self.view.window.rootViewController];
                    }
                } andFailCallBack:^(NSError *error) {
                    [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self.view.window.rootViewController];
                }];
            }
        } else if ([status isEqualToString:@"ZERO_RESULTS"]) {
            [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:KKLocalizedString(@"Cannot find") onFollowingViewController:self.view.window.rootViewController];
        }
    } andFailCallBack:^(NSError *error) {
        [Utils showSimpleAlertsWithTitle:KKLocalizedString(@"ERROR") andMessage:[error localizedDescription] onFollowingViewController:self.view.window.rootViewController];
    }];
}

#pragma mark -
#pragma mark Buttons' actions

- (void)closeAction {
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
    [self.presentingPopinViewController dismissCurrentPopinControllerAnimated:YES];
}

- (void)acceptAction {
    NSLog(@"Accept Action");
    NSString *pickedAddress = [self.searchBar text];
    if (pickedAddress) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            if ([self.navigationTitle containsString:KKLocalizedString(@"Home")]) {
                [defaults setObject:pickedAddress forKey:@"home_address"];
            } else if ([self.navigationTitle containsString:KKLocalizedString(@"Work")]) {
                [defaults setObject:pickedAddress forKey:@"work_address"];
            }
        } else if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            if ([self.navigationTitle rangeOfString:KKLocalizedString(@"Home")].location != NSNotFound) {
                [defaults setObject:pickedAddress forKey:@"home_address"];
            } else if ([self.navigationTitle rangeOfString:KKLocalizedString(@"Work")].location != NSNotFound) {
                [defaults setObject:pickedAddress forKey:@"work_address"];
            }
        }
        [defaults synchronize];
        NSLog(@"hhhh :%@, wwww :%@", [defaults objectForKey:@"home_address"], [defaults objectForKey:@"work_address"]);
    }
    if ([self.delegate respondsToSelector:@selector(refreshTableView)]) {
        [self.delegate refreshTableView];
    }
    [self.presentingPopinViewController dismissCurrentPopinControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
