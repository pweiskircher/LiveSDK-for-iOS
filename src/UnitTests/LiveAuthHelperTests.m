//
//  LiveAuthHelperTests.m
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


#import "LiveAuthHelper.h"
#import "LiveAuthHelperTests.h"
#import "LiveConnectSession.h"

@implementation LiveAuthHelperTests

#pragma mark scopes utility

- (void) testNormalizeScopes
{
    NSArray *array1 = [LiveAuthHelper normalizeScopes:nil];
    XCTAssertNotNil(array1, @"We should return empty NSArray");
    XCTAssertEqual((NSUInteger)0, array1.count, @"Incorrect array count value.");
    
    NSArray *array2 = [LiveAuthHelper normalizeScopes:@[@"WL.SignIn", @"WL.Basic", @"", @" "]];
    XCTAssertNotNil(array2, @"We should return not nil NSArray");
    XCTAssertEqual((NSUInteger)2, array2.count, @"We should return the same size of array");
    XCTAssertEqualObjects(@"wl.signin", array2[0], @"We should lower case string values");
    XCTAssertEqualObjects(@"wl.basic", array2[1], @"We should lower case string values");
}

- (void) testIsScopesSubSetOf
{
    NSArray *array1 = @[@"wl.signin", @"wl.basic"];
    NSArray *array2 = @[@"wl.basic", @"wl.signin"];
    NSArray *array3 = @[@"wl.basic", @"wl.share", @"wl.signin"];
    NSArray *array4 = @[@"wl.share", @"wl.signin"];    

    XCTAssertTrue([LiveAuthHelper isScopes:array1 subSetOf:array2] , @"The two arrays are the same set.");
    XCTAssertTrue([LiveAuthHelper isScopes:array2 subSetOf:array1] , @"The two arrays are the same set.");
    XCTAssertTrue([LiveAuthHelper isScopes:array1 subSetOf:array3] , @"Incorrect subset computation.");    
    XCTAssertTrue([LiveAuthHelper isScopes:array2 subSetOf:array3] , @"Incorrect subset computation.");   
    XCTAssertFalse([LiveAuthHelper isScopes:array3 subSetOf:array1] , @"Incorrect subset computation.");    
    XCTAssertFalse([LiveAuthHelper isScopes:array3 subSetOf:array2] , @"Incorrect subset computation.");   
    XCTAssertFalse([LiveAuthHelper isScopes:array4 subSetOf:array1] , @"Incorrect subset computation.");    
    XCTAssertFalse([LiveAuthHelper isScopes:array4 subSetOf:array2] , @"Incorrect subset computation.");     
}

#pragma mark shouldRefreshToken

- (void)testShouldRefreshToken_should
{
    LiveConnectSession *session = [[LiveConnectSession alloc] initWithAccessToken:@"accessToken" 
                                                               authenticationToken:@"authToken" 
                                                                      refreshToken:@"refreshToken" 
                                                                            scopes:@[@"wl.signin"]
                                                                           expires:[NSDate dateWithTimeIntervalSinceNow:19]];
    XCTAssertTrue([LiveAuthHelper shouldRefreshToken:session refreshToken:@"refreshToken" ], 
                  @"should refresh if it has less than 20 seconds before it expires.");
}

- (void)testShouldRefreshToken_shouldNot_emptyRefreshToken
{
    LiveConnectSession *session = [[LiveConnectSession alloc] initWithAccessToken:@"accessToken" 
                                                               authenticationToken:@"authToken" 
                                                                      refreshToken:@" " 
                                                                            scopes:@[@"wl.signin"]
                                                                           expires:[NSDate dateWithTimeIntervalSinceNow:210]];
    XCTAssertFalse([LiveAuthHelper shouldRefreshToken:session refreshToken: @" "], 
                  @"should not refresh if we don't have refresh token.");
}

- (void)testShouldRefreshToken_shouldNot_nilRefreshToken
{
    LiveConnectSession *session = [[LiveConnectSession alloc] initWithAccessToken:@"accessToken" 
                                                               authenticationToken:@"authToken" 
                                                                      refreshToken:nil 
                                                                            scopes:@[@"wl.signin"]
                                                                           expires:[NSDate dateWithTimeIntervalSinceNow:210]];
    XCTAssertFalse([LiveAuthHelper shouldRefreshToken:session refreshToken:nil], 
                  @"should not refresh if we don't have refresh token.");
}

- (void)testShouldRefreshToken_shouldNot_EnoughExpirePeriod
{
    LiveConnectSession *session = [[LiveConnectSession alloc] initWithAccessToken:@"accessToken" 
                                                               authenticationToken:@"authToken" 
                                                                      refreshToken:@"refreshToken" 
                                                                            scopes:@[@"wl.signin"]
                                                                           expires:[NSDate dateWithTimeIntervalSinceNow:31]];
    XCTAssertFalse([LiveAuthHelper shouldRefreshToken:session refreshToken:@"refreshToken" ], 
                 @"should not refresh if it has more than 20 seconds before it expires.");
}

- (void)testShouldRefreshToken_nilSession_refreshToken
{
    XCTAssertTrue([LiveAuthHelper shouldRefreshToken:nil refreshToken:@"refreshToken"], 
                  @"Should refresh token if we have the refresh token although the session is nil");
}

- (void)testShouldRefreshToken_nilSession_nilRefreshToken
{
    XCTAssertFalse([LiveAuthHelper shouldRefreshToken:nil refreshToken:nil], 
                 @"Should not refresh token if the session is nil and the refresh token is nil");
}

#pragma mark isSessionValid

- (void)testIsSessionValid_nil
{
    XCTAssertFalse([LiveAuthHelper isSessionValid:nil], @"nil session should be invalid.");
}

- (void)testIsSessionValid_Valid
{
    LiveConnectSession *session = [[LiveConnectSession alloc] initWithAccessToken:@"accessToken" 
                                                               authenticationToken:@"authToken" 
                                                                      refreshToken:@"refreshToken" 
                                                                            scopes:@[@"wl.signin"]
                                                                           expires:[NSDate dateWithTimeIntervalSinceNow:4]];
    XCTAssertTrue([LiveAuthHelper isSessionValid:session], 
                 @"The token should be still valid, if it has 4 seconds before expire.");
}

- (void)testIsSessionValid_inValid
{
    LiveConnectSession *session = [[LiveConnectSession alloc] initWithAccessToken:@"accessToken" 
                                                               authenticationToken:@"authToken" 
                                                                      refreshToken:@"refreshToken" 
                                                                            scopes:@[@"wl.signin"]
                                                                           expires:[NSDate dateWithTimeIntervalSinceNow:2]];
    XCTAssertFalse([LiveAuthHelper isSessionValid:session], 
                 @"The token should be still invalid, if it has less than 3 seconds before expire.");
}
@end
