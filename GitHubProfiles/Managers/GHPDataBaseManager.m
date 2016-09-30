//
//  GHPDataBaseManager.m
//  GitHubProfiles
//
//  Created by Grzegorz Maciak on 29.09.2016.
//  Copyright © 2016 Grzegorz Maciak. All rights reserved.
//

#import "GHPDataBaseManager.h"
#import "FMDB.h"

@interface GHPDataBaseManager () {
    FMDatabaseQueue* queue;
}

@end

@implementation GHPDataBaseManager

- (void)loadDatabase {
    NSString* destinationPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent: @"db.sqlite" ];
    
    
    NSString* sourcePath = [[NSBundle mainBundle] pathForResource:@"db" ofType:@"sqlite"];
    if( ![[NSFileManager defaultManager] fileExistsAtPath:destinationPath] ){
        [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:nil];
        [[NSFileManager defaultManager] setAttributes:[NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey] ofItemAtPath:destinationPath error:nil];
    }
    
    // FMDB will create empty data base at destination path if it does not exists
    queue = [[FMDatabaseQueue alloc] initWithPath: destinationPath ];
    
    [queue inDatabase:^(FMDatabase *db) {
        [[self class] createTablesInDB:db];
    }];
}

#pragma mark - static helpsers

+ (void)createTablesInDB:(FMDatabase*)db {
    
    BOOL success;
    
    // create SearchResultsIndex table
    success = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS SearchResultsIndex ("
               "local_id        integer NOT NULL PRIMARY KEY,"
               "id              integer NOT NULL,"
               "type            integer DEFAULT 0," // 0 - user, 1 - repo
               ")"];
    
    if (!success) NSLog(@"Could not crate SearchResultsIndex table");
    
    // create User table
    success = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS User ("
               "id              integer NOT NULL,"
               "login           text    NOT NULL,"
               "repos_url       text,"
               "followers_url   text,"
               "avatar_url      text,"
               ")"];
    if (!success) NSLog(@"Could not crate User table");
    
    // create Repository table
    success = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS Repository ("
               "id              integer NOT NULL,"
               "owner_id        text," // user id
               "name            text    NOT NULL,"
               ")"];
    if (!success) NSLog(@"Could not crate Repository table");
}

- (void)getNextResultsPageWithLastResultId:(NSNumber*)lastId {
    NSMutableString* query = [NSMutableString stringWithFormat:@"SELECT * FROM SearchResult"];
    [query appendFormat:@" WHERE id > %li",[lastId integerValue]];
    [query appendString:@" ORDER BY id LIMIT 100"];
    
    NSMutableArray* resultsList = [[NSMutableArray alloc] initWithCapacity:100];
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:query];
        while ([rs next]) {
            [resultsList addObject:[rs resultDictionary]];
        }
        [rs close];
    }];
    
    NSMutableArray* usersResults = [resultsList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type == 0"]];
    NSMutableArray* reposResults = [resultsList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type == 1"]];
}

- (void)insertResults:(NSArray*)results {
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (NSDictionary* result in results) {
            [self insertOrReplaceObject:result tableName:@"SearchResult" inDB:db];
        }
    }];
}

- (BOOL)insertOrReplaceObject:(NSDictionary*)object tableName:(NSString*)tableName inDB:(FMDatabase*)db {
    NSMutableArray* arguments = [[NSMutableArray alloc] init];
    NSString* query = [self insertQueryWithTableName:tableName object:object arguments:arguments ignoreProperties:nil];
    if (![db executeUpdate:query withArgumentsInArray:arguments]) {
        NSLog(@"Could not insert object in table '%@'", tableName);
        return NO;
    }
    return YES;
}

-(NSString*) insertQueryWithTableName:(NSString*)tableName object:(NSDictionary*)object arguments:(NSMutableArray*)arguments ignoreProperties:(NSArray*)ignoreProperties{
    [arguments removeAllObjects];
    
    NSMutableArray* columnsNames = [[object allKeys] mutableCopy];
    
    //remove properties
    if (ignoreProperties) [columnsNames removeObjectsInArray:ignoreProperties];
    
    NSMutableString* query = [[NSMutableString alloc] initWithCapacity: 256 ];
    [query appendString:@"INSERT OR REPLACE INTO "];
    [query appendString: tableName ];
    [query appendFormat:@" (%@) ",[columnsNames componentsJoinedByString:@", "]];
    [query appendString:@"VALUES ("];
    for(int i=0; i<[columnsNames count];++i){
        [query appendString:@"?"];
        if( i!=[columnsNames count]-1 ) [query appendString:@", "];
    }
    [query appendString:@")"];
    
    for(NSString* propertyName in columnsNames){
        id value = [object objectForKey:propertyName];
        if(value){
            [arguments addObject: value];
        }else{
            [arguments addObject: [NSNull null] ];
        }
    }
    
    return query;
}

@end
