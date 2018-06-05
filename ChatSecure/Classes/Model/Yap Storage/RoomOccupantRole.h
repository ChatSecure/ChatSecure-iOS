//
//  RoomOccupantRole.h
//  ChatSecureCore
//
//  Created by Chris Ballinger on 6/4/18.
//  Copyright © 2018 Chris Ballinger. All rights reserved.
//

@import Foundation;

typedef NS_ENUM(NSInteger, RoomOccupantRole) {
    RoomOccupantRoleNone = 0,
    RoomOccupantRoleParticipant = 1,
    RoomOccupantRoleModerator = 2,
    RoomOccupantRoleVisitor = 3
};
