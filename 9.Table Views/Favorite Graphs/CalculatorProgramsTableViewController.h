//
//  CalculatorProgramsTableViewController.h
//  Calculator
//
//  Created by CS193p Instructor.
//  Copyright (c) 2011 Stanford University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CalculatorProgramsTableViewController;

@protocol CalculatorProgramsTableViewControllerDelegate
@optional
- (void)calculatorProgramsTableViewController:(CalculatorProgramsTableViewController *)sender
                                 choseProgram:(id)program;
@end

@interface CalculatorProgramsTableViewController : UITableViewController
@property (nonatomic, strong) NSArray *programs; // of CalculatorBrain programs
@property (nonatomic, weak) id <CalculatorProgramsTableViewControllerDelegate> delegate;
@end
