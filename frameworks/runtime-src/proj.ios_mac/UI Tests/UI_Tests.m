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

@implementation UI_Tests {
    TFTCPConnection *_conn;
}

- (void)beforeAll {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        _conn = [[TFTCPConnection alloc] initWithHostname:@"localhost" port:6010 timeout:30];
        if ([_conn openSocket]) {
            NSString *req = @"sendrequest {\"cmd\":\"start-logic\",\"debugcfg\":\"nil\"}\nfps off\n";
            [_conn writeData:[req dataUsingEncoding:NSUTF8StringEncoding]];
        }
    });
}

- (void)afterAll {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_conn closeSocket];
    });
}

- (void)testPressStart {
    [tester waitForTimeInterval:1];
    NSArray *windows = [[UIApplication sharedApplication] windowsWithKeyWindow];
    UIGraphicsBeginImageContextWithOptions([[windows objectAtIndex:0] bounds].size, YES, 0);
    for (UIWindow *window in windows) {
        [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData *actual = UIImagePNGRepresentation(image);
    NSString *path = OHPathForFileInBundle(@"ss.png", nil);
    NSData *expected = [NSData dataWithContentsOfFile:path];
    XCTAssertTrue([expected isEqual:actual]);
}

@end
