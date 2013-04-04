//
//  CMMotionManager+Shared.h
//  Kitchen Sink
//
//  Created by CS193p Instructor on 11/18/11.
//  Copyright (c) 2011 Stanford University. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>

@interface CMMotionManager (Shared)

+ (CMMotionManager *)sharedMotionManager;

@end
