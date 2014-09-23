App-Update-Tracker
==================

AppUpdateTracker is a simple, very lightweight iOS library intended to detect basic user behavior such as:

- when the user launches the app for the first time
- when the user opens the app after updating, and from which version the user updated from
- number of times the user opened a specific version of the app

The tracking library/system you use is up to you, this library merely gathers the 
aforementioned information.

How to Add to Your Project
==========================

Merely add AppUpdateTracker.m and AppUpdateTracker.h to your project.

Usage
=====

Import AppUpdateTracker.h in your AppDelegate class and make calls to `appDidFinishLaunching` 
and `appWillEnterForeground` in `application:didFinishLaunchingWithOptions:` and
`applicationWillEnterForeground:` callbacks respectively.

**Example:**
```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
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
    [AppUpdateTracker sharedInstance];
    
    //...
}

- (void)appFreshInstall:(NSNotification *)notification {
    NSLog(@"App Fresh Install Notification Received! %@", [[notification userInfo] objectForKey:@"FIRST_USE_TIME"]);
}

- (void)appUpdated:(NSNotification *)notification {
    NSString *oldVersion = [[notification userInfo] objectForKey:@"OLD_VERSION"];
    NSLog(@"App Updated Notification Received! %@", oldVersion);
}

- (void)appUseIncremented:(NSNotification *)notification {
    NSLog(@"App Use Incremented Notification Received! %@", [[notification userInfo] objectForKey:@"USE_COUNT"]);
}
```

License
=======

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

Development
===========

Contributing back to the development of this library is appreciated and encouraged.

Contact
=======

Github username: Stunner
email: technetix@gmail.com