//
//  HappinessViewController.m
//  Happiness
//
//  Created by CS193p Instructor.
//  Copyright (c) 2011 Stanford University. All rights reserved.
//

#import "HappinessViewController.h"
#import "FaceView.h"

@interface HappinessViewController() <FaceViewDataSource>
@property (nonatomic, weak) IBOutlet FaceView *faceView;
@end

@implementation HappinessViewController

@synthesize happiness = _happiness;
@synthesize faceView = _faceView;

- (void)setHappiness:(int)happiness
{
    _happiness = happiness;
    [self.faceView setNeedsDisplay]; // any time our Model changes, redraw our View
}

- (void)setFaceView:(FaceView *)faceView
{
    _faceView = faceView;
    // enable pinch gestures in the FaceView using its pinch: handler
    [self.faceView addGestureRecognizer:[[UIPinchGestureRecognizer alloc] initWithTarget:self.faceView action:@selector(pinch:)]];
    [self.faceView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleHappinessGesture:)]];  // gesture to modify our Model
    self.faceView.dataSource = self;
}

- (void)handleHappinessGesture:(UIPanGestureRecognizer *)gesture
{
    if ((gesture.state == UIGestureRecognizerStateChanged) ||
        (gesture.state == UIGestureRecognizerStateEnded)) {
        CGPoint translation = [gesture translationInView:self.faceView];
        self.happiness -= translation.y / 2;
        [gesture setTranslation:CGPointZero inView:self.faceView];
    }
}

- (float)smileForFaceView:(FaceView *)sender
{
    return (self.happiness - 50) / 50.0; // translate Model for View
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES; // support all orientations
}

@end
