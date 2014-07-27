//
//  XYZOutsideLandsOverlay.m
//  MappedIn
//
//  Created by Ruofei Ma on 7/26/14.
//  Copyright (c) 2014 Ruofei Ma. All rights reserved.
//

#import "XYZOutsideLandsOverlay.h"
#import "XYZOutsideLands.h"


@implementation XYZOutsideLandsOverlay

@synthesize coordinate;
@synthesize boundingMapRect;

- (instancetype)initOverlay: (XYZOutsideLands*) park {
    self = [super init];
    
    if (self) {
        boundingMapRect = park.overlayBoundingMapRect;
        coordinate = park.midCoordinate;
    }
    
    return self;
}



@end
