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
@end

@implementation CalculatorGraphViewController

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
        NSArray *programs = [[NSUserDefaults standardUserDefaults] objectForKey:FAVORITES_KEY];
        [segue.destinationViewController setPrograms:programs];
        [segue.destinationViewController setDelegate:self];
    }
}

- (void)calculatorProgramsTableViewController:(CalculatorProgramsTableViewController *)sender choseProgram:(id)program
{
    self.calculatorProgram = program;
}

@end
