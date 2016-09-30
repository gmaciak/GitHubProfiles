//
//  GHPWebServicesManager.m
//  GitHubProfiles
//
//  Created by Grzegorz Maciak on 27.09.2016.
//  Copyright © 2016 Grzegorz Maciak. All rights reserved.
//

#import "GHPWebServicesManager.h"
#import "GHPLoginViewController.h"

NSString* const GITHUB_API_CLIENT_ID = @"cd9035e4a1e1b78ebeed";
NSString* const GITHUB_API_APP_SECRET = @"06d24004d26e44a626917fa1b39d65bf5a4fb838";

NSUInteger const GITHUB_RESPONSE_PAGE_SIZE = 30;

NSString* const GHPDataKey = @"data";
NSString* const GHPCellHeightKey = @"cellHeight";

NSString* const GHPWebServisesControllerDidLoginNotification = @"GHPWebServisesControllerDidLoginNotification";

typedef void(^GHPPageDownoldingCompletionBlock)(id result, NSHTTPURLResponse* lastResponse, NSError* error);

@implementation GHPWebServicesManager

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

#pragma mark - Login

- (void)dismissPresentedViewController {
    [presentedViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)login:(id)sender {
    NSString* urlString = [NSString stringWithFormat: @"https://github.com/login/oauth/authorize?client_id=%@",GITHUB_API_CLIENT_ID];
    
    GHPLoginViewController* controller = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"WebViewController"];
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

#pragma mark search
- (void)searchUsersWithPhrase:(NSString*)phrase page:(NSUInteger)page completion:(void (^)(NSDictionary* data))completionHandler {
    [self searchWithServiceName:@"users" phrase:phrase page:page completion:completionHandler];
}

- (void)searchReposWithPhrase:(NSString*)phrase page:(NSUInteger)page completion:(void (^)(NSDictionary* data))completionHandler {
    [self searchWithServiceName:@"repositories" phrase:phrase page:page completion:completionHandler];
}

- (void)searchWithServiceName:(NSString*)serviceName phrase:(NSString*)phrase page:(NSUInteger)page completion:(void (^)(NSDictionary* data))completionHandler {
    NSString* searchQuery = [[NSString stringWithFormat:@"q=%@&page=%li&per_page=%li",phrase,page,GITHUB_RESPONSE_PAGE_SIZE] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSString* urlString = [NSString stringWithFormat:@"https://api.github.com/search/%@?%@", serviceName, searchQuery];
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
                
                NSString* message = [NSString stringWithFormat:@"Could not load next %@. Please wait %li second(s) and try again.",serviceName,secondsLeft];
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

#pragma mark Service items count
- (void)getCountOfItemsWithURLString:(NSString*)urlString result:(NSMutableDictionary*)result completion:(GHPPageDownoldingCompletionBlock)completionHandler {
    if (urlString) {
        if (result == nil) {
            result = [NSMutableDictionary dictionaryWithCapacity:3];
            
            // setup pages count
            result[@"pages_count"] = @(1);
        }
        
        NSURL *URL = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        if (self.accessToken != nil) {
            [request setValue:[NSString stringWithFormat:@"token %@",self.accessToken] forHTTPHeaderField:@"Authorization"];
        }
        
        NSURLSessionDataTask *dataTask = [self.urlSessionManager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
            
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (error) {
                NSLog(@"Error: %@", error);

                if (completionHandler){
                    completionHandler(nil, httpResponse, error);
                }
            } else {
                //NSLog(@"Responce hearders: %@",[httpResponse allHeaderFields]);
                
                // set current page count as last page count (there may be no other pages than current)
                result[@"last_page_count"] = @([responseObject count]);
                
                NSString* lastPageURLString = [self lastPageLinkForResponse:httpResponse];
                
                if (lastPageURLString) {
                    // setup pages count
                    result[@"pages_count"] = @([self pageNumberFromLink:lastPageURLString]);
                }
                
                // get last page if it is different than first page
                if (lastPageURLString && ![lastPageURLString isEqualToString:urlString]) {
                    [self getCountOfItemsWithURLString:lastPageURLString result:result completion:completionHandler];
                    
                }else if (completionHandler){
                    result[GHPDataKey] = @(([result[@"pages_count"] integerValue] -1) * GITHUB_RESPONSE_PAGE_SIZE + [result[@"last_page_count"] integerValue]);

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

- (void)getCountOfItemsWithServiceName:(NSString*)serviceName userID:(NSNumber*)userID result:(NSMutableDictionary*)result completion:(GHPPageDownoldingCompletionBlock)completionHandler {
    NSString* urlString = [NSString stringWithFormat:@"https://api.github.com/user/%@/%@?per_page=%li",[userID stringValue],serviceName,GITHUB_RESPONSE_PAGE_SIZE];
    
    // get items count of first and last page
    [self getCountOfItemsWithURLString:urlString result:result completion:completionHandler];
}

- (void)getFollowersCountForUserID:(NSNumber*)userID completion:(void (^)(NSUInteger count))completionHandler {
    [self getCountOfItemsWithServiceName:@"followers" userID:userID result:nil completion:^(id result, NSHTTPURLResponse *lastResponse, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            //NSLog(@"Responce hearders: %@",[lastResponse allHeaderFields]);
            if (completionHandler) {
                completionHandler([result[GHPDataKey] unsignedIntegerValue]);
            }
        }
    }];
}

- (void)getStarsCountForUserID:(NSNumber*)userID completion:(void (^)(NSUInteger count))completionHandler {
    [self getCountOfItemsWithServiceName:@"starred" userID:userID result:nil completion:^(id result, NSHTTPURLResponse *lastResponse, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            //NSLog(@"Responce hearders: %@",[lastResponse allHeaderFields]);
            if (completionHandler) {
                completionHandler([result[GHPDataKey] unsignedIntegerValue]);
            }
        }
    }];
}

#pragma mark - GitHub API helpers

- (NSUInteger)pageNumberFromLink:(NSString*)urlString {
    NSString* matchStriing = nil;
    if (urlString) {
        // regex to get the next page number
        NSRegularExpression* nextPageLinkRegex = [NSRegularExpression regularExpressionWithPattern:@"&page=(\\d+)" options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray* matches = [nextPageLinkRegex matchesInString:urlString options:0 range:NSMakeRange(0, urlString.length)];
        NSTextCheckingResult* match = [matches firstObject];
        
        if (match.numberOfRanges > 1) {
            matchStriing = [urlString substringWithRange:[match rangeAtIndex:1]];
            return [matchStriing integerValue];
        }
    }
    return NSNotFound;
}

- (NSString*)linkForPage:(NSString*)pageName response:(NSHTTPURLResponse*)response {
    NSString* linkHeader = [response allHeaderFields][@"Link"];
    NSString* matchStriing = nil;
    if (linkHeader) {
        // regex to get the next page url string
        NSString* regexPattern = [NSString stringWithFormat:@"<([^\\s]+)>; rel=\"%@\"",pageName];
        NSRegularExpression* nextPageLinkRegex = [NSRegularExpression regularExpressionWithPattern:regexPattern options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray* matches = [nextPageLinkRegex matchesInString:linkHeader options:0 range:NSMakeRange(0, linkHeader.length)];
        NSTextCheckingResult* match = [matches firstObject];
        
        if (match.numberOfRanges > 1) {
            matchStriing = [linkHeader substringWithRange:[match rangeAtIndex:1]];
        }
    }
    return matchStriing;
}

- (NSString*)nextPageLinkForResponse:(NSHTTPURLResponse*)response {
    return [self linkForPage:@"next" response:response];
}

- (NSString*)lastPageLinkForResponse:(NSHTTPURLResponse*)response {
    return [self linkForPage:@"last" response:response];
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
