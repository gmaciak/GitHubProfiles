//
//  WebServicesController.m
//  GitHubProfiles
//
//  Created by Grzegorz Maciak on 27.09.2016.
//  Copyright © 2016 Grzegorz Maciak. All rights reserved.
//

#import "WebServicesController.h"

NSUInteger const GITHUB_DEFAULT_PAGE_SIZE = 30;


NSString* const GHPLoadingStatusKey = @"reposLoadingStatus";
NSString* const GHPDataKey = @"data";
NSString* const GHPURLKey = @"url";
NSString* const GHPCellHeightKey = @"cellHeight";

@implementation WebServicesController

- (AFURLSessionManager*)urlSesionManager {
    if (urlSesionManager == nil) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        urlSesionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    }
    return urlSesionManager;
}

- (void)loadDataWithURLString:(NSString*)urlString result:(NSMutableDictionary*)result completion:(void (^)(id result, NSHTTPURLResponse* lastResponse, NSError* error))completionHandler {
    if (result == nil) {
        result = [NSMutableDictionary dictionaryWithCapacity:3];
    }
    
    NSInteger reposLoadingStatus = [result[GHPLoadingStatusKey] integerValue];
    if (reposLoadingStatus != GHPLoadingStatusLoaded) {
        
        if (urlString) {
            
            result[GHPLoadingStatusKey] = @(GHPLoadingStatusLoading);
            
            NSURL *URL = [NSURL URLWithString:urlString];
            NSURLRequest *request = [NSURLRequest requestWithURL:URL];
            
            NSURLSessionDataTask *dataTask = [self.urlSesionManager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if (error) {
                    NSLog(@"Error: %@", error);
                    result[GHPLoadingStatusKey] = @(GHPLoadingStatusNotLoaded);
                    
                    if (completionHandler){
                        completionHandler(nil, httpResponse, error);
                    }
                } else {
                    NSLog(@"Responce hearders: %@",[httpResponse allHeaderFields]);
                    NSMutableArray* items = result[GHPDataKey];
                    if (!items) {
                        items = [NSMutableArray arrayWithCapacity:[responseObject count]];
                        result[GHPDataKey] = items;
                    }
                    [items addObjectsFromArray:responseObject];
                    
                    NSString* nextReposPageURLString = [self nextPageLinkForResponse:httpResponse];
                    if (nextReposPageURLString) {
                        [self loadDataWithURLString:nextReposPageURLString result:result completion:completionHandler];
                    }
                    else if (completionHandler){
                        completionHandler(result, httpResponse, nil);
                    }
                }
            }];
            [dataTask resume];
            
        }
        else if (completionHandler){
            completionHandler(result, nil, nil);
        }
    }
    else if (completionHandler){
        completionHandler(result, nil, nil);
    }
}

- (void)loadReposForUsers:(NSArray*)usersData progress:(void (^)(id item))progressHandler completion:(void (^)(void))completionHandler {
    
    dispatch_group_t group = dispatch_group_create();
    
    for (NSMutableDictionary* user in usersData) {
        NSInteger reposLoadingStatus = [user[GHPLoadingStatusKey] integerValue];
        if (reposLoadingStatus == GHPLoadingStatusNotLoaded) {
            
            NSString* urlString = user[@"repos_url"];
            
            if (urlString) {
                
                dispatch_group_enter(group);
                [self loadDataWithURLString:urlString result:nil completion:^(id result, NSHTTPURLResponse* lastResponse, NSError* error) {
                    if (error) {
                        NSLog(@"Error: %@", error);
                        user[GHPLoadingStatusKey] = @(GHPLoadingStatusNotLoaded);

                    } else {
                        NSLog(@"Responce hearders: %@",[lastResponse allHeaderFields]);
                        NSMutableArray* userRepos = result[GHPDataKey];
                        
                        // repos names list
                        NSArray* reposNames = [userRepos valueForKeyPath:@"@distinctUnionOfObjects.name"];
                        
                        // repos names to display
                        NSString* titlesListString = [reposNames componentsJoinedByString:@",\n"];
                        user[@"reposNames"] = titlesListString;
                        
                        // repos text size
                        CGSize size = [titlesListString sizeWithAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:11]}];
                        user[GHPCellHeightKey] = @(size.height + 44.0f);
                        
                        // clean
                        user[GHPLoadingStatusKey] = @(GHPLoadingStatusLoaded);
                    }
                    
                    if (progressHandler) {
                        progressHandler(user);
                    }
                    
                    dispatch_group_leave(group);
                }];
                
                
//                if (!hasAtLestOneTask) hasAtLestOneTask = YES;
//                
//                user[GHPLoadingStatusKey] = @(GHPLoadingStatusLoading);
//                
//                NSURL *URL = [NSURL URLWithString:urlString];
//                NSURLRequest *request = [NSURLRequest requestWithURL:URL];
//                
//                NSURLSessionDataTask *dataTask = [self.urlSesionManager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
//                    
//                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
//                    if (error) {
//                        NSLog(@"Error: %@", error);
//                        user[GHPLoadingStatusKey] = @(GHPLoadingStatusNotLoaded);
//                        dispatch_group_leave(group);
//                    } else {
//                        NSLog(@"Responce hearders: %@",[httpResponse allHeaderFields]);
//                        NSMutableArray* userRepos = user[GHPReposKey];
//                        if (!userRepos) {
//                            userRepos = [NSMutableArray arrayWithCapacity:[responseObject count]];
//                            user[GHPReposKey] = userRepos;
//                        }
//                        [userRepos addObjectsFromArray:responseObject];
//                        
//                        NSString* nextReposPageURLString = [self nextPageLinkForResponse:httpResponse];
//                        user[@"repos_url"] = nextReposPageURLString;
//                        if (nextReposPageURLString) {
//                            user[GHPLoadingStatusKey] = @(GHPLoadingStatusNotLoaded);
//                        }else{
//                            // repos names list
//                            NSArray* reposNames = [userRepos valueForKeyPath:@"@distinctUnionOfObjects.name"];
//                            
//                            // repos names to display
//                            NSString* titlesListString = [reposNames componentsJoinedByString:@",\n"];
//                            if (titlesListString.length > 0) {
//                                user[@"reposNames"] = titlesListString;
//                            }
//                            
//                            // repos text size
//                            CGSize size = [titlesListString sizeWithAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:11]}];
//                            user[GHPCellHeightKey] = @(size.height + 44.0f);
//                            
//                            // clean
//                            user[GHPReposKey] = nil;
//                            user[GHPLoadingStatusKey] = @(GHPLoadingStatusLoaded);
//                        }
//                        dispatch_group_leave(group);
//                    }
//                }];
//                
//                dispatch_group_enter(group);
//                [dataTask resume];
            }
            
        }
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (completionHandler) completionHandler();
    });
}

- (NSString*)nextPageLinkForResponse:(NSHTTPURLResponse*)response {
    NSString* linkHeader = [response allHeaderFields][@"Link"];
    NSString* matchStriing = nil;
    if (linkHeader) {
        // regex to get the next page url string
        NSRegularExpression* nextPageLinkRegex = [NSRegularExpression regularExpressionWithPattern:@"<(.+)>; rel=\"next\"" options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray* matches = [nextPageLinkRegex matchesInString:linkHeader options:0 range:NSMakeRange(0, linkHeader.length)];
        NSTextCheckingResult* match = [matches firstObject];
        
        if (match.numberOfRanges > 1) {
            matchStriing = [linkHeader substringWithRange:[match rangeAtIndex:1]];
        }
    }
    return matchStriing;
}

@end
