//
//  FaceView.h
//  Happiness
//
//  Created by CS193p Instructor.
//  Copyright (c) 2011 Stanford University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FaceView;  // forward declaration for use in @protocol

@protocol FaceViewDataSource
- (float)smileForFaceView:(FaceView *)sender;
@end

@interface FaceView : UIView

@property (nonatomic) CGFloat scale;

- (void)pinch:(UIPinchGestureRecognizer *)gesture;  // resizes the face

// set this property to whatever object will provide this View's data
// usually a Controller using a FaceView in its View
@property (nonatomic, weak) IBOutlet id <FaceViewDataSource> dataSource;

@end
