//
//  XYZPathViewAnnotation.m
//  MappedIn
//
//  Created by Ruofei Ma on 7/27/14.
//  Copyright (c) 2014 Ruofei Ma. All rights reserved.
//

#import "XYZPathViewAnnotation.h"

@implementation XYZPathViewAnnotation

@synthesize coordinate=_coordinate;
@synthesize title=_title;
-(id) initWithTitle:(NSString *) title AndCoordinate:(CLLocationCoordinate2D)coordinate
{
    self = [super init];
    _title = title;
    _coordinate = coordinate;
    return self;
}

@end
