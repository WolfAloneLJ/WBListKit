//
//  WBListKitAdapter.m
//  Pods
//
//  Created by fangyuxi on 2017/3/17.
//
//

#import "WBTableViewAdapter.h"
#import "UITableView+FDTemplateLayoutCell.h"
#import "WBTableViewDelegateProxy.h"
#import "WBTableHeaderFooterViewProtocal.h"
#import "WBTableCellProtocal.h"
#import "UITableView+WBListKitPrivate.h"
#import "UITableView+WBListKit.h"
#import "WBTableViewAdapterPrivate.h"

#import "WBTableSection.h"
#import "WBTableSectionPrivate.h"
#import "WBTableRow.h"

#import "IGListDiffKit.h"
#import "IGListBatchUpdates.h"
#import "UICollectionView+IGListBatchUpdateData.h"
#import "IGListReloadIndexPath.h"
#import "WBTableUpdater.h"

@interface WBTableViewAdapter ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableSet *registedCellIdentifiers;
@property (nonatomic, strong) NSMutableSet *registedHeaderFooterIdentifiers;
@property (nonatomic, strong) WBTableViewDelegateProxy *delegateProxy;

@end

@implementation WBTableViewAdapter

#pragma mark bind unbind

- (void)setTableView:(UITableView *)tableView{
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
    _tableView = nil;
    
    _tableView = tableView;
    
    if (!_tableView) {
        return;
    }
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    if (self.actionDelegate || self.tableDataSource) {
        [self updateTableDelegateProxy];
    }
}

#pragma mark manage appearance

- (void)willAppear{
    NSArray *cells = [self.tableView visibleCells];
    
    [cells enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        UITableViewCell<WBTableCellProtocol> *cell = obj;
        if ([cell respondsToSelector:@selector(reload)]) {
            [cell reload];
        }
    }];
    
    //TO invoke header footer 'reload'
}

- (void)didDisappear{
    NSArray *cells = [self.tableView visibleCells];
    
    [cells enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        UITableViewCell<WBTableCellProtocol> *cell = obj;
        if ([cell respondsToSelector:@selector(cancel)]) {
            [cell cancel];
        }
    }];
    
    //TO invoke header footer 'cancel'
}

#pragma mark section operators

- (WBTableSection *)sectionAtIndex:(NSUInteger)index{
    if (index >= self.sections.count){
        return nil;
    }
    WBTableSection *section = [self.sections objectAtIndex:index];
    return section;
}

- (WBTableSection *)sectionForKey:(NSString *)key{
    
    __block WBTableSection *section = nil;
    [self.sections enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        WBTableSection *tmpSection = (WBTableSection *)obj;
        if ([tmpSection.key isEqualToString:key]){
            section = tmpSection;
            BOOL b = true;
            stop = &b;
        }
    }];
    if (!section) {
        return nil;
    }
    return section;
}

- (NSUInteger)indexOfSection:(WBTableSection *)section{
    return [self.sections indexOfObject:section];
}

- (void)addSection:(void(^)(WBTableSection *newSection))block{
     [self insertSection:block atIndex:[self.sections count]];
}

- (void)insertSection:(void(^)(WBTableSection *newSection))block
              atIndex:(NSUInteger)index{
    if (index > self.sections.count){
        return;
    }
    WBTableSection *section = [[WBTableSection alloc] init];
    [self.sections insertObject:section atIndex:index];
    block(section);
}

- (void)updateSection:(WBTableSection *)section
             useBlock:(void(^)(WBTableSection *section))block{
    block(section);
}

- (void)updateSectionAtIndex:(NSUInteger)index
                    useBlock:(void(^)(WBTableSection *section))block{
    WBTableSection *section = [self sectionAtIndex:index];
    if (section) {
        [self updateSection:section useBlock:^(WBTableSection *section) {
            block(section);
        }];
    }
}

- (void)updateSectionForKey:(NSString *)key
                          useBlock:(void(^)(WBTableSection *section))block{
    WBTableSection *section = [self sectionForKey:key];
    if (section) {
        [self updateSection:section useBlock:^(WBTableSection *section) {
            block(section);
        }];
    }
}

- (void)exchangeSectionIndex:(NSInteger)index1
            withSectionIndex:(NSInteger)index2{
    if (index1 == index2 || index1 < 0 || index2 < 0) {
        return;
    }
    WBTableSection *section1 = [self sectionAtIndex:index1];
    WBTableSection *section2 = [self sectionAtIndex:index2];
    
    if (section1 && section2) {
        [self.sections exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
    }
}

- (void)deleteSection:(WBTableSection *)section{
    [self.sections removeObject:section];
}
- (void)deleteSectionAtIndex:(NSUInteger)index{
    WBTableSection *section = [self sectionAtIndex:index];
    if (section) {
        [self deleteSection:section];
    }
}
- (void)deleteSectionForKey:(NSString *)key{
    WBTableSection *section = [self sectionForKey:key];
    if (section) {
        [self deleteSection:section];
    }
}
- (void)deleteAllSections{
    [self.sections removeAllObjects];
}

#pragma mark UITableviewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    WBTableSection *section = [self sectionAtIndex:indexPath.section];
    WBTableRow *row = [section rowAtIndex:indexPath.row];
    WBListKitAssert(row ,@"当前列表的状态，数据同显示不付，您所操作的行，虽然在显示，但是数据中已经没有了");
    Class cellClass = row.associatedCellClass;
    NSString *identifier = NSStringFromClass(cellClass);
    WBListKitAssert(!identifier || ![identifier isEqualToString:@""], @"row 相关联的 associatedCellClass 为空");
    
    //registe if needed
    [self registeCellIfNeededUseCellClass:cellClass];
    
    //hook by
    UITableViewCell<WBTableCellProtocol> *cell = nil;
    if ([self.tableDataSource respondsToSelector:@selector(tableView:cellForRowAtIndexPath:)]) {
        return [self.tableDataSource tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    
    cell = [self.tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    WBListKitAssert([cell conformsToProtocol:@protocol(WBTableCellProtocol)],@"cell 必须遵守 WBTableCellProtocol 协议");
    if ([cell respondsToSelector:@selector(reset)]) {
        [cell reset];
    }
    row.indexPath = indexPath;
    cell.row = row;
    if ([cell respondsToSelector:@selector(setActionDelegate:)]) {
        cell.actionDelegate = self.actionDelegate;
    }
    [cell update];
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    WBListKitAssertMainThread();
    if ([self.tableDataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
        return [self.tableDataSource numberOfSectionsInTableView:tableView];
    }
    return [self.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if ([self.tableDataSource respondsToSelector:@selector(tableView:numberOfRowsInSection:)]) {
        return [self.tableDataSource tableView:tableView numberOfRowsInSection:section];
    }
    WBTableSection *sectionObject = [self sectionAtIndex:section];
    return sectionObject.rowCount;
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    WBTableSection *section = [self sectionAtIndex:indexPath.section];
    WBTableRow *row = [section rowAtIndex:indexPath.row];
    Class cellClass = row.associatedCellClass;
    
    //registe if needed
    [self registeCellIfNeededUseCellClass:cellClass];
    
    // hook by
    if ([self.tableDataSource respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
        return [self.tableDataSource tableView:tableView heightForRowAtIndexPath:indexPath];
    }

    if (row.calculateHeight) {
        CGFloat height = row.calculateHeight(row);
        if (height != WBListCellHeightAutoLayout) {
            return height;
        }

    }
    
    CGFloat f = [tableView fd_heightForCellWithIdentifier:NSStringFromClass(row.associatedCellClass)
                                         cacheByIndexPath:indexPath
                                            configuration:^(UITableViewCell<WBTableCellProtocol> *cell) {
                                                cell.row = row;
                                                [cell update];
                                            }];
    return f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    WBTableSection *sectionObject = [self sectionAtIndex:section];
    WBTableSectionHeaderFooter *header = sectionObject.header;
    if (!header) {
        return 0;
    }

    //registe if needed
    [self registeHeaderFooterIfNeededUseClass:header.associatedHeaderFooterClass];
    
    // hook by
    if ([self.tableDataSource respondsToSelector:@selector(tableView:heightForHeaderInSection:)]) {
        return [self.tableDataSource tableView:tableView heightForHeaderInSection:section];
    }
    
    CGFloat height = 0;
    if (header.calculateHeight) {
        height = header.calculateHeight(header);
        if (height == WBTableHeaderFooterHeightAutoLayout) {
            height = [self heightForHeaderFooter:header inSectoin:sectionObject];
        }
    }else{
        height = [self heightForHeaderFooter:header inSectoin:sectionObject];
    }
    return height;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    WBTableSection *sectionObject = [self sectionAtIndex:section];
    WBTableSectionHeaderFooter *footer = sectionObject.footer;
    if (!footer) {
        return 0;
    }
    
    //registe if needed
    [self registeHeaderFooterIfNeededUseClass:footer.associatedHeaderFooterClass];
    
    // hook by
    if ([self.tableDataSource respondsToSelector:@selector(tableView:heightForFooterInSection:)]) {
        return [self.tableDataSource tableView:tableView heightForFooterInSection:section];
    }
    
    CGFloat height = 0;
    if (footer.calculateHeight) {
        height = footer.calculateHeight(footer);
        if (height == WBTableHeaderFooterHeightAutoLayout) {
            height = [self heightForHeaderFooter:footer inSectoin:sectionObject];
        }
    }else{
        height = [self heightForHeaderFooter:footer inSectoin:sectionObject];
    }
    return height;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    WBTableSection *sectionObject = [self sectionAtIndex:section];
    WBTableSectionHeaderFooter *header = sectionObject.header;
    if (!header) {
        return nil;
    }
    NSString *headerIdentifier = NSStringFromClass(header.associatedHeaderFooterClass);
    
    //registe if needed
    [self registeHeaderFooterIfNeededUseClass:header.associatedHeaderFooterClass];
    
    //hook by
    UITableViewHeaderFooterView<WBTableHeaderFooterViewProtocal> *headerView = nil;
    if ([self.tableDataSource respondsToSelector:@selector(tableView:viewForHeaderInSection:)]) {
        return [self.tableDataSource tableView:tableView viewForHeaderInSection:section];
    }
    
    headerView = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:headerIdentifier];
    WBListKitAssert([headerView isKindOfClass:[UITableViewHeaderFooterView class]],@"header 必须是 UITableViewHeaderFooterView的子类");
    WBListKitAssert([headerView conformsToProtocol:@protocol(WBTableHeaderFooterViewProtocal)],@"header 必须遵守 WBListHeaderFooterViewProtocal 协议");
    if ([headerView respondsToSelector:@selector(reset)]) {
        [headerView reset];
    }
    if ([headerView respondsToSelector:@selector(setActionDelegate:)]) {
        headerView.actionDelegate = self.actionDelegate;
    }
    headerView.headerFooter = header;
    [headerView update];
    return headerView;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    WBTableSection *sectionObject = [self sectionAtIndex:section];
    WBTableSectionHeaderFooter *footer = sectionObject.footer;
    if (!footer) {
        return nil;
    }
    NSString *footerIdentifier = NSStringFromClass(footer.associatedHeaderFooterClass);
    
    //registe if needed
    [self registeHeaderFooterIfNeededUseClass:footer.associatedHeaderFooterClass];
    
    //hook by
    UITableViewHeaderFooterView<WBTableHeaderFooterViewProtocal> *footerView = nil;
    if ([self.tableDataSource respondsToSelector:@selector(tableView:viewForFooterInSection:)]) {
        return [self.tableDataSource tableView:tableView viewForFooterInSection:section];
    }
    
    footerView = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:footerIdentifier];
    WBListKitAssert([footerView isKindOfClass:[UITableViewHeaderFooterView class]],@"footer 必须是 UITableViewHeaderFooterView的子类");
    WBListKitAssert([footerView conformsToProtocol:@protocol(WBTableHeaderFooterViewProtocal)],@"footer 必须遵守 WBListHeaderFooterViewProtocal 协议");
    if ([footerView respondsToSelector:@selector(reset)]) {
        [footerView reset];
    }
    if ([footerView respondsToSelector:@selector(setActionDelegate:)]) {
        footerView.actionDelegate = self.actionDelegate;
    }
    footerView.headerFooter = footer;
    [footerView update];
    return footerView;
}

#pragma mark setters

- (void)setTableDataSource:(id)tableDataSource {
    if (_tableDataSource != tableDataSource) {
        _tableDataSource = tableDataSource;
        [self updateTableDelegateProxy];
    }
}

- (void)setActionDelegate:(id<WBListActionToControllerProtocol>)actionDelegate{
    if (_actionDelegate != actionDelegate) {
        _actionDelegate = actionDelegate;
        [self updateTableDelegateProxy];
    }
}

#pragma mark getters

- (NSMutableSet *)registedCellIdentifier
{
    if (!_registedCellIdentifiers) {
        _registedCellIdentifiers = [NSMutableSet set];
    }
    return _registedCellIdentifiers;
}

- (NSMutableSet *)registedHeaderFooterIdentifiers
{
    if (!_registedHeaderFooterIdentifiers) {
        _registedHeaderFooterIdentifiers = [NSMutableSet set];
    }
    return _registedHeaderFooterIdentifiers;
}

- (NSMutableArray *)sections
{
    if (!_sections) {
        _sections = [NSMutableArray array];
    }
    return _sections;
}

- (WBTableUpdater *)updater{
    if (!_updater) {
        _updater = [WBTableUpdater new];
    }
    return _updater;
}

#pragma mark private method

- (void)updateTableDelegateProxy
{
    // there is a known bug with accessibility and using an NSProxy as the delegate that will cause EXC_BAD_ACCESS
    // when voiceover is enabled. it will hold an unsafe ref to the delegate
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
    
    self.delegateProxy = [[WBTableViewDelegateProxy alloc] initWithTableDataSourceTarget:_tableDataSource
                                                                         tableDelegateTarget:_actionDelegate
                                                                                 interceptor:self];
    
    // set up the delegate to the proxy so the adapter can intercept events
    // default to the adapter simply being the delegate
    _tableView.delegate = (id<UITableViewDelegate>)self.delegateProxy ?: self;
    _tableView.dataSource = (id<UITableViewDataSource>)self.delegateProxy ?: self;
}

- (CGFloat)heightForHeaderFooter:(WBTableSectionHeaderFooter *)headerFooter
                        inSectoin:(WBTableSection *)section{
    NSString *identifier = NSStringFromClass(headerFooter.associatedHeaderFooterClass);
    CGFloat height = [self.tableView fd_heightForHeaderFooterViewWithIdentifier:identifier configuration:^(id headerFooterView) {
        UIView<WBTableHeaderFooterViewProtocal> *view = headerFooterView;
        view.headerFooter = headerFooter;
        [view update];
    }];
    return height;
}

- (void)registeCellIfNeededUseCellClass:(Class)cellClass{
    WBListKitAssert(cellClass, @"请关联WBListRow对象的Cell");

    NSString *cellIdentifier = NSStringFromClass(cellClass);
    
    if ([self.registedCellIdentifiers containsObject:cellIdentifier]) {
        return;
    }
    
    NSString *cellNibPath = [[NSBundle mainBundle] pathForResource:cellIdentifier ofType:@"nib"];
    if (cellNibPath)
    {
        [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(cellClass) bundle:nil] forCellReuseIdentifier:cellIdentifier];
        [self.registedCellIdentifiers addObject:cellIdentifier];
    }
    else
    {
        [self.tableView registerClass:cellClass forCellReuseIdentifier:cellIdentifier];
        [self.registedCellIdentifiers addObject:cellIdentifier];
    }
}
- (void)registeHeaderFooterIfNeededUseClass:(Class)headerFooterClass{
    WBListKitAssert(headerFooterClass, @"请关联Footer和Header对象的View");
    NSString *footerHeaderIdentifier = NSStringFromClass(headerFooterClass);
    
    if ([self.registedHeaderFooterIdentifiers containsObject:footerHeaderIdentifier]) {
        return;
    }
    
    NSString *footerHeaderNibPath = [[NSBundle mainBundle] pathForResource:footerHeaderIdentifier ofType:@"nib"];
    if (footerHeaderNibPath)
    {
        [self.tableView registerNib:[UINib nibWithNibName:footerHeaderNibPath bundle:nil] forHeaderFooterViewReuseIdentifier:footerHeaderIdentifier];
        [self.registedHeaderFooterIdentifiers addObject:footerHeaderIdentifier];
    }
    else
    {
        [self.tableView registerClass:headerFooterClass forHeaderFooterViewReuseIdentifier:footerHeaderIdentifier];
        [self.registedHeaderFooterIdentifiers addObject:footerHeaderIdentifier];
    }
}

- (void)resetAllSectionsAndRowsRecords{
    [self.sections enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        WBTableSection *section = (WBTableSection *)obj;
        [section resetOldArray];
    }];
    self.oldSections = [self.sections copy];
}

@end

@implementation WBTableViewAdapter (ReloadShortcut)

- (void)reloadRowAtIndex:(NSIndexPath *)indexPath
               animation:(UITableViewRowAnimation)animationType
              usingBlock:(void(^)(WBTableRow *row))block{
    WBTableSection *section = [self sectionAtIndex:indexPath.section];
    WBTableRow *row = [section rowAtIndex:indexPath.row];
    block(row);
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:animationType];
}

- (void)reloadRowAtIndex:(NSInteger )index
           forSectionKey:(NSString *)key
               animation:(UITableViewRowAnimation)animationType
              usingBlock:(void(^)(WBTableRow *row))block{
    WBTableSection *section = [self sectionForKey:key];
    NSInteger sectionIndex = [self indexOfSection:section];
    WBTableRow *row = [section rowAtIndex:index];
    block(row);
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index
                                                                inSection:sectionIndex]]
                          withRowAnimation:animationType];
}

- (void)reloadSectionAtIndex:(NSInteger)index
                   animation:(UITableViewRowAnimation)animationType
                  usingBlock:(void(^)(WBTableSection *section))block{
    WBTableSection *section = [self sectionAtIndex:index];
    block(section);
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:index]
                  withRowAnimation:animationType];
}

- (void)reloadSectionForKey:(NSString *)key
                         animation:(UITableViewRowAnimation)animationType
                        usingBlock:(void(^)(WBTableSection *section))block{
    WBTableSection *section = [self sectionForKey:key];
    NSInteger sectionIndex = [self indexOfSection:section];
    block(section);
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                  withRowAnimation:animationType];
}

@end

@implementation WBTableViewAdapter (AutoDiffer)

- (void)beginAutoDiffer{
    if (self.isInDifferring){
        NSException* exception = [NSException exceptionWithName:@" BeginAutoDiffer Exception"
                                                         reason:@"已经有一个在differ中的任务"
                                                       userInfo:nil];
        @throw exception;
        return;
    }
    
    [self reloadDifferWithAnimation:NO];
    
    self.isInDifferring = YES;
    self.oldSections = [self.sections copy];
    [self.sections enumerateObjectsUsingBlock:^(id  _Nonnull obj,
                                                NSUInteger idx,
                                                BOOL * _Nonnull stop) {
        WBTableSection *section = (WBTableSection *)obj;
        [section recordOldArray];
    }];
}

- (void)commitAutoDifferWithAnimation:(BOOL)animation{
    if (!self.isInDifferring) {
        NSException* exception = [NSException exceptionWithName:@" CommitAutoDiffer Exception"
                                                         reason:@"先使用beginAutoDiffer开始任务，才能提交任务"
                                                       userInfo:nil];
        @throw exception;
        return;
    }
    self.isInDifferring = NO;
    [self.updater diffSectionsAndRowsInTableView:self.tableView
                                            from:self.oldSections
                                              to:self.sections
                                       animation:animation];
    [self resetAllSectionsAndRowsRecords];
}

- (void)reloadDifferWithAnimation:(BOOL)animation{
    [self.updater diffSectionsAndRowsInTableView:self.tableView
                                            from:self.oldSections
                                              to:self.sections
                                       animation:animation];
    [self resetAllSectionsAndRowsRecords];
}

@end

