//
//  XYZPathViewAnnotation.h
//  MappedIn
//
//  Created by Ruofei Ma on 7/27/14.
//  Copyright (c) 2014 Ruofei Ma. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface XYZPathViewAnnotation : NSObject <MKAnnotation>

@property (nonatomic,copy) NSString *title;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
-(id) initWithTitle:(NSString *) title AndCoordinate:(CLLocationCoordinate2D)coordinate;

@end
