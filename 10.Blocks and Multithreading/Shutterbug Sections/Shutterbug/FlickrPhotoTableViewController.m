//
//  FlickrPhotoTableViewController.m
//  Shutterbug
//
//  Created by CS193p Instructor.
//  Copyright (c) 2011 Stanford University. All rights reserved.
//

#import "FlickrPhotoTableViewController.h"
#import "FlickrFetcher.h"

@interface FlickrPhotoTableViewController()
// keys: photographer NSString, values: NSArray of photo NSDictionary
@property (nonatomic, strong) NSDictionary *photosByPhotographer;
@end

@implementation FlickrPhotoTableViewController

@synthesize photos = _photos;
@synthesize photosByPhotographer = _photosByPhotographer;

- (void)updatePhotosByPhotographer
{
    NSMutableDictionary *photosByPhotographer = [NSMutableDictionary dictionary];
    for (NSDictionary *photo in self.photos) {
        NSString *photographer = [photo objectForKey:FLICKR_PHOTO_OWNER];
        NSMutableArray *photos = [photosByPhotographer objectForKey:photographer];
        if (!photos) {
            photos = [NSMutableArray array];
            [photosByPhotographer setObject:photos forKey:photographer];
        }
        [photos addObject:photo];
    }
    self.photosByPhotographer = photosByPhotographer;
}

- (void)setPhotos:(NSArray *)photos
{
    if (_photos != photos) {
        _photos = photos;
        // Model changed, so update our View (the table)
        [self updatePhotosByPhotographer];
        [self.tableView reloadData];
    }
}

- (IBAction)refresh:(id)sender
{
    // might want to use introspection to be sure sender is UIBarButtonItem
    // (if not, it can skip the spinner)
    // that way this method can be a little more generic
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [spinner startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("flickr downloader", NULL);
    dispatch_async(downloadQueue, ^{
        NSArray *photos = [FlickrFetcher recentGeoreferencedPhotos];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.navigationItem.rightBarButtonItem = sender;
            self.photos = photos;
        });
    });
    dispatch_release(downloadQueue);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - UITableViewDataSource

- (NSString *)photographerForSection:(NSInteger)section
{
    return [[self.photosByPhotographer allKeys] objectAtIndex:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self photographerForSection:section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.photosByPhotographer count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // return [self.photos count];
    NSString *photographer = [self photographerForSection:section];
    NSArray *photosByPhotographer = [self.photosByPhotographer objectForKey:photographer];
    return [photosByPhotographer count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Flickr Photo";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    // NSDictionary *photo = [self.photos objectAtIndex:indexPath.row];
    NSString *photographer = [self photographerForSection:indexPath.section];
    NSArray *photosByPhotographer = [self.photosByPhotographer objectForKey:photographer];
    NSDictionary *photo = [photosByPhotographer objectAtIndex:indexPath.row];
    cell.textLabel.text = [photo objectForKey:FLICKR_PHOTO_TITLE];
    cell.detailTextLabel.text = [photo objectForKey:FLICKR_PHOTO_OWNER];
    
    return cell;
}

@end
