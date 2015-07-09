App-Update-Tracker
==================

AppUpdateTracker is a simple, lightweight iOS library intended to determine basic app install/update behavior. The following is a list of when events are triggered:

* when the user launches the app for the first time, provides:
  * **timestamp** of when user opened app for the first time, in seconds since epoch
  * **installation count** representing the number of times the user has opened the app for the first time on the same device
* when the user opens the app for the first time after updating, provides:
  * the **previous version** the user updated from
  * the **current version** of the app (provided for convenience)
* when the user brings the app to the foreground, provides:
  * **usage count** representing how many times the app has been opened (includes bringing app to foreground after resigning active, not only cold start)

This library posts an alert or executes a block with information on one (and only one) of the 3 aforementioned behaviors per app session (each time the app is run).

# How to Add to Your Project

### CocoaPods

To install with [CocoaPods](http://cocoapods.org/) include the following in your Podfile:

```ruby
pod 'App-Update-Tracker', '~> 2.0'
```

Then install:

```ruby
$ pod install
```

Consult the ["Getting Started"](https://github.com/AFNetworking/AFNetworking/wiki/Getting-Started-with-AFNetworking) guide (taken from the lovely AFNetworking project) for more information.

### The Old Fashioned Way

Merely copy the AppUpdateTracker folder (and its contents) to your project.

# Usage


Import `AppUpdateTracker.h` in your `AppDelegate` class and register for `AppUpdateTracker` events within the `application:didFinishLaunchingWithOptions:` method:

```
#import "AppUpdateTracker.h"

//...

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    [AppUpdateTracker registerForAppUpdatesWithBlock:^(NSString *previousVersion, NSString *currentVersion) {
        NSLog(@"app updated from: %@ to: %@", previousVersion, currentVersion);
    }];
    [AppUpdateTracker registerForFirstInstallWithBlock:^(NSTimeInterval installTimeSinceEpoch, NSUInteger installCount) {
        NSLog(@"first install detected at: %f amount of times app was (re)installed: %lu", installTimeSinceEpoch, (unsigned long)installCount);
    }];
    [AppUpdateTracker registerForIncrementedUseCountWithBlock:^(NSUInteger useCount) {
        NSLog(@"incremented use count to: %lu", (unsigned long)useCount);
    }];
    
    //...
}
```

Consult the sample project for more info.

# Migration

### 1.x to 2.0

Potential codebreaking changes:
* Added `installCount` to first install event, this changes the first install block registration method to `+ (void)registerForFirstInstallWithBlock:(void (^)(NSTimeInterval installTimeSinceEpoch, NSUInteger installCount))block`.
* Changed `oldVersion` to `previousVersion` for app updated event, this changes the notification previous version key to `kAUTNotificationUserInfoPreviousVersionKey`.
* Added `currentVersion` to app updateded event, this changes the app updated block registration method to `+ (void)registerForAppUpdatesWithBlock:(void (^)(NSString *previousVersion, NSString *currentVersion))block`.
* Changed `+ (BOOL)getUserUpgradedApp` to `+ (BOOL)getUserUpdatedApp`.

# License

MIT License

Copyright (c) 2012, Aaron Jubbal
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
