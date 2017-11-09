//
//  WBListSectionHeaderFooter.h
//  Pods
//
//  Created by fangyuxi on 2017/3/20.
//
//

#import <Foundation/Foundation.h>
#import "WBListKitAssert.h"
#import "WBListKitMacros.h"

/** 使用AutoLayout自动计算高度 **/
extern const CGFloat WBTableHeaderFooterHeightAutoLayout;

/**
 类型
 */
typedef NS_ENUM(NSInteger, WBTableHeaderFooterType)
{
    WBTableHeaderFooterTypeHeader = 1,
    WBTableHeaderFooterTypeFooter
};

/**
 A 'Model Object' for header & footer
 */
WBListKit_SUBCLASSING_RESTRICTED
@interface WBTableSectionHeaderFooter<__covariant Data> : NSObject

@property (nonatomic, assign) WBTableHeaderFooterType displayType;

/**
 associated raw data
 */
@property (nonatomic, strong) Data data;

/**
  class name will be used as reuseIditifier
  class or nib will be automatically registed in tableview by kit
  for standard, the cell name must ended in 'header or footer' like HYCustomHeader,otherwise will crash
 */
@property (nonatomic, strong) Class associatedHeaderFooterClass;

/**
 if height is WBListHeaderFooterHeightAutoLayout
 then calculateHeight will never be called
 */
@property (nonatomic, copy) CGFloat(^calculateHeight)(WBTableSectionHeaderFooter *headerFooter);


@end
