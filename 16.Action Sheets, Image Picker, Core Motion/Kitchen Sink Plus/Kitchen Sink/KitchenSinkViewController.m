//
//  KitchenSinkViewController.m
//  Kitchen Sink
//
//  Created by CS193p Instructor.
//  Copyright (c) 2011 Stanford University. All rights reserved.
//

#import "KitchenSinkViewController.h"
#import "AskerViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <CoreMotion/CoreMotion.h>
#import "CMMotionManager+Shared.h"

@interface KitchenSinkViewController() <AskerViewControllerDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIView *kitchenSink;
@property (weak, nonatomic) NSTimer *drainTimer;
@property (weak, nonatomic) UIActionSheet *actionSheet;
@property (nonatomic) BOOL faucetIsOn;
@property (nonatomic, strong) UIPopoverController *imagePopover;
@end

@implementation KitchenSinkViewController

@synthesize kitchenSink = _kitchenSink;
@synthesize drainTimer = _drainTimer;
@synthesize actionSheet = _actionSheet;
@synthesize faucetIsOn = _faucetIsOn;
@synthesize imagePopover = _imagePopover;

#pragma mark - Utility Methods

- (void)setRandomLocationForView:(UIView *)view
{
    CGRect sinkBounds = CGRectInset(self.kitchenSink.bounds, view.frame.size.width/2, view.frame.size.height/2);
    CGFloat x = arc4random() % (int)sinkBounds.size.width + view.frame.size.width/2;
    CGFloat y = arc4random() % (int)sinkBounds.size.height + view.frame.size.height/2;
    view.center = CGPointMake(x, y);
}

- (void)addLabel:(NSString *)text
{
    UILabel *label = [[UILabel alloc] init];
    static NSDictionary *colors = nil;
    if (!colors) colors = [NSDictionary dictionaryWithObjectsAndKeys:
                           [UIColor blueColor], @"Blue",
                           [UIColor greenColor], @"Green",
                           [UIColor orangeColor], @"Orange",
                           [UIColor redColor], @"Red",
                           [UIColor purpleColor], @"Purple",
                           [UIColor brownColor], @"Brown",
                           nil];
    if (![text length]) {
        NSString *color = [[colors allKeys] objectAtIndex:arc4random()%[colors count]];
        text = color;
        label.textColor = [colors objectForKey:color];
    }
    label.text = text;
    label.font = [UIFont systemFontOfSize:48.0];
    label.backgroundColor = [UIColor clearColor];
    [label sizeToFit];
    [self setRandomLocationForView:label];
    [self.kitchenSink addSubview:label];
}

#pragma mark - Modal View Controllers

// prepare for the modal view controller buttons in the toolbar 

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier hasPrefix:@"Create Label"]) {
        AskerViewController *asker = (AskerViewController *)segue.destinationViewController;
        asker.question = @"What do you want your label to say?";
        asker.answer = @"Label Text";
        asker.delegate = self;
    }
}

- (void)askerViewController:(AskerViewController *)sender didAskQuestion:(NSString *)question andGotAnswer:(NSString *)answer
{
    [self addLabel:answer];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - View Animation

- (IBAction)tap:(UITapGestureRecognizer *)gesture
{
    CGPoint tapLocation = [gesture locationInView:self.kitchenSink];
    for (UIView *view in self.kitchenSink.subviews) {
        if (CGRectContainsPoint(view.frame, tapLocation)) {
            [UIView animateWithDuration:4.0 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [self setRandomLocationForView:view];
                view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.99, 0.99);
            } completion:^(BOOL finished) {
                view.transform = CGAffineTransformIdentity;
            }];
        }
    }
}

#define DRAIN_DURATION 3.0

- (void)drain
{
    for (UIView *view in self.kitchenSink.subviews) {
        CGAffineTransform transform = view.transform;
        if (CGAffineTransformIsIdentity(transform)) {
            UIViewAnimationOptions options = UIViewAnimationOptionCurveLinear;
            [UIView animateWithDuration:DRAIN_DURATION/3 delay:0 options:options animations:^{
                view.transform = CGAffineTransformRotate(CGAffineTransformScale(transform, 0.7, 0.7), 2*M_PI/3);
            } completion:^(BOOL finished) {
                if (finished) {
                    [UIView animateWithDuration:DRAIN_DURATION/3 delay:0 options:options animations:^{
                        view.transform = CGAffineTransformRotate(CGAffineTransformScale(transform, 0.4, 0.4), -2*M_PI/3);
                    } completion:^(BOOL finished) {
                        if (finished) {
                            [UIView animateWithDuration:DRAIN_DURATION/3 delay:0 options:options animations:^{
                                view.transform = CGAffineTransformScale(transform, 0.1, 0.1);
                            } completion:^(BOOL finished) {
                                if (finished) [view removeFromSuperview];
                            }];
                        }
                    }];
                }
            }];
        }
    }
}

- (void)drain:(NSTimer *)timer
{
    [self drain];
}

- (void)startDraining
{
    self.drainTimer = [NSTimer scheduledTimerWithTimeInterval:DRAIN_DURATION/3
                                                       target:self
                                                     selector:@selector(drain:)
                                                     userInfo:nil
                                                      repeats:YES];
}

- (void)stopDraining
{
    [self.drainTimer invalidate];
}

#pragma mark - Dripping Faucet

#define FAUCET_INTERVAL 2.0

- (void)drip
{
    if (self.kitchenSink.window) {
        [self addLabel:nil];
        [self performSelector:@selector(drip) withObject:nil afterDelay:FAUCET_INTERVAL];
        self.faucetIsOn = YES;
    } else {
        self.faucetIsOn = NO;
    }
}

#pragma mark - Control Sink Action Sheet

#define STOP_DRAIN @"Stopper Drain"
#define UNSTOP_DRAIN @"Unstopper Drain"

#define TURN_FAUCET_ON @"Turn Faucet On"
#define TURN_FAUCET_OFF @"Turn Faucet Off"

- (IBAction)controlSink:(UIBarButtonItem *)sender
{
    if (self.actionSheet) {
        // do nothing
    } else {
        NSString *drainButton = self.drainTimer ? STOP_DRAIN : UNSTOP_DRAIN;
        NSString *faucetButton = self.faucetIsOn ? TURN_FAUCET_OFF : TURN_FAUCET_ON;
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Sink Controls" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Empty Sink" otherButtonTitles:drainButton, faucetButton, nil];
        [actionSheet showFromBarButtonItem:sender animated:YES];
        self.actionSheet = actionSheet;
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *choice = [actionSheet buttonTitleAtIndex:buttonIndex];
    if (buttonIndex == [actionSheet destructiveButtonIndex]) {
        [self.kitchenSink.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    } else if ([choice isEqualToString:STOP_DRAIN]) {
        [self stopDraining];
    } else if ([choice isEqualToString:UNSTOP_DRAIN]) {
        [self startDraining];
    } else if ([choice isEqualToString:TURN_FAUCET_ON]) {
        [self drip];
    } else if ([choice isEqualToString:TURN_FAUCET_OFF]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(drip) object:nil];
        self.faucetIsOn = NO;
    }
}

#pragma mark - UIImagePickerController

#define IMAGE_PICKER_IN_POPOVER YES

- (IBAction)addImage:(UIBarButtonItem *)sender
{
    if (!self.imagePopover && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        if ([mediaTypes containsObject:(NSString *)kUTTypeImage]) {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
            picker.allowsEditing = YES;
            if (IMAGE_PICKER_IN_POPOVER) {
                self.imagePopover = [[UIPopoverController alloc] initWithContentViewController:picker];
                [self.imagePopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            } else {
                [self presentModalViewController:picker animated:YES];
            }
        }
    }
}

- (void)dismissImagePicker
{
    [self.imagePopover dismissPopoverAnimated:YES];
    self.imagePopover = nil;
    [self dismissModalViewControllerAnimated:YES];
}

#define MAX_IMAGE_WIDTH 200

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image) image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (image) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        CGRect frame = imageView.frame;
        while (frame.size.width > MAX_IMAGE_WIDTH) {
            frame.size.width /= 2;
            frame.size.height /= 2;
        }
        imageView.frame = frame;
        [self setRandomLocationForView:imageView];
        [self.kitchenSink addSubview:imageView];
    }
    [self dismissImagePicker];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissImagePicker];
}

#pragma mark - Drift (Core Motion)

#define DRIFT_HZ 50.0
#define DRIFT_RATE 20

- (void)startDrift
{
    CMMotionManager *manager = [CMMotionManager sharedMotionManager];
    if ([manager isAccelerometerAvailable]) {
        [manager setAccelerometerUpdateInterval:1.0/DRIFT_HZ];
        [manager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *data, NSError *error) {
            for (UIView *view in self.kitchenSink.subviews) {
                CGPoint center = view.center;
                center.x += data.acceleration.x * DRIFT_RATE;
                center.y -= data.acceleration.y * DRIFT_RATE;
                view.center = center;
                if (!CGRectContainsRect(self.kitchenSink.bounds, view.frame) && !CGRectIntersectsRect(self.kitchenSink.bounds, view.frame)) {
                    [view removeFromSuperview];
                }
            }
        }];
    }
}

- (void)stopDrift
{
    [[CMMotionManager sharedMotionManager] stopAccelerometerUpdates];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startDraining];
    [self startDrift];
    [self drip];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopDrift];
    [self stopDraining];
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

@end
