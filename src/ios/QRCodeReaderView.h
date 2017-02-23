/*
 * QRCodeReaderViewController
 */

#import <UIKit/UIKit.h>

/**
 * Simple view to display an overlay (a square) over the camera view.
 * @since 2.0.0
 */


typedef NS_ENUM(NSInteger,CodeType){
    CodeTypeQR = 1,
    CodeTypeBar = 2
};

@protocol QRCodeReaderViewDelegate <NSObject>
- (void)loadView:(CGRect)rect;
@end

@interface QRCodeReaderView : UIView


@property (nonatomic, weak)   id<QRCodeReaderViewDelegate> delegate;
@property (nonatomic, assign) CGRect innerViewRect;

@property (nonatomic, assign) CodeType codeType;
@end
