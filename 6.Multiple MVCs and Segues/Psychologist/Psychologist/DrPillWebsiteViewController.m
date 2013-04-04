//
//  DrPillWebsiteViewController.m
//  Psychologist
//
//  Created by CS193p Instructor.
//  Copyright (c) 2011 Stanford University. All rights reserved.
//

#import "DrPillWebsiteViewController.h"

@interface DrPillWebsiteViewController()
@property (nonatomic, weak) IBOutlet UIWebView *webView;
@end

@implementation DrPillWebsiteViewController

@synthesize webView = _webView;

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://cs193p.stanford.edu"]]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
