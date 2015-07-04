//
//  AUTKeychainAccess.h
//  AppUpdateTracker
//
//  Created by Aaron Jubbal on 7/2/15.
//
//

#import <Foundation/Foundation.h>

@interface AUTKeychainAccess : NSObject

- (NSData *)searchKeychainCopyMatching:(NSString *)identifier;

- (BOOL)createKeychainValue:(NSString *)value forIdentifier:(NSString *)identifier;

- (BOOL)updateKeychainValue:(NSString *)value forIdentifier:(NSString *)identifier;

- (void)deleteKeychainValue:(NSString *)identifier;

@end
