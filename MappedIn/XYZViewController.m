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

@interface XYZViewController ()
@property (weak, nonatomic) IBOutlet MKMapView *mainMap;
@property XYZOutsideLands * park;
@property UIImage * parkImage;
@end

@implementation XYZViewController
#define METERS_PER_MILE 1609.34
- (void)viewDidLoad
{
    NSLog(@"View is loading");
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
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

- (void)setToOutsideLands
{
    self.mainMap.delegate = self;
    CLLocationDegrees latDelta = self.park.overlayTopLeftCoordinate.latitude - self.park.overlayBottomRightCoordinate.latitude;
    
    CLLocationDegrees longDelta = self.park.overlayTopLeftCoordinate.longitude - self.park.overlayBottomRightCoordinate.longitude;
    
    MKCoordinateSpan span = MKCoordinateSpanMake(fabsf(longDelta), 0.0);
    
    MKCoordinateRegion region = MKCoordinateRegionMake(self.park.midCoordinate, span);
    
    self.mainMap.region = region;
}
// Map Implementations
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

@end
