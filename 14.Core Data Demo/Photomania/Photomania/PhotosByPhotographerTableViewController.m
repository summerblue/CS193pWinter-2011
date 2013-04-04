//
//  PhotosByPhotographerTableViewController.m
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2011 Stanford University. All rights reserved.
//

#import "PhotosByPhotographerTableViewController.h"
#import "Photo.h"
#import "ImageViewController.h"

@implementation PhotosByPhotographerTableViewController

@synthesize photographer = _photographer;

// 17. Create a fetch request that looks for Photographers with the given name and hook it up through NSFRC
// (we inherited the code to integrate with NSFRC from CoreDataTableViewController)

- (void)setupFetchedResultsController // attaches an NSFetchRequest to this UITableViewController
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"title"
                                                                                     ascending:YES
                                                                                      selector:@selector(localizedCaseInsensitiveCompare:)]];
    request.predicate = [NSPredicate predicateWithFormat:@"whoTook.name = %@", self.photographer.name];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:self.photographer.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

// 16. Update our title and set up our NSFRC when our Model is set

- (void)setPhotographer:(Photographer *)photographer
{
    _photographer = photographer;
    self.title = photographer.name;
    [self setupFetchedResultsController];
}

// 18. Load up our cell using the NSManagedObject retrieved using NSFRC's objectAtIndexPath:
// (back to PhotographersTableViewController.m for next step, segueing)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Photo Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath]; // ask NSFRC for the NSMO at the row in question
    cell.textLabel.text = photo.title;
    cell.detailTextLabel.text = photo.subtitle;
    
    return cell;
}

// 20. Add segue to show the photo (ADDED AFTER LECTURE)

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath]; // ask NSFRC for the NSMO at the row in question
    if ([segue.identifier isEqualToString:@"Show Photo"]) {
        [segue.destinationViewController setImageURL:[NSURL URLWithString:photo.imageURL]];
        [segue.destinationViewController setTitle:photo.title];
    }
}

@end
