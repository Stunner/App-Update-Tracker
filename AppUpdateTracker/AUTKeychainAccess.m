//
//  AUTKeychainAccess.m
//  AppUpdateTracker
//
//  Created by Aaron Jubbal on 7/2/15.
//
//

#import "AUTKeychainAccess.h"
#import <Security/Security.h>

// reference: http://useyourloaf.com/blog/2010/03/29/simple-iphone-keychain-access.html
@implementation AUTKeychainAccess

- (NSMutableDictionary *)newSearchDictionary:(NSString *)identifier {
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
    
    [searchDictionary setObject:(id)CFBridgingRelease(kSecClassGenericPassword) forKey:(id)CFBridgingRelease(kSecClass)];
    
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    [searchDictionary setObject:encodedIdentifier forKey:(id)CFBridgingRelease(kSecAttrGeneric)];
    [searchDictionary setObject:encodedIdentifier forKey:(id)CFBridgingRelease(kSecAttrAccount)];
    [searchDictionary setObject:[[NSBundle mainBundle] bundleIdentifier] forKey:(id)CFBridgingRelease(kSecAttrService)];
    
    return searchDictionary;
}

- (NSData *)searchKeychainCopyMatching:(NSString *)identifier {
    NSMutableDictionary *searchDictionary = [self newSearchDictionary:identifier];
    
    // Add search attributes
    [searchDictionary setObject:(__bridge id)(kSecMatchLimitOne) forKey:(__bridge id)(kSecMatchLimit)];
    
    // Add search return types
    [searchDictionary setObject:(id)kCFBooleanTrue forKey:(__bridge id)(kSecReturnData)];
    
    NSData *result = nil;
    CFTypeRef inTypeRef = (__bridge CFTypeRef)result;
    OSStatus __unused status = SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, &inTypeRef);
    result = (__bridge_transfer NSData *)inTypeRef;
    return result;
}

- (BOOL)createKeychainValue:(NSString *)value forIdentifier:(NSString *)identifier {
    NSMutableDictionary *dictionary = [self newSearchDictionary:identifier];
    
    NSData *passwordData = [value dataUsingEncoding:NSUTF8StringEncoding];
    [dictionary setObject:passwordData forKey:(__bridge id)kSecValueData];
    
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);
    
    if (status == errSecSuccess) {
        return YES;
    }
    return NO;
}

- (BOOL)updateKeychainValue:(NSString *)value forIdentifier:(NSString *)identifier {
    
    NSMutableDictionary *searchDictionary = [self newSearchDictionary:identifier];
    NSMutableDictionary *updateDictionary = [[NSMutableDictionary alloc] init];
    NSData *passwordData = [value dataUsingEncoding:NSUTF8StringEncoding];
    [updateDictionary setObject:passwordData forKey:(__bridge id)kSecValueData];
    
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)searchDictionary,
                                    (__bridge CFDictionaryRef)updateDictionary);
    
    if (status == errSecSuccess) {
        return YES;
    }
    return NO;
}

- (void)deleteKeychainValue:(NSString *)identifier {
    
    NSMutableDictionary *searchDictionary = [self newSearchDictionary:identifier];
    SecItemDelete((__bridge CFDictionaryRef)searchDictionary);
}

@end
