/********* bqScanner.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import "QRCodeReaderViewController.h"
@interface bqScanner : CDVPlugin<QRCodeReaderDelegate> {
  // Member variables go here.
}

- (void)scan:(CDVInvokedUrlCommand*)command;
@end

@implementation bqScanner

- (void)scan:(CDVInvokedUrlCommand*)command
{
    
    
    
    QRCodeReaderViewController *reader = nil;
    
    NSString *type = command.arguments[0];
    if ([type isEqualToString:@"QRCode"]) {
        reader.codeType = CodeTypeQR;
        reader = [[QRCodeReaderViewController alloc] initWithCodeType:CodeTypeQR];
    }else{//BarCode
        reader = [[QRCodeReaderViewController alloc] initWithCodeType:CodeTypeBar];
    }
    
    reader.modalPresentationStyle = UIModalPresentationFormSheet;
    reader.delegate = self;
    
    [reader setCompletionWithBlock:^(NSString *resultAsString) {
        CDVPluginResult* result = nil;
        
        if (resultAsString) {
            result = [CDVPluginResult
                      resultWithStatus: CDVCommandStatus_OK
                      messageAsString: resultAsString
                      ];
        }else{
            result = [CDVPluginResult
                      resultWithStatus: CDVCommandStatus_ERROR
                      messageAsString: @"cancel"
                      ];
        }
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
    [self.viewController presentViewController:reader animated:YES completion:nil];
}


@end
