//
//  LiveOperationCore.h
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


#import <Foundation/Foundation.h>
#import "LiveAuthDelegate.h"
#import "LiveOperationDelegate.h"
#import "StreamReader.h"

@class LiveConnectClientCore;
@class LiveOperation;

@interface LiveOperationCore : NSObject <StreamReaderDelegate, LiveAuthDelegate>

@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) NSString *method;
@property (nonatomic, strong) NSData *requestBody;
@property (nonatomic, readonly) id userState; 
@property (nonatomic, weak) id delegate;
@property (nonatomic, readonly) LiveConnectClientCore *liveClient;
@property (nonatomic, strong) NSInputStream *inputStream;
@property (weak, nonatomic, readonly) NSURL *requestUrl;
@property (nonatomic, strong) StreamReader *streamReader;
@property (nonatomic, strong) NSMutableURLRequest *request; 

@property (nonatomic) BOOL completed;
@property (nonatomic, strong) NSString *rawResult;
@property (nonatomic, strong) NSDictionary *result;
@property (nonatomic, strong) id connection;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) id publicOperation;
@property (nonatomic, strong) NSHTTPURLResponse *httpResponse;
@property (nonatomic, strong) NSError *httpError;

- (instancetype) initWithMethod:(NSString *)method
                 path:(NSString *)path
          requestBody:(NSData *)requestBody
             delegate:(id)delegate
            userState:(id)userState
           liveClient:(LiveConnectClientCore *)liveClient NS_DESIGNATED_INITIALIZER;

- (instancetype) initWithMethod:(NSString *)method
                 path:(NSString *)path
          inputStream:(NSInputStream *)inputStream
             delegate:(id)delegate
            userState:(id)userState
           liveClient:(LiveConnectClientCore *)liveClient NS_DESIGNATED_INITIALIZER;

- (void) execute;

- (void) cancel;

- (void) dismissCurrentRequest;

- (void) setRequestContentType;

- (void) sendRequest;

- (void) operationFailed:(NSError *)error;

- (void) operationCompleted;

- (void) operationReceivedData:(NSData *)data;

@end
