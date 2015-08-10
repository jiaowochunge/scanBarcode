//
//  ScanQRCodeViewController.m
//  Taolv365.IOS.Info
//
//  Created by taolv on 15/8/6.
//  Copyright (c) 2015年 taolv365.com. All rights reserved.
//

#import "ScanQRCodeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ScanView.h"

@interface ScanQRCodeViewController ()<AVCaptureMetadataOutputObjectsDelegate>

@property (strong, nonatomic) AVCaptureDevice* device;
@property (strong, nonatomic) AVCaptureDeviceInput* input;
@property (strong, nonatomic) AVCaptureMetadataOutput* output;
@property (strong, nonatomic) AVCaptureSession* session;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer* preview;

@property (strong, nonatomic) UILabel *scanResultLabel;

@property (strong, nonatomic) UIButton *transitionButton;

@property (strong, nonatomic) UISlider *presetSlider;

@property (strong, nonatomic) ScanView *scanView;

@end

@implementation ScanQRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"扫一扫";
    [self setupSession];
    
    [self buildOtherNode];
    
    // 没什么用，不要了。
//    [self.view addSubview:self.presetSlider];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)buildOtherNode {
    // 扫描结果
    _scanResultLabel = [[UILabel alloc] init];
    _scanResultLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:_scanResultLabel];
    // add constraints
    _scanResultLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_scanResultLabel attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_scanResultLabel attribute:NSLayoutAttributeBottom multiplier:1 constant:50]];
    [self.view addSubview:self.scanResultLabel];
    // 查询按钮
    _transitionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_transitionButton setTitle:@"立即查询" forState:UIControlStateNormal];
    [_transitionButton addTarget:self action:@selector(queryCodeAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_transitionButton];
    // add constraints
    _transitionButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_transitionButton attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_transitionButton attribute:NSLayoutAttributeBottom multiplier:1 constant:20]];
    self.transitionButton.hidden = YES;
}

- (void)queryCodeAction:(id)sender {
}

- (UISlider *)presetSlider {
    if (_presetSlider) {
        _presetSlider = [UISlider new];
        _presetSlider.minimumValue = 0.1;
        _presetSlider.maximumValue = 0.9;
        _presetSlider.continuous = NO;
        [_presetSlider addTarget:self action:@selector(changePreset:) forControlEvents:UIControlEventValueChanged];
        // 添加约束
        _presetSlider.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_presetSlider attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [_presetSlider addConstraint:[NSLayoutConstraint constraintWithItem:_presetSlider attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:100]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_presetSlider attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:20]];
    }
    return _presetSlider;
}

- (void)changePreset:(id)sender
{
    NSInteger dd = _presetSlider.value / 0.33;
    switch (dd) {
        case 0:
            if ([_session canSetSessionPreset:AVCaptureSessionPresetLow]) {
                _session.sessionPreset = AVCaptureSessionPresetLow;
            }
            break;
        case 1:
            if ([_session canSetSessionPreset:AVCaptureSessionPresetMedium]) {
                _session.sessionPreset = AVCaptureSessionPresetMedium;
            }
            break;
        case 2:
            if ([_session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
                _session.sessionPreset = AVCaptureSessionPresetHigh;
            }
            break;
        default:
            break;
    }
}

- (void)setupSession {
    self.session = [[AVCaptureSession alloc] init];
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
    if (input) {
        [self.session addInput:input];
    } else {
        NSLog(@"Error: %@", error);
        return;
    }
    
    dispatch_queue_t queue = dispatch_queue_create("com.taolv.scan", DISPATCH_QUEUE_SERIAL);
    
    self.output = [[AVCaptureMetadataOutput alloc] init];
    [self.output setMetadataObjectsDelegate:self queue:queue];
    [self.session addOutput:self.output];
    // 去掉人脸扫描
    NSArray *availableMetadataObjectTypes = [self.output availableMetadataObjectTypes];
    NSMutableArray *processedTypes = [availableMetadataObjectTypes mutableCopy];
    [processedTypes removeObject:AVMetadataObjectTypeFace];
    [self.output setMetadataObjectTypes:processedTypes];
    
    // Preview
    self.preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.preview.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self.view.layer addSublayer:self.preview];
    
    self.scanView = [[ScanView alloc] initWithFrame:self.view.bounds scanRect:CGRectMake(30, 100, self.view.bounds.size.width - 60, 200)];
    __weak typeof(self) weakSelf = self;
    _scanView.endOfChangeScanRect = ^(CGRect scanRect) {
        // 设置扫描区
        CGRect rect1 = [weakSelf.preview metadataOutputRectOfInterestForRect:scanRect];
        weakSelf.output.rectOfInterest = rect1;
    };
    [self.view addSubview:_scanView];

    [self.session startRunning];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (![self.session isRunning]) {
        [self.session startRunning];
    }
    // 设置扫描区。这个放viewdidload中不生效。
    CGRect rect1 = [_preview metadataOutputRectOfInterestForRect:_scanView.scanRect];
    self.output.rectOfInterest = rect1;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.session stopRunning];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection
{
    NSString *QRCode = nil;
    for (AVMetadataObject *metadata in metadataObjects) {
        if ([metadata isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
            QRCode = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
            break;
        }
    }
    
    if (QRCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _scanResultLabel.text = QRCode;
            _transitionButton.hidden = NO;
        });
    }
}

@end
