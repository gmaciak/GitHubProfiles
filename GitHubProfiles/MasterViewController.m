//
//  MasterViewController.m
//  GitHubProfiles
//
//  Created by Grzegorz Maciak on 21.09.2016.
//  Copyright © 2016 Grzegorz Maciak. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "AFNetworking.h"

@interface MasterViewController () {
    AFURLSessionManager *urlSesionManager;
    NSString* searchPhrase;
    NSMutableArray* tableData;
    NSUInteger totalResultsCount;
}

@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    tableData = [NSMutableArray array];
    
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
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

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDictionary* object = [tableData objectAtIndex:indexPath.row];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
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

- (void)loadUsersWithPhrase:(NSString*)phrase {
    if (phrase.length > 0) {
        NSUInteger page = [self nextPageNumber];
        if (page != NSNotFound) {
            [self.webServicesController cancellAllTasks];
            [self.webServicesController searchUsersWithPhrase:phrase page:page completion:^(NSDictionary *data) {
                if (data) {
                    [tableData addObjectsFromArray:[self userDataWithResponseObject:data]];
                    //            [tableData sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES]]];
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
    
    [self.webServicesController loadReposForUsers:tableData progress:^(id item) {
        NSInteger index = [tableData indexOfObject:item];
        if (index != NSNotFound) {
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
    } completion:^{
        
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
    NSString* reposNames = object[@"reposNames"];
    if (reposNames) {
        cell.detailTextLabel.text = reposNames.length > 0 ? reposNames : @"User has no repository.";
    }else{
        cell.detailTextLabel.text = @"";
    }
    
    UIActivityIndicatorView* indicator = [cell.contentView viewWithTag:3];
    if (!indicator.isAnimating && reposNames == nil) {
        [indicator startAnimating];
    }else if (indicator.isAnimating && reposNames != nil) {
        [indicator stopAnimating];
    }
}

#pragma mark - Fetched results controller
/*
- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];

    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	     // Replace this implementation with code to handle the error appropriately.
	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            return;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] withObject:anObject];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}*/

/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */

@end
