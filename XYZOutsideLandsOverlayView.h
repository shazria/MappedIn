//
//  XYZOutsideLandsOverlayView.h
//  MappedIn
//
//  Created by Ruofei Ma on 7/26/14.
//  Copyright (c) 2014 Ruofei Ma. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface XYZOutsideLandsOverlayView : MKOverlayRenderer

- (instancetype)initWithOverlay:(id<MKOverlay>)overlay overlayImage:(UIImage *)overlayImage;

@end
