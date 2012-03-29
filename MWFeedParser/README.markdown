# MWFeedParser — An RSS and Atom web feed parser for iOS

MWFeedParser is an Objective-C framework for downloading and parsing RSS (1.* and 2.*) and Atom web feeds. It is a very simple and clean implementation that reads the following information from a web feed:

#### Feed Information
- Title
- Link
- Summary

#### Feed Items
- Title
- Link
- Date (the date the item was published)
- Updated date  (the date the item was updated, if available)
- Summary (brief description of item)
- Content (detailed item content, if available)
- Enclosures (i.e. podcasts, mp3, pdf, etc)
- Identifier (an item's guid/id)

If you use MWFeedParser on your iPhone/iPad app then please do let me know, I'd love to check it out :)

***Important:*** This free software is provided under the MIT licence (X11 license) with the addition of the following condition:

>This Software cannot be used to archive or collect data such as (but not
limited to) that of events, news, experiences and activities, for the 
purpose of any concept relating to diary/journal keeping.

The full licence can be found at the end of this document.


## Demo / Example App

There is an example iPhone application within the project which demonstrates how to use the parser to display the title of a feed, list all of the feed items, and display an item in more detail when tapped.


## Setting up the parser

Create parser:

	// Create feed parser and pass the URL of the feed
	NSURL *feedURL = [NSURL URLWithString:@"http://images.apple.com/main/rss/hotnews/hotnews.rss"];
	feedParser = [[MWFeedParser alloc] initWithFeedURL:feedURL];

Set delegate:

	// Delegate must conform to `MWFeedParserDelegate`
	feedParser.delegate = self;
	
Set the parsing type. Options are `ParseTypeFull`, `ParseTypeInfoOnly`, `ParseTypeItemsOnly`. Info refers to the information about the feed, such as it's title and description. Items are the individual items or stories.

	// Parse the feeds info (title, link) and all feed items
	feedParser.feedParseType = ParseTypeFull;
	
Set whether the parser should connect and download the feed data synchronously or asynchronously. Note, this only affects the download of the feed data, not the parsing operation itself.

	// Connection type
	feedParser.connectionType = ConnectionTypeSynchronously;
	
Initiate parsing:

	// Begin parsing
	[feedParser parse];
	
The parser will then download and parse the feed. If at any time you wish to stop the parsing, you can call:

	// Stop feed download / parsing
	[feedParser stopParsing];
	
The `stopParsing` method will stop the downloading and parsing of the feed immediately.


## Reading the feed data

Once parsing has been initiated, the delegate will receive the feed data as it is parsed.

	- (void)feedParserDidStart:(MWFeedParser *)parser; // Called when data has downloaded and parsing has begun
	- (void)feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info; // Provides info about the feed
	- (void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item; // Provides info about a feed item
	- (void)feedParserDidFinish:(MWFeedParser *)parser; // Parsing complete or stopped at any time by `stopParsing`
	- (void)feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error; // Parsing failed

`MWFeedInfo` and `MWFeedItem` contains properties (title, link, summary, etc.) that will hold the parsed data. View `MWFeedInfo.h` and `MWFeedItem.h` for more information.

***Important:*** There are some occasions where feeds do not contain some information, such as titles, links or summaries. Before using any data, you should check to see if that data exists:

	NSString *title = item.title ? item.title : @"[No Title]";
	NSString *link = item.link ? item.link : @"[No Link]";
	NSString *summary = item.summary ? item.summary : @"[No Summary]";

The method `feedParserDidFinish:` will only be called when the feed has successfully parsed, or has been stopped by a call to `stopParsing`. To determine whether the parsing completed successfully, or was stopped, you can call `isStopped`.

For a usage example, please see `RootViewController.m` in the demo project.


## Available data

Here is a list of the available properties for feed info and item objects:

#### MWFeedInfo
- `info.title` (`NSString`)
- `info.link` (`NSString`)
- `info.summary` (`NSString`)

#### MWFeedItem

- `item.title` (`NSString`)
- `item.link` (`NSString`)
- `item.date` (`NSDate`)
- `item.updated` (`NSDate`)
- `item.summary` (`NSString`)
- `item.content` (`NSString`)
- `item.enclosures` (`NSArray` of `NSDictionary` with keys `url`, `type` and `length`)
- `item.identifier` (`NSString`)


## Using the data

All properties of `MWFeedInfo` and `MWFeedItem` return the raw data as provided by the feed. This content may or may not include HTML and encoded entities. If the content does include HTML, you could display the data within a UIWebView, or you could use the provided `NSString` category (`NSString+HTML`) which will allow you to manipulate this HTML content. The methods available for your convenience are:

    // Convert HTML to Plain Text
    //  - Strips HTML tags & comments, removes extra whitespace and decodes HTML character entities.
    - (NSString *)stringByConvertingHTMLToPlainText;

    // Decode all HTML entities using GTM.
    - (NSString *)stringByDecodingHTMLEntities;

    // Encode all HTML entities using GTM.
    - (NSString *)stringByEncodingHTMLEntities;

    // Minimal unicode encoding will only cover characters from table
    // A.2.2 of http://www.w3.org/TR/xhtml1/dtds.html#a_dtd_Special_characters
    // which is what you want for a unicode encoded webpage.
    - (NSString *)stringByEncodingHTMLEntities:(BOOL)isUnicode;

    // Replace newlines with <br /> tags.
    - (NSString *)stringWithNewLinesAsBRs;

    // Remove newlines and white space from string.
    - (NSString *)stringByRemovingNewLinesAndWhitespace;

    // Wrap plain URLs in <a href="..." class="linkified">...</a>
    //  - Ignores URLs inside tags (any URL beginning with =")
    //  - HTTP & HTTPS schemes only
    //  - Only works in iOS 4+ as we use NSRegularExpression (returns self if not supported so be careful with NSMutableStrings)
    //  - Expression: (?<!=")\b((http|https):\/\/[\w\-_]+(\.[\w\-_]+)+([\w\-\.,@?^=%&amp;:/~\+#]*[\w\-\@?^=%&amp;/~\+#])?)
    //  - Adapted from http://regexlib.com/REDetails.aspx?regexp_id=96
    - (NSString *)stringByLinkifyingURLs;

An example of this would be:

    // Display item summary which contains HTML as plain text
	NSString *plainSummary = [item.summary stringByConvertingHTMLToPlainText];


## Debugging problems

If for some reason the parser doesn't seem to be working, try enabling Debug Logging in `MWFeedParser.h`. This will log error messages to the console and help you diagnose the problem. Error codes and their descriptions can be found at the top of `MWFeedParser.h`.


## Other information

MWFeedParser is not currently thread-safe.


## Adding to your project

1. Open `MWFeedParser.xcodeproj`.
2. Drag the `MWFeedParser` & `Categories` groups into your project, ensuring you check **Copy items into destination group's folder**.
3. Import `MWFeedParser.h` into your source as required.


## Outstanding and suggested features

- Demonstrate the previewing of formatted item summary/content (HTML with images, paragraphs, etc) within a `UIWebView` in demo app.
- Provide functionality to list available feeds when given the URL to a webpage with one or more web feeds associated with it.
- Support for the Media RSS extension (from Flickr, etc.)
- Support for the GeoRSS extension.
- Look into web feed icons.
- Look into supporting/detecting images in feed items.

Feel free to get in touch and suggest/vote for other features.


## Licence

Copyright (c) 2010 Michael Waterfall

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

1. The above copyright notice and this permission notice shall be included
   in all copies or substantial portions of the Software.

2. This Software cannot be used to archive or collect data such as (but not
   limited to) that of events, news, experiences and activities, for the 
   purpose of any concept relating to diary/journal keeping.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.


Contact
===============

Website: 	<http://michaelwaterfall.com>
Twitter:	<http://twitter.com/mwaterfall>