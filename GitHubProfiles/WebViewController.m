//
//  WebViewController.m
//  GitHubProfiles
//
//  Created by Grzegorz Maciak on 27.09.2016.
//  Copyright © 2016 Grzegorz Maciak. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Login";
    
    NSURL *url = [NSURL URLWithString:self.startURL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [_webView loadRequest:requestObj];
    
    UIBarButtonItem *loginButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)];
    self.navigationItem.rightBarButtonItem = loginButton;
}

- (void)refresh:(id)sender {
    NSURL *url = [NSURL URLWithString:self.startURL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [_webView loadRequest:requestObj];
}

@end
