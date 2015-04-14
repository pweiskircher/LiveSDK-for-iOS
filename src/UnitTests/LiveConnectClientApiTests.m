//
//  LiveConnectClientApiTests.m
//  Live SDK for iOS
//
//  Copyright 2015 Microsoft Corporation
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//


#import "JsonWriter.h"
#import "LiveAuthRefreshRequest.h"
#import "LiveAuthStorage.h"
#import "LiveConnectClientApiTests.h"
#import "LiveConnectClient.h"
#import "LiveConnectClientListener.h"
#import "LiveConnectionHelper.h"
#import "MockResponse.h"
#import "MockUrlConnection.h"
#import "LiveTemporaryAuthStorage.h"

@interface LiveConnectClientApiTests ()

@property (nonatomic) id<LiveAuthStorage> authStorage;

@end

@implementation LiveConnectClientApiTests
@synthesize factory, clientId, listener;

#pragma mark - Utility methods

- (void) setRefreshToken:(NSString *)refreshToken
{
    self.authStorage.refreshToken = refreshToken;
}

- (void) clearStorage
{
    [self setRefreshToken:nil];
}

- (LiveConnectClient *) createAuthenticatedClient
{
    [self setRefreshToken:@"refresh token"];
    
    NSArray *scopes = @[@"wl.signin", @"wl.basic"];
    NSString *userState = @"init";
    LiveConnectClient *liveClient = [[LiveConnectClient alloc] initWithClientId:self.clientId
                                                                    authStorage:self.authStorage
                                                                          scopes:scopes 
                                                                        delegate:self.listener 
                                                                       userState:userState];
    
    // Validate outbound request
    MockUrlConnection *connection = [self.factory fetchRequestConnection];
    NSURLRequest *request = connection.request;
    
    XCTAssertEqualObjects(@"POST", [request HTTPMethod], @"Method should be POST");
    XCTAssertEqualObjects(@"https://login.live.com/oauth20_token.srf", request.URL.absoluteString, @"Invalid url");

    
    // set response
    id delegate = connection.delegate;
    MockResponse *response = [[MockResponse alloc] init];
    response.statusCode = 200;
    [delegate connection:connection didReceiveResponse:response];
    
    // set response data
    NSString *accessToken = @"accesstoken";
    NSString *authenticationToken = @"authtoken";
    NSString *refreshToken = @"refreshtoken";
    NSString *scopesStr = @"wl.signin wl.basic";
    NSString *expiresIn = @"3600";
    
    NSDictionary *responseDict = @{LIVE_AUTH_ACCESS_TOKEN: accessToken, 
                                  LIVE_AUTH_AUTHENTICATION_TOKEN: authenticationToken,
                                  LIVE_AUTH_REFRESH_TOKEN: refreshToken,
                                  LIVE_AUTH_SCOPE: scopesStr, LIVE_AUTH_EXPIRES_IN: expiresIn};
    NSString *responseText = [MSJSONWriter textForValue:responseDict];
    NSData *data = [responseText dataUsingEncoding:NSUTF8StringEncoding]; 
    [delegate connection:connection didReceiveData:data]; 
    
    // notify complete
    [delegate connectionDidFinishLoading:connection];
    
    // validate event
    XCTAssertEqual((NSUInteger)1, listener.events.count, @"Should receive 1 event.");
    
    NSDictionary *eventArgs = [listener fetchEvent];
    
    XCTAssertEqual(LiveAuthConnected, (LiveConnectSessionStatus)[eventArgs[LIVE_UNIT_STATUS] intValue], @"Invalid status");
    XCTAssertNotNil(eventArgs[LIVE_UNIT_SESSION], @"session should not be nil");
    XCTAssertEqualObjects(userState, eventArgs[LIVE_UNIT_USERSTATE], @"incorrect userState");
    
    return liveClient;
}

#pragma mark - Set up and tear down


- (void) setUp 
{
    self.clientId = @"56789999932";
    self.factory = [MockFactory factory];
    self.authStorage = [LiveTemporaryAuthStorage new];
    [LiveConnectionHelper setLiveConnectCreator:self.factory];
    self.listener = [[LiveConnectClientListener alloc]init];
    [self clearStorage];
}

- (void) tearDown 
{
    [self clearStorage];
    self.factory = nil;
    [LiveConnectionHelper setLiveConnectCreator:nil];
    self.listener = nil;
}

#pragma mark - Test cases

- (void) testGet
{
    NSString *path = @"me";
    NSString *userState = @"getme";
    LiveConnectClient *liveClient = [self createAuthenticatedClient];
    
    LiveOperation * operation = [liveClient getWithPath:path
                                               delegate:self.listener 
                                              userState:userState];
    
    XCTAssertEqualObjects(path, operation.path, @"Path invalid");
    XCTAssertEqualObjects(@"GET", operation.method, @"METHOD invalid");
    
    // We should get an async event right away. We use the NSRunLoop to allow the async event to kick in.
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:10];
    while ((listener.events.count == 0) && ([timeout timeIntervalSinceNow] > 0)) 
    {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2.0]];
        NSLog(@"Polling...");
    }
    
    // Validate outbound request
    MockUrlConnection *connection = [self.factory fetchRequestConnection];
    NSURLRequest *request = connection.request;
    
    XCTAssertEqualObjects(@"GET", [request HTTPMethod], @"Method should be GET");
    XCTAssertEqualObjects(@"https://apis.live.net/v5.0/me?suppress_response_codes=true&suppress_redirects=true", request.URL.absoluteString, @"Invalid url");
    
    
    // set response
    id delegate = connection.delegate;
    MockResponse *response = [[MockResponse alloc] init];
    response.statusCode = 200;
    [delegate connection:connection didReceiveResponse:response];
    
    // set response data
    NSString *cid = @"aw383339";
    NSString *name = @"Alice W.";
    NSString *gender = @"female";
    
    NSDictionary *responseDict = @{@"id": cid, 
                                  @"name": name,
                                  @"gender": gender};
    NSString *responseText = [MSJSONWriter textForValue:responseDict];
    NSData *data = [responseText dataUsingEncoding:NSUTF8StringEncoding]; 
    [delegate connection:connection didReceiveData:data]; 
    
    // notify complete
    [delegate connectionDidFinishLoading:connection];
    
    // validate event
    XCTAssertEqual((NSUInteger)1, listener.events.count, @"Should receive 1 event.");
    
    NSDictionary *eventArgs = [listener fetchEvent];
    
    XCTAssertEqual(LIVE_UNIT_OPCOMPLETED, eventArgs[LIVE_UNIT_EVENT], @"Incorrect event.");
    XCTAssertNotNil(eventArgs[LIVE_UNIT_OPERATION], @"operation should be nil");
    XCTAssertEqualObjects(operation, eventArgs[LIVE_UNIT_OPERATION], @"operation instance should be the same.");
    
    XCTAssertNotNil(operation.rawResult, @"rawresult should not be nil");
    
    XCTAssertEqualObjects(cid, (operation.result)[@"id"], @"Incorrect id value");
    XCTAssertEqualObjects(name, (operation.result)[@"name"], @"Incorrect name value");
    XCTAssertEqualObjects(gender, (operation.result)[@"gender"], @"Incorrect gender value");    
}

- (void) testPost
{
    NSString *path = @"me/contacts";
    NSString *userState = @"create a contact";
    NSString *firstName = @"Alice";
    NSString *lastName = @"Wang";
    LiveConnectClient *liveClient = [self createAuthenticatedClient];
    NSDictionary *dictBody = @{@"first_name": firstName, @"last_name": lastName};
    NSString *jsonBody = [MSJSONWriter textForValue:dictBody];
    LiveOperation * operation = [liveClient postWithPath:path dictBody:dictBody delegate:self.listener userState:userState];
    
    XCTAssertEqualObjects(path, operation.path, @"Path invalid");
    XCTAssertEqualObjects(@"POST", operation.method, @"METHOD invalid");
    
    // We should get an async event right away. We use the NSRunLoop to allow the async event to kick in.
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:10];
    while ((listener.events.count == 0) && ([timeout timeIntervalSinceNow] > 0)) 
    {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2.0]];
        NSLog(@"Polling...");
    }
    
    // Validate outbound request
    MockUrlConnection *connection = [self.factory fetchRequestConnection];
    NSURLRequest *request = connection.request;
    
    XCTAssertEqualObjects(@"POST", [request HTTPMethod], @"Method should be POST");
    XCTAssertEqualObjects(@"https://apis.live.net/v5.0/me/contacts?suppress_response_codes=true&suppress_redirects=true", request.URL.absoluteString, @"Invalid url");
    XCTAssertEqualObjects(jsonBody,  [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding], @"Request body incorrrect.");
    XCTAssertEqualObjects(LIVE_API_HEADER_CONTENTTYPE_JSON, [request valueForHTTPHeaderField:LIVE_API_HEADER_CONTENTTYPE], @"Incorrect content-type.");
    
    // set response
    id delegate = connection.delegate;
    MockResponse *response = [[MockResponse alloc] init];
    response.statusCode = 200;
    [delegate connection:connection didReceiveResponse:response];
    
    // set response data
    NSString *cid = @"aw383339";
    NSString *name = @"Alice W.";
    NSString *gender = @"female";
    
    NSDictionary *responseDict = @{@"id": cid, 
                                  @"name": name,
                                  @"gender": gender};
    NSString *responseText = [MSJSONWriter textForValue:responseDict];
    NSData *data = [responseText dataUsingEncoding:NSUTF8StringEncoding]; 
    [delegate connection:connection didReceiveData:data]; 
    
    // notify complete
    [delegate connectionDidFinishLoading:connection];
    
    // validate event
    XCTAssertEqual((NSUInteger)1, listener.events.count, @"Should receive 1 event.");
    
    NSDictionary *eventArgs = [listener fetchEvent];
    
    XCTAssertEqual(LIVE_UNIT_OPCOMPLETED, eventArgs[LIVE_UNIT_EVENT], @"Incorrect event.");
    XCTAssertNotNil(eventArgs[LIVE_UNIT_OPERATION], @"operation should be nil");
    XCTAssertEqualObjects(operation, eventArgs[LIVE_UNIT_OPERATION], @"operation instance should be the same.");
    
    XCTAssertNotNil(operation.rawResult, @"rawresult should not be nil");
    
    XCTAssertEqualObjects(cid, (operation.result)[@"id"], @"Incorrect id value");
    XCTAssertEqualObjects(name, (operation.result)[@"name"], @"Incorrect name value");
    XCTAssertEqualObjects(gender, (operation.result)[@"gender"], @"Incorrect gender value");    
}

- (void) testCopy
{
    NSString *path = @"file.12345678";
    NSString *destination = @"folder.232323444";
    NSString *userState = @"copy a file";
    LiveConnectClient *liveClient = [self createAuthenticatedClient];
    
    LiveOperation * operation = [liveClient copyFromPath:path toDestination:destination delegate:self.listener userState:userState];
                                 
    XCTAssertEqualObjects(path, operation.path, @"Path invalid");
    XCTAssertEqualObjects(@"COPY", operation.method, @"Method invalid");
    
    // We should get an async event right away. We use the NSRunLoop to allow the async event to kick in.
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:10];
    while ((listener.events.count == 0) && ([timeout timeIntervalSinceNow] > 0)) 
    {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2.0]];
        NSLog(@"Polling...");
    }
    
    // Validate outbound request
    MockUrlConnection *connection = [self.factory fetchRequestConnection];
    NSURLRequest *request = connection.request;
    
    XCTAssertEqualObjects(@"COPY", [request HTTPMethod], @"Method should be COPY");
    XCTAssertEqualObjects(@"https://apis.live.net/v5.0/file.12345678?suppress_response_codes=true&suppress_redirects=true", request.URL.absoluteString, @"Invalid url");
   
    NSDictionary *dictBody = @{@"destination": destination};
    NSString *jsonBody = [MSJSONWriter textForValue:dictBody];
    XCTAssertEqualObjects(jsonBody,[[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding], @"Request body incorrrect.");
    XCTAssertEqualObjects(LIVE_API_HEADER_CONTENTTYPE_JSON, [request valueForHTTPHeaderField:LIVE_API_HEADER_CONTENTTYPE], @"Incorrect content-type.");
    
    NSString *tokenHeader = [NSString stringWithFormat:@"bearer %@", liveClient.session.accessToken];
    XCTAssertEqualObjects(tokenHeader, [request valueForHTTPHeaderField:LIVE_API_HEADER_AUTHORIZATION], @"Token invalid");
    
    // set response
    id delegate = connection.delegate;
    MockResponse *response = [[MockResponse alloc] init];
    response.statusCode = 200;
    [delegate connection:connection didReceiveResponse:response];
    
    // set response data
    
    NSString *name = @"Alice W.";
    
    NSDictionary *responseDict = @{@"id": path, 
                                  @"name": name};
    NSString *responseText = [MSJSONWriter textForValue:responseDict];
    NSData *data = [responseText dataUsingEncoding:NSUTF8StringEncoding]; 
    [delegate connection:connection didReceiveData:data]; 
    
    // notify complete
    [delegate connectionDidFinishLoading:connection];
    
    // validate event
    XCTAssertEqual((NSUInteger)1, listener.events.count, @"Should receive 1 event.");
    
    NSDictionary *eventArgs = [listener fetchEvent];
    
    XCTAssertEqual(LIVE_UNIT_OPCOMPLETED, eventArgs[LIVE_UNIT_EVENT], @"Incorrect event.");
    XCTAssertNotNil(eventArgs[LIVE_UNIT_OPERATION], @"operation should be nil");
    XCTAssertEqualObjects(operation, eventArgs[LIVE_UNIT_OPERATION], @"operation instance should be the same.");
    
    XCTAssertNotNil(operation.rawResult, @"rawresult should not be nil");
    
    XCTAssertEqualObjects(path, (operation.result)[@"id"], @"Incorrect id value");
    XCTAssertEqualObjects(name, (operation.result)[@"name"], @"Incorrect name value");   
}

@end
