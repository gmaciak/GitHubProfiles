//
//  SearchViewController.m
//  GitHubProfiles
//
//  Created by Grzegorz Maciak on 22.09.2016.
//  Copyright © 2016 Grzegorz Maciak. All rights reserved.
//

#import "SearchViewController.h"
#import "MasterViewController.h"
#import "AppDelegate.h"

@interface SearchViewController ()

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Search";
    
    MasterViewController *masterController = [[self childViewControllers] firstObject];
    masterController.webServicesController = [(AppDelegate*)[UIApplication sharedApplication].delegate webServicesController];
//    masterController.managedObjectContext = [(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext];
    
    self.searchBar.delegate = masterController;
    
//    self.navigationItem.leftBarButtonItem = masterController.editButtonItem;
    
    UIBarButtonItem *loginButton = [[UIBarButtonItem alloc] initWithTitle:@"Login" style:UIBarButtonItemStylePlain target:masterController.webServicesController action:@selector(login:)];
    self.navigationItem.rightBarButtonItem = loginButton;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
