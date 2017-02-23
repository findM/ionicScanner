/*
 * QRCodeReaderViewController
 *
 */

#import "QRCodeReaderView.h"
#import <QuartzCore/QuartzCore.h>

@interface QRCodeReaderView ()
{
    __weak id<QRCodeReaderViewDelegate> delegate;
    CGRect       innerViewRect;
    
}
@property (nonatomic, strong) CAShapeLayer *overlay;
@end

@implementation QRCodeReaderView
@synthesize innerViewRect,delegate;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self addOverlay];
  }
  
  return self;
}

- (void)drawRect:(CGRect)rect
{
    CGRect innerRect = CGRectInset(rect, 50, 50);
    
    CGFloat minSize = MIN(innerRect.size.width, innerRect.size.height);
    if (innerRect.size.width != minSize) {
        innerRect.origin.x   += 50;
        innerRect.size.width = minSize;
    }
    else if (innerRect.size.height != minSize) {
        innerRect.origin.y   += (rect.size.height - minSize) / 2 - rect.size.height / 6;
        innerRect.size.height = minSize;
    }
    CGRect offsetRect = CGRectOffset(innerRect, 0, 15);
    
    if(_codeType == CodeTypeBar){
        offsetRect.size.height = offsetRect.size.height - 100;
    }
    
    
    innerViewRect = offsetRect;
    if(delegate)
    {
        [delegate loadView:innerViewRect];
    }
    _overlay.path = [UIBezierPath bezierPathWithRect:offsetRect].CGPath;
    
    [self addOtherLay:offsetRect];
}

#pragma mark - Private Methods

- (void)addOverlay
{
    _overlay = [[CAShapeLayer alloc] init];
    _overlay.backgroundColor = [UIColor redColor].CGColor;
    _overlay.fillColor       = [UIColor clearColor].CGColor;
    _overlay.strokeColor     = [UIColor lightGrayColor].CGColor;
    _overlay.lineWidth       = 1;
    _overlay.lineDashPattern = @[@50,@0];
    _overlay.lineDashPhase   = 1;
    _overlay.opacity         = 0.5;
    [self.layer addSublayer:_overlay];
}

- (void)addOtherLay:(CGRect)rect
{
    CAShapeLayer* layerTop   = [[CAShapeLayer alloc] init];
    layerTop.fillColor       = [UIColor blackColor].CGColor;
    layerTop.opacity         = 0.5;
    layerTop.path            = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, rect.origin.y)].CGPath;
    [self.layer addSublayer:layerTop];
    
    CAShapeLayer* layerLeft   = [[CAShapeLayer alloc] init];
    layerLeft.fillColor       = [UIColor blackColor].CGColor;
    layerLeft.opacity         = 0.5;
    layerLeft.path            = [UIBezierPath bezierPathWithRect:CGRectMake(0, rect.origin.y, 50, [UIScreen mainScreen].bounds.size.height)].CGPath;
    [self.layer addSublayer:layerLeft];
    
    CAShapeLayer* layerRight   = [[CAShapeLayer alloc] init];
    layerRight.fillColor       = [UIColor blackColor].CGColor;
    layerRight.opacity         = 0.5;
    layerRight.path            = [UIBezierPath bezierPathWithRect:CGRectMake([UIScreen mainScreen].bounds.size.width - 50, rect.origin.y, 50, [UIScreen mainScreen].bounds.size.height)].CGPath;
    [self.layer addSublayer:layerRight];
    
    CAShapeLayer* layerBottom   = [[CAShapeLayer alloc] init];
    layerBottom.fillColor       = [UIColor blackColor].CGColor;
    layerBottom.opacity         = 0.5;
    layerBottom.path            = [UIBezierPath bezierPathWithRect:CGRectMake(50, rect.origin.y + rect.size.height, [UIScreen mainScreen].bounds.size.width - 100, [UIScreen mainScreen].bounds.size.height - rect.origin.y - rect.size.height)].CGPath;
    [self.layer addSublayer:layerBottom];

}
@end
