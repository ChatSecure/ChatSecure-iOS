//
//  OTROscarAccount.m
//  Off the Record
//
//  Created by Christopher Ballinger on 8/9/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import "OTROldOscarAccount.h"
#import "OTRProtocol.h"
#import "Strings.h"
#import "OTROscarManager.h"
#import "OTRConstants.h"

@implementation OTROscarAccount

- (id) init {
    if (self = [super initWithProtocol:kOTRProtocolTypeAIM]) {
        
    }
    return self;
}

- (NSString *) imageName {
    return kAIMImageName;
}

- (NSString *)providerName
{
    return AIM_STRING;
}

- (Class) protocolClass {
    return [OTROscarManager class];
}

@end
