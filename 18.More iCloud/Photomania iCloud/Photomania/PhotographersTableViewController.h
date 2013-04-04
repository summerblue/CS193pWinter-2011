//
//  PhotographersTableViewController.h
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2011 Stanford University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataTableViewController.h"

// inherits from CoreDataTableViewController to get an NSFetchedResultsController @property
// and to get all the copy/pasted code for the NSFetchedResultsController delegate from the documentation

@interface PhotographersTableViewController : CoreDataTableViewController

@property (nonatomic, strong) UIManagedDocument *photoDatabase;  // Model is a Core Data database of photos

@end
