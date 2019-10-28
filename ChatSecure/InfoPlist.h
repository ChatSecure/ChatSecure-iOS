//
//  InfoPlist.h
//  ChatSecure
//
//  Created by Chris Ballinger on 10/27/19.
//  Copyright © 2019 Chris Ballinger. All rights reserved.
//

#pragma once

#if (!defined(TARGET_OS_MACCATALYST) || (TARGET_OS_MACCATALYST==0))
#define EXPORT_COMPLIANCE_CODE 51d17d3e-5e07-49ad-a308-9625d81e411f
#else
// TODO: Get Mac App Store export compliance code
#endif
