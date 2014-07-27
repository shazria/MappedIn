//
//  XYZOutsideLandsOverlay.h
//  MappedIn
//
//  Created by Ruofei Ma on 7/26/14.
//  Copyright (c) 2014 Ruofei Ma. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "XYZOutsideLands.h"

@interface XYZOutsideLandsOverlay : NSObject <MKOverlay>
- (instancetype)initOverlay: (XYZOutsideLands*) park;
@end
