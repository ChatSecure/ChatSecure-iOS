//
//  OTRXMPPServerInfo.m
//  ChatSecure
//
//  Created by David Chiles on 6/4/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPServerInfo.h"

/*
 {
 "name": "Calyx Institute",
 "description": "Non-profit education and research organization focused on privacy technology.",
 "website": "https://www.calyxinstitute.org",
 "twitter": "https://twitter.com/calyxinstitute",
 "privacy_policy": "https://www.calyxinstitute.org/legal/privacy-policy",
 "logo": "images/calyx.jpg",
 "country_code": "US",
 "domain": "calyxinstitute.org",
 "server": "conference.calyxinstitute.org",
 "onion": "ijeeynrc6x2uy5ob.onion",
 "port": 5222,
 "certificate": "..."
 }
 */

@implementation OTRXMPPServerInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"name": @"name",
             @"serverDescription": @"description",
             @"websiteURL": @"website",
             @"twitterURL": @"twitter",
             @"privacyPolicyURL": @"privacy_policy",
             @"logo": @"logo",
             @"countryCode": @"country_code",
             @"domain": @"domain",
             @"server": @"server",
             @"onion": @"onion",
             @"portNumber": @"port",
             @"certificate": @"certificate"
             };
}

+ (NSValueTransformer *)websiteURLJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)twitterURLJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)privacyPolicyURLJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

- (UIImage*) logoImage {
    NSBundle *bundle = [[self class] serverBundle];
    NSArray *pathComponents = [self.logo pathComponents];
    NSString *folder = pathComponents[0];
    NSString *fileName = pathComponents[1];
    NSString *extension = [fileName pathExtension];
    NSString *resource = [fileName stringByDeletingPathExtension];
    NSString *path = [bundle pathForResource:resource ofType:extension inDirectory:folder];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    NSParameterAssert(image);
    return image;
}

+ (NSBundle*)serverBundle {
    NSString *folderName = @"xmpp-server-list";
    NSString *bundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:folderName];
    NSBundle *dataBundle = [NSBundle bundleWithPath:bundlePath];
    NSParameterAssert(dataBundle);
    return dataBundle;
}

+ (NSArray *)defaultServerList
{
    NSBundle *dataBundle = [self serverBundle];
    NSURL *url = [dataBundle URLForResource:@"servers" withExtension:@"json"];
    NSParameterAssert(url != nil);
    
    NSData *jsonData = [[NSData alloc] initWithContentsOfURL:url];
    return [self serverListFromJSONData:jsonData];
}

+ (NSArray *)serverListFromJSONData:(NSData*)jsonData {
    NSParameterAssert(jsonData != nil);
    NSError *error = nil;
    NSDictionary *root = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    NSParameterAssert(root != nil);
    if (error) {
        NSLog(@"Error parsing server list JSON: %@", error);
        return nil;
    }
    NSArray *serverDictionaries = root[@"servers"];
    NSParameterAssert(serverDictionaries);
    NSArray *servers = [MTLJSONAdapter modelsOfClass:[self class] fromJSONArray:serverDictionaries error:&error];
    if (error) {
        NSLog(@"Error parsing server list JSON: %@", error);
        return nil;
    }
    return servers;
}

@end
