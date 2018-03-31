//
//  TCPCommunicator.m
//  BusBus
//
//  Created by Tony Hrabovskyi on 3/30/18.
//  Copyright © 2018 Tony Hrabovskyi. All rights reserved.
//

#import "TCPCommunicator.h"

@interface TCPCommunicator () <NSStreamDelegate>

@property (strong, nonatomic) NSInputStream *inputStream;
@property (strong, nonatomic) NSOutputStream *outputStream;

@end

@implementation TCPCommunicator

#pragma mark - Public Methods

- (instancetype)initWithAddress:(NSString *)address andPort:(NSUInteger)port {
    self = [super init];
    if (self) {
        _address = address;
        _port = (unsigned int)port;
    }
    return self;
}


- (void)connectToServer {
    if (self.address == nil || self.port == 0 || [self isConnecting] || [self isConnected])
        return;
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    CFStreamCreatePairWithSocketToHost(nil, (__bridge CFStringRef) _address, _port, &readStream, &writeStream);
    
    _outputStream = (__bridge NSOutputStream *)writeStream;
    _inputStream = (__bridge NSInputStream *)readStream;
    
    [_outputStream setDelegate:self];
    [_inputStream setDelegate:self];
    
    [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [_outputStream open];
    [_inputStream open];
}


- (void)sendMessage:(NSString *)message {
    if (![self isConnected]) {
        // handle not connected sending
        return;
    }
    
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    [self sendData:data];
        
}

- (void)sendJSON:(NSDictionary *)json {
    if (![self isConnected]) {
        // handle not connected sending
        return;
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
    [self sendData:data];
}

- (BOOL)isConnected {
    return (_inputStream.streamStatus == NSStreamStatusOpen || _inputStream.streamStatus == NSStreamStatusReading)
       && (_outputStream.streamStatus == NSStreamStatusOpen || _outputStream.streamStatus == NSStreamStatusWriting);
}

- (BOOL)isConnecting {
    return _inputStream.streamStatus == NSStreamStatusOpening || _outputStream.streamStatus == NSStreamStatusOpening;
}

- (void)disconnect {
    
    [_inputStream close];
    [_outputStream close];
    
    [_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [_inputStream setDelegate:nil];
    [_outputStream setDelegate:nil];
    
    _inputStream = nil;
    _outputStream = nil;
}

#pragma mark - Private Methods

- (void)sendData:(NSData *)data {
    if (data == nil || data.length == 0)
        return;
    
    [_outputStream write:[data bytes] maxLength:[data length]];
}

- (void)parseResponce:(NSData *)data {
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    if (json) {
        [self.delegate receiveJSON:json];
        return;
    }
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (message) {
        [self.delegate receiveMessage:message];
        return;
    }
    
    // Error with Parse
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent  {
    
    switch (streamEvent) {
            
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened");
            break;
        case NSStreamEventHasBytesAvailable:
            
            if (theStream == _inputStream)
            {
                uint8_t buffer[1024];
                NSInteger len;
                NSMutableData *data = [[NSMutableData alloc] init];
                
                while ([_inputStream hasBytesAvailable])
                {
                    len = [_inputStream read:buffer maxLength:sizeof(buffer)];
                    [data appendBytes:(const void *)buffer length:len];
                }
                
                NSString *responce = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                NSLog(@"server message: %@", responce);
                [self parseResponce:data];
                
            }
            break;
            
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"Stream has space available now");
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Stream Error: %@",[theStream streamError].localizedDescription);
            break;
            
        case NSStreamEventEndEncountered:
            
            [self disconnect];
            NSLog(@"close stream");
            break;
        default:
            NSLog(@"Unknown event");
    }
    
}


@end
