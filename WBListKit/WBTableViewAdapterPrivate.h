//
//  WBTableViewAdapterPrivate.h
//  Pods
//
//  Created by Romeo on 2017/5/16.
//
//

//#import "WBTableViewAdapter.h"

@protocol WBListActionToControllerProtocol;

@interface WBTableViewAdapter ()

@property (nonatomic, weak) id<WBListActionToControllerProtocol> actionDelegate;

@end

