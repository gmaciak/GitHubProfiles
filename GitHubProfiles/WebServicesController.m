//
//  WebServicesController.m
//  GitHubProfiles
//
//  Created by Grzegorz Maciak on 27.09.2016.
//  Copyright © 2016 Grzegorz Maciak. All rights reserved.
//

#import "WebServicesController.h"
#import "WebViewController.h"

NSString* const GITHUB_API_CLIENT_ID = @"cd9035e4a1e1b78ebeed";
NSString* const GITHUB_API_APP_SECRET = @"06d24004d26e44a626917fa1b39d65bf5a4fb838";

NSUInteger const GITHUB_DEFAULT_PAGE_SIZE = 30;

NSString* const GHPLoadingStatusKey = @"reposLoadingStatus";
NSString* const GHPDataKey = @"data";
NSString* const GHPURLKey = @"url";
NSString* const GHPCellHeightKey = @"cellHeight";

NSString* const GHPWebServisesControllerDidLoginNotification = @"GHPWebServisesControllerDidLoginNotification";

@implementation WebServicesController

- (AFHTTPSessionManager*)urlSessionManager {
    if (urlSesionManager == nil) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        urlSesionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
    }
    return urlSesionManager;
}

- (void)cancellAllTasks {
    for (NSURLSessionTask* task in [[self urlSessionManager] tasks]) {
        [task cancel];
    };
}

- (void)dismissPresentedViewController {
    [presentedViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)login:(id)sender {
    NSString* urlString = [NSString stringWithFormat: @"https://github.com/login/oauth/authorize?client_id=%@",GITHUB_API_CLIENT_ID];
    
    WebViewController* controller = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"WebViewController"];
    controller.startURL = urlString;
    
    UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    presentedViewController = navigationController;
    [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)getAccessTokenWithCode:(NSString*)code {
    if (code.length == 0) {
        return;
    }
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFHTTPSessionManager* sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
    sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    NSString* urlString = @"https://github.com/login/oauth/access_token";
    NSDictionary* params = @{@"client_id" : GITHUB_API_CLIENT_ID,
                             @"client_secret" : GITHUB_API_APP_SECRET,
                             @"code" : code};
    
    [sessionManager POST:urlString parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        // parse responce
        NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSDictionary* responseParams = [[self class] paramsDictFromQuery:responseString];
        
        // store token
        self.accessToken = responseParams[@"access_token"];
        
        // dismiss login controller
        [self dismissPresentedViewController];
        
        // post GHPWebServisesControllerDidLoginNotification
        [[NSNotificationCenter defaultCenter] postNotificationName:GHPWebServisesControllerDidLoginNotification object:self];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)loadAllPagesWithURLString:(NSString*)urlString result:(NSMutableDictionary*)result completion:(void (^)(id result, NSHTTPURLResponse* lastResponse, NSError* error))completionHandler {
    if (result == nil) {
        result = [NSMutableDictionary dictionaryWithCapacity:3];
    }
    
    NSInteger reposLoadingStatus = [result[GHPLoadingStatusKey] integerValue];
    if (reposLoadingStatus != GHPLoadingStatusLoaded) {
        
        if (urlString) {
            
            result[GHPLoadingStatusKey] = @(GHPLoadingStatusLoading);
            
            NSURL *URL = [NSURL URLWithString:urlString];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
            if (self.accessToken != nil) {
                [request setValue:[NSString stringWithFormat:@"token %@",self.accessToken] forHTTPHeaderField:@"Authorization"];
            }
            
            NSURLSessionDataTask *dataTask = [self.urlSessionManager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                
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
                        [self loadAllPagesWithURLString:nextReposPageURLString result:result completion:completionHandler];
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

- (void)searchUsersWithPhrase:(NSString*)phrase page:(NSUInteger)page completion:(void (^)(NSDictionary* data))completionHandler {
    NSString* searchQuery = [[NSString stringWithFormat:@"q=%@&page=%li&per_page=%li",phrase,page,GITHUB_DEFAULT_PAGE_SIZE] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSString* urlString = [@"https://api.github.com/search/users" stringByAppendingFormat:@"?%@",searchQuery];
    NSURL *URL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    if (self.accessToken != nil) {
        [request setValue:[NSString stringWithFormat:@"token %@",self.accessToken] forHTTPHeaderField:@"Authorization"];
    }
    
    NSURLSessionDataTask *dataTask = [self.urlSessionManager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error) {
            NSLog(@"Error: %@", error);
            
            NSUInteger rateLimitReset = [[(NSHTTPURLResponse *)response allHeaderFields][@"X-RateLimit-Reset"] integerValue];
            NSDate* resetDate = [NSDate dateWithTimeIntervalSince1970:rateLimitReset];
            
            if (httpResponse.statusCode == 403 && [resetDate compare:[NSDate date]] == NSOrderedDescending) {
                NSUInteger secondsLeft = rateLimitReset - [[NSDate date] timeIntervalSince1970];
                
                NSString* message = [NSString stringWithFormat:@"Could not load next users. Please wait %li second(s) and try again.",secondsLeft];
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Ups" message:message preferredStyle:UIAlertControllerStyleAlert];
                
                [alert addAction:[UIAlertAction actionWithTitle:@"Try again" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self searchUsersWithPhrase:phrase page:page completion:completionHandler];
                }]];
                [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
                [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alert animated:YES completion:nil];
            }
            
            if (completionHandler) completionHandler(nil);
        } else {
            NSLog(@"Responce hearders: %@",[httpResponse allHeaderFields]);
            if (completionHandler) completionHandler(responseObject);
        }
    }];
    [dataTask resume];
}

- (void)loadReposForUsers:(NSArray*)usersData progress:(void (^)(id item))progressHandler completion:(void (^)(void))completionHandler {
    
    dispatch_group_t group = dispatch_group_create();
    
    for (NSMutableDictionary* user in usersData) {
        NSInteger reposLoadingStatus = [user[GHPLoadingStatusKey] integerValue];
        if (reposLoadingStatus == GHPLoadingStatusNotLoaded) {
            
            NSString* urlString = user[@"repos_url"];
            
            if (urlString) {
                
                dispatch_group_enter(group);
                [self loadAllPagesWithURLString:urlString result:nil completion:^(id result, NSHTTPURLResponse* lastResponse, NSError* error) {
                    if (error) {
                        NSLog(@"Error: %@", error);
                        user[GHPLoadingStatusKey] = @(GHPLoadingStatusError);

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
            }
            
        }
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (completionHandler) completionHandler();
    });
}

- (void)getFollowersCountForUserID:(NSNumber*)userID completion:(void (^)(NSUInteger count))completionHandler {
    NSString* urlString = [NSString stringWithFormat:@"https://api.github.com/user/%@/followers",[userID stringValue]];
    [self loadAllPagesWithURLString:urlString result:nil completion:^(id result, NSHTTPURLResponse* lastResponse, NSError* error) {
        if (error) {
            //NSLog(@"Error: %@", error);
        } else {
            //NSLog(@"Responce hearders: %@",[lastResponse allHeaderFields]);
            NSMutableArray* items = result[GHPDataKey];
            if (completionHandler) {
                completionHandler(items.count);
            }
        }
    }];
}

- (void)getStarsCountForUserID:(NSNumber*)userID completion:(void (^)(NSUInteger count))completionHandler {
    NSString* urlString = [NSString stringWithFormat:@"https://api.github.com/user/%@/starred",[userID stringValue]];
    [self loadAllPagesWithURLString:urlString result:nil completion:^(id result, NSHTTPURLResponse* lastResponse, NSError* error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            NSLog(@"Responce hearders: %@",[lastResponse allHeaderFields]);
            NSMutableArray* items = result[GHPDataKey];
            if (completionHandler) {
                completionHandler(items.count);
            }
        }
    }];
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

+ (NSDictionary*)paramsDictFromQuery:(NSString*)queryString {
    NSArray* paramsComponents = [queryString componentsSeparatedByString:@"&"];
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:paramsComponents.count];
    for (NSString* keyValueString in paramsComponents) {
        NSArray* keyValue = [keyValueString componentsSeparatedByString:@"="];
        if (keyValue.count == 2) {
            params[[keyValue firstObject]] = [keyValue lastObject];
        }
    }
    return params;
}

@end
