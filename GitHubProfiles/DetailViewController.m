//
//  DetailViewController.m
//  GitHubProfiles
//
//  Created by Grzegorz Maciak on 21.09.2016.
//  Copyright © 2016 Grzegorz Maciak. All rights reserved.
//

#import "DetailViewController.h"
#import "AFNetworking.h"
#import "UIImageView+AFNetworking.h"

@interface DetailViewController ()

@end

@implementation DetailViewController

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
        [self.avatarImageView setImageWithURL:url];
        [self reloadDetails];
        if (_detailItem[@"followersCount"] == nil) {
            [self.webServicesController getFollowersCountForUserID:_detailItem[@"id"] completion:^(NSUInteger count) {
                _detailItem[@"followersCount"] = @(count);
                [self reloadDetails];
            }];
        }
        if (_detailItem[@"starsCount"] == nil) {
            [self.webServicesController getStarsCountForUserID:_detailItem[@"id"] completion:^(NSUInteger count) {
                _detailItem[@"starsCount"] = @(count);
                [self reloadDetails];
            }];
        }
    }
}

- (void)reloadDetails {
    NSMutableString* detailText = [NSMutableString stringWithFormat:@"Login: %@\n",_detailItem[@"login"]];
    [detailText appendFormat:@"\nFollowers: %@", _detailItem[@"followersCount"] ?: @"--"];
    [detailText appendFormat:@"\nStarred %@ repos", _detailItem[@"starsCount"] ?: @"--"];
    self.detailDescriptionLabel.text = detailText;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
