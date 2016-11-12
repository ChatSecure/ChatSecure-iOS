//
//  OTRMessage.h
//  ChatSecure
//
//  Created by David Chiles on 11/11/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

@import Foundation;
@import Mantle;

/**
 This class is left over after the transition from one class OTRMessage to two class OTRIncomingMessage and OTROutgoingMessage.
 The only purpose of this class is to move serialized objects from OTRMessage to the correct class based on the 'incomimg' value.
 */
@interface OTRMessage : MTLModel

@end
