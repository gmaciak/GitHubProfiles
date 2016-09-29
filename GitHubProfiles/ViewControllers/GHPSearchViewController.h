//
//  SearchViewController.h
//  GitHubProfiles
//
//  Created by Grzegorz Maciak on 22.09.2016.
//  Copyright © 2016 Grzegorz Maciak. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GHPSearchViewController : UIViewController

@property(nonatomic, weak) IBOutlet UISearchBar* searchBar;
@property(nonatomic, weak) IBOutlet UIView* resultContainer;

@end
