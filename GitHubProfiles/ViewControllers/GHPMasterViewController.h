//
//  MasterViewController.h
//  GitHubProfiles
//
//  Created by Grzegorz Maciak on 21.09.2016.
//  Copyright © 2016 Grzegorz Maciak. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GHPDetailViewController;

@interface GHPMasterViewController : UITableViewController <UISearchBarDelegate>

@property (strong, nonatomic) GHPDetailViewController *detailViewController;

@end