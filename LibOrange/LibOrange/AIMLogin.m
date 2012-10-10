//
//  AIMLogin.m
//  LibOrange
//
//  Created by Alex Nichol on 6/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMLogin.h"
#import "JSON.h"

@interface AIMLogin (private)

- (void)configurePost:(NSData *)postData onRequest:(NSMutableURLRequest *)request;
- (NSURLConnection *)currentRequest;
- (void)setCurrentRequest:(NSURLConnection *)newConn;
- (NSString *)createAuthenticationKey:(NSString *)secret;
- (NSString *)hmacSha256WithKey:(NSString *)key message:(NSString *)value;

- (void)handleClientLoginResponse:(NSData *)response;
- (void)handleStartOscarResponse:(NSData *)responseData;

@end

@implementation AIMLogin

@synthesize delegate;

- (id)initWithUsername:(NSString *)username password:(NSString *)password {
	if ((self = [super init])) {
		lusername = [username retain];
		lpassword = [password retain];
	}
	return self;
}

- (BOOL)beginAuthorization {
	if (currentRequest || loginStage != AIMLoginStageUnstarted) {
		return NO;
	}
	[downloadedData release];
	downloadedData = [[NSMutableData alloc] init];
	
	NSURL * urlObj = [NSURL URLWithString:kClientLoginURL];
	NSString * postString = [NSString stringWithFormat:@"k=%@&s=%@&pwd=%@&clientVersion=%@&clientName=%@",
							 [kOSCARAPIKEY stringByEscapingAllAsciiCharacters],
							 [lusername stringByEscapingAllAsciiCharacters],
							 [lpassword stringByEscapingAllAsciiCharacters],
							 @"1", @"ANOSCAR"];
	NSData * postData = [postString dataUsingEncoding:NSUTF8StringEncoding];
	NSMutableURLRequest * request = [[[NSMutableURLRequest alloc] initWithURL:urlObj
																  cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
															  timeoutInterval:50.0f] autorelease];
	[self configurePost:postData onRequest:request];
	NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	[connection start];
	[self setCurrentRequest:connection];
	[connection release];
	loginStage = AIMLoginStageSentFirst;
	return YES;
}

#pragma mark Connection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[downloadedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[downloadedData release];
	downloadedData = nil;
	int errorCode = 1;
	if (loginStage == AIMLoginStageSentFirst) {
		errorCode = 2;
	}
	NSError * err = [NSError errorWithDomain:@"LoginError" code:errorCode userInfo:nil];
	if ([delegate respondsToSelector:@selector(aimLogin:failedWithError:)]) {
		[delegate aimLogin:self failedWithError:err];
	}
	[self setCurrentRequest:nil];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if (loginStage == AIMLoginStageSentFirst) {
		[self handleClientLoginResponse:downloadedData];
	} else if (loginStage == AIMLoginStageSentStart) {
		[self handleStartOscarResponse:downloadedData];
	} else {
		[self setCurrentRequest:nil];
		[downloadedData release];
		downloadedData = nil;
	}
}

#pragma mark Private

- (void)configurePost:(NSData *)postData onRequest:(NSMutableURLRequest *)request {
	NSString * postLen = [NSString stringWithFormat:@"%lu", [postData length]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:postData];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[request setValue:postLen forHTTPHeaderField:@"Content-Length"];
}

- (NSURLConnection *)currentRequest {
	return currentRequest;
}

- (void)setCurrentRequest:(NSURLConnection *)newConn {
	if (currentRequest) {
		[currentRequest cancel];
	}
	[currentRequest autorelease];
	currentRequest = [newConn retain];
}

- (NSString *)createAuthenticationKey:(NSString *)secret {
	return [self hmacSha256WithKey:lpassword message:secret];
}

- (NSString *)hmacSha256WithKey:(NSString *)lkey message:(NSString *)lvalue {
	hmac_sha256 hash;
	const unsigned char * key = (const unsigned char *)[lkey UTF8String];
	const unsigned char * message = (const unsigned char *)[lvalue UTF8String];
	hmac_sha256_initialize(&hash, key, (int)strlen((const char *)key));
	hmac_sha256_finalize(&hash, message, (int)strlen((const char *)message));
	const unsigned char * digest = hash.digest;
	// base64
	NSData * d = [NSData dataWithBytes:digest length:32];
	NSString * b64 = [d base64EncodedString];
	return b64;
}

#pragma Private Handlers

- (void)handleClientLoginResponse:(NSData *)response {
	NSString * responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
	NSDictionary * parsed = [responseString parseHTTPParaemters];
	[responseString release];
	// we will read the status
	NSString * content = [parsed objectForKey:@"statusCode"];
	if (![content isEqual:@"200"]) {
		NSLog(@"Login status code is not good: %@", content);
		NSError * error = [NSError errorWithDomain:@"AIMClientLogin"
											  code:[content intValue]
										  userInfo:parsed];
		if ([delegate respondsToSelector:@selector(aimLogin:failedWithError:)]) {
			[delegate aimLogin:self failedWithError:error];
		}
		return;
	}
	
	aToken = [[parsed objectForKey:@"token_a"] retain];
	sessionSecret = [[parsed objectForKey:@"sessionSecret"] retain];
	hosttime = [[parsed objectForKey:@"hostTime"] retain];
	if (!sessionSecret) {
		[downloadedData release];
		downloadedData = nil;
		if ([delegate respondsToSelector:@selector(aimLogin:failedWithError:)]) {
			[delegate aimLogin:self failedWithError:[NSError errorWithDomain:@"AIMClientLogin" code:4 userInfo:nil]];
		}
		return;
	}
	sessionKey = [[self createAuthenticationKey:sessionSecret] retain];
	
	[downloadedData release];
	downloadedData = [[NSMutableData alloc] init];
	
	NSString * queryString = [NSString stringWithFormat:@"a=%@&f=%@&k=%@&ts=%@&useTLS=%@",
							  [aToken stringByEscapingAllAsciiCharacters], @"json",
							  [kOSCARAPIKEY stringByEscapingAllAsciiCharacters],
							  hosttime,
							  @"0"];
	NSString * hashData = [NSString stringWithFormat:@"GET&%@&%@", 
						   [kStartOscarURL stringByEscapingAllAsciiCharacters], 
						   [queryString stringByEscapingAllAsciiCharacters]];
	NSString * sigsha = [self hmacSha256WithKey:sessionKey message:hashData];
	NSString * urlStr = [NSString stringWithFormat:@"%@%c%@%@%@", kStartOscarURL, '?',
					  queryString, @"&sig_sha256=", sigsha];
	NSURL * url = [NSURL URLWithString:urlStr];
	NSURLRequest * request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
	NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	[request release];
	[self setCurrentRequest:connection];
	[connection start];
	[connection release];
	
	loginStage = AIMLoginStageSentStart;
}

- (void)handleStartOscarResponse:(NSData *)responseData {
	NSString * string = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
	NSDictionary * jsonData = [string JSONValue];
	// the response object in the JSON data.
	NSDictionary * response = [jsonData objectForKey:@"response"];
	// the return statusCode, should be 200.
	NSNumber * statusCode = [response objectForKey:@"statusCode"];
	int status = [statusCode intValue];
	if (status != 200) {
		// the request returned unsuccessful.
		NSLog(@"startOSCAR error code: %d", status);
		if ([(id)delegate respondsToSelector:@selector(authorizer:didFailWithError:)]) {
			if ([delegate respondsToSelector:@selector(aimLogin:failedWithError:)]) {
				NSError * error = [NSError errorWithDomain:@"StartOSCAR" code:status userInfo:response];
				[delegate aimLogin:self failedWithError:error];
			}
		}
	} else {
		NSDictionary * data = [response objectForKey:@"data"];
		UInt16 port = [[data objectForKey:@"port"] shortValue];
		NSString * host = [data objectForKey:@"host"];
		NSData * cookie = [NSData dataFromBase64String:(NSString *)[data objectForKey:@"cookie"]];
		
		AIMLoginHostInfo * info = [[AIMLoginHostInfo alloc] initWithHost:host port:port cookie:cookie];
		manager = [[AIMSessionManager alloc] initWithLoginHostInfo:info delegate:self];
		[info release];
	}
}

#pragma mark AIMSessionManager

- (void)aimSessionManagerSignonFailed:(AIMSessionManager *)sender {
	[self retain];
	NSError * error = [NSError errorWithDomain:@"OSCARConnection" code:3 userInfo:nil];
	if ([delegate respondsToSelector:@selector(aimLogin:failedWithError:)]) {
		[delegate aimLogin:self failedWithError:error];
	}
	[self release];
}

- (void)aimSessionManagerSignedOn:(AIMSessionManager *)sender {
	[self retain];
	[sender setDelegate:nil];
	[[sender session] setUsername:lusername];
	if ([delegate respondsToSelector:@selector(aimLogin:openedSession:)]) {
		[delegate aimLogin:self openedSession:sender];
	}
	[self release];
}

- (void)dealloc {
	[manager release];
	[aToken release];
	[sessionSecret release];
	[sessionKey release];
	[hosttime release];
	[lusername release];
	[lpassword release];
	[self setCurrentRequest:nil];
	[downloadedData release];
	[super dealloc];
}

@end
