//
//  MasterViewController.m
//  GitHubProfiles
//
//  Created by Grzegorz Maciak on 21.09.2016.
//  Copyright © 2016 Grzegorz Maciak. All rights reserved.
//

#import "GHPMasterViewController.h"
#import "GHPDetailViewController.h"
#import "GHPWebServicesManager.h"
#import "AFNetworking.h"

@interface GHPMasterViewController () {
    AFURLSessionManager *urlSesionManager;
    NSString* searchPhrase;
    NSMutableArray* tableData;
    NSUInteger totalResultsCount;
}

@end

@implementation GHPMasterViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    tableData = [NSMutableArray array];
    
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.detailViewController = (GHPDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginNotificationHandler:) name:GHPWebServisesControllerDidLoginNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}

- (void)searchWithPhrase:(NSString*)phrase {
    totalResultsCount = 0;
    [tableData removeAllObjects];
    [self loadUsersWithPhrase:phrase];
}

-(void)loginNotificationHandler:(NSNotification*)notification {
    [self searchWithPhrase:searchPhrase];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDictionary* object = [tableData objectAtIndex:indexPath.row];
        GHPDetailViewController *controller = (GHPDetailViewController *)[[segue destinationViewController] topViewController];
        [controller setDetailItem:object];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(searchWithPhrase:) object:searchPhrase];
    searchPhrase = searchBar.text;
    [self performSelector:@selector(searchWithPhrase:) withObject:searchPhrase afterDelay:0.2];
}

#pragma mark - GitHub Web Api requests

- (void)loadUsersWithPhrase:(NSString*)phrase {
    if (phrase.length > 0) {
        NSUInteger page = [self nextPageNumber];
        if (page != NSNotFound) {
            [[GHPWebServicesManager sharedInstance] cancellAllTasks];
            [[GHPWebServicesManager sharedInstance] searchUsersWithPhrase:phrase page:page completion:^(NSDictionary *data) {
                if (data) {
                    [tableData addObjectsFromArray:[self userDataWithResponseObject:data]];
//                    [tableData sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES]]];
                    NSLog(@"Items loaded: %li totalCount: %li", tableData.count, totalResultsCount);
                    [self.tableView reloadData];
                    [self loadRepos];
                }
            }];
        }
    }else{
        [self.tableView reloadData];
    }
}

- (void)loadRepos {
    
    [[GHPWebServicesManager sharedInstance] loadReposForUsers:tableData progress:^(id item) {
        NSInteger index = [tableData indexOfObject:item];
        if (index != NSNotFound) {
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
    } completion:^{
        
    }];
}

#pragma mark GitHub Web Api helpers

- (NSUInteger)nextPageNumber {
    if (tableData.count == 0) {
        return 1;
    }
    else if (tableData.count == totalResultsCount) {
        return NSNotFound;
    }
    NSUInteger loadedPagesCount = (tableData.count/GITHUB_DEFAULT_PAGE_SIZE);
    return loadedPagesCount + 1;
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

- (NSArray*)userDataWithResponseObject:(NSDictionary*)responseObject {
    NSArray* items = responseObject[@"items"];
    totalResultsCount = [(NSNumber*)responseObject[@"total_count"] unsignedIntegerValue];
    
    NSMutableArray* usersData = [[NSMutableArray alloc] initWithCapacity:items.count];
    for (NSDictionary* item in items) {
        NSMutableDictionary* userData = [[NSMutableDictionary alloc] initWithCapacity:5];
        userData[@"id"] = item[@"id"];
        userData[@"login"] = item[@"login"];
        userData[@"repos_url"] = item[@"repos_url"];
        userData[@"followers_url"] = item[@"followers_url"];
        userData[@"avatar_url"] = item[@"avatar_url"];
        [usersData addObject:userData];
    }
    
    return usersData;
}

#pragma mark - Table View

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *data = tableData[indexPath.row];
    NSNumber* height = data[GHPCellHeightKey];
    if (height) {
        return [height floatValue];
    }
    return 44.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [tableData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSDictionary *data = tableData[indexPath.row];
    [self configureCell:cell withObject:data];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(nonnull UITableViewCell *)cell forRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (indexPath.row == tableData.count - 1 && tableData.count < totalResultsCount) {
        [self loadUsersWithPhrase:searchPhrase];
    }
}

- (void)configureCell:(UITableViewCell *)cell withObject:(NSDictionary *)object {
    cell.textLabel.text = object[@"login"] ?: @"";
    
    BOOL shouldShowIndicator = YES;
    NSString* reposNames = object[@"reposNames"];
    if (reposNames) {
        cell.detailTextLabel.text = reposNames.length > 0 ? reposNames : @"User has no repository.";
        shouldShowIndicator = NO;
    }
    else if ([object[GHPLoadingStatusKey] integerValue] == GHPLoadingStatusError) {
        cell.detailTextLabel.text = @"You need to login to get repos info.";
        shouldShowIndicator = NO;
    }
    else{
        cell.detailTextLabel.text = @"";
    }
    
    UIActivityIndicatorView* indicator = [cell.contentView viewWithTag:3];
    if (!indicator.isAnimating && shouldShowIndicator) {
        [indicator startAnimating];
    }else if (indicator.isAnimating && !shouldShowIndicator) {
        [indicator stopAnimating];
    }
}

@end
