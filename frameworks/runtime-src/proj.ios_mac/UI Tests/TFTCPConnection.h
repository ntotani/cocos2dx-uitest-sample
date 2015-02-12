#ifndef rkyun_TFTCPConnection_h
#define rkyun_TFTCPConnection_h

#import <Foundation/Foundation.h>

@interface TFTCPConnection : NSObject<NSStreamDelegate>

@property (readonly, nonatomic) NSString* hostname;
@property (readonly, nonatomic) UInt32 port;
@property (nonatomic) NSInteger timeoutSec;

- (id)initWithHostname:(NSString*)hostname port:(UInt32)port timeout:(int)timeoutSec;

- (BOOL)openSocket;
- (void)closeSocket;
- (BOOL)readData:(NSMutableData*)data length:(NSUInteger)len;
- (BOOL)writeData:(NSData*)data;

@end

#endif
