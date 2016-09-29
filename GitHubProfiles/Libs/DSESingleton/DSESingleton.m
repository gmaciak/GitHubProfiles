//
//  Singleton.m
//  Singleton
//
//  Created by Grzegorz Maciak on 05.02.2014.
//  Copyright (c) 2014 Grzegorz Maciak. All rights reserved.
//

// This code is distributed under the terms and conditions of the MIT license:

// Copyright (c) 2016 Grzegorz Maciak
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "DSESingleton.h"
//#import "DSECommonLoggingMacros.h"
#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#ifndef VLog
#define VLog NSLog
#endif

@interface __DSEMasterSingleton : NSObject {
    NSRecursiveLock* locker;
    NSMutableDictionary* singletons;
}
+(instancetype) sharedInstance;
-(id) getSingletonForKey:(NSString*)key;
-(BOOL) isSingletonAllocated:(NSString*)key;
-(void) addSingleton:(id)singleton;
-(void) removeSingleton:(id)singleton;
-(void) remove;
@end

#pragma mark Singleton Implementation
@implementation DSESingleton

- (void)dealloc {
    VLog(@"%@ SINGLETON DESTROYED", NSStringFromClass([self class]));
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

#pragma mark Singleton Methods

+(id) sharedInstance{
    return [[__DSEMasterSingleton sharedInstance] getSingletonForKey:NSStringFromClass(self)];
}

+(BOOL) isAllocated {
    return [[__DSEMasterSingleton sharedInstance] isSingletonAllocated:NSStringFromClass(self)];
}

+(void)destroy {
    [[__DSEMasterSingleton sharedInstance] removeSingleton:self];
}

@end

#pragma mark - Master Singleton Implementation
@implementation __DSEMasterSingleton

static id _masterSingletonSharedInstance = nil;

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#if ! __has_feature(objc_arc)
    [locker release];
    [singletons release];
#endif
    VLog(@"%@ SINGLETON DESTROYED", NSStringFromClass([self class]));
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

+(id)sharedInstance {
    
    if (_masterSingletonSharedInstance != nil) {
        return _masterSingletonSharedInstance;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^(void){
        _masterSingletonSharedInstance = [[self alloc] init];
    });
    
    return _masterSingletonSharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        locker = [[NSRecursiveLock alloc] init];
#if TARGET_OS_IOS
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
#else
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
#endif
        singletons = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(id)getSingletonForKey:(NSString*)key {
    id singleton = nil;
    [locker lock];
    singleton = [singletons objectForKey:key];
    if (!singleton) {
        singleton = [[NSClassFromString(key) alloc] init];
        if (singleton) {
            [[__DSEMasterSingleton sharedInstance] addSingleton:singleton];
#if ! __has_feature(objc_arc)
            [singleton release];
#endif
        }
    }
    [locker unlock];
    return singleton;
}

-(BOOL)isSingletonAllocated:(NSString*)key {
    BOOL isAllocated;
    [locker lock];
    isAllocated = singletons[key] != nil;
    [locker unlock];
    return isAllocated;
}

-(void)addSingleton:(id)singleton {
    [locker lock];
    [singletons setObject:singleton forKey:NSStringFromClass([singleton class])];
    [locker unlock];
}

#if TARGET_OS_IOS
-(void)applicationWillTerminate:(UIApplication *)application{
    [self remove];
}
#else
-(void)applicationWillTerminate:(NSApplication *)application{
    [self remove];
}
#endif

-(void)removeSingleton:(id)singleton {
    [locker lock];
    [singletons removeObjectForKey:NSStringFromClass([singleton class])];
    [locker unlock];
}

-(void)remove {
    
    // remove all singletons
    [locker lock];
    [singletons removeAllObjects];
    [locker unlock];
    
#if ! __has_feature(objc_arc)
    [_masterSingletonSharedInstance release];
#endif
    _masterSingletonSharedInstance = nil;
}

@end
