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
//#import "NSJSONSerialization.h"


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

- (void)viewDidLoad
{
    NSLog(@"View is loading");
    [super viewDidLoad];
    [self configureStaticUI];
    [self initializeVariables];
    [self getRequest];
    

    // Set up Maps.
    _park = [[XYZOutsideLands alloc] initHard];
    UIImage *outsideLandsImage = [UIImage imageNamed:@"map_transparent.png"];
    [self setCurrentImage: (UIImage *)outsideLandsImage];
    [self addOverlay];
    [self setToOutsideLands];
    
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

    MKCoordinateSpan span = MKCoordinateSpanMake(fabsf(longDelta), 0.0);

    MKCoordinateRegion region = MKCoordinateRegionMake(self.park.midCoordinate, span);

    self.mainMap.region = region;
    
    [self addPins];

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

- (void)setCurrentImage: (UIImage*) image {
    NSLog(@"Adding Image");
    if(image == nil) {
        NSLog(@"The image cannot be found");
    }
    self.parkImage = image;
    [self.mainMap reloadInputViews];
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


- (void)addPins {
    
    self.mainMap.delegate = self;
    
    MKPointAnnotation *annotation1 = [[MKPointAnnotation alloc] init];
    annotation1.coordinate = CLLocationCoordinate2DMake(37.7678, -122.49428);
    [annotation1 setTitle:@"Lands End"];
    [self.mainMap addAnnotation:annotation1];
    
    MKPointAnnotation *annotation2 = [[MKPointAnnotation alloc] init];
    annotation2.coordinate = CLLocationCoordinate2DMake(37.76809, -122.490965);
    [annotation2 setTitle:@"The Dome By Heineken"];
    [self.mainMap addAnnotation:annotation2];
    
    MKPointAnnotation *annotation3 = [[MKPointAnnotation alloc] init];
    annotation3.coordinate = CLLocationCoordinate2DMake(37.769935, -122.49275);
    [annotation3 setTitle:@"Suto Stage"];
    [self.mainMap addAnnotation:annotation3];
    
    MKPointAnnotation *annotation4 = [[MKPointAnnotation alloc] init];
    annotation4.coordinate = CLLocationCoordinate2DMake(37.76987, -122.4852);
    [annotation4 setTitle:@"Panhandle Stage"];
    [self.mainMap addAnnotation:annotation4];
    
    MKPointAnnotation *annotation5 = [[MKPointAnnotation alloc] init];
    annotation5.coordinate = CLLocationCoordinate2DMake(37.769808, -122.482549);
    
    [annotation5 setTitle:@"Twin Peaks Stage"];
    [self.mainMap addAnnotation:annotation5];
    
    MKPointAnnotation *annotation6 = [[MKPointAnnotation alloc] init];
    annotation6.coordinate = CLLocationCoordinate2DMake(37.770447, -122.48853);
    [annotation6 setTitle:@"The Barbary"];
    [self.mainMap addAnnotation:annotation6];
    


}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id)annotation {
    
    if([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    static NSString *identifier = @"myAnnotation";
    MKPinAnnotationView * annotationView = (MKPinAnnotationView*)[self.mainMap dequeueReusableAnnotationViewWithIdentifier:identifier];
    if (!annotationView)
    {
        
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        annotationView.pinColor = MKPinAnnotationColorPurple;
        annotationView.animatesDrop = YES;
        annotationView.canShowCallout = YES;
    }else {
        annotationView.annotation = annotation;
    }
    annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    return annotationView;
}


- (void)configureStaticUI
{
    //nav bar init
    self.title = @"MappedIn";
    [self.navigationController.navigationBar setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIFont fontWithName:@"GurmukhiMN-Bold" size:28],
      NSFontAttributeName,
      [UIColor colorWithRed:(229/255.0) green:(188/255.0) blue:(45/255.0) alpha:1],
      NSForegroundColorAttributeName, nil]];
    
    // segmenter controller init
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"GurmukhiMN-Bold" size:16], NSFontAttributeName, nil];
    
    [self.segControl setTitleTextAttributes:attributes
                                   forState:UIControlStateNormal];
}



- (void)initializeVariables {

    manager = [[CLLocationManager alloc] init];
    manager.delegate = self;
    manager.desiredAccuracy = kCLLocationAccuracyBest;
    manager.distanceFilter = 10;
    [manager startUpdatingLocation];
    
    //Initialize swiper
    NSLog(@"adding icon");

    current_displayed_map_id = 0;
    mapButtonIcon = @[@"swipe_icon.png", @"swipe_icon2.png"];
    
    UIImage *image = [UIImage imageNamed:@"swipe_icon.png"];
    if(image == nil) {
        NSLog(@"swipe_icon not found");
    }
    [self.swiperBar setImage:image];
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

-(void)getRequest {
    NSURL *url = [NSURL URLWithString:@"https://api.spotify.com/v1/artists/5K4W6rqBFWDnAN6FQUkS6x"];
    
    // Create a download task.
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url
        completionHandler:^(NSData *data,
         NSURLResponse *response,
         NSError *error)
    {
      if (!error)
      {
          NSError *JSONError = nil;
          
          NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONError];
          if (JSONError)
          {
              NSLog(@"Serialization error: %@", JSONError.localizedDescription);
          }
          else
          {
              NSLog(@"Response: %@", dictionary);
          }
      }
      else
      {
          NSLog(@"Error: %@", error.localizedDescription);
      }
    }];
    
    // Start the task.
    [task resume];
}

-(void)pushRequest:(CLLocation*) location {
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
       [self pushRequest:location];
   }
}



@end
