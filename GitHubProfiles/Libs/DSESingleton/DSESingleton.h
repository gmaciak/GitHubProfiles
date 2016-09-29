//
//  Singleton.h
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

#import <Foundation/Foundation.h>

@interface DSESingleton : NSObject

+(instancetype)sharedInstance;
+(BOOL)isAllocated;

@end

/*
 You can also use implementation macros to define interface and implementation of  required methods of your signleton.
 There is no need to declaring interface again in case of inheritance, but you must add SINGLETON_IMPLEMENTATION code in derived class to create different instance of derived singleton which inherits functionalities of its base class
 */

#if __has_feature(objc_arc)

// ARC Singleton Implementation Macros
#define SINGLETON_INTERFACE(CLASS_NAME) \
\
+(instancetype)sharedInstance;\
+(BOOL)isAllocated;\


#define SINGLETON_IMPLEMENTATION(CLASS_NAME) \
\
static id g_ ## CLASS_NAME ## SingletonSharedInstance = nil;\
\
+(id)sharedInstance {\
    if (g_ ## CLASS_NAME ## SingletonSharedInstance != nil) {\
        return g_ ## CLASS_NAME ## SingletonSharedInstance;\
    }\
    static dispatch_once_t onceToken;\
    dispatch_once(&onceToken, ^(void){\
        g_ ## CLASS_NAME ## SingletonSharedInstance = [[self alloc] init];\
    });\
    return g_ ## CLASS_NAME ## SingletonSharedInstance;\
}\
\
+(BOOL) isAllocated {\
    return g_ ## CLASS_NAME ## SingletonSharedInstance != nil;\
}\
\
+(void)invalidate { \
g_ ## CLASS_NAME ## SingletonSharedInstance = nil;\
}\
\
- (id)copyWithZone:(NSZone *)zone {\
return self;\
}\

#else

// MRC Singleton Implementation Macros
#define SINGLETON_INTERFACE(CLASS_NAME) \
\
+(instancetype)sharedInstance;\
+(BOOL)isAllocated;\
+(void)invalidate; // Singleton should be invalidated in -applicationWillTerminate: method of the AppDelegate


#define SINGLETON_IMPLEMENTATION(CLASS_NAME) \
\
static id g_ ## CLASS_NAME ## SingletonSharedInstance = nil;\
\
+(id)sharedInstance {\
if (g_ ## CLASS_NAME ## SingletonSharedInstance != nil) {\
return g_ ## CLASS_NAME ## SingletonSharedInstance;\
}\
static dispatch_once_t onceToken;\
dispatch_once(&onceToken, ^(void){\
g_ ## CLASS_NAME ## SingletonSharedInstance = [[self alloc] init];\
});\
return g_ ## CLASS_NAME ## SingletonSharedInstance;\
}\
\
+(BOOL) isAllocated {\
return g_ ## CLASS_NAME ## SingletonSharedInstance != nil;\
}\
\
+(void)invalidate { \
[g_ ## CLASS_NAME ## SingletonSharedInstance release];\
g_ ## CLASS_NAME ## SingletonSharedInstance = nil;\
}\
\
- (id)copyWithZone:(NSZone *)zone {\
    return self;\
}\

#endif
