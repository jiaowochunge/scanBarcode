//
//  ScanView.h
//  Taolv365.IOS.Info
//
//  Created by taolv on 15/8/7.
//  Copyright (c) 2015年 taolv365.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScanView : UIView

// designated initializer
- (instancetype)initWithFrame:(CGRect)frame scanRect:(CGRect)scanRect;

@property (nonatomic, assign) CGRect scanRect;

// 设置扫描区域结束时回调
@property (nonatomic, copy) void(^endOfChangeScanRect)(CGRect scanRect);

@end
