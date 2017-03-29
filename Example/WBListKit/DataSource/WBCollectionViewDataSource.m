//
//  WBCollectionViewDataSource.m
//  WBListKit
//
//  Created by fangyuxi on 2017/3/29.
//  Copyright © 2017年 xcoder.fang@gmail.com. All rights reserved.
//

#import "WBCollectionViewDataSource.h"

@interface WBCollectionViewDataSource ()

/**
 display data on whitch
 */
@property (nonatomic, weak, readwrite, nullable) UICollectionView *collectionView;

@end

@implementation WBCollectionViewDataSource

@synthesize collectionViewAdapter = _collectionViewAdapter;
@synthesize actionDelegate = _actionDelegate;

- (void)bindCollectionView:(nullable UICollectionView *)collectionView{
    [self.collectionViewAdapter unBindCollectionView];
    _collectionView = collectionView;
    if (collectionView) {
        [self.collectionViewAdapter bindCollectionView:collectionView];
    }
}

- (void)unBindCollectionView{
    [self.collectionViewAdapter unBindCollectionView];
    self.collectionView = nil;
}

- (WBCollectionViewAdapter *)collectionViewAdapter{
    if (!_collectionViewAdapter) {
        _collectionViewAdapter = [WBCollectionViewAdapter new];
    }
    return _collectionViewAdapter;
}

- (void)setActionDelegate:(id<WBListActionToControllerProtocol>)actionDelegate{
    _actionDelegate = actionDelegate;
    //self.collectionViewAdapter.tableDelegate = _actionDelegate;
}


@end
