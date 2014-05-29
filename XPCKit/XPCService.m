//
//  XPCService.m
//  XPCKit
//
//  Created by Steve Streza on 7/27/11. Copyright 2011 XPCKit.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "XPCService.h"

static void XPCServiceConnectionHandler(xpc_connection_t handler);
static void XPCServiceConnectionHandler(xpc_connection_t handler){
	XPCConnection *connection = [[XPCConnection alloc] initWithConnection:handler];
	[[NSNotificationCenter defaultCenter] postNotificationName:XPCConnectionReceivedNotification object:connection];
	[connection release];
}

@implementation XPCService

@synthesize connectionHandler, connections=_connections;

-(id)initWithConnectionHandler:(XPCConnectionHandler)aConnectionHandler
{
    self = [super init];
    if (self) {
        // Initialization code here.
		self.connectionHandler = aConnectionHandler;
		[[NSNotificationCenter defaultCenter] addObserverForName:XPCConnectionReceivedNotification
														  object:nil 
														   queue:[NSOperationQueue mainQueue]
													  usingBlock:^(NSNotification *note) {
														  XPCConnection *connection = [note object];
														  [self handleConnection:connection];
													  }];
    }
    
    return self;
}

+(void)runService{
	xpc_main(XPCServiceConnectionHandler);
}

+(void) runMachService
{
    xpc_connection_t connection = xpc_connection_create_mach_service([[[NSBundle mainBundle] bundleIdentifier] cStringUsingEncoding:NSUTF8StringEncoding],dispatch_get_main_queue(),XPC_CONNECTION_MACH_SERVICE_LISTENER);
    
    if(!connection)
    {
        // Try to safely warn of an issue. This stems from C# development, if there are better methods fork/fix!
        [NSException raise:@"Unable to create mach service." format:@"connection == NULL"];
        return;
    }
    
    xpc_connection_set_event_handler(connection, ^(xpc_object_t connection)
    {
        XPCServiceConnectionHandler(connection);
    });
    
    xpc_connection_resume(connection);
}

-(void)handleConnection:(XPCConnection *)connection{
	if(!_connections){
		_connections = [[NSMutableArray alloc] init];
	}

	[(NSMutableArray *)self.connections addObject:connection];
	
//	[connection sendLog:@"We got a connection"];
	
	if(self.connectionHandler){
		self.connectionHandler(connection);
	}
}

+(void)runServiceWithConnectionHandler:(XPCConnectionHandler)connectionHandler{
	XPCService *service = [[XPCService alloc] initWithConnectionHandler:connectionHandler];
	
	[XPCService runService];
	
	[service release];
}

@end
