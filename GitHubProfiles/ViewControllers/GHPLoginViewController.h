//
//  GHPWebViewController.h
//  GitHubProfiles
//
//  Created by Grzegorz Maciak on 27.09.2016.
//  Copyright © 2016 Grzegorz Maciak. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GHPLoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIWebView* webView;
@property (strong, nonatomic) NSString* startURL;

@end
