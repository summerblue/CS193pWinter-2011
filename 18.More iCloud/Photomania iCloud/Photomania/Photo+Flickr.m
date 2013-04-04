//
//  Photo+Flickr.m
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2011 Stanford University. All rights reserved.
//

#import "Photo+Flickr.h"
#import "FlickrFetcher.h"
#import "Photographer+Create.h"

@implementation Photo (Flickr)

// 9. Query the database to see if this Flickr dictionary's unique id is already there
// 10. If error, handle it, else if not in database insert it, else just return the photo we found
// 11. Create a category to Photographer to add a factory method and use it to set whoTook
// (then back to PhotographersTableViewController)

+ (Photo *)photoWithFlickrInfo:(NSDictionary *)flickrInfo
        inManagedObjectContext:(NSManagedObjectContext *)context
{
    Photo *photo = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.predicate = [NSPredicate predicateWithFormat:@"unique = %@", [flickrInfo objectForKey:FLICKR_PHOTO_ID]];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || ([matches count] > 1)) {
        // handle error
    } else if ([matches count] == 0) {
        photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:context];
        photo.unique = [flickrInfo objectForKey:FLICKR_PHOTO_ID];
        photo.title = [flickrInfo objectForKey:FLICKR_PHOTO_TITLE];
        photo.subtitle = [flickrInfo valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
        photo.imageURL = [[FlickrFetcher urlForPhoto:flickrInfo format:FlickrPhotoFormatLarge] absoluteString];
        photo.whoTook = [Photographer photographerWithName:[flickrInfo objectForKey:FLICKR_PHOTO_OWNER] inManagedObjectContext:context];
    } else {
        photo = [matches lastObject];
    }
    
    return photo;
}

@end
