//
//  TCPCommunicator.h
//  BusBus
//
//  Created by Tony Hrabovskyi on 3/30/18.
//  Copyright © 2018 Tony Hrabovskyi. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TCPCommunicatorDelegate <NSObject>

- (void)receiveJSON:(NSDictionary *)json;
- (void)receiveMessage:(NSString *)message;

@optional



@end

@interface TCPCommunicator : NSObject

@property (strong, nonatomic) NSString *        address;
@property (assign, nonatomic) unsigned int      port;

@property (weak, nonatomic) id<TCPCommunicatorDelegate> delegate;

- (instancetype)initWithAddress:(NSString *)address andPort:(NSUInteger)port;
- (void)connectToServer;
- (BOOL)isConnected;
- (void)sendMessage:(NSString *)message;
- (void)sendJSON:(NSDictionary *)json;
- (void)disconnect;

@end
