//
//  XYZViewController.m
//  MappedIn
//
//  Created by Ruofei Ma on 7/26/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "XYZViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CommonCrypto/CommonDigest.h>


@interface XYZViewController () <CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mainMap;

@end

@implementation XYZViewController {
    CLLocationManager *manager;
    NSMutableDictionary *responsesData;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureStaticUI];
	// Do any additional setup after loading the view, typically from a nib.
   [self initializeVariables];
    
    
    
}


- (void)configureStaticUI
{
    // Nav bar - general.
    //UIImage *image = [UIImage imageNamed:@"logo_small.png"];
   // [self.navigationItem setTitleView:[[UIImageView alloc] initWithImage:image]];  // place logo in nav bar
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initializeVariables {
    
    manager = [[CLLocationManager alloc] init];
    manager.delegate = self;
    manager.desiredAccuracy = kCLLocationAccuracyBest;
    manager.distanceFilter = 5;
    [manager startUpdatingLocation];
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

-(void)pushRequest:(NSDictionary *)mapData {
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
    
    NSData *postData = [NSJSONSerialization dataWithJSONObject:mapData options:0 error:&error];
    [request setHTTPBody:postData];
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error1) {
        
        if(error1 == nil)
        {
            NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
            NSLog(@"Data = %@",text);
        }
        
    }];
    
    [postDataTask resume];
    
    NSLog(@"attempted post request");
    
}



-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];

    NSTimeInterval eventInterval = [location.timestamp timeIntervalSinceNow];
   if(abs(eventInterval) < 15){ //make sure it is a recent event
       
       UIDevice *device = [UIDevice currentDevice];
       NSString  *currentDeviceId = [[device identifierForVendor]UUIDString];
       //NSLog(@"Device ID: %@", currentDeviceId);
       NSString *encryptedStr = [self sha1: currentDeviceId];
       //NSLog(@"Device ID encrypted: %@", encryptedStr);
       //NSLog(@"latitude %+.6f, longitude %+.6f\n",location.coordinate.latitude, location.coordinate.longitude);
       NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys:
                                encryptedStr, @"phone_id",
                                [NSNumber numberWithDouble:location.coordinate.latitude], @"latitude",
                                [NSNumber numberWithDouble:location.coordinate.longitude], @"longitude",
                                nil];
       //send push request
       [self pushRequest:mapData];
    
    
    }

}



@end
