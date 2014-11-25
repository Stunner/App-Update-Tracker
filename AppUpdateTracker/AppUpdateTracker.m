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

#define DISPLAY_AUT_LOG_NAME @"AUT >"

NSString *const kAUTCurrentVersion = @"kAUTCurrentVersion";
NSString *const kAUTPreviousVersion = @"kAUTPreviousVersion";
NSString *const kAUTFirstUseTime = @"kAUTFirstUseTime";
NSString *const kAUTUseCount = @"kAUTUseCount";
NSString *const kAUTUserUpgradedApp = @"kAUTUserUpgradedApp";

@interface AppUpdateTracker ()

- (void)incrementUseCount;
- (void)appDidFinishLaunching;

@end

@implementation AppUpdateTracker

- (id)init {
    if (self = [super init]) {
        __block AppUpdateTracker *weakSelf = self;
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
                                                          [weakSelf incrementUseCount];
                                                      }];
        [self appDidFinishLaunching];
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

+ (BOOL)getUserUpgradedApp {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kAUTUserUpgradedApp];
}

#pragma mark - Core Functionality

- (void)incrementUseCount {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    // increment the use count
    NSUInteger useCount = [userDefaults integerForKey:kAUTUseCount];
    useCount++;
#if APP_UPDATE_TRACKER_DEBUG
    NSLog(@"%@ useCount++: %lu", DISPLAY_AUT_LOG_NAME, (unsigned long)useCount);
#endif
    [userDefaults setInteger:useCount forKey:kAUTUseCount];
    [userDefaults synchronize];
    
    NSDictionary *userInfo = @{kAUTNotificationUserInfoUseCountKey : [NSNumber numberWithInteger:useCount]};
    [[NSNotificationCenter defaultCenter] postNotificationName:AUTUseCountUpdatedNotification
                                                        object:self
                                                      userInfo:userInfo];
}

- (void)appDidFinishLaunching {
    
    // get the app's version
    NSString *shortVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]; //has priority
    NSString *longVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    
    NSString *version;
    if (shortVersion) {
        version = shortVersion;
    } else if (longVersion) {
        version = longVersion;
    } else {
#if APP_UPDATE_TRACKER_DEBUG
        NSLog(@"App Update Tracker ERROR: No bundle version found. Current version is nil.");
#endif
    }
    
    // get the version number that we've been tracking
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *trackingVersion = [userDefaults stringForKey:kAUTCurrentVersion];
    
#if APP_UPDATE_TRACKER_DEBUG
    NSLog(@"%@ trackingVersion: %@", DISPLAY_AUT_LOG_NAME, trackingVersion);
#endif
    
    if ([trackingVersion isEqualToString:version]) {
        [self incrementUseCount];
        [userDefaults setBool:NO forKey:kAUTUserUpgradedApp];
#if APP_UPDATE_TRACKER_DEBUG
        NSLog(@"User Upgraded? %d", [userDefaults boolForKey:kAUTUserUpgradedApp]);
#endif
    } else { // it's an upgraded or new version of the app
        if (trackingVersion) { // we have read the old version - user updated app
#if APP_UPDATE_TRACKER_DEBUG
            NSLog(@"%@, app updated from %@", DISPLAY_AUT_LOG_NAME, trackingVersion);
#endif
            
            // app updated to current version from version found in <trackingVersion>
            NSDictionary *userInfo = @{kAUTNotificationUserInfoOldVersionKey : trackingVersion};
            [[NSNotificationCenter defaultCenter] postNotificationName:AUTAppUpdatedNotification
                                                                object:self
                                                              userInfo:userInfo];
            [userDefaults setBool:YES forKey:kAUTUserUpgradedApp];
#if APP_UPDATE_TRACKER_DEBUG
            NSLog(@"User Upgraded? %d", [userDefaults boolForKey:kAUTUserUpgradedApp]);
#endif
        } else { // no old version exists - first time opening after install
#if APP_UPDATE_TRACKER_DEBUG
            NSLog(@"%@ fresh install detected", DISPLAY_AUT_LOG_NAME);
#endif
            NSTimeInterval timeInterval = [userDefaults doubleForKey:kAUTFirstUseTime];
            if (timeInterval == 0) {
                timeInterval = [[NSDate date] timeIntervalSince1970];
                [userDefaults setDouble:timeInterval forKey:kAUTFirstUseTime];
            }
            
            // fresh install of the app
            NSDictionary *userInfo = @{kAUTNotificationUserInfoFirstUseTimeKey : [NSNumber numberWithDouble:timeInterval]};
            [[NSNotificationCenter defaultCenter] postNotificationName:AUTFreshInstallNotification
                                                                object:self
                                                              userInfo:userInfo];
            [userDefaults setBool:NO forKey:kAUTUserUpgradedApp];
            
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

@end