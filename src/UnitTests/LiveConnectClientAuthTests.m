//
//  LiveAuthRefreshRequestTests.m
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
#import "LiveConnectClientAuthTests.h"
#import "LiveAuthRefreshRequest.h"
#import "LiveAuthStorage.h"
#import "LiveConnectClient.h"
#import "LiveConnectClientListener.h"
#import "LiveConnectionHelper.h"
#import "MockResponse.h"
#import "MockUrlConnection.h"

@implementation LiveConnectClientAuthTests

@synthesize factory, clientId;

#pragma mark - Utility methods

- (void) setRefreshToken:(NSString *)refreshToken
{
    LiveAuthStorage *storage = [[LiveAuthStorage alloc] initWithClientId:self.clientId];
    storage.refreshToken = refreshToken;
}

- (void) clearStorage
{
    [self setRefreshToken:nil];
}

#pragma mark - Set up and tear down


- (void) setUp 
{
    self.clientId = @"56789999932";
    self.factory = [MockFactory factory];
    [LiveConnectionHelper setLiveConnectCreator:self.factory];
    
    [self clearStorage];
}

- (void) tearDown 
{
    [self clearStorage];
    
    self.factory = nil;
    [LiveConnectionHelper setLiveConnectCreator:nil];
}

#pragma mark - Test cases

- (void) testInitWithoutRefreshToken
{
    NSArray *scopes = @[@"wl.signin", @"wl.basic"];
    LiveConnectClientListener *listener = [[LiveConnectClientListener alloc]init];
    NSString *userState = @"init";
    LiveConnectClient *liveClient = [[LiveConnectClient alloc] initWithClientId:self.clientId 
                                                                          scopes:scopes 
                                                                        delegate:listener 
                                                                       userState:userState];
  
    // We should get an async event right away. We use the NSRunLoop to allow the async event to kick in.
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:10];
    while ((listener.events.count == 0) && ([timeout timeIntervalSinceNow] > 0)) 
    {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2.0]];
        NSLog(@"Polling...");
    }
    
    XCTAssertEqual((NSUInteger)1, listener.events.count, @"Should receive 1 event.");
    
    NSDictionary *eventArgs = [listener fetchEvent];
    XCTAssertEqual(LIVE_UNIT_AUTHCOMPLETED, eventArgs[LIVE_UNIT_EVENT], @"Incorrect event.");
    XCTAssertEqual(LiveAuthUnknown, (LiveConnectSessionStatus)[eventArgs[LIVE_UNIT_STATUS] intValue], @"Invalid status");
    XCTAssertNil(eventArgs[LIVE_UNIT_SESSION], @"session should be nil");
    XCTAssertEqualObjects(userState, eventArgs[LIVE_UNIT_USERSTATE], @"incorrect userState");
    
}

- (void) testInitWithRefreshToken
{
    [self setRefreshToken:@"refresh token"];
    
    NSArray *scopes = @[@"wl.signin", @"wl.basic"];
    LiveConnectClientListener *listener = [[LiveConnectClientListener alloc]init];
    NSString *userState = @"init";
    LiveConnectClient *liveClient = [[LiveConnectClient alloc] initWithClientId:self.clientId 
                                                                          scopes:scopes 
                                                                        delegate:listener 
                                                                       userState:userState];
    
    // Validate outbound request
    MockUrlConnection *connection = [self.factory fetchRequestConnection];
    NSURLRequest *request = connection.request;
    
    XCTAssertEqualObjects(@"POST", [request HTTPMethod], @"Method should be POST");
    XCTAssertEqualObjects(@"https://login.live.com/oauth20_token.srf", request.URL.absoluteString, @"Invalid url");
    
    NSString *requestBodyString = [[NSString alloc] initWithData:request.HTTPBody
                                                         encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(@"client_id=56789999932&refresh_token=refresh%20token&scope=wl.signin%20wl.basic&grant_type=refresh_token", requestBodyString, @"Invalid url");
    XCTAssertEqualObjects(LIVE_AUTH_POST_CONTENT_TYPE, [request valueForHTTPHeaderField:LIVE_API_HEADER_CONTENTTYPE], @"Incorrect content-type.");
        

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
    XCTAssertEqual(LIVE_UNIT_AUTHCOMPLETED, eventArgs[LIVE_UNIT_EVENT], @"Incorrect event.");
    XCTAssertEqual(LiveAuthConnected, (LiveConnectSessionStatus)[eventArgs[LIVE_UNIT_STATUS] intValue], @"Invalid status");
    XCTAssertNotNil(eventArgs[LIVE_UNIT_SESSION], @"session should not be nil");
    XCTAssertEqualObjects(userState, eventArgs[LIVE_UNIT_USERSTATE], @"incorrect userState");
    
    LiveConnectSession *session = eventArgs[LIVE_UNIT_SESSION];
    
    XCTAssertEqualObjects(accessToken, session.accessToken, @"Incorrect access_token");
    XCTAssertEqualObjects(authenticationToken, session.authenticationToken, @"Incorrect authentication_token");
    XCTAssertEqualObjects(refreshToken, session.refreshToken, @"Incorrect refresh_token");
     
    XCTAssertEqual((NSUInteger)2, session.scopes.count, @"Incorrect scopes");
    XCTAssertEqualObjects(@"wl.signin", (session.scopes)[0], @"Incorrect scopes");
    XCTAssertEqualObjects(@"wl.basic", (session.scopes)[1], @"Incorrect scopes");
    XCTAssertTrue([session.expires timeIntervalSinceNow] < 3600, @"Invalid expires value");
    XCTAssertTrue([session.expires timeIntervalSinceNow] > 3500, @"Invalid expires value");
}
@end
