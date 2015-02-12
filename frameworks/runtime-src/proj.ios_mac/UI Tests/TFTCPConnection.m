#import "TFTCPConnection.h"

@implementation TFTCPConnection
{
    dispatch_semaphore_t _semaphore;
    
    NSInputStream* _readStream;
    NSOutputStream* _writeStream;
}

- (id)initWithHostname:(NSString*)hostname port:(UInt32)port timeout:(int)timeoutSec
{
    self = [super init];
    if(self){
        _hostname = hostname;
        _port = port;
        _timeoutSec = timeoutSec;
        
        _readStream = nil;
        _writeStream = nil;
    }
    return self;
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    assert(aStream == _readStream || aStream == _writeStream);
    dispatch_semaphore_signal(_semaphore);
}

- (dispatch_time_t)innerDispatch_time
{
    if(_timeoutSec > 0){
        return dispatch_time(DISPATCH_TIME_NOW, (_timeoutSec * NSEC_PER_SEC));
    }else if(_timeoutSec == 0){
        return DISPATCH_TIME_NOW;
    }else{
        return DISPATCH_TIME_FOREVER;
    }
}

- (BOOL)openSocket
{
    BOOL ret = NO;
    
    if(_semaphore) return ret;
    _semaphore = dispatch_semaphore_create(0);
    //dispatch_retain(_semaphore);
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)_hostname,  _port, &readStream,&writeStream);
    
    _readStream = (__bridge_transfer NSInputStream*)readStream;
    _readStream.delegate = self;
    [_readStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    _writeStream = (__bridge_transfer NSOutputStream*)writeStream;
    _writeStream.delegate = self;
    [_writeStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    [_readStream open];
    [_writeStream open];
    
    dispatch_time_t timeout = [self innerDispatch_time];
    
    // 読み込みストリームオープン検査
    while(TRUE){
        NSStreamStatus stat = _readStream.streamStatus;
        if(stat == NSStreamStatusOpen){
            break;
        }else if(stat != NSStreamStatusOpening){
            return ret; // エラー
        }
        if(dispatch_semaphore_wait(_semaphore, timeout)) return ret;
    }
    //  書き出しストリームオープン検査
    while(TRUE){
        NSStreamStatus stat = _writeStream.streamStatus;
        if(stat == NSStreamStatusOpen){
            break;
        }else if(stat != NSStreamStatusOpening){
            return ret; // エラー
        }
        if(dispatch_semaphore_wait(_semaphore, timeout)) return ret;
    }
    return YES;
}

- (void)closeSocket
{
    if(_writeStream){
        _writeStream.delegate = nil;
        [_writeStream close];
        [_writeStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        _writeStream = nil;
    }
    if(_readStream){
        _readStream.delegate = nil;
        [_readStream close];
        [_readStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        _readStream = nil;
    }
    if(_semaphore){
        //dispatch_release(_semaphore);
        _semaphore = nil;
    }
}

- (BOOL)readData:(NSMutableData*)data length:(NSUInteger)len
{
    BOOL ret = NO;
    NSInteger leftlen = len;
    if(leftlen <= 0) return YES;
    dispatch_time_t timeout = [self innerDispatch_time];
    while(TRUE){
        NSStreamStatus stat = _readStream.streamStatus;
        if(stat == NSStreamStatusOpen || stat == NSStreamStatusReading){
            if([_readStream hasBytesAvailable]){
                // 読み込み可能
                uint8_t buf[1024];
                NSInteger maxlen = (sizeof(buf) / sizeof(uint8_t)); // バッファサイズ
                if(maxlen > leftlen) maxlen = leftlen;
                NSInteger count = [_readStream read:buf maxLength:maxlen];
                if(count > 0){
                    [data appendBytes:buf length:count];
                    leftlen -= count;
                    if(leftlen <= 0){
                        // 指定バイト読み込めたので終了
                        ret = YES;
                        break;
                    }
                }else{
                    if(count == 0){
                        NSLog(@"readData eof");
                    }else{
                        NSLog(@"readData error %@",_readStream.streamError.description);
                    }
                    break;
                }
            }
        }else{
            break; // エラー
        }
        if(dispatch_semaphore_wait(_semaphore, timeout)){
            NSLog(@"readData timeout");
            break;
        }
    }
    return ret;
}

- (BOOL)writeData:(NSData*)data
{
    BOOL ret = NO;
    if (data.length == 0) return YES;
    dispatch_time_t timeout = [self innerDispatch_time];
    while (TRUE) {
        NSStreamStatus stat = _writeStream.streamStatus;
        if (stat == NSStreamStatusOpen || stat == NSStreamStatusWriting) {
            if ([_writeStream hasSpaceAvailable]) {
                NSInteger count = [_writeStream write:data.bytes maxLength:data.length];
                if (count >= 0) {
                    ret = YES;
                    break;
                } else {
                    NSLog(@"writeData error %@",_writeStream.streamError.description);
                    break;
                }
            }
        } else {
            break;
        }
        if (dispatch_semaphore_wait(_semaphore, timeout)) {
            NSLog(@"writeData timeout");
            break;
        }
    }
    return ret;
}

@end