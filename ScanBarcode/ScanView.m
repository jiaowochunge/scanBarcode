//
//  ScanView.m
//  Taolv365.IOS.Info
//
//  Created by taolv on 15/8/7.
//  Copyright (c) 2015年 taolv365.com. All rights reserved.
//

#import "ScanView.h"

typedef NS_ENUM(NSInteger, PanCorner) {
    PanCornerLeftTop,
    PanCornerLeftBottom,
    PanCornerRightTop,
    PanCornerRightBottom,
    PanCornerNot
};

@interface ScanView ()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImageView *leftTopCornerView;
@property (nonatomic, strong) UIImageView *leftBottomCornerView;
@property (nonatomic, strong) UIImageView *rightTopCornerView;
@property (nonatomic, strong) UIImageView *rightBottomCornerView;

// 边角指示线长度
@property (nonatomic, assign) CGFloat cornerLength;
// 扩展边角点击范围
@property (nonatomic, assign) CGFloat expandCornerLength;
// 四周半透明，中间透明的遮罩
@property (nonatomic, strong) CAShapeLayer *maskLayer;
// 平移手势种类。平移整个扫描框，还是拖动四角
@property (nonatomic, assign) PanCorner panType;

@end

@implementation ScanView

- (instancetype)initWithFrame:(CGRect)frame scanRect:(CGRect)scanRect
{
    self = [super initWithFrame:frame];
    if (self) {
        _scanRect = scanRect;
        
        [self.layer addSublayer:self.maskLayer];
        [self addFourCorner];
        
        self.userInteractionEnabled = YES;
        // 拖动事件
        UIGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveScanRect:)];
        panGesture.delegate = self;
        [self addGestureRecognizer:panGesture];
        // 缩放事件
        UIGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(scaleScanRect:)];
        [self addGestureRecognizer:pinchGesture];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.leftTopCornerView.frame = CGRectMake(_scanRect.origin.x, _scanRect.origin.y, _cornerLength, _cornerLength);
    self.rightTopCornerView.frame = CGRectMake(_scanRect.origin.x + _scanRect.size.width - _cornerLength, _scanRect.origin.y, _cornerLength, _cornerLength);
    self.leftBottomCornerView.frame = CGRectMake(_scanRect.origin.x, _scanRect.origin.y + _scanRect.size.height - _cornerLength, _cornerLength, _cornerLength);
    self.rightBottomCornerView.frame = CGRectMake(_scanRect.origin.x + _scanRect.size.width - _cornerLength, _scanRect.origin.y + _scanRect.size.height - _cornerLength, _cornerLength, _cornerLength);
}

- (void)addFourCorner {
    _cornerLength = 10;
    _expandCornerLength = 10;
    // 添加左上角指示
    UIImage *image = [self leftTopCornerImage];
    self.leftTopCornerView = [[UIImageView alloc] initWithImage:image];
    self.leftTopCornerView.frame = CGRectMake(_scanRect.origin.x, _scanRect.origin.y, _cornerLength, _cornerLength);
    [self addSubview:self.leftTopCornerView];
    // 右上角
    UIImage *image2 = [UIImage imageWithCGImage:image.CGImage scale:1 orientation:UIImageOrientationUpMirrored];
    self.rightTopCornerView = [[UIImageView alloc] initWithImage:image2];
    self.rightTopCornerView.frame = CGRectMake(_scanRect.origin.x + _scanRect.size.width - _cornerLength, _scanRect.origin.y, _cornerLength, _cornerLength);
    [self addSubview:self.rightTopCornerView];
    // 左下角
    UIImage *image3 = [UIImage imageWithCGImage:image.CGImage scale:1 orientation:UIImageOrientationDownMirrored];
    self.leftBottomCornerView = [[UIImageView alloc] initWithImage:image3];
    self.leftBottomCornerView.frame = CGRectMake(_scanRect.origin.x, _scanRect.origin.y + _scanRect.size.height - _cornerLength, _cornerLength, _cornerLength);
    [self addSubview:self.leftBottomCornerView];
    // 右下角
    UIImage *image4 = [UIImage imageWithCGImage:image.CGImage scale:1 orientation:UIImageOrientationDown];
    self.rightBottomCornerView = [[UIImageView alloc] initWithImage:image4];
    self.rightBottomCornerView.frame = CGRectMake(_scanRect.origin.x + _scanRect.size.width - _cornerLength, _scanRect.origin.y + _scanRect.size.height - _cornerLength, _cornerLength, _cornerLength);
    [self addSubview:self.rightBottomCornerView];
}

// 左上角图片
- (UIImage *)leftTopCornerImage {
    // 不知道这样做对不对，完全是自臆
    CGContextRef context = UIGraphicsGetCurrentContext();
    // push context
    UIGraphicsPushContext(context);
    // 创建一个新的图形上下文
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(_cornerLength, _cornerLength), NO, [UIScreen mainScreen].scale);
    context = UIGraphicsGetCurrentContext();
    CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);//设置当前笔头颜色
    CGContextSetLineWidth(context, 5.0);//设置当前画笔粗细
    CGContextMoveToPoint(context, _cornerLength, 0.0);//将画笔移到某点
    CGContextAddLineToPoint(context, 0, 0);//设置一个终点
    CGContextAddLineToPoint(context, 0, _cornerLength);
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    // 结束图形上下文
    UIGraphicsEndImageContext();
    // pop context
    UIGraphicsPopContext();
    return image;
}

- (CAShapeLayer *)maskLayer
{
    if (!_maskLayer) {
        UIBezierPath *rectPath = [UIBezierPath bezierPathWithRect:_scanRect];
        rectPath.usesEvenOddFillRule = YES;
        
        UIBezierPath *clipPath = [UIBezierPath bezierPathWithRect:self.bounds];
        [clipPath appendPath:rectPath];
        clipPath.usesEvenOddFillRule = YES;
        
        self.maskLayer = [CAShapeLayer layer];
        _maskLayer.fillRule = kCAFillRuleEvenOdd;
        _maskLayer.fillColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.7f].CGColor;
        _maskLayer.path = [clipPath CGPath];
    }
    return _maskLayer;
}

- (void)setScanRect:(CGRect)scanRect
{
    // 超出边界，拒绝变换
    if (!CGRectContainsRect(self.bounds, scanRect)) {
        return;
    }
    if (scanRect.size.width < 50 || scanRect.size.height < 50) {
        return;
    }
    _scanRect = scanRect;
    if (_maskLayer) {
        UIBezierPath *rectPath = [UIBezierPath bezierPathWithRect:_scanRect];
        rectPath.usesEvenOddFillRule = YES;
        
        UIBezierPath *clipPath = [UIBezierPath bezierPathWithRect:self.bounds];
        [clipPath appendPath:rectPath];
        clipPath.usesEvenOddFillRule = YES;
        
        _maskLayer.path = [clipPath CGPath];
    }
    [self setNeedsLayout];
}

- (void)moveScanRect:(UIPanGestureRecognizer *)gesture
{
    CGPoint translation = [gesture translationInView:self];
    CGRect scanRect;
    if (_panType == PanCornerNot) {
        scanRect = CGRectOffset(_scanRect, translation.x, translation.y);
    } else if (_panType == PanCornerLeftTop) {
        scanRect = _scanRect;
        scanRect.origin.x += translation.x;
        scanRect.origin.y += translation.y;
        scanRect.size.width -= translation.x;
        scanRect.size.height -= translation.y;
    } else if (_panType == PanCornerLeftBottom) {
        scanRect = _scanRect;
        scanRect.origin.x += translation.x;
        scanRect.size.width -= translation.x;
        scanRect.size.height += translation.y;
    } else if (_panType == PanCornerRightTop) {
        scanRect = _scanRect;
        scanRect.origin.y += translation.y;
        scanRect.size.width += translation.x;
        scanRect.size.height -= translation.y;
    } else if (_panType == PanCornerRightBottom) {
        scanRect = _scanRect;
        scanRect.size.width += translation.x;
        scanRect.size.height += translation.y;
    } else {
        NSAssert(NO, @"shenme gui");
    }
    self.scanRect = scanRect;
    [gesture setTranslation:CGPointZero inView:self];
    if (gesture.state == UIGestureRecognizerStateEnded) {
        if (_endOfChangeScanRect) {
            _endOfChangeScanRect(_scanRect);
        }
    }
}

- (void)scaleScanRect:(UIPinchGestureRecognizer *)gesture
{
    CGFloat scale = gesture.scale;
    CGRect scanRect = self.scanRect;
    CGFloat deltaW = scanRect.size.width * (scale - 1);
    CGFloat deltaH = scanRect.size.height * (scale - 1);
    // 保持中心不变
    scanRect.size.width += deltaW;
    scanRect.size.height += deltaH;
    scanRect.origin.x -= deltaW * 0.5;
    scanRect.origin.y -= deltaH * 0.5;
    self.scanRect = scanRect;
    gesture.scale = 1;
    if (gesture.state == UIGestureRecognizerStateEnded) {
        if (_endOfChangeScanRect) {
            _endOfChangeScanRect(_scanRect);
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        CGPoint touchPoint = [touch locationInView:self];
        
        BOOL (^testInCorner)(UIView *testView) = ^(UIView *testView) {
            CGRect testRect = CGRectInset(testView.frame, -_expandCornerLength, -_expandCornerLength);
            if (CGRectContainsPoint(testRect, touchPoint)) {
                return YES;
            }
            return NO;
        };
        if (testInCorner(_leftTopCornerView)) {
            _panType = PanCornerLeftTop;
            return YES;
        }
        if (testInCorner(_leftBottomCornerView)) {
            _panType = PanCornerLeftBottom;
            return YES;
        }
        if (testInCorner(_rightTopCornerView)) {
            _panType = PanCornerRightTop;
            return YES;
        }
        if (testInCorner(_rightBottomCornerView)) {
            _panType = PanCornerRightBottom;
            return YES;
        }
        if (CGRectContainsPoint(_scanRect, touchPoint)) {
            _panType = PanCornerNot;
            return YES;
        }
        return NO;
    }
    return YES;
}

@end
