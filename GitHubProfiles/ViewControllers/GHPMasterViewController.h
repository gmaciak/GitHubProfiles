//
//  MasterViewController.h
//  GitHubProfiles
//
//  Created by Grzegorz Maciak on 21.09.2016.
//  Copyright © 2016 Grzegorz Maciak. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GHPDetailViewController;

typedef NS_ENUM(NSInteger, GHPMasterViewControllerSourceType) {
    GHPMasterViewControllerSourceTypeUser,
    GHPMasterViewControllerSourceTypeRepo
};

@interface GHPMasterViewController : UITableViewController <UISearchBarDelegate>

@property (strong, nonatomic) GHPDetailViewController *detailViewController;
@property (strong, nonatomic) NSString *searchPhrase;
@property (nonatomic,assign) GHPMasterViewControllerSourceType sourceType;

- (void)searchWithPhrase:(NSString*)phrase ;

@end