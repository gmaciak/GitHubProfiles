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

@synthesize searchPhrase;

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
    searchPhrase = phrase;
    totalResultsCount = 0;
    [tableData removeAllObjects];
    
    [self loadResultsWithPhrase:phrase];
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

#pragma mark - GitHub Web Api requests

- (void)loadResultsWithPhrase:(NSString*)phrase {
    if (phrase.length > 0) {
        NSUInteger page = [self nextPageNumber];
        if (page != NSNotFound) {
            [[GHPWebServicesManager sharedInstance] cancellAllTasks];
            
            if (_sourceType == GHPMasterViewControllerSourceTypeUser) {
                [[GHPWebServicesManager sharedInstance] searchUsersWithPhrase:phrase page:page completion:^(NSDictionary *data) {
                    [self updateResultsListWithNewData:data];
                }];
            }else{
                [[GHPWebServicesManager sharedInstance] searchReposWithPhrase:phrase page:page completion:^(NSDictionary *data) {
                    [self updateResultsListWithNewData:data];
                }];
            }
            
        }
    }else{
        [self.tableView reloadData];
    }
}

- (void)updateResultsListWithNewData:(NSDictionary*)data {
    if (data) {
        [tableData addObjectsFromArray:[self userDataWithResponseObject:data]];
        //                    [tableData sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES]]];
        NSLog(@"Items loaded: %li totalCount: %li", tableData.count, totalResultsCount);
        [self.tableView reloadData];
    }
}

#pragma mark GitHub Web Api helpers

- (NSUInteger)nextPageNumber {
    if (tableData.count == 0) {
        return 1;
    }
    else if (tableData.count == totalResultsCount) {
        return NSNotFound;
    }
    NSUInteger loadedPagesCount = (tableData.count/GITHUB_RESPONSE_PAGE_SIZE);
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
        userData[@"login"] = item[@"login"] ?: item[@"owner"][@"login"];
        userData[@"name"] = item[@"name"];
        userData[@"repos_url"] = item[@"repos_url"];
        userData[@"followers_url"] = item[@"followers_url"];
        userData[@"avatar_url"] = item[@"avatar_url"];
        userData[@"stars"] = item[@"stargazers_count"];
        userData[@"watchers"] = item[@"watchers_count"];
        userData[@"source_type"] = @(self.sourceType);
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
        [self loadResultsWithPhrase:searchPhrase];
    }
}

- (void)configureCell:(UITableViewCell *)cell withObject:(NSDictionary *)object {
    
    if (_sourceType == GHPMasterViewControllerSourceTypeUser) {
        cell.textLabel.text = object[@"login"] ?: @"";
    }else{
        cell.textLabel.text = object[@"name"] ?: @"";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Owner: %@",object[@"login"] ?: @""];
    }
    
}

@end
