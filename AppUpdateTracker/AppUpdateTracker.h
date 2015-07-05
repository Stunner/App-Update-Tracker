//
// AppUpdateTracker.h
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


#import <Foundation/Foundation.h>

#define AUTUseCountUpdatedNotification @"AUTUseCountUpdatedNotification"
#define AUTAppUpdatedNotification @"AUTAppUpdatedNotification"
#define AUTFreshInstallNotification @"AUTFreshInstallNotification"

#define kAUTNotificationUserInfoUseCountKey @"AUTNotificationUserInfoUseCountKey"
#define kAUTNotificationUserInfoOldVersionKey @"AUTNotificationUserInfoOldVersionKey"
#define kAUTNotificationUserInfoFirstUseTimeKey @"AUTNotificationUserInfoFirstUseTimeKey"
#define kAUTNotificationUserInfoInstallCount @"AUTNotificationUserInfoInstallCount"

#define APP_UPDATE_TRACKER_DEBUG 1

/**
 Provides version string comparison methods for convenience sake.
 */
@interface NSString (AUTVersionComparison)

/**
 @returns BOOL indicating if receiver is greater than parameter.
 */
- (BOOL)isGreaterThanVersionString:(NSString *)version;

/**
 @returns BOOL indicating if receiver is greater than or equal to parameter.
 */
- (BOOL)isGreaterThanOrEqualToVersionString:(NSString *)version;

/**
 @returns BOOL indicating if receiver is equal to parameter.
 */
- (BOOL)isEqualToVersionString:(NSString *)version;

/**
 @returns BOOL indicating if receiver is less than parameter.
 */
- (BOOL)isLessThanVersionString:(NSString *)version;

/**
 @returns BOOL indicating if receiver is less than or equal to parameter.
 */
- (BOOL)isLessThanOrEqualToVersionString:(NSString *)version;

@end

/**
 Registering for an event with blocks guarentees that the event that occured during that app session
 will be run *once and only once* (even well after initialization of AppUpdateTracker). This is contrary 
 to the behavior of AUT notifications, that are posted once upon AUT initialization.
 
 One of the three events is guarenteed to be called *once* during an app session.
 */
@interface AppUpdateTracker : NSObject

/**
 Returns singleton instance of AppUpdateTracker.
 */
+ (id)sharedInstance;

// Getters
/**
 Returns the most recent version of the app that has last been seen by AppUpdateTracker.
 
 This will always return the current version of the app *after* AppUpdateTracker has been intialized.
 */
+ (NSString *)getTrackingVersion;
/**
 Returns the version of the app the user updated from or `nil` if no update has been performed.
 
 Value returned from this method is accurate only *after* AppUpdateTracker has been intialized.
 */
+ (NSString *)getPreviousVersion;
/**
 Returns time at which user first opened the app after install represented as time since epoch.
 
 This function uses NSDate's `timeIntervalSince1970`.
 */
+ (NSTimeInterval)getFirstUseTime;
/**
 Returns number of times the current version of the app has been opened.
 
 Counts entries into app from both `application:didFinishLaunchingWithOptions:` and 
 `applicationWillEnterForeground:`.
 */
+ (NSUInteger)getUseCount;
/**
 Returns `YES` if the current session is the first session after updating.
 
 Call this method *after* AppUpdateTracker has been intialized to ensure accurate results.
 */
+ (BOOL)getUserUpgradedApp;

/**
 Registers block parameter to be called when user opens the app for the first time after installing. Block is 
 called once registered, even if this function is called later during the app session.
 */
+ (void)registerForFirstInstallWithBlock:(void (^)(NSTimeInterval installTimeSinceEpoch, NSUInteger installCount))block;
/**
 Registers block parameter to be called when user opens the app and it is not a first time install nor an 
 update event. Block is called once registered, even if this function is called later during the app session.
 */
+ (void)registerForIncrementedUseCountWithBlock:(void (^)(NSUInteger useCount))block;
/**
 Registers block parameter to be called when user opens the app for the first time after updating. Block is 
 called once registered, even if this function is called later during the app session.
 */
+ (void)registerForAppUpdatesWithBlock:(void (^)(NSString *oldVersion))block;

@end
