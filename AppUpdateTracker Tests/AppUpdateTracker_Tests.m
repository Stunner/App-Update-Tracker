//
//  AppUpdateTracker_Tests.m
//  AppUpdateTracker Tests
//
//  Created by Aaron Jubbal on 1/20/15.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "AppUpdateTracker.h"

@interface AppUpdateTracker_Tests : XCTestCase

@end

@implementation AppUpdateTracker_Tests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testVersionStringComparators {
    // This is an example of a functional test case.
    XCTAssert([@"1.0" isGreaterThanVersionString:@"0.9"], @"Pass");
    XCTAssert(![@"1.0" isGreaterThanVersionString:@"1.9"], @"Pass");
    
    XCTAssert([@"1.0" isGreaterThanOrEqualToVersionString:@"0.0"], @"Pass");
    XCTAssert([@"1.0" isGreaterThanOrEqualToVersionString:@"1.0"], @"Pass");
    
    XCTAssert([@"1.0.0" isEqualToVersionString:@"1.0.0"], @"Pass");
    XCTAssert(![@"1.0.0" isEqualToVersionString:@"1.0.01"], @"Pass");
    XCTAssert([@"1.0" isEqualToVersionString:@"1.0.0"], @"Pass");
    
    XCTAssert([@"1.0" isLessThanVersionString:@"1.9"], @"Pass");
    XCTAssert(![@"1.0" isLessThanVersionString:@"0.9"], @"Pass");
    XCTAssert(![@"1.0" isLessThanVersionString:@"1.0"], @"Pass");
    XCTAssert(![@"1.8" isLessThanVersionString:@"1.7.10.2"], @"Pass");
    
    XCTAssert(![@"1.0" isLessThanOrEqualToVersionString:@"0.0"], @"Pass");
    XCTAssert([@"1.0" isLessThanOrEqualToVersionString:@"1.0.0"], @"Pass");
    XCTAssert([@"1.0" isLessThanOrEqualToVersionString:@"2.0"], @"Pass");
}

@end
