//
//  DocumentViewController.m
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2011 Stanford University. All rights reserved.
//

#import "DocumentViewController.h"
#import <CoreData/CoreData.h>
#import "AskerViewController.h"

// 1. Add a UITableViewController of this class to the storyboard as the rootViewController of the UINavigationController
// Step 2 in cellForRowAtIndexPath:

// 4. Add Model "documents" which is an NSArray of NSURL
// 7. Add property for an iCloud metadata query called iCloudQuery

@interface DocumentViewController() <AskerViewControllerDelegate>
@property (nonatomic, strong) NSArray *documents;  // of NSURL
@property (nonatomic, strong) NSMetadataQuery *iCloudQuery;
@end

@implementation DocumentViewController

@synthesize documents = _documents;
@synthesize iCloudQuery = _iCloudQuery;

// 5. Implement documents setter to sort the array of urls (and only reload if actual changes)
// Step 6 below in UITableViewDataSource section

- (void)setDocuments:(NSArray *)documents
{
    documents = [documents sortedArrayUsingComparator:^NSComparisonResult(NSURL *url1, NSURL *url2) {
        return [[url1 lastPathComponent] caseInsensitiveCompare:[url2 lastPathComponent]];
    }];
    if (![_documents isEqualToArray:documents]) {
        _documents = documents;
        [self.tableView reloadData];
    }
}

#pragma mark - iCloud Query

// 8. Implement getter of iCloudQuery to lazily instantiate it (set it to find all Documents files in cloud)
// Step 9 in viewWillAppear:
// 10. Add ourself as observer for both initial iCloudQuery results and any updates that happen later
// Step 11 at the very bottom of this file, then step 12 in viewWillAppear: again.

// 36. Observe changes to the ubiquious key-value store

- (NSMetadataQuery *)iCloudQuery
{
    if (!_iCloudQuery) {
        _iCloudQuery = [[NSMetadataQuery alloc] init];
        _iCloudQuery.searchScopes = [NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope];
        _iCloudQuery.predicate = [NSPredicate predicateWithFormat:@"%K like '*'", NSMetadataItemFSNameKey];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(processCloudQueryResults:)
                                                     name:NSMetadataQueryDidFinishGatheringNotification
                                                   object:_iCloudQuery];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(processCloudQueryResults:)
                                                     name:NSMetadataQueryDidUpdateNotification
                                                   object:_iCloudQuery];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(ubiquitousKeyValueStoreChanged:)
                                                     name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                   object:[NSUbiquitousKeyValueStore defaultStore]];
        
    }
    return _iCloudQuery;
}

// 37. Reload the table whenever the ubiquitous key-value store changes
//     (Don't miss step 38!)

- (void)ubiquitousKeyValueStoreChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
}

// 15. Add a methods to get the URL for the entire cloud and for the Documents directory in the cloud
// 16. Click Add Entitlements in the Summary tab of the Targets section of the Project to enable iCloud for this app
//     (The application is now capable of displaying a list of documents in the cloud.)
// Step 17 is to segue (see Segue section below).

- (NSURL *)iCloudURL
{
    return [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
}

- (NSURL *)iCloudDocumentsURL
{
    return [[self iCloudURL] URLByAppendingPathComponent:@"Documents"];
}

// 14. Extract the file package that the passed url is contained in and return it

- (NSURL *)filePackageURLForCloudURL:(NSURL *)url
{
    if ([[url path] hasPrefix:[[self iCloudDocumentsURL] path]]) {
        NSArray *iCloudDocumentsURLComponents = [[self iCloudDocumentsURL] pathComponents];
        NSArray *urlComponents = [url pathComponents];
        if ([iCloudDocumentsURLComponents count] < [urlComponents count]) {
            urlComponents = [urlComponents subarrayWithRange:NSMakeRange(0, [iCloudDocumentsURLComponents count]+1)];
            url = [NSURL fileURLWithPathComponents:urlComponents];
        }
    }
    return url;
}

// 13. Handle changes to the iCloudQuery's results by iterating through and adding file packages to our Model

- (void)processCloudQueryResults:(NSNotification *)notification
{
    [self.iCloudQuery disableUpdates];
    NSMutableArray *documents = [NSMutableArray array];
    int resultCount = [self.iCloudQuery resultCount];
    for (int i = 0; i < resultCount; i++) {
        NSMetadataItem *item = [self.iCloudQuery resultAtIndex:i];
        NSURL *url = [item valueForAttribute:NSMetadataItemURLKey]; // this will be a file, not a directory
        url = [self filePackageURLForCloudURL:url];
        if (url && ![documents containsObject:url]) [documents addObject:url];  // in case a file package contains multiple files, don't add twice
    }
    self.documents = documents;
    [self.iCloudQuery enableUpdates];
}

#pragma mark - View Controller Lifecycle

// 9. Start up the iCloudQuery in viewWillAppear: if not already started
// 12. Turn iCloudQuery updates on and off as we appear/disappear from the screen

// 38. Since changes that WE make to the ubiquitous key-value store don't generate an NSNotification,
//      we are responsible for updating our UI when we change it.
//     We'll be cheap here and just reload ourselves each time we appear!
//     Probably would be a lot better to have our own internal NSNotification or some such.

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData]; // step 38: ugh!
    if (![self.iCloudQuery isStarted]) [self.iCloudQuery startQuery];
    [self.iCloudQuery enableUpdates];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.iCloudQuery disableUpdates];
    [super viewWillDisappear:animated];
}

#pragma mark - Autorotation

// 3. Autorotation YES in all orientations
// Back to the top for step 4.

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - UITableViewDataSource

// 6. Implement UITableViewDataSource number of rows in section and cellForRowAtIndexPath: using Model
// Back to top for step 7.

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.documents count];
}

// 2. Set the reuse identifier of the prototype to be "Document Cell" and set in cellForRowAtIndexPath:

// 33. Set the subtitle of the cell to whatever string is in the ubiquitious key-value store under the document name

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Document Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    NSURL *url = [self.documents objectAtIndex:indexPath.row];
    cell.textLabel.text = [url lastPathComponent];
    cell.detailTextLabel.text = [[NSUbiquitousKeyValueStore defaultStore] objectForKey:[url lastPathComponent]];
    
    return cell;
}

// Convenience method for logging errors returned through NSError

- (void)logError:(NSError *)error inMethod:(SEL)method
{
    NSString *errorDescription = error.localizedDescription;
    if (!errorDescription) errorDescription = @"???";
    NSString *errorFailureReason = error.localizedFailureReason;
    if (!errorFailureReason) errorFailureReason = @"???";
    if (error) NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(method), errorDescription, errorFailureReason);
}

// 25. Remove the url from the cloud in a coordinated manner (and in a separate thread)
//     (At this point, the application is capable of both adding and deleting documents from the cloud.)
// The next step is to be able to edit the documents themselves in PhotographersTableViewController (step 26).

// 34. Remove any ubiquitous key-value store entry for this document too (since we're deleting it)
//     Next step is to actually set the key-value store entry for a document.  Back in PhotographersTVC (step 35).

- (void)removeCloudURL:(NSURL *)url
{
    [[NSUbiquitousKeyValueStore defaultStore] removeObjectForKey:[url lastPathComponent]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        NSError *coordinationError;
        [coordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForDeleting error:&coordinationError byAccessor:^(NSURL *newURL) {
            NSError *removeError;
            [[NSFileManager defaultManager] removeItemAtURL:newURL error:&removeError];
            [self logError:removeError inMethod:_cmd]; // _cmd means "this method" (it's a SEL)
            // should also remove log files in CoreData directory in the cloud!
            // i.e., delete the files in [self iCloudCoreDataLogFilesURL]/[url lastPathComponent]
        }];
        [self logError:coordinationError inMethod:_cmd];
    });
}

// 24. Make documents deletable by removing them from the Model, and from the table, and from the cloud.
//     (Note that we access _documents directly here! Ack! That's bad form! We should probably find a better way.)

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSURL *url = [self.documents objectAtIndex:indexPath.row];
        NSMutableArray *documents = [self.documents mutableCopy];
        [documents removeObject:url];
        _documents = documents;  // Argh!
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self removeCloudURL:url];
    }   
}

#pragma mark - Segue

- (NSURL *)iCloudCoreDataLogFilesURL
{
    return [[self iCloudURL] URLByAppendingPathComponent:@"CoreData"];
}

// 19. Set persistentStoreOptions in the document before segueing
//     (Both the automatic schema-migration options and the "logging-based Core Data" options are set.)
//     (The application is now capable of showing the contents of documents in the cloud.)
// See step 20 in PhotographersTableViewController (adding a spinner to better see what's happening).

- (void)setPersistentStoreOptionsInDocument:(UIManagedDocument *)document
{
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    [options setObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
    [options setObject:[NSNumber numberWithBool:YES] forKey:NSInferMappingModelAutomaticallyOption];
    
    [options setObject:[document.fileURL lastPathComponent] forKey:NSPersistentStoreUbiquitousContentNameKey];
    [options setObject:[self iCloudCoreDataLogFilesURL] forKey:NSPersistentStoreUbiquitousContentURLKey];
    
    document.persistentStoreOptions = options;
}

// 17. In the storyboard, create a Push segue called "Show Document" from this VC to our old Photomania VC chain
// 18. Prepare for segue by getting the URL at the segued-from row, creating a document, and setting it in destination
//     (Note the generic mechanism we use to get the segued-from indexPath.)
//     (Note how we use a protocol (DocumentViewControllerSegue) to generically segue to any destination.)

// 21. Add a + button to the storyboard which segues Modally to an AskerViewController (get this from KitchenSink)
//     (Note, you will have to add the questionLabel and answerTextFields to the AskerViewController scene.)
// 22. Modify prepare for segue to set ourself as the delegate and set the question of the AskerViewController.

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"New Document"]) {
        AskerViewController *asker = (AskerViewController *)segue.destinationViewController;
        asker.delegate = self;
        asker.question = @"New document name:";
    } else {
        NSIndexPath *indexPath = nil;
        if ([sender isKindOfClass:[NSIndexPath class]]) {
            indexPath = (NSIndexPath *)sender;
        } else if ([sender isKindOfClass:[UITableViewCell class]]) {
            indexPath = [self.tableView indexPathForCell:sender];
        } else if (!sender || (sender == self) || (sender == self.tableView)) {
            indexPath = [self.tableView indexPathForSelectedRow];
        }
        if (indexPath && [segue.identifier isEqualToString:@"Show Document"]) {
            if ([segue.destinationViewController conformsToProtocol:@protocol(DocumentViewControllerSegue)]) {
                NSURL *url = [self.documents objectAtIndex:indexPath.row];
                [segue.destinationViewController setTitle:[url lastPathComponent]];
                UIManagedDocument *document = [[UIManagedDocument alloc] initWithFileURL:url];
                [self setPersistentStoreOptionsInDocument:document]; // make cloud Core Data documents efficient!
                [segue.destinationViewController setDocument:document];
            }
        }
    }
}

// 23. Implement AVC delegate to create an NSURL in the cloud with the chosen name, add it to our Model,
//      then segue to create it (and we must dismiss the AVC too)
//     (It is now possible to create documents in the cloud using the application!)

- (void)askerViewController:(AskerViewController *)sender
             didAskQuestion:(NSString *)question
               andGotAnswer:(NSString *)answer
{
    NSURL *url = [[self iCloudDocumentsURL] URLByAppendingPathComponent:answer];
    NSMutableArray *documents = [self.documents mutableCopy];
    [documents addObject:url];
    self.documents = documents;
    int row = [self.documents indexOfObject:url];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    [self performSegueWithIdentifier:@"Show Document" sender:indexPath];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Dealloc

// 11. Remove ourself as an observer (of anything) when we leave the heap

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

