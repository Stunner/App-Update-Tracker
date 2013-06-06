//
// AppUpdateTracker.m
// AppUpdateTracker
//
/*
 Copyright (c) 2013, Aaron Jubbal
 All rights reserved.
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */


#import "AppUpdateTracker.h"

#define APP_UPDATE_TRACKER_DEBUG 1

#define DISPLAY_AUT_LOG_NAME @"App Update Tracker"

NSString *const kAUTCurrentVersion = @"kAppiraterCurrentVersion";
NSString *const kAUTPreviousVersion = @"kPreviousVersion";
NSString *const kAUTFirstUseTime = @"kAUTFirstUseTime";
NSString *const kAUTUseCount = @"kAUTUseCount";

@interface AppUpdateTracker ()

- (void)incrementUseCount;
- (void)appDidFinishLaunching:(NSNotification *)notification;
- (void)appWillEnterForeground:(NSNotification *)notification;

@end

@implementation AppUpdateTracker

- (id)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidFinishLaunching:)
                                                     name:UIApplicationDidFinishLaunchingNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    return self;
}

+ (id)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Getters

+ (NSString *)getTrackingVersion {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kAUTCurrentVersion];
}

+ (NSString *)getPreviousVersion {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kAUTPreviousVersion];
}

+ (double)getFirstUseTime {
    return [[NSUserDefaults standardUserDefaults] doubleForKey:kAUTFirstUseTime];
}

+ (NSUInteger)getUseCount {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kAUTUseCount];
}

#pragma mark - Core Functionality

- (void)incrementUseCount {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    // increment the use count
    NSUInteger useCount = [userDefaults integerForKey:kAUTUseCount];
    useCount++;
#if APP_UPDATE_TRACKER_DEBUG
    NSLog(@"%@, useCount++: %d", DISPLAY_AUT_LOG_NAME, useCount);
#endif
    [userDefaults setInteger:useCount forKey:kAUTUseCount];
    [userDefaults synchronize];
    
    NSDictionary *userInfo = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObject:[NSNumber numberWithInteger:useCount]]
                                                           forKeys:[NSArray arrayWithObject:@"USE_COUNT"]];
    [[NSNotificationCenter defaultCenter] postNotificationName:AUTUseCountUpdatedNotification
                                                        object:self
                                                      userInfo:userInfo];
}

- (void)appDidFinishLaunching:(NSNotification *)notification {
    // get the app's version
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    // get the version number that we've been tracking
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *trackingVersion = [userDefaults stringForKey:kAUTCurrentVersion];
    
#if APP_UPDATE_TRACKER_DEBUG
    NSLog(@"%@, trackingVersion: %@", DISPLAY_AUT_LOG_NAME, trackingVersion);
#endif
    
    if ([trackingVersion isEqualToString:version]) {
        [self incrementUseCount];
    } else { // it's an upgraded or new version of the app
        if (trackingVersion) { // we have read the old version - user updated app
#if APP_UPDATE_TRACKER_DEBUG
            NSLog(@"%@, app updated from %@", DISPLAY_AUT_LOG_NAME, trackingVersion);
#endif
            
            // app updated to current version from version found in <trackingVersion>
            NSDictionary *userInfo = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObject:trackingVersion]
                                                                   forKeys:[NSArray arrayWithObject:@"OLD_VERSION"]];
            [[NSNotificationCenter defaultCenter] postNotificationName:AUTAppUpdatedNotification
                                                                object:self
                                                              userInfo:userInfo];
            
        } else { // no old version exists - first time opening after install
#if APP_UPDATE_TRACKER_DEBUG
            NSLog(@"%@, fresh install detected", DISPLAY_AUT_LOG_NAME);
#endif
            NSTimeInterval timeInterval = [userDefaults doubleForKey:kAUTFirstUseTime];
            if (timeInterval == 0) {
                timeInterval = [[NSDate date] timeIntervalSince1970];
                [userDefaults setDouble:timeInterval forKey:kAUTFirstUseTime];
            }
            
            // fresh install of the app
            NSDictionary *userInfo = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObject:[NSNumber numberWithDouble:timeInterval]]
                                                                   forKeys:[NSArray arrayWithObject:@"FIRST_USE_TIME"]];
            [[NSNotificationCenter defaultCenter] postNotificationName:AUTFreshInstallNotification
                                                                object:self
                                                              userInfo:userInfo];
            
        }
        // include what version user updated from, nil if user didn't update
        // (only for initial session)
        [userDefaults setObject:trackingVersion forKey:kAUTPreviousVersion];
        [userDefaults setObject:version forKey:kAUTCurrentVersion];
        [userDefaults setDouble:[[NSDate date] timeIntervalSince1970]
                         forKey:kAUTFirstUseTime];
        [userDefaults setInteger:1 forKey:kAUTUseCount];
    }
    
    [userDefaults synchronize];
}

- (void)appWillEnterForeground:(NSNotification *)notification {
    [self incrementUseCount];
}

@end