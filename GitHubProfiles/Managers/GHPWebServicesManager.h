//
//  GHPWebServicesManager.h
//  GitHubProfiles
//
//  Created by Grzegorz Maciak on 27.09.2016.
//  Copyright © 2016 Grzegorz Maciak. All rights reserved.
//

#import "DSESingleton.h"
#import "AFNetworking.h"

FOUNDATION_EXPORT NSString* const GITHUB_API_CLIENT_ID;
FOUNDATION_EXPORT NSString* const GITHUB_API_APP_SECRET;

FOUNDATION_EXPORT NSUInteger const GITHUB_RESPONSE_PAGE_SIZE;

FOUNDATION_EXPORT NSString* const GHPDataKey;
FOUNDATION_EXPORT NSString* const GHPCellHeightKey;

typedef NS_ENUM(NSInteger, GHPLoadingStatus) {
    GHPLoadingStatusNotLoaded,
    GHPLoadingStatusLoading,
    GHPLoadingStatusLoaded,
    GHPLoadingStatusError
};

@interface GHPWebServicesManager : DSESingleton {
    AFHTTPSessionManager *urlSesionManager;
    __weak UIViewController* presentedViewController;
}

@property (strong, nonatomic) NSString *accessToken;
@property (weak, nonatomic) UIViewController* loginController;

- (void)login:(id)sender;
- (void)getAccessTokenWithCode:(NSString*)code;
- (void)searchUsersWithPhrase:(NSString*)phrase page:(NSUInteger)page completion:(void (^)(NSDictionary* data))completionHandler;
- (void)searchReposWithPhrase:(NSString*)phrase page:(NSUInteger)page completion:(void (^)(NSDictionary* data))completionHandler;
- (void)getFollowersCountForUserID:(NSNumber*)userID completion:(void (^)(NSUInteger count))completionHandler;
- (void)getStarsCountForUserID:(NSNumber*)userID completion:(void (^)(NSUInteger count))completionHandler;
- (void)cancellAllTasks;

+ (NSDictionary*)paramsDictFromQuery:(NSString*)queryString;

@end

FOUNDATION_EXPORT NSString* const GHPWebServisesControllerDidLoginNotification;

