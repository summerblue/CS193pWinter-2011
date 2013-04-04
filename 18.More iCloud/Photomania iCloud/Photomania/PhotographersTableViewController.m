//
//  PhotographersTableViewController.m
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2011 Stanford University. All rights reserved.
//

#import "PhotographersTableViewController.h"
#import "FlickrFetcher.h"
#import "Photographer.h"
#import "Photo+Flickr.h"
#import "DocumentViewController.h"

@interface PhotographersTableViewController() <DocumentViewControllerSegue>
@end

@implementation PhotographersTableViewController

@synthesize photoDatabase = _photoDatabase;

// implement the DocumentViewController Segue protocol

- (UIManagedDocument *)document
{
    return self.photoDatabase;
}

- (void)setDocument:(UIManagedDocument *)document
{
    self.photoDatabase = document;
}

// 20. Add start and stop spinner methods and call them in appropriate spots (search "spinner" lower in the file).

- (void)startSpinner:(NSString *)activity
{
    self.navigationItem.title = activity;
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [spinner startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
}

- (void)stopSpinner
{
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.title = self.title;
}

- (void)setupFetchedResultsController // attaches an NSFetchRequest to this UITableViewController
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photographer"];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
    // no predicate because we want ALL the Photographers
                             
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:self.photoDatabase.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

// 35. Add a save method which updates the ubiquitous key-value store to show number of photographers

// Next step is to be sure we see changes to the ubiquitous key-value store from other devices.
// Go back to DocumentViewController (step 36).

- (void)save
{
    [self.photoDatabase saveToURL:self.photoDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        if (success) {
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photographer"];
            int photographerCount = [self.photoDatabase.managedObjectContext countForFetchRequest:request error:NULL];
            NSString *documentNote = [NSString stringWithFormat:@"%d photographer(s)", photographerCount];
            NSString *documentNoteKey = [self.photoDatabase.fileURL lastPathComponent];
            [[NSUbiquitousKeyValueStore defaultStore] setObject:documentNote forKey:documentNoteKey];
            [[NSUbiquitousKeyValueStore defaultStore] synchronize];
        }
    }];
}

- (void)fetchFlickrDataIntoDocument:(UIManagedDocument *)document
{
    [self startSpinner:@"Flickr ..."];
    dispatch_queue_t fetchQ = dispatch_queue_create("Flickr fetcher", NULL);
    dispatch_async(fetchQ, ^{
        NSArray *photos = [FlickrFetcher recentGeoreferencedPhotos];
        [document.managedObjectContext performBlock:^{ // perform in the NSMOC's safe thread (main thread)
            for (NSDictionary *flickrInfo in photos) {
                [Photo photoWithFlickrInfo:flickrInfo inManagedObjectContext:document.managedObjectContext];
                // table will automatically update due to NSFetchedResultsController's observing of the NSMOC
            }
            [self save]; // see step 35
        }];
    });
    dispatch_release(fetchQ);
}

- (void)useDocument
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.photoDatabase.fileURL path]]) {
        // does not exist on disk, so create it
        [self.photoDatabase saveToURL:self.photoDatabase.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            [self setupFetchedResultsController];
            [self fetchFlickrDataIntoDocument:self.photoDatabase];
            
        }];
    } else if (self.photoDatabase.documentState == UIDocumentStateClosed) {
        // exists on disk, but we need to open it
        [self.photoDatabase openWithCompletionHandler:^(BOOL success) {
            [self setupFetchedResultsController];
        }];
    } else if (self.photoDatabase.documentState == UIDocumentStateNormal) {
        // already open and ready to use
        [self setupFetchedResultsController];
    }
}

// 27. Now we need to watch for this document being changed on other devices via NSNotifications
// Step 28 is a quick trip to the bottom to remove ourself as an observer on dealloc.

// 30. Let's also watch the document state so that we can see if we have version conflicts

- (void)setPhotoDatabase:(UIManagedDocument *)photoDatabase
{
    if (_photoDatabase != photoDatabase) {
        [[NSNotificationCenter defaultCenter] removeObserver:self  // remove observing of old document (if any)
                                                        name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                      object:_photoDatabase.managedObjectContext.persistentStoreCoordinator];
        [[NSNotificationCenter defaultCenter] removeObserver:self  // remove observing of old document (if any)
                                                        name:UIDocumentStateChangedNotification
                                                      object:_photoDatabase];
        _photoDatabase = photoDatabase;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(documentContentsChanged:)
                                                     name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                   object:_photoDatabase.managedObjectContext.persistentStoreCoordinator];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(documentStateChanged:)
                                                     name:UIDocumentStateChangedNotification
                                                   object:_photoDatabase];
        if ([[NSFileManager defaultManager] isUbiquitousItemAtURL:photoDatabase.fileURL]) {
            [self startSpinner:@"iCloud ..."];
        }
        [self useDocument];
    }
}

// 29. Merge changes from other documents when we get the NSNotification that the document has changed
//     (Now the application can delete photographers and will see when other devices delete photographers.)

- (void)documentContentsChanged:(NSNotification *)notification
{
    [self.photoDatabase.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
}

// 31. React to document state changing to "in conflict" by just taking the current (most recent) version.  Delete other versions.
// 32. Could also react to saving errors here.

// Next step is to add a subtitle on documents saying how many photographers are in that document.
// Go to step 33 back in DocumentViewController.

- (void)documentStateChanged:(NSNotification *)notification
{
    if (self.photoDatabase.documentState & UIDocumentStateInConflict) {
        // look at the changes in notification's userInfo and resolve conflicts
        //   or just take the latest version (by doing nothing)
        // in any case (even if you do nothing and take latest version),
        //   mark all old versions resolved ...
        NSArray *conflictingVersions = [NSFileVersion unresolvedConflictVersionsOfItemAtURL:self.photoDatabase.fileURL];
        for (NSFileVersion *version in conflictingVersions) {
            version.resolved = YES;
        }
        // ... and remove the old version files in a separate thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            NSError *error;
            [coordinator coordinateWritingItemAtURL:self.photoDatabase.fileURL options:NSFileCoordinatorWritingForDeleting error:&error byAccessor:^(NSURL *newURL) {
                [NSFileVersion removeOtherVersionsOfItemAtURL:self.photoDatabase.fileURL error:NULL];
            }];
            if (error) NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error.localizedDescription, error.localizedFailureReason);
        });
    } else if (self.photoDatabase.documentState & UIDocumentStateSavingError) {
        // try again?
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.photoDatabase) {  // for demo purposes, we'll create a default database if none is set
        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        url = [url URLByAppendingPathComponent:@"Default Photo Database"];
        // url is now "<Documents Directory>/Default Photo Database"
        self.photoDatabase = [[UIManagedDocument alloc] initWithFileURL:url]; // setter will create this for us on disk
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Photographer Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [self stopSpinner];
    
    // ask NSFetchedResultsController for the NSMO at the row in question
    Photographer *photographer = [self.fetchedResultsController objectAtIndexPath:indexPath];
    // Then configure the cell using it ...
    cell.textLabel.text = photographer.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d photos", [photographer.photos count]];
    
    return cell;
}

// 26. Now make the document itself editable (i.e. allow deletion of Photographers).
//     (No need to update the table view here after modifying our Model because NSFRC will handle that.)
//     (Note that we do not allow deletion if the EditingDisabled in the document state.)
// Step 27 is to observe deletions in other documents.  See setPhotoDatabase: above.

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!(self.photoDatabase.documentState & UIDocumentStateEditingDisabled)) {
        Photographer *photographer = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [self.fetchedResultsController.managedObjectContext deleteObject:photographer];
        [self save]; // see step 35
    } else {
        // notify user that deletion is not currently possible? (probably not)
        // we probably also should return NO from canDeleteRowAtIndexPath: whenever editing is disabled
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    Photographer *photographer = [self.fetchedResultsController objectAtIndexPath:indexPath];
    // be somewhat generic here (slightly advanced usage)
    // we'll segue to ANY view controller that has a photographer @property
    if ([segue.destinationViewController respondsToSelector:@selector(setPhotographer:)]) {
        // use performSelector:withObject: to send without compiler checking
        // (which is acceptable here because we used introspection to be sure this is okay)
        [segue.destinationViewController performSelector:@selector(setPhotographer:) withObject:photographer];
    }
}

// 28. Remove self as observer

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
