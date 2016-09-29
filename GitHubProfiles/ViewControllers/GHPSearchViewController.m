//
//  SearchViewController.m
//  GitHubProfiles
//
//  Created by Grzegorz Maciak on 22.09.2016.
//  Copyright © 2016 Grzegorz Maciak. All rights reserved.
//

#import "GHPSearchViewController.h"
#import "GHPMasterViewController.h"
#import "AppDelegate.h"

@interface GHPSearchViewController ()

@end

@implementation GHPSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Search";
    
    GHPMasterViewController *masterController = [[self childViewControllers] firstObject];
    
    self.searchBar.delegate = masterController;
    
    UIBarButtonItem *loginButton = [[UIBarButtonItem alloc] initWithTitle:@"Login" style:UIBarButtonItemStylePlain target:[GHPWebServicesManager sharedInstance] action:@selector(login:)];
    self.navigationItem.rightBarButtonItem = loginButton;
}

@end
