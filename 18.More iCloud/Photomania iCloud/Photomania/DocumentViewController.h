//
//  DocumentViewController.h
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2011 Stanford University. All rights reserved.
//

#import <UIKit/UIKit.h>

// implement this protocol if you want DocumentViewController to be able to segue to you
@protocol DocumentViewControllerSegue <NSObject>
@property (nonatomic, strong) UIManagedDocument *document;
@end

@interface DocumentViewController : UITableViewController

@end
