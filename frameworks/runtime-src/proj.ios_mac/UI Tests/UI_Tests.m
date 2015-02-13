//
//  UI_Tests.m
//  UI Tests
//
//  Created by ntotani on 2015/02/11.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>
#import <KIF/UIApplication-KIFAdditions.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import "TFTCPConnection.h"

@interface UI_Tests : KIFTestCase

@end

@implementation UI_Tests

dispatch_queue_t queue;
TFTCPConnection *_conn;

- (void)beforeAll {
    queue = dispatch_queue_create("org.cocos2dx.MyLuaGame.uitest", NULL);
    XCTestExpectation *exp = [self expectationWithDescription:@"connect"];
    dispatch_async(queue, ^{
        _conn = [[TFTCPConnection alloc] initWithHostname:@"localhost" port:6010 timeout:30];
        if (![_conn openSocket]) {
            XCTFail(@"cant open");
        }
        NSString *req = @"sendrequest {\"cmd\":\"start-logic\",\"debugcfg\":\"nil\"}\n";
        [_conn writeData:[req dataUsingEncoding:NSUTF8StringEncoding]];
        [tester waitForTimeInterval:1];
        [exp fulfill];
    });
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)afterAll {
    dispatch_async(queue, ^{
        [_conn closeSocket];
    });
}

- (void)testPressStart {
    XCTestExpectation *exp = [self expectationWithDescription:@"pressStart"];
    dispatch_async(queue, ^{
        [_conn writeData:[@"sendrequest {\"cmd\":\"reload\",\"modulefiles\":[\"src/test/noRand.lua\"]}\nfps off\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [tester waitForTimeInterval:1];
        //[self saveSS];
        [self assertSS:@"ss.png"];
        [exp fulfill];
    });
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testResult {
    XCTestExpectation *exp = [self expectationWithDescription:@"result"];
    dispatch_async(queue, ^{
        [_conn writeData:[@"sendrequest {\"cmd\":\"reload\",\"modulefiles\":[\"src/test/noRand.lua\"]}\nfps off\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [tester waitForTimeInterval:1];
        [_conn writeData:[@"touch tap 600 600\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [tester waitForTimeInterval:15];
        //[self saveSS];
        [self assertSS:@"result.png"];
        [exp fulfill];
    });
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void)testAlive {
    XCTestExpectation *exp = [self expectationWithDescription:@"alive"];
    dispatch_async(queue, ^{
        [_conn writeData:[@"sendrequest {\"cmd\":\"reload\",\"modulefiles\":[\"src/test/noRand.lua\"]}\nfps off\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [tester waitForTimeInterval:1];
        [_conn writeData:[@"touch tap 600 600\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [tester waitForTimeInterval:11];
        [_conn writeData:[@"touch tap 686 535\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [tester waitForTimeInterval:0.1];
        [_conn writeData:[@"touch tap 560 742\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [tester waitForTimeInterval:0.1];
        [_conn writeData:[@"touch tap 283 617\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [tester waitForTimeInterval:0.1];
        [_conn writeData:[@"touch tap 120 191\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [tester waitForTimeInterval:1];
        //[self saveSS];
        [self assertSS:@"alive.png"];
        [exp fulfill];
    });
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void)assertSS:(NSString*)fileName {
    NSArray *windows = [[UIApplication sharedApplication] windowsWithKeyWindow];
    UIGraphicsBeginImageContextWithOptions([[windows objectAtIndex:0] bounds].size, YES, 0);
    for (UIWindow *window in windows) {
        [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData *actual = UIImagePNGRepresentation(image);
    NSString *path = OHPathForFileInBundle(fileName, nil);
    NSData *expected = [NSData dataWithContentsOfFile:path];
    XCTAssertTrue([expected isEqual:actual]);
}

- (void)saveSS {
    [[UIApplication sharedApplication] writeScreenshotForLine:0 inFile:@"kif" description:@"screenshot" error:nil];
}

@end
