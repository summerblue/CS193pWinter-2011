//
//  CalculatorGraphViewController.m
//  Calculator
//
//  Created by CS193p Instructor.
//  Copyright (c) 2011 Stanford University. All rights reserved.
//

#import "CalculatorGraphViewController.h"
#import "CalculatorBrain.h"
#import "CalculatorProgramsTableViewController.h"

@interface CalculatorGraphViewController() <CalculatorProgramsTableViewControllerDelegate>
@property (nonatomic, strong) UIPopoverController *popoverController; // added after lecture to prevent multiple popovers
@end

@implementation CalculatorGraphViewController

@synthesize popoverController;

#define FAVORITES_KEY @"CalculatorGraphViewController.Favorites"

- (IBAction)addToFavorites:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *favorites = [[defaults objectForKey:FAVORITES_KEY] mutableCopy];
    if (!favorites) favorites = [NSMutableArray array];
    [favorites addObject:self.calculatorProgram];
    [defaults setObject:favorites forKey:FAVORITES_KEY];
    [defaults synchronize];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Favorite Graphs"]) {
        // this if statement added after lecture to prevent multiple popovers
        // appearing if the user keeps touching the Favorites button over and over
        // simply remove the last one we put up each time we segue to a new one
        if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
            UIStoryboardPopoverSegue *popoverSegue = (UIStoryboardPopoverSegue *)segue;
            [self.popoverController dismissPopoverAnimated:YES];
            self.popoverController = popoverSegue.popoverController; // might want to be popover's delegate and self.popoverController = nil on dismiss?
        }
        NSArray *programs = [[NSUserDefaults standardUserDefaults] objectForKey:FAVORITES_KEY];
        [segue.destinationViewController setPrograms:programs];
        [segue.destinationViewController setDelegate:self];
    }
}

- (void)calculatorProgramsTableViewController:(CalculatorProgramsTableViewController *)sender
                                 choseProgram:(id)program
{
    self.calculatorProgram = program;
    // if you wanted to close the popover when a graph was selected
    // you could uncomment the following line
    // you'd probably want to set self.popoverController = nil after doing so
    // [self.popoverController dismissPopoverAnimated:YES];
    [self.navigationController popViewControllerAnimated:YES]; // added after lecture to support iPhone
}

// added after lecture to support deletion from the table
// deletes the given program from NSUserDefaults (including duplicates)
// then resets the Model of the sender

- (void)calculatorProgramsTableViewController:(CalculatorProgramsTableViewController *)sender
                               deletedProgram:(id)program
{
    NSString *deletedProgramDescription = [CalculatorBrain descriptionOfProgram:program];
    NSMutableArray *favorites = [NSMutableArray array];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (id program in [defaults objectForKey:FAVORITES_KEY]) {
        if (![[CalculatorBrain descriptionOfProgram:program] isEqualToString:deletedProgramDescription]) {
            [favorites addObject:program];
        }
    }
    [defaults setObject:favorites forKey:FAVORITES_KEY];
    [defaults synchronize];
    sender.programs = favorites;
}

@end
