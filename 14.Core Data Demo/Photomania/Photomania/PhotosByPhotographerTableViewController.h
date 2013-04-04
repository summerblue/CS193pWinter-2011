//
//  PhotosByPhotographerTableViewController.h
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2011 Stanford University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photographer.h"
#import "CoreDataTableViewController.h"

// inherits from CoreDataTableViewController to get an NSFetchedResultsController @property
// and to get all the copy/pasted code for the NSFetchedResultsController delegate from the documentation

@interface PhotosByPhotographerTableViewController : CoreDataTableViewController

// 15. Added public Model (the photographer whose photos we want to show)

@property (nonatomic, strong) Photographer *photographer;

@end
