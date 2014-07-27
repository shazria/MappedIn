//
//  XYZOutsideLandsOverlayView.m
//  MappedIn
//
//  Created by Ruofei Ma on 7/26/14.
//  Copyright (c) 2014 Ruofei Ma. All rights reserved.
//

#import "XYZOutsideLandsOverlayView.h"

@interface XYZOutsideLandsOverlayView()

@property (nonatomic, strong) UIImage *overlayImage;
@property UIImage *backgroundImage;
@end

@implementation XYZOutsideLandsOverlayView

- (instancetype)initWithOverlay:(id<MKOverlay>)overlay overlayImage:(UIImage *)overlayImage {
    self = [super initWithOverlay:overlay];
    if (self) {
        _overlayImage = overlayImage;
    }
    
    self.backgroundImage =  [UIImage imageNamed:@"map_transparent.png"];
    return self;
}

- (void) changeOverlayImage: (UIImage *) image {
    self.overlayImage = image;
}

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context {
    
    CGImageRef backgroundImageReference = self.backgroundImage.CGImage;
    CGImageRef imageReference = nil;
    if(self.overlayImage !=nil ) {
        imageReference = self.overlayImage.CGImage;
    }
    
    MKMapRect theMapRect = self.overlay.boundingMapRect;
    CGRect theRect = [self rectForMapRect:theMapRect];
    
    
    
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextTranslateCTM(context, 0.0, -theRect.size.height);
    
    CGContextDrawImage(context, theRect, backgroundImageReference);
    
    
    if(imageReference != nil) {
        CGContextDrawImage(context, theRect, imageReference);
    }
}

@end
