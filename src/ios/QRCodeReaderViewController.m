/*
 * QRCodeReaderViewController
 */


#import "QRCodeReaderViewController.h"
#define mainHeight     [[UIScreen mainScreen] bounds].size.height
#define mainWidth      [[UIScreen mainScreen] bounds].size.width
#define navBarHeight   self.navigationController.navigationBar.frame.size.height


#define QRHeight 44
#define BarHeight -100


@interface QRCodeReaderViewController () <AVCaptureMetadataOutputObjectsDelegate,QRCodeReaderViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property (strong, nonatomic) QRCodeReaderView     *cameraView;
@property (strong, nonatomic) AVAudioPlayer        *beepPlayer;
@property (strong, nonatomic) UIImageView          *imgLine;
@property (strong, nonatomic) UILabel              *lblTip;
@property (strong, nonatomic) NSTimer              *timerScan;

@property (strong, nonatomic) AVCaptureDevice            *defaultDevice;
@property (strong, nonatomic) AVCaptureDeviceInput       *defaultDeviceInput;
@property (strong, nonatomic) AVCaptureDevice            *frontDevice;
@property (strong, nonatomic) AVCaptureDeviceInput       *frontDeviceInput;
@property (strong, nonatomic) AVCaptureMetadataOutput    *metadataOutput;
@property (strong, nonatomic) AVCaptureSession           *session;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;


@property (nonatomic, weak) UIImageView *cornerImg1;
@property (nonatomic, weak) UIImageView *cornerImg2;
@property (nonatomic, weak) UIImageView *cornerImg3;
@property (nonatomic, weak) UIImageView *cornerImg4;


@property (nonatomic, assign) BOOL torchIsOn;

@property (strong, nonatomic) CIDetector *detector;

@property (copy, nonatomic) void (^completionBlock) (NSString *);

@end

@implementation QRCodeReaderViewController

- (id)init{
    return [self initWithCodeType:CodeTypeQR];
}

- (id)initWithCodeType:(int)type;
{
    if ((self = [super init])) {
        self.view.backgroundColor = [UIColor blackColor];
        
        NSString * wavPath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"wav"];
        NSData* data = [[NSData alloc] initWithContentsOfFile:wavPath];
        _beepPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];

        [self setupAVComponents];
        [self configureDefaultComponents];
        [self setupUIComponentsWithCodeType:type];
        [self setupAutoLayoutConstraints];

        [_cameraView.layer insertSublayer:self.previewLayer atIndex:0];
    }
    return self;
}

+ (instancetype)readerWithCodeType:(int)type
{
  return [[self alloc] initWithCodeType:type];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
}
- (void)setUI{
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [self startScanning];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [self stopScanning];
  [super viewWillDisappear:animated];
}

- (void)viewWillLayoutSubviews
{
  [super viewWillLayoutSubviews];
  
  _previewLayer.frame = self.view.bounds;
}

- (BOOL)shouldAutorotate
{
  return YES;
}

- (void)scanAnimate
{
    _imgLine.frame = CGRectMake(0, _cameraView.innerViewRect.origin.y + 64 - 64, mainWidth, 12);
    [UIView animateWithDuration:2 animations:^{
        _imgLine.frame = CGRectMake(_imgLine.frame.origin.x, _imgLine.frame.origin.y + _cameraView.innerViewRect.size.height - 6, _imgLine.frame.size.width, _imgLine.frame.size.height);
    }];
}

- (void)loadView:(CGRect)rect
{
    _imgLine.frame = CGRectMake(0, _cameraView.innerViewRect.origin.y, mainWidth, 12);
    [self scanAnimate];
}

#pragma mark - Managing the Orientation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  
  [_cameraView setNeedsDisplay];
  
  if (self.previewLayer.connection.isVideoOrientationSupported) {
    self.previewLayer.connection.videoOrientation = [[self class] videoOrientationFromInterfaceOrientation:toInterfaceOrientation];
  }
}

+ (AVCaptureVideoOrientation)videoOrientationFromInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  switch (interfaceOrientation) {
    case UIInterfaceOrientationLandscapeLeft:
      return AVCaptureVideoOrientationLandscapeLeft;
    case UIInterfaceOrientationLandscapeRight:
      return AVCaptureVideoOrientationLandscapeRight;
    case UIInterfaceOrientationPortrait:
      return AVCaptureVideoOrientationPortrait;
    default:
      return AVCaptureVideoOrientationPortraitUpsideDown;
  }
}

#pragma mark - Managing the Block

- (void)setCompletionWithBlock:(void (^) (NSString *resultAsString))completionBlock
{
    self.completionBlock = completionBlock;
}

#pragma mark - Initializing the AV Components

- (void)setupUIComponentsWithCodeType:(int)type
{
    self.cameraView                                       = [[QRCodeReaderView alloc] init];
    _cameraView.translatesAutoresizingMaskIntoConstraints = NO;
    _cameraView.clipsToBounds                             = YES;
    _cameraView.delegate                                  = self;
    
    _cameraView.codeType = type;
    
    [self.view addSubview:_cameraView];
    
    CGFloat opHeight = 44;
    
    if (type == CodeTypeBar) {
        opHeight = opHeight - 100;
    }

    
    CGFloat c_width = mainWidth - 100;
    CGFloat s_height = mainHeight - 40;
    CGFloat y = (s_height - c_width) / 2 - s_height / 6 + 64 - 44;
    
    _lblTip = [[UILabel alloc] initWithFrame:CGRectMake(0,y + 90 + c_width, mainWidth, 15)];
    _lblTip.text = @"请将二维码/条形码放入框内";
    _lblTip.textColor = [UIColor whiteColor];
    _lblTip.font = [UIFont systemFontOfSize:14];
    _lblTip.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_lblTip];
    
    CGFloat corWidth = 16;
    
    UIImageView* img1 = [[UIImageView alloc] initWithFrame:CGRectMake(49, y + 56, corWidth, corWidth)];
    img1.image = [UIImage imageNamed:@"corner1"];
    _cornerImg1 = img1;
    [self.view addSubview:img1];
    
    UIImageView* img2 = [[UIImageView alloc] initWithFrame:CGRectMake(35 + c_width, y + 56, corWidth, corWidth)];
    img2.image = [UIImage imageNamed:@"corner2"];
    _cornerImg2 = img2;
    [self.view addSubview:img2];

    UIImageView* img3 = [[UIImageView alloc] initWithFrame:CGRectMake(49, y + c_width + opHeight, corWidth, corWidth)];
    img3.image = [UIImage imageNamed:@"corner3"];
    _cornerImg3 = img3;
    [self.view addSubview:img3];
    
    UIImageView* img4 = [[UIImageView alloc] initWithFrame:CGRectMake(35 + c_width, y + c_width + opHeight, corWidth, corWidth)];
    img4.image = [UIImage imageNamed:@"corner4"];
    _cornerImg4 = img4;
    [self.view addSubview:img4];
    
    
    _imgLine = [[UIImageView alloc] init];
    _imgLine.image = [UIImage imageNamed:@"QRCodeScanLine"];
    [self.view addSubview:_imgLine];
    
    
    UIButton *cancelBtn = [[UIButton alloc] init];
    cancelBtn.frame = CGRectMake((mainWidth - 200) / 2, mainHeight - 44 - 20, 200, 44);
    cancelBtn.backgroundColor = [UIColor clearColor];
    
    cancelBtn.layer.borderWidth = 1;
    cancelBtn.layer.borderColor = [[UIColor whiteColor] CGColor];
    cancelBtn.layer.cornerRadius = 5;
    cancelBtn.clipsToBounds = YES;
    
    [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancelBtn];
    
    
}


- (void)setupAutoLayoutConstraints
{
  NSDictionary *views = NSDictionaryOfVariableBindings(_cameraView);
  
  [self.view addConstraints:
   [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_cameraView]-0-|" options:0 metrics:nil views:views]];
  [self.view addConstraints:
   [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_cameraView]|" options:0 metrics:nil views:views]];
    
    
}

- (void)setupAVComponents
{
  self.defaultDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
  
  if (_defaultDevice) {
    self.defaultDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_defaultDevice error:nil];
    self.metadataOutput     = [[AVCaptureMetadataOutput alloc] init];
    self.session            = [[AVCaptureSession alloc] init];
    self.previewLayer       = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
      if (device.position == AVCaptureDevicePositionFront) {
        self.frontDevice = device;
      }
    }
    
    if (_frontDevice) {
      self.frontDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_frontDevice error:nil];
    }
  }
}

- (void)configureDefaultComponents
{
    [_session addOutput:_metadataOutput];
    _session.sessionPreset = AVCaptureSessionPresetHigh;
    
    if (_defaultDeviceInput) {
        [_session addInput:_defaultDeviceInput];
    }

    [_metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];

    [_metadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code]];


    [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    if ([_previewLayer.connection isVideoOrientationSupported]) {
        _previewLayer.connection.videoOrientation = [[self class] videoOrientationFromInterfaceOrientation:self.interfaceOrientation];
    }
}

- (void)switchDeviceInput
{
  if (_frontDeviceInput) {
    [_session beginConfiguration];
    
    AVCaptureDeviceInput *currentInput = [_session.inputs firstObject];
    [_session removeInput:currentInput];
    
    AVCaptureDeviceInput *newDeviceInput = (currentInput.device.position == AVCaptureDevicePositionFront) ? _defaultDeviceInput : _frontDeviceInput;
    [_session addInput:newDeviceInput];
    
    [_session commitConfiguration];
  }
}

#pragma mark - Catching Button Events

- (void)cancelAction:(UIButton *)button
{
  [self stopScanning];
  if (_completionBlock) {
    _completionBlock(nil);
  }
  
  if (_delegate && [_delegate respondsToSelector:@selector(readerDidCancel:)]) {
    [_delegate readerDidCancel:self];
  }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)switchCameraAction:(UIButton *)button
{
  [self switchDeviceInput];
}

#pragma mark - Controlling Reader

- (void)startScanning;
{
    if (![self.session isRunning]) {
        [self.session startRunning];
        CGRect rect = CGRectMake(_cornerImg1.frame.origin.y / mainHeight,
                                 _cornerImg1.frame.origin.x / mainWidth,
                                 (_cornerImg3.frame.origin.y - _cornerImg1.frame.origin.y) / mainHeight,
                                 (_cornerImg2.frame.origin.x - _cornerImg1.frame.origin.x) / mainWidth);
        _metadataOutput.rectOfInterest = rect;
        
    }
    
    if(_timerScan)
    {
        [_timerScan invalidate];
        _timerScan = nil;
    }
    
    _timerScan = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(scanAnimate) userInfo:nil repeats:YES];
}

- (void)stopScanning;
{
    if ([self.session isRunning]) {
        [self.session stopRunning];
    }
    if(_timerScan)
    {
        [_timerScan invalidate];
        _timerScan = nil;
    }
}

#pragma mark - AVCaptureMetadataOutputObjects Delegate Methods

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    for(AVMetadataObject *current in metadataObjects) {
        if ([current isKindOfClass:[AVMetadataMachineReadableCodeObject class]]){
            NSString *scannedResult = [(AVMetadataMachineReadableCodeObject *) current stringValue];
            
            
            [self stopScanning];

           if (_completionBlock) {
                [_beepPlayer play];
                _completionBlock(scannedResult);
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            
            __weak __typeof(&*self)weakSelf = self;
            
             if (_delegate && [_delegate respondsToSelector:@selector(reader:didScanResult:)]) {
                 [_delegate reader:weakSelf didScanResult:scannedResult];
                 [self dismissViewControllerAnimated:YES completion:nil];
             }
        }
    }
}

#pragma mark - Checking the Metadata Items Types

+ (BOOL)isAvailable
{
  @autoreleasepool {
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if (!captureDevice) {
      return NO;
    }
    
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (!deviceInput || error) {
      return NO;
    }
    
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    
    if (![output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
      return NO;
    }
    
    return YES;
  }
}

#pragma mark - Checking RightBarButtonItem
-(void)clickRightBarButton:(UIBarButtonItem*)item
{
    self.detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate
- ( void )imagePickerController:( UIImagePickerController *)picker didFinishPickingMediaWithInfo:( NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image){
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    //    NSArray *features = [self.detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]
    //                                               options:@{CIDetectorImageOrientation:[NSNumber numberWithInt:1]}];
    NSArray *features = [self.detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
    if (features.count >=1) {
        CIQRCodeFeature *feature = [features objectAtIndex:0];
        NSString *scannedResult = feature.messageString;
        if (_completionBlock) {
            [_beepPlayer play];
            _completionBlock(scannedResult);
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        
        if (_delegate && [_delegate respondsToSelector:@selector(reader:didScanResult:)]) {
            [_delegate reader:self didScanResult:scannedResult];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}
- (void)rightAction{
    [self turnTorchOn:!_torchIsOn];
}

- (void) turnTorchOn: (bool) on {
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
            
            [device lockForConfiguration:nil];
            if (on) {
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
                _torchIsOn = YES;
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
                _torchIsOn = NO;
            }
            [device unlockForConfiguration];
        }
    }
}



@end
