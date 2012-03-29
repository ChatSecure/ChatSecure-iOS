//
//  MWFeedParser.h
//  MWFeedParser
//
//  Copyright (c) 2010 Michael Waterfall
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  1. The above copyright notice and this permission notice shall be included
//     in all copies or substantial portions of the Software.
//  
//  2. This Software cannot be used to archive or collect data such as (but not
//     limited to) that of events, news, experiences and activities, for the 
//     purpose of any concept relating to diary/journal keeping.
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
#import "MWFeedInfo.h"
#import "MWFeedItem.h"

// Debug Logging
#if 0 // Set to 1 to enable debug logging
#define MWLog(x, ...) NSLog(x, ## __VA_ARGS__);
#else
#define MWLog(x, ...)
#endif

// Errors & codes
#define MWErrorDomain @"MWFeedParser"
#define MWErrorCodeNotInitiated				1		/* MWFeedParser not initialised correctly */
#define MWErrorCodeConnectionFailed			2		/* Connection to the URL failed */
#define MWErrorCodeFeedParsingError			3		/* NSXMLParser encountered a parsing error */
#define MWErrorCodeFeedValidationError		4		/* NSXMLParser encountered a validation error */
#define MWErrorCodeGeneral					5		/* MWFeedParser general error */

// Class
@class MWFeedParser;

// Types
typedef enum { ConnectionTypeAsynchronously, ConnectionTypeSynchronously } ConnectionType;
typedef enum { ParseTypeFull, ParseTypeItemsOnly, ParseTypeInfoOnly } ParseType;
typedef enum { FeedTypeUnknown, FeedTypeRSS, FeedTypeRSS1, FeedTypeAtom } FeedType;

// Delegate
@protocol MWFeedParserDelegate <NSObject>
@optional
- (void)feedParserDidStart:(MWFeedParser *)parser;
- (void)feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info;
- (void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item;
- (void)feedParserDidFinish:(MWFeedParser *)parser;
- (void)feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error;
@end

// MWFeedParser
@interface MWFeedParser : NSObject <NSXMLParserDelegate> {

@private
	
	// Required
	id <MWFeedParserDelegate> delegate;
	
	// Connection
	NSURLConnection *urlConnection;
	NSMutableData *asyncData;
	NSString *asyncTextEncodingName;
	ConnectionType connectionType;
	
	// Parsing
	ParseType feedParseType;
	NSXMLParser *feedParser;
	FeedType feedType;
	NSDateFormatter *dateFormatterRFC822, *dateFormatterRFC3339;
	
	// Parsing State
	NSURL *url;
	BOOL aborted; // Whether parse stopped due to abort
	BOOL parsing; // Whether the MWFeedParser has started parsing
	BOOL stopped; // Whether the parse was stopped
	BOOL failed; // Whether the parse failed
	BOOL parsingComplete; // Whether NSXMLParser parsing has completed
	BOOL hasEncounteredItems; // Whether the parser has started parsing items
	
	// Parsing of XML structure as content
	NSString *pathOfElementWithXHTMLType; // Hold the path of the element who's type="xhtml" so we can stop parsing when it's ended
	BOOL parseStructureAsContent; // For atom feeds when element type="xhtml"
	
	// Parsing Data
	NSString *currentPath;
	NSMutableString *currentText;
	NSDictionary *currentElementAttributes;
	MWFeedItem *item;
	MWFeedInfo *info;
	
}

#pragma mark Public Properties

// Delegate to recieve data as it is parsed
@property (nonatomic, assign) id <MWFeedParserDelegate> delegate;

// Whether to parse feed info & all items, just feed info, or just feed items
@property (nonatomic) ParseType feedParseType;

// Set whether to download asynchronously or synchronously
@property (nonatomic) ConnectionType connectionType;

// Whether parsing was stopped
@property (nonatomic, readonly, getter=isStopped) BOOL stopped;

// Whether parsing failed
@property (nonatomic, readonly, getter=didFail) BOOL failed;

// Whether parsing is in progress
@property (nonatomic, readonly, getter=isParsing) BOOL parsing;

#pragma mark Public Methods

// Init MWFeedParser with a URL string
- (id)initWithFeedURL:(NSURL *)feedURL;

// Begin parsing
- (BOOL)parse;

// Stop parsing
- (void)stopParsing;

// Returns the URL
- (NSURL *)url;

@end