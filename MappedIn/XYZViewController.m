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
#import "XYZPathViewAnnotation.h"
#import <Foundation/Foundation.h>


@interface XYZViewController () <CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mainMap;
@property XYZOutsideLands * park;
@property (weak, nonatomic) IBOutlet UIImageView *swiperBar;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segControl;
@property UIImage * parkImage;
@property NSArray * personalPath;
@property XYZOutsideLandsOverlayView * overlayViewControl;

@property (nonatomic, strong) NSArray *dictArr;
@end

#define METERS_PER_MILE 1609.34

@implementation XYZViewController {
    CLLocationManager *manager;
    NSMutableDictionary *responsesData;
    int current_displayed_map_id;
    NSArray * mapButtonIcon;
}

@synthesize dictArr = _dictArr;

- (IBAction)homeButtonHandler:(id)sender {
    NSLog(@"Going home");
    [self setToOutsideLands];
}

- (IBAction)SegValueChanged:(id)sender {
    switch (self.segControl.selectedSegmentIndex) {
        case 0:
            NSLog(@"11111");
            [self changeToPublicMap:[self downloadHeatMap]];
            break;
        case 1: {
            NSLog(@"22222");
//            [self changeToPrivateMap:[self downloadPersonalPath]];
            NSArray * coords = [self downloadPersonalPath];
            [self changeToPrivateMap:coords];
            break; }
        default:
            break;
    }
}

- (void)removeAllPinsButUserLocation
{
    id userLocation = [self.mainMap userLocation];
    NSMutableArray *pins = [[NSMutableArray alloc] initWithArray:[self.mainMap annotations]];
    if ( userLocation != nil ) {
        [pins removeObject:userLocation]; // avoid removing user location off the map
    }

    [self.mainMap removeAnnotations:pins];
    pins = nil;
}

- (void) resetMap {
    [self removeAllPinsButUserLocation];
    [self.mainMap removeOverlays:self.mainMap.overlays];
}

- (NSArray *)downloadPersonalPath{

    
    UIDevice *device = [UIDevice currentDevice];
    NSString  *currentDeviceId = [[device identifierForVendor]UUIDString];
    NSString *encryptedStr = [self sha1: currentDeviceId];
    
    NSString* url = [NSString stringWithFormat:@"http://stuki.org/rpc/phone/path/%@",encryptedStr];
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    
    if(data != nil) {
        NSLog(@"Successful retrival of personal path");
    } else {
        NSLog(@"Failed retrival of personal path");
    }
    
    NSError *localError = nil;
    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&localError];
    NSArray* allObj =parsedObject[@"path"];
    
    NSLog(@"My dictionary is %@", allObj);
    

    NSMutableArray*  coordinates = [[NSMutableArray alloc]initWithCapacity:([allObj count] / 10) +1];
//    CLLocationCoordinate2D pointsToUse[([allObj count] / 10) +1];
    
    for(int i = 0; i < [allObj count]; i+=10) {
        NSDictionary *objectList = (NSArray *)allObj[i];
        
        NSString *pair = [NSString stringWithFormat:@"{%@,%@}", objectList[@"latitude"], objectList[@"longitude"]]
        ;

        [coordinates addObject:pair];
        
    }
    NSArray *array = [NSArray arrayWithArray:coordinates];
    
    return array;
//    return @[@"{37.7679523696108,-122.493548619190}", @"{37.7683324214340,-122.491511479933}"];
    
}


- (void) changeToPrivateMap:(NSArray*)coords{
    NSLog(@"My array is %@", coords);

    [self resetMap];
    current_displayed_map_id = 1;
    [self addPublicOverlay];

    
    //NSString *thePath = [[NSBundle mainBundle] pathForResource:@"EntranceToGoliathRoute" ofType:@"plist"];
//    NSArray *pointsArray = [NSArray arrayWithContentsOfFile:thePath];

    if(coords == nil || [coords count] == 0) {
        if(_personalPath == nil) {
            return;
        } else {
            coords =_personalPath;
        }
    } else {
        _personalPath = coords;
    }

    for(int i = 0 ;i < [coords count]; i++) {
        NSLog(@"%@", coords[i]);
    }
    
    NSInteger pointsCount = [coords count];
    
    CLLocationCoordinate2D pointsToUse[pointsCount];
    
    for(int i = 0; i < pointsCount; i++) {
        CGPoint p = CGPointFromString(coords[i]);
        pointsToUse[i] = CLLocationCoordinate2DMake(p.x,p.y);
    }
    
    MKPolyline *myPolyline = [MKPolyline polylineWithCoordinates:pointsToUse count:pointsCount];
    
    [self.mainMap addOverlay:myPolyline];
    
    XYZPathViewAnnotation* begin =[self createAnnotations:pointsToUse[0] text:@"begin"];
    XYZPathViewAnnotation* end =[self createAnnotations:pointsToUse[pointsCount-1] text:@"end"];
    
    [self.mainMap addAnnotations:@[begin,end]];
    [self addPins];
}


- (void) changeToPublicMap:(UIImage*)image {
    current_displayed_map_id = 0;
    [self resetMap];
    if(image != nil) {
        self.parkImage = image;
    }
    [self addPublicOverlay];
    [self addPins];
}

- (UIImage *)downloadHeatMap {
    UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://stuki.org/rpc/phone/heatmap"]]];
    NSLog(@"image to download");
    if(image == nil) {
        NSLog(@"image is not downloaded");
    } else {
        NSLog(@"image is downloaded");
    }

    return image;
}


- (void)addPublicOverlay {
    NSLog(@"Map has been added");
    XYZOutsideLandsOverlay *overlay = [[XYZOutsideLandsOverlay alloc] initOverlay: _park ];
    [self.mainMap addOverlay:overlay];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    NSLog(@"Rendering View");
    if ([overlay isKindOfClass:XYZOutsideLandsOverlay.class]) {
        if(current_displayed_map_id == 0) {
            self.overlayViewControl = [[XYZOutsideLandsOverlayView alloc] initWithOverlay:overlay overlayImage:self.parkImage];
        } else {
            self.overlayViewControl = [[XYZOutsideLandsOverlayView alloc] initWithOverlay:overlay overlayImage:nil];
        }
        return self.overlayViewControl;
    } else if ([overlay isKindOfClass:MKPolyline.class]) {
        MKPolylineRenderer *lineView = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
        lineView.strokeColor = [UIColor greenColor];

        return lineView;
    }
    return nil;
}

- (NSArray *)dictArr {
    if (!_dictArr) {
        NSDictionary *myDict1 = [self getRequest:[NSURL URLWithString:@"https://api.spotify.com/v1/artists/10NEMYLJwVvYSvtvZn5Ipz"]];
        NSDictionary *myDict2 = [self getRequest:[NSURL URLWithString:@"https://api.spotify.com/v1/artists/4BqZuFqHJ8CLn3ig0f1m0G"]];
        NSDictionary *myDict3 = [self getRequest:[NSURL URLWithString:@"https://api.spotify.com/v1/artists/57kIMCLPgkzQlXjblX7XXP"]];
        NSDictionary *myDict4 = [self getRequest:[NSURL URLWithString:@"https://api.spotify.com/v1/artists/7m3fe3erw9iO9gs4AeLSG8"]];
        NSDictionary *myDict5 = [self getRequest:[NSURL URLWithString:@"https://api.spotify.com/v1/artists/25hbSOMmbhgqvonjC876UJ"]];
        NSDictionary *myDict6 = [self getRequest:[NSURL URLWithString:@"https://api.spotify.com/v1/artists/2wZcAibn3pVsNvp95HQx8n"]];
        _dictArr = @[myDict1, myDict2, myDict3, myDict4, myDict5, myDict6];
    }
    
    return _dictArr;
}

- (void)viewDidLoad
{
    NSLog(@"View is loading");
    self.dictArr;
    
    [super viewDidLoad];
    [self configureStaticUI];
    [self initializeVariables];
    //[self getRequest];


    // Set up Maps.
    _park = [[XYZOutsideLands alloc] initHard];

    [self changeToPublicMap: [self downloadHeatMap]];

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
    [self addPins];
}

// Map Implementations
- (void)setToOutsideLands
{
    self.mainMap.delegate = self;
    CLLocationDegrees latDelta = self.park.overlayTopLeftCoordinate.latitude - self.park.overlayBottomRightCoordinate.latitude;

    CLLocationDegrees longDelta = self.park.overlayTopLeftCoordinate.longitude - self.park.overlayBottomRightCoordinate.longitude;

    MKCoordinateSpan span = MKCoordinateSpanMake(fabsf(2*latDelta), 0.0);

    MKCoordinateRegion region = MKCoordinateRegionMake(self.park.midCoordinate, span);

    self.mainMap.region = region;

}

- (XYZPathViewAnnotation *)createAnnotations:(CLLocationCoordinate2D)coord text: (NSString*) title
{
    NSMutableArray *annotations = [[NSMutableArray alloc] init];
    XYZPathViewAnnotation *annotation = [[XYZPathViewAnnotation alloc] initWithTitle:title AndCoordinate:coord];
    return annotation;
}
// -------------------------------------------------------------------------------------------------------





- (void)addPins {

    self.mainMap.delegate = self;
    //1
   // NSURL *url = [NSURL URLWithString:@"https://api.spotify.com/v1/artists/10NEMYLJwVvYSvtvZn5Ipz"];
   // NSDictionary *myDict = [self getRequest:url];
    
    NSString *myName = self.dictArr[0][@"name"];
    
    MKPointAnnotation *annotation1 = [[MKPointAnnotation alloc] init];
    annotation1.coordinate = CLLocationCoordinate2DMake(37.7678, -122.49428);
    [annotation1 setTitle: myName];
    [annotation1 setSubtitle:@"Lands End | 12:00-12:40"];
    [self.mainMap addAnnotation:annotation1];

    //2
    //url = [NSURL URLWithString:@"https://api.spotify.com/v1/artists/4BqZuFqHJ8CLn3ig0f1m0G"];
    //myDict = [self getRequest:url];
    myName = self.dictArr[1][@"name"];
    MKPointAnnotation *annotation2 = [[MKPointAnnotation alloc] init];
    annotation2.coordinate = CLLocationCoordinate2DMake(37.76809, -122.490965);
    [annotation2 setTitle: myName];
    [annotation2 setSubtitle:@"The Dome By Heineken | 4:30-6:00"];
    [self.mainMap addAnnotation:annotation2];
    
    //3
   // url = [NSURL URLWithString:@"https://api.spotify.com/v1/artists/57kIMCLPgkzQlXjblX7XXP"];
   // myDict = [self getRequest:url];
    myName = self.dictArr[2][@"name"];
    MKPointAnnotation *annotation3 = [[MKPointAnnotation alloc] init];
    annotation3.coordinate = CLLocationCoordinate2DMake(37.769935, -122.49275);
    [annotation3 setTitle: myName];
    [annotation3 setSubtitle:@"Suto Stage | 2:30-3:00"];
    [self.mainMap addAnnotation:annotation3];
    
    //4
    myName = self.dictArr[3][@"name"];
    MKPointAnnotation *annotation4 = [[MKPointAnnotation alloc] init];
    annotation4.coordinate = CLLocationCoordinate2DMake(37.76987, -122.4852);
    [annotation4 setTitle: myName];
    [annotation4 setSubtitle:@"Panhandle Stage | 12:00-12:40"];
    [self.mainMap addAnnotation:annotation4];
    
    //5
    myName = self.dictArr[4][@"name"];
    MKPointAnnotation *annotation5 = [[MKPointAnnotation alloc] init];
    annotation5.coordinate = CLLocationCoordinate2DMake(37.769808, -122.482549);
    [annotation5 setTitle: myName];
    [annotation5 setSubtitle:@"Twin Peaks Stage | 12:00-12:40"];
    [self.mainMap addAnnotation:annotation5];
    
    //6
    myName = self.dictArr[5][@"name"];
    MKPointAnnotation *annotation6 = [[MKPointAnnotation alloc] init];
    annotation6.coordinate = CLLocationCoordinate2DMake(37.770447, -122.48853);
    [annotation6 setTitle: myName];
    [annotation6 setSubtitle:@"The Barbary| 12:45-1:45"];
    [self.mainMap addAnnotation:annotation6];

}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {

    if([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    static NSString *identifier = @"myAnnotation";
    MKPinAnnotationView * annotationView = (MKPinAnnotationView*)[self.mainMap dequeueReusableAnnotationViewWithIdentifier:identifier];
    if (!annotationView)
    {
       
        //NSLog(@"Fetched Title: %@", annotation.title);
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        
        annotationView.animatesDrop = YES;
        annotationView.canShowCallout = YES;
        
        if ([annotation.subtitle isEqualToString:@"Lands End | 12:00-12:40"]) {
           annotationView.pinColor = MKPinAnnotationColorPurple;
            NSArray *myArray = self.dictArr[0][@"images"];
            NSDictionary *imageDict = [myArray objectAtIndex:0];
            NSString *imageURL = imageDict[@"url"];
            UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
            CGSize firstSize = CGSizeMake(45.0,45.0);
            UIImage *scaledImage = [self image:image scaledToSize:firstSize];
            
            UIImageView *iconView = [[UIImageView alloc] initWithImage:scaledImage];
            annotationView.leftCalloutAccessoryView = iconView;        }
        else if ([annotation.subtitle isEqualToString:@"The Dome By Heineken | 4:30-6:00"]) {
            annotationView.pinColor = MKPinAnnotationColorPurple;
            NSArray *myArray = self.dictArr[1][@"images"];
            NSDictionary *imageDict = [myArray objectAtIndex:0];
            NSString *imageURL = imageDict[@"url"];
            UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
            CGSize firstSize = CGSizeMake(45.0,45.0);
            UIImage *scaledImage = [self image:image scaledToSize:firstSize];
            
            UIImageView *iconView = [[UIImageView alloc] initWithImage:scaledImage];
            annotationView.leftCalloutAccessoryView = iconView;

        
        }
        else if ([annotation.subtitle isEqualToString:@"Suto Stage | 2:30-3:00"]) {
            annotationView.pinColor = MKPinAnnotationColorPurple;
            NSArray *myArray = self.dictArr[2][@"images"];
            NSDictionary *imageDict = [myArray objectAtIndex:0];
            NSString *imageURL = imageDict[@"url"];
            UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
            CGSize firstSize = CGSizeMake(45.0,45.0);
            UIImage *scaledImage = [self image:image scaledToSize:firstSize];
            
            UIImageView *iconView = [[UIImageView alloc] initWithImage:scaledImage];
            annotationView.leftCalloutAccessoryView = iconView;
        }
        else if ([annotation.subtitle isEqualToString:@"Panhandle Stage | 12:00-12:40"]) {
           annotationView.pinColor = MKPinAnnotationColorPurple;
            NSArray *myArray = self.dictArr[3][@"images"];
            NSDictionary *imageDict = [myArray objectAtIndex:0];
            NSString *imageURL = imageDict[@"url"];
            UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
            CGSize firstSize = CGSizeMake(45.0,45.0);
            UIImage *scaledImage = [self image:image scaledToSize:firstSize];
            
            UIImageView *iconView = [[UIImageView alloc] initWithImage:scaledImage];
            annotationView.leftCalloutAccessoryView = iconView;
            
            
        }
        else if ([annotation.subtitle isEqualToString:@"Twin Peaks Stage | 12:00-12:40"]) {
            annotationView.pinColor = MKPinAnnotationColorPurple;
            NSArray *myArray = self.dictArr[4][@"images"];
            NSDictionary *imageDict = [myArray objectAtIndex:0];
            NSString *imageURL = imageDict[@"url"];
            UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
            CGSize firstSize = CGSizeMake(45.0,45.0);
            UIImage *scaledImage = [self image:image scaledToSize:firstSize];
            
            UIImageView *iconView = [[UIImageView alloc] initWithImage:scaledImage];
            annotationView.leftCalloutAccessoryView = iconView;
            
            
        }
        else if ([annotation.subtitle isEqualToString:@"The Barbary| 12:45-1:45"]) {
            annotationView.pinColor = MKPinAnnotationColorPurple;
            NSArray *myArray = self.dictArr[5][@"images"];
            NSDictionary *imageDict = [myArray objectAtIndex:0];
            NSString *imageURL = imageDict[@"url"];
            UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
            CGSize firstSize = CGSizeMake(45.0,45.0);
            UIImage *scaledImage = [self image:image scaledToSize:firstSize];
            
            UIImageView *iconView = [[UIImageView alloc] initWithImage:scaledImage];
            annotationView.leftCalloutAccessoryView = iconView;
            
            
        }

      
        
    }else {
        annotationView.annotation = annotation;
        
    }
    
    return annotationView;
}


- (UIImage *)image:(UIImage*)originalImage scaledToSize:(CGSize)size
{
    //avoid redundant drawing
    if (CGSizeEqualToSize(originalImage.size, size))
    {
        return originalImage;
    }
    
    //create drawing context
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    
    //draw
    [originalImage drawInRect:CGRectMake(0.0f, 0.0f, size.width, size.height)];
    
    //capture resultant image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //return image
    return image;
}


//- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
//    // Go to edit view
//    UIViewController *detailViewController = [[UIViewController alloc] initWithNibName:@"UIViewController" bundle:nil];
//    [self.navigationController pushViewController:detailViewController animated:YES];
//    
//}


- (void)configureStaticUI
{
    //nav bar init
    self.title = @"MappedIn";
    [self.navigationController.navigationBar setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIFont fontWithName:@"STHeitiSC-Medium" size:28],
      NSFontAttributeName,
      [UIColor colorWithRed:(229/255.0) green:(188/255.0) blue:(45/255.0) alpha:1],
      NSForegroundColorAttributeName, nil]];

    // segmenter controller init
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"STHeitiSC-Medium" size:18], NSFontAttributeName, nil];

    [self.segControl setTitleTextAttributes:attributes
                                   forState:UIControlStateNormal];
}



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

-(NSDictionary*)getRequest:(NSURL *)url {
   // NSURL *url = [NSURL URLWithString:@"https://api.spotify.com/v1/artists/5K4W6rqBFWDnAN6FQUkS6x"];
    __block NSDictionary *dict;
    // Create a download task.
    dispatch_semaphore_t getSemaphore = dispatch_semaphore_create(0);
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url
        completionHandler:^(NSData *data,
         NSURLResponse *response,
         NSError *error) {
      if (!error) {
          NSError *JSONError = nil;

          dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONError];
          if (JSONError) {
              NSLog(@"Serialization error: %@", JSONError.localizedDescription);
          }
          else {
             // NSLog(@"Response: %@", dict);
          }
      } else {
          NSLog(@"Error: %@", error.localizedDescription);
      }
            dispatch_semaphore_signal(getSemaphore);
    }];

    // Start the task.
    [task resume];
    dispatch_semaphore_wait(getSemaphore, DISPATCH_TIME_FOREVER);
    
    return dict;
}

-(void)pushRequest:(CLLocation*) location {
    UIDevice *device = [UIDevice currentDevice];
    NSString  *currentDeviceId = [[device identifierForVendor]UUIDString];
   // NSLog(@"Device ID: %@", currentDeviceId);
    NSString *encryptedStr = [self sha1: currentDeviceId];
   // NSLog(@"Device ID encrypted: %@", encryptedStr);
  //  NSLog(@"latitude %+.6f, longitude %+.6f\n",
        //  location.coordinate.latitude,
        //  location.coordinate.longitude);

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
