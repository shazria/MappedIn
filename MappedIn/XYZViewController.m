//
//  XYZViewController.m
//  MappedIn
//
//  Created by Ruofei Ma on 7/26/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "XYZViewController.h"
#import <MapKit/MapKit.h>
#import "XYZOutsideLandsOverlay.h"
#import "XYZOutsideLandsOverlayView.h"
#import "XYZOutsideLands.h"
#import <CoreLocation/CoreLocation.h>
#import <CommonCrypto/CommonDigest.h>


@interface XYZViewController () <CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mainMap;
@property XYZOutsideLands * park;
@property (weak, nonatomic) IBOutlet UIImageView *swiperBar;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segControl;
@property UIImage * parkImage;
@end

#define METERS_PER_MILE 1609.34

@implementation XYZViewController {
    CLLocationManager *manager;
    NSMutableDictionary *responsesData;
    int current_displayed_map_id;
    NSArray * mapButtonIcon;
}

- (IBAction)swipeRight:(UISwipeGestureRecognizer *)sender {
    NSLog(@"swiper has been swiped right");
    // [self updateHeatMap];
    if(![self increment_displayed_map_id]) return;
    [self setSwiperImage];
}

- (void)updateHeatMap {
    UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://stuki.org/rpc/phone/heatmap"]]];
    NSLog(@"image to download");
    if(image == nil) {
        NSLog(@"image is not downloaded");
    } else {
        NSLog(@"image is downloaded");
    }

    [self setCurrentImage: image];
}


- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender {
    NSLog(@"swiper has been swiped left");
    if(![self decrement_displayed_map_id]) return;
    [self setSwiperImage];
}

- (void)setSwiperImage {
    UIImage *image = [UIImage imageNamed:mapButtonIcon[current_displayed_map_id]];
    if(image == nil) {
        NSLog(@"swipe_icon not found");
    }
    [self.swiperBar setImage:image];
}

- (bool)increment_displayed_map_id {
    if(current_displayed_map_id < [mapButtonIcon count] - 1) {
        current_displayed_map_id ++;
        return true;
    } else {
        return false;
    }
}

- (bool)decrement_displayed_map_id {
    if(current_displayed_map_id > 0) {
        current_displayed_map_id --;
        return true;
    } else {
        return false;
    }
}

- (void)drawImage: (UIImage*) image {
    NSLog(@"Adding Image");
    if(image == nil) {
        NSLog(@"The image cannot be found");
    }
    self.parkImage = image;
    //[self.mainMap reloadInputViews];

    [self.mainMap removeOverlay:self.mainMap.overlays];
    [self addOverlay];

}

- (void)drawLine {

}

- (void)viewDidLoad
{
    NSLog(@"View is loading");
    [super viewDidLoad];
    [self configureStaticUI];
    [self initializeVariables];


    // Set up Maps.
    _park = [[XYZOutsideLands alloc] initHard];
    UIImage *outsideLandsImage = [UIImage imageNamed:@"map_transparent.png"];
    [self drawImage: (UIImage *)outsideLandsImage];
    [self addOverlay];
    [self setToOutsideLands];

}

- (void)configureStaticUI
{
    // Nav bar - general.
    //UIImage *image = [UIImage imageNamed:@"logo_small.png"];
   // [self.navigationItem setTitleView:[[UIImageView alloc] initWithImage:image]];  // place logo in nav bar
    self.title = @"MappedIn";
    [self.navigationController.navigationBar setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIFont fontWithName:@"STHeitiSC-Medium" size:28],
      NSFontAttributeName,
      [UIColor colorWithRed:(229/255.0) green:(188/255.0) blue:(45/255.0) alpha:1],
      NSForegroundColorAttributeName, nil]];
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0f]};
    [self.segControl setTitleTextAttributes:attributes
                                    forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"View is appearing");
}

// Map Implementations
- (void)setToOutsideLands
{
    self.mainMap.delegate = self;
    CLLocationDegrees latDelta = self.park.overlayTopLeftCoordinate.latitude - self.park.overlayBottomRightCoordinate.latitude;

    CLLocationDegrees longDelta = self.park.overlayTopLeftCoordinate.longitude - self.park.overlayBottomRightCoordinate.longitude;

    MKCoordinateSpan span = MKCoordinateSpanMake(fabsf(latDelta), 0.0);

    MKCoordinateRegion region = MKCoordinateRegionMake(self.park.midCoordinate, span);

    self.mainMap.region = region;
}

- (void)setToCurrentLocation
{
    CLLocationCoordinate2D zoomLocation;
    // TODO: Retrieve real locations here.
    zoomLocation.latitude = 37.768555;
    zoomLocation.longitude= -122.488445;

    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
    [_mainMap setRegion:viewRegion animated:YES];
}

- (void)addOverlay {
    NSLog(@"Map has been added");
    XYZOutsideLandsOverlay *overlay = [[XYZOutsideLandsOverlay alloc] initOverlay: _park ];
    [self.mainMap addOverlay:overlay];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    NSLog(@"Rendering View");
    if ([overlay isKindOfClass:XYZOutsideLandsOverlay.class]) {
        XYZOutsideLandsOverlayView *overlayView = [[XYZOutsideLandsOverlayView alloc] initWithOverlay:overlay overlayImage:self.parkImage];

        return overlayView;
    }
    return nil;
}


// Shana
- (void)initializeVariables {

    manager = [[CLLocationManager alloc] init];
    manager.delegate = self;
    manager.desiredAccuracy = kCLLocationAccuracyBest;
    manager.distanceFilter = 15;
    [manager startUpdatingLocation];

    //Initialize swiper
    NSLog(@"adding icon");

    current_displayed_map_id = 0;
    mapButtonIcon = @[@"swipe_icon.png", @"swipe_icon2.png"];

    [self setSwiperImage];
    [self.swiperBar setUserInteractionEnabled:YES];

}



-(NSString*) sha1:(NSString*)input
{
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];

    uint8_t digest[CC_SHA1_DIGEST_LENGTH];

    CC_SHA1(data.bytes, data.length, digest);

    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];

    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];

    return output;

}


#pragma mark CLLocationManagerDelegate Methods

-(void)locationManager:(CLLocation *)manager didFailWithError:(NSError *)error {
    NSLog(@"Error: %@", error);
    NSLog(@"Failed to get location!");
}

-(void)recordLocation:(CLLocation*) location {
    UIDevice *device = [UIDevice currentDevice];
    NSString  *currentDeviceId = [[device identifierForVendor]UUIDString];
    NSLog(@"Device ID: %@", currentDeviceId);
    NSString *encryptedStr = [self sha1: currentDeviceId];
    NSLog(@"Device ID encrypted: %@", encryptedStr);
    NSLog(@"latitude %+.6f, longitude %+.6f\n",
          location.coordinate.latitude,
          location.coordinate.longitude);

    //send push request
    NSError *error;

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    NSURL *url = [NSURL URLWithString:@"http://stuki.org/api/phone/location"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];

    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];

    [request setHTTPMethod:@"POST"];

    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys:
                             encryptedStr, @"phone_id",
                             [NSNumber numberWithDouble:location.coordinate.latitude], @"latitude",
                             [NSNumber numberWithDouble:location.coordinate.longitude], @"longitude",
                             nil];

    NSData *postData = [NSJSONSerialization dataWithJSONObject:mapData options:0 error:&error];
    [request setHTTPBody:postData];

    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

    }];

    [postDataTask resume];

    NSLog(@"attempted post request");

}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    //make sure this is a recent location event
    NSTimeInterval eventInterval = [location.timestamp timeIntervalSinceNow];
   if(abs(eventInterval) < 15){ //further than 30sec ago
        //this is recent event
       [self recordLocation:location];
   }
}



@end
