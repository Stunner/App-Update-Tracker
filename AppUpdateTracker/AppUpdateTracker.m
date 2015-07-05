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
#import "AUTKeychainAccess.h"

#if APP_UPDATE_TRACKER_DEBUG
#define AUTLog(fmt, ...) NSLog((@"[AppUpdateTracker] %@ " fmt), [NSThread currentThread], ##__VA_ARGS__)
#else
#define AUTLog(...)
#endif

NSString *const kAUTCurrentVersion = @"kAUTCurrentVersion";
NSString *const kAUTPreviousVersion = @"kAUTPreviousVersion";
NSString *const kAUTFirstUseTime = @"kAUTFirstUseTime";
NSString *const kAUTUseCount = @"kAUTUseCount";
NSString *const kAUTUserUpgradedApp = @"kAUTUserUpgradedApp";
NSString *const kAUTInstallationCount = @"kAUTInstallationCount";

NSString *const kFirstLaunchTimeKey = @"kFirstLaunchTimeKey";
NSString *const kInstallCountKey = @"kInstallCountKey";
NSString *const kUseCountKey = @"kUseCountEventKey";
NSString *const kOldVersionKey = @"kOldVersionKey";

@implementation NSString (AUTVersionComparison)

/**
 Removes ".0" suffixes from string.
 
 Used in order to establish accurate equality in version strings (otherwise 1 < 1.0 < 1.0.0).
 
 Reference: http://stackoverflow.com/a/24811200/347339
 */
- (NSString *)shortenedVersionNumberString {
    static NSString *const unnecessaryVersionSuffix = @".0";
    NSString *shortenedVersionNumber = [self copy];
    
    while ([shortenedVersionNumber hasSuffix:unnecessaryVersionSuffix]) {
        shortenedVersionNumber = [shortenedVersionNumber substringToIndex:shortenedVersionNumber.length - unnecessaryVersionSuffix.length];
    }
    
    return shortenedVersionNumber;
}

- (BOOL)isGreaterThanVersionString:(NSString *)version {
    return ([[self shortenedVersionNumberString] compare:[version shortenedVersionNumberString]
                                                 options:NSNumericSearch] == NSOrderedDescending);
}

- (BOOL)isGreaterThanOrEqualToVersionString:(NSString *)version {
    NSString *shortenedSelf = [self shortenedVersionNumberString];
    NSString *shortenedVersion = [version shortenedVersionNumberString];
    return ([shortenedSelf compare:shortenedVersion options:NSNumericSearch] == NSOrderedDescending ||
            [shortenedSelf compare:shortenedVersion options:NSNumericSearch] == NSOrderedSame);
}

- (BOOL)isEqualToVersionString:(NSString *)version {
    return ([[self shortenedVersionNumberString] compare:[version shortenedVersionNumberString]
                                                 options:NSNumericSearch] == NSOrderedSame);
}

- (BOOL)isLessThanVersionString:(NSString *)version {
    return ([[self shortenedVersionNumberString] compare:[version shortenedVersionNumberString]
                                                 options:NSNumericSearch] == NSOrderedAscending);
}

- (BOOL)isLessThanOrEqualToVersionString:(NSString *)version {
    NSString *shortenedSelf = [self shortenedVersionNumberString];
    NSString *shortenedVersion = [version shortenedVersionNumberString];
    return ([shortenedSelf compare:shortenedVersion options:NSNumericSearch] == NSOrderedAscending ||
            [shortenedSelf compare:shortenedVersion options:NSNumericSearch] == NSOrderedSame);
}

@end

@interface AppUpdateTracker ()

@property (nonatomic, copy) void (^firstInstallBlock)(NSTimeInterval installTimeSinceEpoch, NSUInteger installCount);
@property (nonatomic, copy) void (^useCountBlock)(NSUInteger useCount);
@property (nonatomic, copy) void (^appUpdatedBlock)(NSString *oldVersion);

@property (nonatomic, strong) NSMutableDictionary *postedEventsDictionary;

- (void)incrementUseCount;
- (void)appDidFinishLaunching;

@end

@implementation AppUpdateTracker

- (id)init {
    if (self = [super init]) {
        self.postedEventsDictionary = [[NSMutableDictionary alloc] initWithCapacity:3];
        
        __block AppUpdateTracker *weakSelf = self;
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                          object:nil
                                                           queue:[NSOperationQueue currentQueue]
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

+ (NSString *)getShortVersionString {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

+ (NSString *)getLongVersionString {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
}

+ (NSString *)getTrackingVersion {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kAUTCurrentVersion];
}

+ (NSString *)getPreviousVersion {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kAUTPreviousVersion];
}

+ (NSTimeInterval)getFirstUseTime {
    return (NSTimeInterval)[[NSUserDefaults standardUserDefaults] doubleForKey:kAUTFirstUseTime];
}

+ (NSUInteger)getInstallCount {
    AUTKeychainAccess *keychainAccess = [AUTKeychainAccess new];
    NSData *installationKeyData = [keychainAccess searchKeychainCopyMatching:kAUTInstallationCount];
    if (installationKeyData) {
        NSString *installationCount = [[NSString alloc] initWithData:installationKeyData
                                                            encoding:NSUTF8StringEncoding];
        return [installationCount integerValue];
    }
    return 0; // invalid value
}

+ (NSUInteger)getUseCount {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kAUTUseCount];
}

+ (BOOL)getUserUpgradedApp {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAUTUserUpgradedApp];
}

#pragma mark - Setters

- (void)setFirstInstallBlock:(void (^)(NSTimeInterval installTimeSinceEpoch, NSUInteger installCount))firstInstallBlock {
    _firstInstallBlock = firstInstallBlock;
    NSNumber *firstLaunchTime = [self.postedEventsDictionary objectForKey:kFirstLaunchTimeKey];
    NSNumber *installCount = [self.postedEventsDictionary objectForKey:kInstallCountKey];
    if (firstLaunchTime && installCount) {
        firstInstallBlock([firstLaunchTime doubleValue], [installCount integerValue]);
        [self.postedEventsDictionary removeObjectForKey:kFirstLaunchTimeKey];
        [self.postedEventsDictionary removeObjectForKey:kInstallCountKey];
    }
}

- (void)setUseCountBlock:(void (^)(NSUInteger useCount))useCountBlock {
    _useCountBlock = useCountBlock;
    NSNumber *useCount = [self.postedEventsDictionary objectForKey:kUseCountKey];
    if (useCount) {
        useCountBlock([useCount integerValue]);
        [self.postedEventsDictionary removeObjectForKey:kUseCountKey];
    }
}

- (void)setAppUpdatedBlock:(void (^)(NSString *oldVersion))appUpdatedBlock {
    _appUpdatedBlock = appUpdatedBlock;
    NSString *oldVersion = [self.postedEventsDictionary objectForKey:kOldVersionKey];
    if (oldVersion) {
        appUpdatedBlock(oldVersion);
        [self.postedEventsDictionary removeObjectForKey:kOldVersionKey];
    }
}

#pragma mark - Public

+ (void)registerForFirstInstallWithBlock:(void (^)(NSTimeInterval installTimeSinceEpoch, NSUInteger installCount))block {
    [[AppUpdateTracker sharedInstance] setFirstInstallBlock:block];
}

+ (void)registerForIncrementedUseCountWithBlock:(void (^)(NSUInteger useCount))block {
    [[AppUpdateTracker sharedInstance] setUseCountBlock:block];
}

+ (void)registerForAppUpdatesWithBlock:(void (^)(NSString *oldVersion))block {
    [[AppUpdateTracker sharedInstance] setAppUpdatedBlock:block];
}

#pragma mark - Internal Methods

- (void)incrementUseCount {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    // increment the use count
    NSUInteger useCount = [userDefaults integerForKey:kAUTUseCount];
    useCount++;
    AUTLog(@"useCount++: %lu", (unsigned long)useCount);
    
    [userDefaults setInteger:useCount forKey:kAUTUseCount];
    [userDefaults synchronize];
    
    NSNumber *useCountNumber = @(useCount);
    NSDictionary *userInfo = @{kAUTNotificationUserInfoUseCountKey : useCountNumber};
    [[NSNotificationCenter defaultCenter] postNotificationName:AUTUseCountUpdatedNotification
                                                        object:self
                                                      userInfo:userInfo];
    [self.postedEventsDictionary setObject:useCountNumber forKey:kUseCountKey];
    if (self.useCountBlock) { // TODO: check if these style of blocks are ever called... I'm thinking these may never be used
        self.useCountBlock(useCount);
    }
}

- (void)appDidFinishLaunching {
    
    // get the app's version
    NSString *shortVersion = [AppUpdateTracker getShortVersionString]; //has priority
    NSString *longVersion = [AppUpdateTracker getLongVersionString];
    
    NSString *version = nil;
    if (shortVersion) {
        version = shortVersion;
    } else if (longVersion) {
        version = longVersion;
    } else {
        AUTLog(@"App Update Tracker ERROR: No bundle version found. Current version is nil.");
        return;
    }
    
    // get the version number that we've been tracking
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *trackingVersion = [userDefaults stringForKey:kAUTCurrentVersion];
    
    AUTLog(@"trackingVersion: %@", trackingVersion);
    
    if ([trackingVersion isEqualToString:version]) {
        [self incrementUseCount];
        [userDefaults setBool:NO forKey:kAUTUserUpgradedApp];
        
        // ensure install count entry is created in keychain for legacy users
        AUTKeychainAccess *keychainAccess = [AUTKeychainAccess new];
        NSData *installationKeyData = [keychainAccess searchKeychainCopyMatching:kAUTInstallationCount];
        if (!installationKeyData) {
            [keychainAccess createKeychainValue:@"1" forIdentifier:kAUTInstallationCount];
        }
        
    } else { // it's an upgraded or new version of the app
        if (trackingVersion) { // we have read the old version - user updated app
            AUTLog(@"app updated from %@", trackingVersion);
            
            // app updated to current version from version found in <trackingVersion>
            NSDictionary *userInfo = @{kAUTNotificationUserInfoOldVersionKey : trackingVersion};
            [[NSNotificationCenter defaultCenter] postNotificationName:AUTAppUpdatedNotification
                                                                object:self
                                                              userInfo:userInfo];
            
            // ensure install count entry is created in keychain for legacy users
            AUTKeychainAccess *keychainAccess = [AUTKeychainAccess new];
            NSData *installationKeyData = [keychainAccess searchKeychainCopyMatching:kAUTInstallationCount];
            if (!installationKeyData) {
                [keychainAccess createKeychainValue:@"1" forIdentifier:kAUTInstallationCount];
            }
            
            [self.postedEventsDictionary setObject:trackingVersion forKey:kOldVersionKey];
            if (self.appUpdatedBlock) {
                self.appUpdatedBlock(trackingVersion);
            }
            [userDefaults setBool:YES forKey:kAUTUserUpgradedApp];
            
        } else { // no old version exists - first time opening after install
            AUTLog(@"fresh install detected");
            
            AUTKeychainAccess *keychainAccess = [AUTKeychainAccess new];
            NSData *installationKeyData = [keychainAccess searchKeychainCopyMatching:kAUTInstallationCount];
            NSInteger installationCountInteger = 1;
            if (installationKeyData) {
                NSString *installationCount = [[NSString alloc] initWithData:installationKeyData
                                                                    encoding:NSUTF8StringEncoding];
                installationCountInteger = [installationCount integerValue];
                [keychainAccess updateKeychainValue:[NSString stringWithFormat:@"%lu", (long)++installationCountInteger]
                                      forIdentifier:kAUTInstallationCount];
            } else {
                [keychainAccess createKeychainValue:@"1" forIdentifier:kAUTInstallationCount];
            }
            AUTLog(@"installation count: %lu", (long)installationCountInteger);
            
            NSTimeInterval timeInterval = [userDefaults doubleForKey:kAUTFirstUseTime];
            if (timeInterval == 0) {
                timeInterval = [[NSDate date] timeIntervalSince1970];
                [userDefaults setDouble:timeInterval forKey:kAUTFirstUseTime];
            }
            
            // fresh install of the app
            NSDictionary *userInfo = @{kAUTNotificationUserInfoFirstUseTimeKey : @(timeInterval),
                                       kAUTNotificationUserInfoInstallCount : @(installationCountInteger)};
            [[NSNotificationCenter defaultCenter] postNotificationName:AUTFreshInstallNotification
                                                                object:self
                                                              userInfo:userInfo];
            [self.postedEventsDictionary setObject:@(timeInterval) forKey:kFirstLaunchTimeKey];
            [self.postedEventsDictionary setObject:@(installationCountInteger) forKey:kInstallCountKey];
            if (self.firstInstallBlock) {
                self.firstInstallBlock(timeInterval, installationCountInteger);
            }
            [userDefaults setBool:NO forKey:kAUTUserUpgradedApp];
        }
        // include what version user updated from, nil if user didn't update
        // (only for initial session)
        [userDefaults setObject:trackingVersion forKey:kAUTPreviousVersion];
        [userDefaults setObject:version forKey:kAUTCurrentVersion];
        [userDefaults setDouble:[[NSDate date] timeIntervalSince1970]
                         forKey:kAUTFirstUseTime];
        [userDefaults setInteger:1 forKey:kAUTUseCount];
        
    } // it's an upgraded or new version of the app
    [userDefaults synchronize];
}

@end