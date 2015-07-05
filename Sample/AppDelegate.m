//
//  AppDelegate.m
//  AppUpdateTracker
//
/* 
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
 */


#import "AppDelegate.h"

#import "ViewController.h"
#import "AppUpdateTracker.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (void)appFreshInstall:(NSNotification *)notification {
    NSLog(@"App Fresh Install Notification Received! Install count: %@ install time: %@ from thread: %@",
          [[notification userInfo] objectForKey:kAUTNotificationUserInfoInstallCount],
          [[notification userInfo] objectForKey:kAUTNotificationUserInfoFirstUseTimeKey], [NSThread currentThread]);
}

- (void)appUpdated:(NSNotification *)notification {
    NSLog(@"App Updated Notification Received! %@ from thread: %@",
          [[notification userInfo] objectForKey:kAUTNotificationUserInfoOldVersionKey], [NSThread currentThread]);
}

- (void)appUseIncremented:(NSNotification *)notification {
    NSLog(@"App Use Incremented Notification Received! %@ from thread: %@",
          [[notification userInfo] objectForKey:kAUTNotificationUserInfoUseCountKey], [NSThread currentThread]);
}

- (void)setUpAppUpdateTracker {
    
    // for logging purposes only -- so that we can see the main thread labeled as 'main' and background thread labeled as 'background'
    if ([NSThread currentThread] == [NSThread mainThread]) {
        [[NSThread currentThread] setName:@"main"];
    } else {
        [[NSThread currentThread] setName:@"background"];
    }
    
    ///////////////////////////////////////////////////////
    // register for AUT events through notifications: //
    ///////////////////////////////////////////////////////
    
    // if you want to register for AppUpdateTracker events:
    // IMPORTANT: Must subscribe to notifications *before* initializing the tracker, like so:
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appFreshInstall:)
                                                 name:AUTFreshInstallNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appUpdated:)
                                                 name:AUTAppUpdatedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appUseIncremented:)
                                                 name:AUTUseCountUpdatedNotification
                                               object:nil];
    [AppUpdateTracker sharedInstance]; // initialize the tracker
    
    ////////////////////////////////////////////////
    // OR register for AUT events through blocks: //
    ////////////////////////////////////////////////
    
    // Note: Above call to [AppUpdateTracker sharedInstance] is not necessary when registering for blocks (the call is made internally):
    [AppUpdateTracker registerForAppUpdatesWithBlock:^(NSString *oldVersion) {
        NSLog(@"app updated from: %@ on thread: %@", oldVersion, [NSThread currentThread]);
    }];
    [AppUpdateTracker registerForFirstInstallWithBlock:^(NSTimeInterval installTimeSinceEpoch, NSUInteger installCount) {
        NSLog(@"installed %lu times (inclusive), installed at: %f on thread: %@", (unsigned long)installCount, installTimeSinceEpoch, [NSThread currentThread]);
    }];
    [AppUpdateTracker registerForIncrementedUseCountWithBlock:^(NSUInteger useCount) {
        NSLog(@"incremented use count to: %lu on thread: %@", (unsigned long)useCount, [NSThread currentThread]);
    }];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"before AUT init > previous version %@", [AppUpdateTracker getPreviousVersion]);
    NSLog(@"before AUT init > tracking version %@", [AppUpdateTracker getTrackingVersion]);
    
    // to test and see how AppUpdateTracker handles various threading scenarios
    BOOL setupAUTOnMainThread = YES;
    if (setupAUTOnMainThread) {
        [self setUpAppUpdateTracker];
    } else {
        [self performSelectorInBackground:@selector(setUpAppUpdateTracker) withObject:nil];
    }
    
    NSLog(@"after AUT init > previous version %@", [AppUpdateTracker getPreviousVersion]);
    NSLog(@"after AUT init > tracking version %@", [AppUpdateTracker getTrackingVersion]);
    
    // the usual application:didFinishLaunchingWithOptions: stuff...
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.viewController = [[ViewController alloc] initWithNibName:@"ViewController_iPhone" bundle:nil];
    } else {
        self.viewController = [[ViewController alloc] initWithNibName:@"ViewController_iPad" bundle:nil];
    }
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
