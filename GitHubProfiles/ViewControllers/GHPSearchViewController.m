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
    
    self.searchBar.delegate = self;
    
    UIBarButtonItem *loginButton = [[UIBarButtonItem alloc] initWithTitle:@"Login" style:UIBarButtonItemStylePlain target:[GHPWebServicesManager sharedInstance] action:@selector(login:)];
    self.navigationItem.rightBarButtonItem = loginButton;
    
    UIBarButtonItem *closeKeyboardButton = [[UIBarButtonItem alloc] initWithTitle:@"Hide keyboard" style:UIBarButtonItemStylePlain target:self action:@selector(onCloaseKeyboard:)];
    self.navigationItem.leftBarButtonItem = closeKeyboardButton;
    
    UITabBarController* tabBarController = [self.childViewControllers firstObject];
    tabBarController.delegate = self;
}

- (void)onCloaseKeyboard:(id)sender {
    if ([self.searchBar canResignFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
}

- (void)searchWithPhrase:(NSString*)phrase {
    UITabBarController* tabBarController = [self.childViewControllers firstObject];
    GHPMasterViewController* masterController = [[tabBarController.viewControllers[tabBarController.selectedIndex] childViewControllers] firstObject];
    [masterController searchWithPhrase:phrase];
}

#pragma mark - UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    GHPMasterViewController* masterController = [[viewController childViewControllers] firstObject];
    masterController.sourceType = tabBarController.selectedIndex == 0 ? GHPMasterViewControllerSourceTypeUser : GHPMasterViewControllerSourceTypeRepo;
    
    if (![masterController.searchPhrase isEqualToString:self.searchBar.text]) {
        [masterController searchWithPhrase:self.searchBar.text];
    }
    
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(searchWithPhrase:) object:searchText];
    [self performSelector:@selector(searchWithPhrase:) withObject:searchText afterDelay:0.2];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
}

@end
