//
//  DetailViewController.m
//  GitHubProfiles
//
//  Created by Grzegorz Maciak on 21.09.2016.
//  Copyright © 2016 Grzegorz Maciak. All rights reserved.
//

#import "GHPDetailViewController.h"
#import "UIImageView+AFNetworking.h"
#import "GHPWebServicesManager.h"
#import "GHPMasterViewController.h"

@implementation GHPDetailViewController {
    __block BOOL isLoadingFollowers;
    __block BOOL isLoadingStars;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[GHPWebServicesManager sharedInstance] cancellAllTasks];
}

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
            
        // Update the view.
        [self configureView];
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.detailItem) {
        NSString* avatarURLString = _detailItem[@"avatar_url"];
        NSURL* url = [NSURL URLWithString:avatarURLString];
        [self reloadDetails];
        [self.avatarImageView setImageWithURL:url];
        
        if (!isLoadingFollowers && _detailItem[@"followersCount"] == nil) {
            isLoadingFollowers = YES;
            [[GHPWebServicesManager sharedInstance] getFollowersCountForUserID:_detailItem[@"id"] completion:^(NSUInteger count) {
                _detailItem[@"followersCount"] = @(count);
                isLoadingFollowers = NO;
                [self reloadDetails];
            }];
        }
        if (!isLoadingStars && _detailItem[@"starsCount"] == nil) {
            isLoadingStars = YES;
            [[GHPWebServicesManager sharedInstance] getStarsCountForUserID:_detailItem[@"id"] completion:^(NSUInteger count) {
                _detailItem[@"starsCount"] = @(count);
                isLoadingStars = NO;
                [self reloadDetails];
            }];
        }
    }
}

- (void)reloadDetails {
    NSMutableString* detailText = nil;
    if ([_detailItem[@"source_type"] integerValue] == GHPMasterViewControllerSourceTypeUser) {
        detailText = [NSMutableString stringWithFormat:@"User: %@\n",_detailItem[@"login"]];
        [detailText appendFormat:@"\nFollowers: %@", _detailItem[@"followersCount"] ?: @"--"];
        [detailText appendFormat:@"\nStarred repos: %@", _detailItem[@"starsCount"] ?: @"--"];
    }else{
        detailText = [NSMutableString stringWithFormat:@"Repository name: %@\n",_detailItem[@"name"]];
        [detailText appendFormat:@"\nWatchers: %@", _detailItem[@"watchers"] ?: @"--"];
        [detailText appendFormat:@"\nStars: %@", _detailItem[@"stars"] ?: @"--"];
        [detailText appendFormat:@"\nOwner: %@", _detailItem[@"login"] ?: @"--"];
    }

    self.detailDescriptionLabel.text = detailText;
}

@end
