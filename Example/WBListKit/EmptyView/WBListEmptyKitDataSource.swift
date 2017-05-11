//
//  WBListEmptyKitDataSource.swift
//  WBListKit
//
//  Created by Romeo on 2017/5/10.
//  Copyright © 2017年 xcoder.fang@gmail.com. All rights reserved.
//

import Foundation
import UIKit

/// EmptyView 的 DataSource，用于配置EmptyView的样式等
public protocol WBListEmptyKitDataSource: class {
    
    /// 单独一张图片
    func emptyImage(for view: UIView ) -> UIImage?
    
    /// 自己定制的一个UIView
    func customEmptyView(for view: UIView) -> UIView?
    
    ///
    func animation(for emptyView: UIView, in view: UIView) -> CAAnimation?
    
    /// 竖向的offset 默认在View的中间位置
    func verticalEmptyViewOffset(for view: UIView) -> CGFloat
    
    /// 在统计列表为空的情况下是否忽略一些section
    func ignoredSectionsNumber(in view: UIView) -> [Int]?
}

/// 提供一些默认实现
public extension WBListEmptyKitDataSource{
    
    func emptyImage(for view: UIView ) -> UIImage?{
        return nil;
    }
    
    func customEmptyView(for view: UIView) -> UIView?{
        return nil;
    }
    
    func verticalEmptyViewOffset(for view: UIView) -> CGFloat{
        return 0;
    }
    
    func ignoredSectionsNumber(in view: UIView) -> [Int]?{
        return nil;
    }
}

/// 如果控制器实现了这个协议，那么判断是否需要去掉导航栏的高度
public extension WBListEmptyKitDataSource where Self: UIViewController{
    
    func verticalEmptyViewOffset(in view: UIView) -> CGFloat {
        if let nav = self.navigationController, !nav.isNavigationBarHidden, nav.navigationBar.isTranslucent {
            return -nav.navigationBar.frame.maxY / 2
        }
        return 0
    }
}
