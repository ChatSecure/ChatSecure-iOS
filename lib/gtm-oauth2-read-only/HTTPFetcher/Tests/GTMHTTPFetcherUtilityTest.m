/* Copyright (c) 2010 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <SenTestingKit/SenTestingKit.h>

#import "GTMHTTPFetcher.h"
#import "GTMHTTPFetcherLogging.h"

@interface GTMHTTPFetcherUtilityTest : SenTestCase
@end

@interface GTMHTTPFetcher (GTMHTTPFetcherLoggingInternal)
+ (NSString *)snipSubstringOfString:(NSString *)originalStr
                 betweenStartString:(NSString *)startStr
                          endString:(NSString *)endStr;
@end


@implementation GTMHTTPFetcherUtilityTest

#if !STRIP_GTM_FETCH_LOGGING
- (void)testLogSnipping {
  // enpty string
  NSString *orig = @"";
  NSString *expected = orig;
  NSString *result = [GTMHTTPFetcher snipSubstringOfString:orig
                                        betweenStartString:@"jkl"
                                                 endString:@"mno"];
  STAssertEqualObjects(result, expected, @"simple snip to end failure");

  // snip the middle
  orig = @"abcdefg";
  expected = @"abcd_snip_fg";
  result = [GTMHTTPFetcher snipSubstringOfString:orig
                              betweenStartString:@"abcd"
                                       endString:@"fg"];
  STAssertEqualObjects(result, expected, @"simple snip in the middle failure");

  // snip to the end
  orig = @"abcdefg";
  expected = @"abcd_snip_";
  result = [GTMHTTPFetcher snipSubstringOfString:orig
                              betweenStartString:@"abcd"
                                       endString:@"xyz"];
  STAssertEqualObjects(result, expected, @"simple snip to end failure");

  // start string not found, so nothing should be snipped
  orig = @"abcdefg";
  expected = orig;
  result = [GTMHTTPFetcher snipSubstringOfString:orig
                              betweenStartString:@"jkl"
                                       endString:@"mno"];
  STAssertEqualObjects(result, expected, @"simple snip to end failure");

  // nothing between start and end
  orig = @"abcdefg";
  expected = @"abcd_snip_efg";
  result = [GTMHTTPFetcher snipSubstringOfString:orig
                              betweenStartString:@"abcd"
                                       endString:@"efg"];
  STAssertEqualObjects(result, expected, @"snip of empty string failure");

  // snip like in OAuth
  orig = @"OAuth oauth_consumer_key=\"example.net\", "
  "oauth_token=\"1%2FpXi_-mBSegSbB-m9HprlwlxF6NF7IL7_9PDZok\", "
  "oauth_signature=\"blP%2BG72aSQ2XadLLTk%2BNzUV6Wes%3D\"";
  expected = @"OAuth oauth_consumer_key=\"example.net\", "
  "oauth_token=\"_snip_\", "
  "oauth_signature=\"blP%2BG72aSQ2XadLLTk%2BNzUV6Wes%3D\"";
  result = [GTMHTTPFetcher snipSubstringOfString:orig
                              betweenStartString:@"oauth_token=\""
                                       endString:@"\""];
  STAssertEqualObjects(result, expected, @"realistic snip failure");
}
#endif

- (void)testGTMCleanedUserAgentString {
  NSString *result = GTMCleanedUserAgentString(nil);
  NSString *expected = nil;
  STAssertEqualObjects(result, expected, nil);

  result = GTMCleanedUserAgentString(@"");
  expected = @"";
  STAssertEqualObjects(result, expected, nil);

  result = GTMCleanedUserAgentString(@"frog in tree/[1.2.3]");
  expected = @"frog_in_tree1.2.3";
  STAssertEqualObjects(result, expected, nil);

  result = GTMCleanedUserAgentString(@"\\iPod ({Touch])\n\r");
  expected = @"iPod_Touch";
  STAssertEqualObjects(result, expected, nil);
}

- (void)testGTMSystemVersionString {
#if TARGET_OS_MAC && !TARGET_OS_IPHONE
  NSString *result = GTMSystemVersionString();
  STAssertTrue([result hasPrefix:@"MacOSX/"], nil);
#else
  STAssertTrue(NO, @"Add system version string test for this configuration");
#endif
}

- (void)testGTMApplicationIdentifier {
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  NSString *result = GTMApplicationIdentifier(bundle);
  STAssertEqualObjects(result, @"com.yourcompany.UnitTests/1.0", nil);
}
@end
