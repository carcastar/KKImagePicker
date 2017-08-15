//
//  KKImagePickerController.m
//  KKImagePicker
//
//  Created by dev2.ttm on 1/11/16.
//  Copyright © 2016 dev2.ttm. All rights reserved.
//

#import "KKImagePickerController.h"
#import <AVFoundation/AVFoundation.h>


//图片选择器
@interface KKImagePickerController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIAlertViewDelegate>

//照片获取
@property (strong, nonatomic) NSMutableArray *assets;
@property (strong, nonatomic) ALAssetsLibrary *assetsLibrary;
@property (strong, nonatomic) UICollectionView *collectionView;

//照相机拍照
typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);
@property (strong, nonatomic) AVCaptureSession *captureSession;//负责输入和输出设备之间的数据传输
@property (strong, nonatomic) AVCaptureDeviceInput *captureDeviceInput;//负责从AVCaptureDevice获取数据
@property (strong, nonatomic) AVCaptureStillImageOutput *captureStillImageOutput;//照片输出流
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPrevicewLayer;//相机拍摄玉兰图层
@property (strong, nonatomic) UIView *viewContainer;//
@property (strong, nonatomic) UIButton *takeButton;//拍照按钮
@property (strong, nonatomic) UIImageView *focusCursor;//聚焦光标

@end

@implementation KKImagePickerController

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor blackColor];
}

#pragma mark - View Did Load
- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupNavigationBar];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"select", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"camera", nil),NSLocalizedString(@"album", nil), nil];
    [alertView show];
    
}
#pragma mark - UIAlertView Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if (buttonIndex == 1) {
        [self.view addSubview:self.viewContainer];
        [self loadCamera];
    } else {
        [self.view addSubview:self.collectionView];
        [self loadPhotos];
    }
}
- (void)setupNavigationBar {
    self.navigationItem.title = @"Select";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(backAction)];
    
}
#pragma mark - Load Photos
- (NSMutableArray *)assets {
    if (!_assets) {
        _assets = [[NSMutableArray alloc] init];
    }
    return _assets;
}

- (ALAssetsLibrary *)assetsLibrary {
    if (!_assetsLibrary) {
        _assetsLibrary = [[ALAssetsLibrary alloc] init];
    }
    return _assetsLibrary;
}
- (void)loadPhotos {
    
    ALAssetsGroupEnumerationResultsBlock assetsEnumerationBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if (result) {
            [self.assets insertObject:result atIndex:0];
        }
    };
    
    ALAssetsLibraryGroupsEnumerationResultsBlock listGroupBlock = ^(ALAssetsGroup *group, BOOL *stop) {
        ALAssetsFilter *onlyPhotosFilter = [ALAssetsFilter allPhotos];
        [group setAssetsFilter:onlyPhotosFilter];
        if ([group numberOfAssets] > 0) {
            if ([[group valueForProperty:ALAssetsGroupPropertyType] intValue] == ALAssetsGroupSavedPhotos) {
                [group enumerateAssetsUsingBlock:assetsEnumerationBlock];
            }
        }
        
        if (group == nil) {
            [self.collectionView reloadData];
        }
        
    };
    
    [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:listGroupBlock failureBlock:^(NSError *error) {
        NSLog(@"Load Photos Error:%@",error);
//        [PromptTool showErrorPromptWithStatus:error.localizedDescription];
    }];
    
}
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        CGFloat colum = 4.0, spacing = 2.0;
        CGFloat value = floorf((CGRectGetWidth(self.view.bounds) - (colum - 1) * spacing) / colum);
        UICollectionViewFlowLayout *layout  = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize                     = CGSizeMake(value, value);
        layout.sectionInset                 = UIEdgeInsetsMake(0, 0, 0, 0);
        layout.minimumInteritemSpacing      = spacing;
        layout.minimumLineSpacing           = spacing;
        
        CGRect rect = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
        _collectionView = [[UICollectionView alloc] initWithFrame:rect collectionViewLayout:layout];
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight ;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        [_collectionView registerClass:[KKImageCollectionViewCell class] forCellWithReuseIdentifier:@"KKImageCollectionViewCell"];
    }
    return _collectionView;
}

#pragma mark - Collection View Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"KKImageCollectionViewCell";
    
    KKImageCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.imageView.image = [UIImage imageWithCGImage:[[self.assets objectAtIndex:indexPath.row] thumbnail]];
    
    return cell;
}

#pragma mark - Collection View Delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if (self.allowsEditing) {
        KKImageEditController *imageEdit = [[KKImageEditController alloc] init];
        imageEdit.asset = [self.assets objectAtIndex:indexPath.row];
        imageEdit.editingBlock = ^(UIImage *image){
            self.cropBlock(image);
            [self backAction];
        };
        [self.navigationController pushViewController:imageEdit animated:YES];
    } else {
        UIImage *image  = [UIImage imageWithCGImage:[[[self.assets objectAtIndex:indexPath.row] defaultRepresentation] fullScreenImage]];
        if (self.cropBlock) {
            self.cropBlock(image);
        }
        [self backAction];
    }
    
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}
#pragma mark - Load Camera
- (UIButton *)takeButton {
    if (!_takeButton) {
        _takeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        CGRect rect = CGRectMake(CGRectGetWidth(self.viewContainer.bounds)/2-30, CGRectGetHeight(self.viewContainer.bounds)-74, 60, 60);
        _takeButton.frame = rect;
        [_takeButton setBackgroundColor:[UIColor whiteColor]];
        _takeButton.layer.masksToBounds = YES;
        _takeButton.layer.cornerRadius = _takeButton.bounds.size.height/2;
        _takeButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
        _takeButton.layer.borderWidth = 1.5;
        [_takeButton addTarget:self action:@selector(takeButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _takeButton;
}

- (UIView *)viewContainer {
    if (!_viewContainer) {
        CGRect rect = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
        _viewContainer = [[UIView alloc] initWithFrame:rect];
        [_viewContainer addSubview:self.takeButton];
        _viewContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight ;
        
    }
    return _viewContainer;
}

- (void)loadCamera {
    //初始化
    _captureSession = [[AVCaptureSession alloc] init];
//    设置分辨率
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        _captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    }
//    获取输入设备
    AVCaptureDevice *captureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];//后置摄像头
    if (!captureDevice) {
        NSLog(@"取得摄像头有问题");
        return;
    }
    
    NSError *error = nil;
    //根据设备初始化设备输入对象,用于获得输入数据
    _captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"取得设备输入对象出错,原因:%@",error.localizedDescription);
        return;
    }
//    初始化设备输出对象,用于获取输出数据
    _captureStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
    [_captureStillImageOutput setOutputSettings:outputSettings];//输出设置
    
//    将设备添加到会话中
    if ([_captureSession canAddInput:_captureDeviceInput]) {
        [_captureSession addInput:_captureDeviceInput];
    }
//    将设备输出添加到会话中
    if ([_captureSession canAddOutput:_captureStillImageOutput]) {
        [_captureSession addOutput:_captureStillImageOutput];
    }
//    创建视频预览层.用于实时预览摄像头状态
    _captureVideoPrevicewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    CALayer *layer = self.viewContainer.layer;
    layer.masksToBounds = YES;
    
    _captureVideoPrevicewLayer.frame = layer.bounds;
    _captureVideoPrevicewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;//填充模式
//    将视频预览层添加到界面中
    [layer insertSublayer:_captureVideoPrevicewLayer below:self.focusCursor.layer];
    
    [self addNotificationToCaptureDevice:captureDevice];
    [self addGenstureRecognizer];

    [self.captureSession startRunning];
    
}
#pragma mark - 私有方法
/**
 *  取得指定位置的摄像头
 *
 *  @param position 摄像头位置
 *
 *  @return 摄像头设备
 */
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position {
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            return camera;
        }
    }
    return nil;
}

- (void)changeDeviceProperty:(PropertyChangeBlock)propertyChange {
    AVCaptureDevice *captureDevice = [self.captureDeviceInput device];
    NSError *error;
    //注意改变设备属性前,首先调用lockForConfiguration,掉用完之后使用unlockForConfiguration解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    } else {
        NSLog(@"设备设置属性过程发生错误,错误信息:%@",error.localizedDescription);
    }
}
/**
 *  添加手势,点按时聚焦
 */
- (void)addGenstureRecognizer {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapScreen:)];
    [self.viewContainer addGestureRecognizer:tapGesture];
}
- (void)tapScreen:(UITapGestureRecognizer *)tapGesture {
    CGPoint point = [tapGesture locationInView:self.viewContainer];
//    将UI坐标转化为摄像头坐标
    CGPoint cameraPoint = [self.captureVideoPrevicewLayer captureDevicePointOfInterestForPoint:point];
    [self setFocusCursorWithPoint:cameraPoint];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}
/**
 *  设置聚焦光标位置
 *
 *  @param point 光标位置
 */
- (void)setFocusCursorWithPoint:(CGPoint)point {
    self.focusCursor.center = point;
    self.focusCursor.transform = CGAffineTransformMakeScale(1.5, 1.5);
    self.focusCursor.alpha = 1.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.focusCursor.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusCursor.alpha = 0.0;
    }];
}
/**
 *  设置聚焦点
 *
 *  @param point        聚焦点
 */
- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point {
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}
/**
 *  设置闪光灯按钮状态,预留,空
 */
- (void)setFlashModeButtonStatus {
    
}
/**
 *  拍照
 *
 *  @param sender 拍照按钮
 */
- (void)takeButtonClick:(UIButton *)sender {
//    根据设备输出获得连接
    AVCaptureConnection *captureConnection = [self.captureStillImageOutput connectionWithMediaType:AVMediaTypeVideo];
//    根据连接聚的设备输出的数据
    [self.captureStillImageOutput captureStillImageAsynchronouslyFromConnection:captureConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [UIImage imageWithData:imageData];
            
            KKImageEditController *imageEdit = [[KKImageEditController alloc] init];
            imageEdit.image = image;
            imageEdit.editingBlock = ^(UIImage *image){
                self.cropBlock(image);
                [self backAction];
            };
            [self.navigationController pushViewController:imageEdit animated:YES];
            
        }
    }];
}

#pragma mark - 通知
- (void)addNotificationToCaptureDevice:(AVCaptureDevice *)captureDevice {
//    注意添加区域改变通知不活必须首先设置设备允许捕获
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        captureDevice.subjectAreaChangeMonitoringEnabled = YES;
    }];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
//    捕获区域发生改变
    [notificationCenter addObserver:self selector:@selector(areaChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
}

/**
 *  捕获区域改变
 *
 *  @param notification 通知对象
 */
-(void)areaChange:(NSNotification *)notification{
    NSLog(@"捕获区域改变...");
}


#pragma mark - View Action
- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

//图片展示cell
@implementation KKImageCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.imageView.layer.borderColor = [UIColor blueColor].CGColor;
        [self.contentView addSubview:self.imageView];
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.imageView.layer.borderWidth = selected ? 2 :0;
}

@end

//图片编辑器

@interface KKImageEditController ()<UIScrollViewDelegate>
{
    CGSize _imageSize;
}

@property (nonatomic, strong) UIScrollView *imageScrollView;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation KKImageEditController

- (void)loadView {
    [super loadView];
    [self.view addSubview:self.imageScrollView];
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self addLayer];
    if (self.asset) {
        [self displayImage:[UIImage imageWithCGImage:[[self.asset defaultRepresentation] fullScreenImage]]];
    }
    if (self.image) {
        [self displayImage:self.image];
    }
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self setupNavigationBar];
}

- (UIScrollView *)imageScrollView {
    if (!_imageScrollView) {
        CGFloat minFloat = MIN(CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
        CGRect rect = CGRectMake(0, 0, minFloat, minFloat);
        _imageScrollView = [[UIScrollView alloc] initWithFrame:rect];
        _imageScrollView.center = self.view.center;
//        _imageScrollView.center = self.view.center;
        _imageScrollView.clipsToBounds = NO;
        _imageScrollView.showsVerticalScrollIndicator = NO;
        _imageScrollView.showsHorizontalScrollIndicator = NO;
        _imageScrollView.alwaysBounceHorizontal = YES;
        _imageScrollView.alwaysBounceVertical = YES;
        _imageScrollView.bouncesZoom = YES;
        _imageScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
        _imageScrollView.delegate = self;
        _imageScrollView.backgroundColor = [UIColor clearColor];
    }
    return _imageScrollView;
}

- (void)addLayer {
    UIView *mask = [[UIView alloc] init];
    mask.layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7].CGColor;
    mask.layer.borderWidth = 1;
    
    mask.bounds = self.imageScrollView.bounds;
    mask.center = self.imageScrollView.center;
    mask.userInteractionEnabled = NO;
    [self.view addSubview:mask];
    
    UIView *maskTop = [[UIView alloc] init];
    maskTop.frame = CGRectMake(0, 0, self.view.bounds.size.width, (self.view.bounds.size.height-self.imageScrollView.bounds.size.height) /2);
    maskTop.userInteractionEnabled = NO;
    maskTop.backgroundColor = [UIColor blackColor];
    maskTop.alpha = 0.5;
    
    UIView *maskDown = [[UIView alloc] init];
    maskDown.backgroundColor = [UIColor blackColor];
    maskDown.alpha = 0.5;
    maskDown.frame = CGRectMake(0, CGRectGetMaxY(self.imageScrollView.frame), self.view.bounds.size.width, self.view.bounds.size.height/4);
    
    maskDown.userInteractionEnabled = NO;
    
    
    [self.view addSubview:maskTop];
    [self.view addSubview:maskDown];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // center the zoom view as it becomes smaller than the size of the screen
    CGSize boundsSize = self.imageScrollView.bounds.size;
    CGRect frameToCenter = self.imageView.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    self.imageView.frame = frameToCenter;
}

//获取scroll内的图片
- (UIImage *)capture {
    UIGraphicsBeginImageContextWithOptions(self.imageScrollView.frame.size, NO, [UIScreen mainScreen].scale);
    
    [self.imageScrollView drawViewHierarchyInRect:CGRectMake(0, 0, self.imageScrollView.frame.size.width, self.imageScrollView.frame.size.height) afterScreenUpdates:YES];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)displayImage:(UIImage *)image
{
    // clear the previous image
    [self.imageView removeFromSuperview];
    self.imageView = nil;
    
    
    // reset our zoomScale to 1.0 before doing any further calculations
    self.imageScrollView.zoomScale = 1.0;
    
    // make a new UIImageView for the new image
    self.imageView = [[UIImageView alloc] initWithImage:image];
    self.imageView.clipsToBounds = NO;
    
    [self.imageScrollView addSubview:self.imageView];
    
    CGRect frame = self.imageView.frame;
    if (image.size.height > image.size.width) {
        frame.size.width = self.imageScrollView.bounds.size.width;
        frame.size.height = (self.imageScrollView.bounds.size.width / image.size.width) * image.size.height;
    } else {
        frame.size.height = self.imageScrollView.bounds.size.height;
        frame.size.width = (self.imageScrollView.bounds.size.height / image.size.height) * image.size.width;
    }
    self.imageView.frame = frame;
    [self configureForImageSize:self.imageView.bounds.size];
}

- (void)configureForImageSize:(CGSize)imageSize
{
    _imageSize = imageSize;
    self.imageScrollView.contentSize = imageSize;
    
    //to center
    if (imageSize.width > imageSize.height) {
        self.imageScrollView.contentOffset = CGPointMake(imageSize.width/4, 0);
    } else if (imageSize.width < imageSize.height) {
        self.imageScrollView.contentOffset = CGPointMake(0, imageSize.height/4);
    }
    
    [self setMaxMinZoomScalesForCurrentBounds];
    self.imageScrollView.zoomScale = self.imageScrollView.minimumZoomScale;
}

- (void)setMaxMinZoomScalesForCurrentBounds
{
    self.imageScrollView.minimumZoomScale = 1.0;
    self.imageScrollView.maximumZoomScale = 2.0;
}
#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)setupNavigationBar {
    self.navigationItem.title = @"Editing";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Ok" style:UIBarButtonItemStylePlain target:self action:@selector(okAction)];
}
- (void)okAction {
    if (self.editingBlock) {
        self.editingBlock([self capture]);
    }
}

- (void)backTop:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
