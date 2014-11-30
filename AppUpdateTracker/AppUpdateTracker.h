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

#define APP_UPDATE_TRACKER_DEBUG 1

/**
 Registering for an event with blocks guarentees that the event that occured during that app session
 will be run *once and only once* (even well after initialization of AppUpdateTracker). This is contrary 
 to the behavior of AUT notifications, that are posted once upon initialization.
 */
@interface AppUpdateTracker : NSObject

+ (id)sharedInstance;

// Getters
+ (NSString *)getTrackingVersion;
+ (NSString *)getPreviousVersion;
+ (double)getFirstUseTime;
+ (NSUInteger)getUseCount;

+ (void)registerForFirstInstallWithBlock:(void (^)(NSTimeInterval installTimeSinceEpoch))block;
+ (void)registerForIncrementedUseCountWithBlock:(void (^)(NSUInteger useCount))block;
+ (void)registerForAppUpdatesWithBlock:(void (^)(NSString *oldVersion))block;

@end
