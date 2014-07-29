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


static bool const USE_TEST_DATA = false;

@interface XYZViewController () <CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mainMap;
@property XYZOutsideLands * park;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;


@property (weak, nonatomic) IBOutlet UISegmentedControl *segControl;
@property UIImage * parkImage;
@property NSArray * personalPath;
@property XYZOutsideLandsOverlayView * overlayViewControl;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;


@property (nonatomic, strong) NSArray *dictArr;
@end

#define METERS_PER_MILE 1609.34

@implementation XYZViewController {
    CLLocationManager *manager;
    NSMutableDictionary *responsesData;
    int current_displayed_map_id;
    bool locationServiceOn;
}

@synthesize dictArr = _dictArr;

- (BOOL)image:(UIImage *)image1 isEqualTo:(UIImage *)image2
{
    NSData *data1 = UIImagePNGRepresentation(image1);
    NSData *data2 = UIImagePNGRepresentation(image2);
    
    return [data1 isEqual:data2];
}

- (void) refreshButtonOff{
    self.refreshButton.hidden = YES;
    self.spinner.hidden = NO;
    [self.spinner startAnimating];
}

- (void) refreshButtonOn {
    self.refreshButton.hidden = NO;
    self.spinner.hidden = YES;
    [self.spinner stopAnimating];
}
- (IBAction)refreshButtonPressed:(id)sender {
    
    [self refreshButtonOff];
    [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)2.0 target:self selector:@selector(refreshButtonOn) userInfo: nil repeats:false];
    if(current_displayed_map_id == 0) {
        NSLog(@"refreshed public map");
        [self changeToPublicMap:[self downloadHeatMap] :true];
    } else {
        NSLog(@"refreshed private map");
        NSArray * coords = [self downloadPersonalPath];
        [self changeToPrivateMap:coords :true];
    }
   
}

- (IBAction)homeButtonHandler:(id)sender {
    NSLog(@"Going home");
    [self setToOutsideLands];
}

- (IBAction)SegValueChanged:(id)sender {
    switch (self.segControl.selectedSegmentIndex) {
        case 0:
            NSLog(@"11111");
            current_displayed_map_id = 0;
            [self changeToPublicMap:[self downloadHeatMap] :false];
            break;
        case 1: {
            NSLog(@"22222");
            if(![CLLocationManager locationServicesEnabled] ||
               [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"You Are Not MappedIn!"
                                                                message:@"Please Turn On Location Service"
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            current_displayed_map_id = 1;
            
            //            [self changeToPrivateMap:[self downloadPersonalPath]];
            NSArray * coords = [self downloadPersonalPath];
            [self changeToPrivateMap:coords :false];
            break; }
        default:
            break;
    }
}

- (void)removeAllPinsButUserLocation
{
    id userLocation = [self.mainMap userLocation];
    NSMutableArray *allPins =[[NSMutableArray alloc] initWithArray:[self.mainMap annotations]];
    //    if ( userLocation != nil ) {
    //        [pins removeObject:userLocation]; // avoid removing user location off the map
    //    }
    XYZPathViewAnnotation * one = nil;
    XYZPathViewAnnotation * two = nil ;
    for(int i = 0;i < [[self.mainMap annotations] count]; i++) {
        NSLog(@"shit");
        if(![allPins[i] isKindOfClass:[XYZPathViewAnnotation class]]) {
            if([allPins[i] isEqualToString: @"one"])
                one = allPins[i];
            if([allPins[i]isEqualToString: @"two"])
                two = allPins[i];
        }
    }
    
    [allPins removeObject:one];
    [allPins removeObject:two];
    [self.mainMap removeAnnotations:allPins];
    allPins = nil;
}

- (void) resetMap {
    //    [self removeAllPinsButUserLocation];
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
        return nil;
    }
    
    NSError *localError = nil;
    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&localError];
    NSArray* allObj =parsedObject[@"path"];
    
    
    NSMutableArray*  coordinates = [[NSMutableArray alloc]initWithCapacity:[allObj count]];
    
    for(int i = 0; i < [allObj count]; i++) {
        NSDictionary *objectList = (NSArray *)allObj[i];
        
        NSString *pair = [NSString stringWithFormat:@"{%@,%@}", objectList[@"latitude"], objectList[@"longitude"]]
        ;
        
        [coordinates addObject:pair];
        
    }
    NSArray *array = [NSArray arrayWithArray:coordinates];
    
    if(USE_TEST_DATA) {
        return @[@"{37.767916797120236,-122.49392372384827}",@"{37.768829752338533,-122.49199025827274}",@"{37.768981082571756,-122.49048731503703}",@"{37.768914588150821,-122.49042621746531}",@"{37.769194491752273,-122.48962664332748}",@"{37.769553803943005,-122.48789343536545}",@"{37.769888761701729,-122.48661272283738}",@"{37.769441179991226,-122.48604763578537}",@"{37.769960191207161,-122.48313687100783}",@"{37.769500779524847,-122.48424637957896}",@"{37.770560579566443,-122.4909186420783}",@"{37.770006879083326,-122.49258694080943}"];
    }
    else {
       return array;
    }
}


- (void) changeToPrivateMap:(NSArray*)coords : (bool) isRefreshing{
    if(coords == nil) return;
    if(isRefreshing &&[coords isEqualToArray:_personalPath]) {
        return;
    }
    [self resetMap];
    [self addPublicOverlay];
    
    
    if(coords == nil || [coords count] == 0) {
        if(_personalPath == nil) {
            return;
        } else {
            coords =_personalPath;
        }
    } else {
        _personalPath = coords;
    }
    
    NSInteger pointsCount = [coords count];
    
    CLLocationCoordinate2D pointsToUse[pointsCount];
    
    for(int i = 0; i < pointsCount; i++) {
        CGPoint p = CGPointFromString(coords[i]);
        pointsToUse[i] = CLLocationCoordinate2DMake(p.x,p.y);
    }
    
    MKPolyline *myPolyline = [MKPolyline polylineWithCoordinates:pointsToUse count:pointsCount];
    
    [self.mainMap addOverlay:myPolyline];
    [self changeToCurrentLoc];
    
    //    XYZPathViewAnnotation* begin =[self createAnnotations:pointsToUse[0] text:@"begin"];
    //    begin.title = @"one";
    //    XYZPathViewAnnotation* end =[self createAnnotations:pointsToUse[pointsCount-1] text:@"end"];
    //    begin.title = @"two";
    //
    //    [self.mainMap addAnnotations:@[begin,end]];
    //    [self addPins];
}


- (void) changeToPublicMap:(UIImage*)image :(bool)refreshing {
    if(image == nil ) {
        return;
    }
    if(refreshing && [self image:image isEqualTo:self.parkImage]) {
        return;
    }
    [self resetMap];
    self.parkImage = image;
    [self addPublicOverlay];
    [self setToOutsideLands];
    //    [self addPins];
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
        lineView.strokeColor = [UIColor blueColor];
        lineView.lineWidth = 2.0;
        
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

- (void)appDidBecomeActive:(NSNotification *)notification {
    NSLog(@"did become active notification");
    if(![CLLocationManager locationServicesEnabled] ||
       [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        [manager stopUpdatingLocation];
        locationServiceOn = false;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"You Are Not MappedIn!"
                                                        message:@"Turn on location service for personal maps."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else if(!locationServiceOn) {
        NSLog(@"Turning On Location Services");
        manager = [[CLLocationManager alloc] init];
        manager.delegate = self;
        manager.desiredAccuracy = kCLLocationAccuracyBest;
        manager.distanceFilter = 15;
        [manager startUpdatingLocation];
        locationServiceOn = true;
    }
}

- (void)viewDidLoad
{
    NSLog(@"View is loading");
    self.dictArr;
    locationServiceOn =false;
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [self configureStaticUI];
    [self initializeVariables];
    //[self getRequest];
    
    self.mainMap.delegate = self;
    // Set up Maps.
    _park = [[XYZOutsideLands alloc] initHard];
    
    [self changeToPublicMap: [self downloadHeatMap]: true];
    
    [self setToOutsideLands];
    [self addPins];

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

- (void )changeToCurrentLoc {
    if(![CLLocationManager locationServicesEnabled] ||
       [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        NSLog(@"location service denied");
        return;
    }
    MKCoordinateRegion mapRegion;
    mapRegion.center = [self.mainMap userLocation].coordinate;
    mapRegion.span.latitudeDelta = 0.005;
    mapRegion.span.longitudeDelta = 0.005;
    self.mainMap.region = mapRegion;
}

// Map Implementations
- (void)setToOutsideLands
{
    
    CLLocationDegrees latDelta = self.park.overlayTopLeftCoordinate.latitude - self.park.overlayBottomRightCoordinate.latitude;
    
    CLLocationDegrees longDelta = self.park.overlayTopLeftCoordinate.longitude - self.park.overlayBottomRightCoordinate.longitude;
    
    MKCoordinateSpan span = MKCoordinateSpanMake(fabsf(3.5*latDelta), 0.0);
    
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
    
    NSString *myName = self.dictArr[0][@"name"];
    
    MKPointAnnotation *annotation1 = [[MKPointAnnotation alloc] init];
    annotation1.coordinate = CLLocationCoordinate2DMake(37.76775, -122.4945);
    [annotation1 setTitle: myName];
    [annotation1 setSubtitle:@"Lands End | 12:00-12:40"];
    [self.mainMap addAnnotation:annotation1];
    
    //2
    myName = self.dictArr[1][@"name"];
    MKPointAnnotation *annotation2 = [[MKPointAnnotation alloc] init];
    annotation2.coordinate = CLLocationCoordinate2DMake(37.76805, -122.4911);
    [annotation2 setTitle: myName];
    [annotation2 setSubtitle:@"The Dome By Heineken | 4:30-6:00"];
    [self.mainMap addAnnotation:annotation2];
    
    //3
    myName = self.dictArr[2][@"name"];
    MKPointAnnotation *annotation3 = [[MKPointAnnotation alloc] init];
    annotation3.coordinate = CLLocationCoordinate2DMake(37.76988, -122.49294);
    [annotation3 setTitle: myName];
    [annotation3 setSubtitle:@"Suto Stage | 2:30-3:00"];
    [self.mainMap addAnnotation:annotation3];
    
    //4
    myName = self.dictArr[3][@"name"];
    MKPointAnnotation *annotation4 = [[MKPointAnnotation alloc] init];
    annotation4.coordinate = CLLocationCoordinate2DMake(37.76987, -122.48532);
    [annotation4 setTitle: myName];
    [annotation4 setSubtitle:@"Panhandle Stage | 12:00-12:40"];
    [self.mainMap addAnnotation:annotation4];
    
    //5
    myName = self.dictArr[4][@"name"];
    MKPointAnnotation *annotation5 = [[MKPointAnnotation alloc] init];
    annotation5.coordinate = CLLocationCoordinate2DMake(37.769808, -122.4827);
    [annotation5 setTitle: myName];
    [annotation5 setSubtitle:@"Twin Peaks Stage | 12:00-12:40"];
    [self.mainMap addAnnotation:annotation5];
    
    //6
    myName = self.dictArr[5][@"name"];
    MKPointAnnotation *annotation6 = [[MKPointAnnotation alloc] init];
    annotation6.coordinate = CLLocationCoordinate2DMake(37.77035, -122.4887);
    [annotation6 setTitle: myName];
    [annotation6 setSubtitle:@"The Barbary| 12:45-1:45"];
    [self.mainMap addAnnotation:annotation6];
    
    
    
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    if([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    [self.mainMap setDelegate:self];
    static NSString *identifier = @"myAnnotation";
    MKAnnotationView * annotationView = (MKAnnotationView*)[self.mainMap dequeueReusableAnnotationViewWithIdentifier:identifier];
    CGSize iconSize = CGSizeMake(24.0,34.0);
    CGSize firstSize = CGSizeMake(45.0,45.0);
    
    UIImage *scaledImage = [self image:[UIImage imageNamed:@"yellowIcon.png"] scaledToSize:iconSize];
    
    annotationView.canShowCallout = YES;
    if (!annotationView)
    {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        annotationView.canShowCallout = YES;
        
        if ([annotation.subtitle isEqualToString:@"Lands End | 12:00-12:40"]) {
            annotationView.image = scaledImage;
            NSArray *myArray = self.dictArr[0][@"images"];
            NSDictionary *imageDict = [myArray objectAtIndex:0];
            NSString *imageURL = imageDict[@"url"];
            UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
            
            UIImage *scaledImage = [self image:image scaledToSize:firstSize];
            
            UIImageView *iconView = [[UIImageView alloc] initWithImage:scaledImage];
            annotationView.leftCalloutAccessoryView = iconView;        }
        else if ([annotation.subtitle isEqualToString:@"The Dome By Heineken | 4:30-6:00"]) {
            annotationView.image = scaledImage;
            NSLog(@"WTF is going on!!!");
            NSArray *myArray = self.dictArr[1][@"images"];
            NSDictionary *imageDict = [myArray objectAtIndex:0];
            NSString *imageURL = imageDict[@"url"];
            UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
            UIImage *scaledImage = [self image:image scaledToSize:firstSize];
            
            UIImageView *iconView = [[UIImageView alloc] initWithImage:scaledImage];
            annotationView.leftCalloutAccessoryView = iconView;
            
            
        }
        else if ([annotation.subtitle isEqualToString:@"Suto Stage | 2:30-3:00"]) {
            annotationView.image = scaledImage;
            NSArray *myArray = self.dictArr[2][@"images"];
            NSDictionary *imageDict = [myArray objectAtIndex:0];
            NSString *imageURL = imageDict[@"url"];
            UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
            UIImage *scaledImage = [self image:image scaledToSize:firstSize];
            
            UIImageView *iconView = [[UIImageView alloc] initWithImage:scaledImage];
            annotationView.leftCalloutAccessoryView = iconView;
        }
        else if ([annotation.subtitle isEqualToString:@"Panhandle Stage | 12:00-12:40"]) {
            annotationView.image = scaledImage;
            
            NSArray *myArray = self.dictArr[3][@"images"];
            NSDictionary *imageDict = [myArray objectAtIndex:0];
            NSString *imageURL = imageDict[@"url"];
            UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
            UIImage *scaledImage = [self image:image scaledToSize:firstSize];
            
            UIImageView *iconView = [[UIImageView alloc] initWithImage:scaledImage];
            annotationView.leftCalloutAccessoryView = iconView;
            
            
        }
        else if ([annotation.subtitle isEqualToString:@"Twin Peaks Stage | 12:00-12:40"]) {
            
            annotationView.image = scaledImage;
            NSArray *myArray = self.dictArr[4][@"images"];
            NSDictionary *imageDict = [myArray objectAtIndex:0];
            NSString *imageURL = imageDict[@"url"];
            UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
            UIImage *scaledImage = [self image:image scaledToSize:firstSize];
            
            UIImageView *iconView = [[UIImageView alloc] initWithImage:scaledImage];
            annotationView.leftCalloutAccessoryView = iconView;
            
            
        }
        else if ([annotation.subtitle isEqualToString:@"The Barbary| 12:45-1:45"]) {
            annotationView.image = scaledImage;
            NSArray *myArray = self.dictArr[5][@"images"];
            NSDictionary *imageDict = [myArray objectAtIndex:0];
            NSString *imageURL = imageDict[@"url"];
            UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
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
    

    //Initialize swiper
    
    
    current_displayed_map_id = 0;
    self.spinner.hidden = YES;
    
    
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
    NSLog(@"retrieve from Spotify");
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
    if(![CLLocationManager locationServicesEnabled] ||
       [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        return;
    }
    CLLocation *location = [locations lastObject];
    //make sure this is a recent location event
    NSTimeInterval eventInterval = [location.timestamp timeIntervalSinceNow];
    if(abs(eventInterval) < 15){ //further than 30sec ago
        //this is recent event
        [self pushRequest:location];
    }
}



@end

