//
//  WebServicesController.h
//  GitHubProfiles
//
//  Created by Grzegorz Maciak on 27.09.2016.
//  Copyright © 2016 Grzegorz Maciak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

FOUNDATION_EXPORT NSString* const GITHUB_API_CLIENT_ID;
FOUNDATION_EXPORT NSString* const GITHUB_API_APP_SECRET;

FOUNDATION_EXPORT NSUInteger const GITHUB_DEFAULT_PAGE_SIZE;

FOUNDATION_EXPORT NSString* const GHPLoadingStatusKey;
FOUNDATION_EXPORT NSString* const GHPDataKey;
FOUNDATION_EXPORT NSString* const GHPCellHeightKey;

typedef NS_ENUM(NSInteger, GHPLoadingStatus) {
    GHPLoadingStatusNotLoaded,
    GHPLoadingStatusLoading,
    GHPLoadingStatusLoaded
};

@interface WebServicesController : NSObject {
    AFHTTPSessionManager *urlSesionManager;
    __weak UIViewController* presentedViewController;
    NSUInteger totalResultsCount;
}

@property (strong, nonatomic) NSString *accessToken;
@property (weak, nonatomic) UIViewController* loginController;

- (void)login:(id)sender;
- (void)getAccessTokenWithCode:(NSString*)code;
- (void)searchUsersWithPhrase:(NSString*)phrase page:(NSUInteger)page completion:(void (^)(NSDictionary* data))completionHandler;
- (void)loadReposForUsers:(NSArray*)usersData progress:(void (^)(id item))progressHandler completion:(void (^)(void))completionHandler;

+ (NSDictionary*)paramsDictFromQuery:(NSString*)queryString;

@end