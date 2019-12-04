//
//  InfoPlist.h
//  ChatSecure
//
//  Created by Chris Ballinger on 10/27/19.
//  Copyright © 2019 Chris Ballinger. All rights reserved.
//

#import <TargetConditionals.h>

#if TARGET_OS_MACCATALYST
#define EXPORT_COMPLIANCE_CODE 240f0a63-ba8b-40ff-bfce-20848ef174d0
#else
#define EXPORT_COMPLIANCE_CODE 51d17d3e-5e07-49ad-a308-9625d81e411f
#endif
