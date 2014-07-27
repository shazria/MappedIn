//
//  XYZOutsideLands.m
//  MappedIn
//
//  Created by Ruofei Ma on 7/26/14.
//  Copyright (c) 2014 Ruofei Ma. All rights reserved.
//

#import "XYZOutsideLands.h"

@implementation XYZOutsideLands

- (instancetype)initHard {
    self = [super init];
    if (self) {
        
        _midCoordinate = CLLocationCoordinate2DMake(37.768555, -122.488445);
        
        _overlayTopLeftCoordinate = CLLocationCoordinate2DMake(37.771020, -122.496036);
        
        _overlayTopRightCoordinate = CLLocationCoordinate2DMake(37.771330, -122.480951);
        
        _overlayBottomLeftCoordinate = CLLocationCoordinate2DMake(37.765987, -122.495886);
        
        _overlayBottomRightCoordinate =CLLocationCoordinate2DMake(37.765885, -122.480908);
    }
    
    return self;
}

//- (CLLocationCoordinate2D)overlayBottomRightCoordinate {
//    return CLLocationCoordinate2DMake(self.overlayBottomLeftCoordinate.latitude, self.overlayTopRightCoordinate.longitude);
//}

- (MKMapRect)overlayBoundingMapRect {
    
    MKMapPoint topLeft = MKMapPointForCoordinate(self.overlayTopLeftCoordinate);
    MKMapPoint topRight = MKMapPointForCoordinate(self.overlayTopRightCoordinate);
    MKMapPoint bottomLeft = MKMapPointForCoordinate(self.overlayBottomLeftCoordinate);
    
    return MKMapRectMake(topLeft.x,
                         topLeft.y,
                         fabs(topLeft.x - topRight.x),
                         fabs(topLeft.y - bottomLeft.y));
}

@end
