//
//  OTRMediaTests.m
//  ChatSecure
//
//  Created by David Chiles on 2/25/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <ChatSecureCore/OTRMediaFileManager.h>
#import <ChatSecureCore/OTRVideoItem.h>
#import <ChatSecureCore/OTRBuddy.h>
#import <ChatSecureCore/OTRMessage.h>
#import <IOCipher/IOCipher.h>

@interface OTRMediaTests : XCTestCase

@property (nonatomic, strong) OTRMediaFileManager *mediaFileManager;
@property (nonatomic, strong) NSArray *mediaItems;
@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, strong) OTRBuddy *buddy;

@end

@implementation OTRMediaTests

- (void)setUp {
    [super setUp];
    self.queue = dispatch_queue_create("OTRMediaTestsQUEUE", 0);
    
    NSString *filePath =  [NSTemporaryDirectory() stringByAppendingPathComponent:NSStringFromSelector(_cmd)];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:nil]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    
    self.mediaFileManager = [[OTRMediaFileManager alloc] init];
    [self.mediaFileManager setupWithPath:filePath password:@"password"];
    
    self.buddy = [[OTRBuddy alloc] init];
    
    self.mediaItems = @[];
    
    NSArray *sampleFiles = [[NSBundle bundleForClass:[self class]] pathsForResourcesOfType:nil inDirectory:@"samples"];
    for (NSString *filePath in sampleFiles) {
        OTRMediaItem *mediaItem = [[OTRMediaItem alloc] initWithFilename:[filePath lastPathComponent] mimeType:nil isIncoming:NO];
        
        self.mediaItems = [self.mediaItems arrayByAddingObject:mediaItem];
    }
    
}

- (NSString *)sampleDirectoryPath
{
    return [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:@"samples"];
}

- (NSString *)bundlePathForMediaItem:(OTRMediaItem *)mediaItem
{
    return [[self sampleDirectoryPath] stringByAppendingPathComponent:mediaItem.filename];
}

- (NSString *)encryptedPathForMediaItem:(OTRMediaItem *)mediaItem
{
    return [OTRMediaFileManager pathForMediaItem:mediaItem buddyUniqueId:self.buddy.uniqueId];
}

- (void)copyToEncryptedStorage:(OTRMediaItem *)mediaItem completion:(void (^)(BOOL success, NSError *error))completion
{
    
    __block NSString *bundlePath = [self bundlePathForMediaItem:mediaItem];
    __block NSString *encryptedPath = [self encryptedPathForMediaItem:mediaItem];;
    
    [self.mediaFileManager copyDataFromFilePath:bundlePath toEncryptedPath:encryptedPath completion:completion completionQueue:self.queue];
}

- (void)testCopyIntoEncryptedStorage
{
    XCTAssertGreaterThan([self.mediaItems count],0, @"No test files found in bundle");
    [self.mediaItems enumerateObjectsUsingBlock:^(OTRMediaItem *mediaItem, NSUInteger idx, BOOL *stop) {
        __block XCTestExpectation *expectation = [self expectationWithDescription:mediaItem.filename];
        
        [self copyToEncryptedStorage:mediaItem completion:^(BOOL success, NSError *error) {
            XCTAssertNil(error,@"Error copying File: %@",error);
            NSError *attributesError = nil;
            NSDictionary *fileAttributes = [self.mediaFileManager.ioCipher fileAttributesAtPath:[self encryptedPathForMediaItem:mediaItem] error:&attributesError];
            
            XCTAssertNotNil(fileAttributes[NSFileModificationDate],@"No modifaction date");
            NSNumber *attributesFileSize = fileAttributes[NSFileSize];
            XCTAssertNotNil(attributesFileSize,@"No file size");
            XCTAssertNil(attributesError,@"Error getting attributes");
            XCTAssertNotNil(fileAttributes, @"Error no attributes");
            XCTAssertGreaterThan([[fileAttributes allKeys] count], 0,@"Error no attributes");
            
            NSData *data = [self.mediaFileManager dataForItem:mediaItem buddyUniqueId:self.buddy.uniqueId error:&error];
            XCTAssertNotNil(data, @"Data is nil");
            XCTAssertNil(error, @"Found Error getting file");
            NSData *unencryptedData = [[NSFileManager defaultManager] contentsAtPath:[self bundlePathForMediaItem:mediaItem]];
            BOOL equalData = [unencryptedData isEqualToData:data];
            XCTAssertTrue(equalData, @"Data is not equal");
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        NSLog(@"Timeout error: %@",error);
    }];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}



@end
