//
//  CMMotionManager+Shared.m
//  Kitchen Sink
//
//  Created by CS193p Instructor on 11/18/11.
//  Copyright (c) 2011 Stanford University. All rights reserved.
//

#import "CMMotionManager+Shared.h"

@implementation CMMotionManager (Shared)

+ (CMMotionManager *)sharedMotionManager
{
    static CMMotionManager *shared = nil;
    if (!shared) shared = [[CMMotionManager alloc] init];
    return shared;
}

@end
