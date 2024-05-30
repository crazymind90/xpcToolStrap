//  Created by CrazyMind90 ~ 2024.


#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/NSObjCRuntime.h>
#import <objc/message.h>
#import <CoreFoundation/CoreFoundation.h>
#include <dlfcn.h>

 

#pragma GCC diagnostic ignored "-Wunused-variable"
#pragma GCC diagnostic ignored "-Wprotocol"
#pragma GCC diagnostic ignored "-Wmacro-redefined"
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#pragma GCC diagnostic ignored "-Wincomplete-implementation"
#pragma GCC diagnostic ignored "-Wunknown-pragmas"
#pragma GCC diagnostic ignored "-Wformat"
#pragma GCC diagnostic ignored "-Wunknown-warning-option"
#pragma GCC diagnostic ignored "-Wincompatible-pointer-types"
#pragma GCC diagnostic ignored "-Wunused-value"
#pragma GCC diagnostic ignored "-Wunused-function"
#pragma GCC diagnostic ignored "-Wunused-variable"


#define CLog(format, ...) NSLog(@"CM90~[inApp] : " format, ##__VA_ARGS__)


#define rgbValue
#define UIColorFromHEX(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

 
static UIViewController *_topMostController(UIViewController *cont) {
UIViewController *topController = cont;
 while (topController.presentedViewController) {
 topController = topController.presentedViewController;
 }
 if ([topController isKindOfClass:[UINavigationController class]]) {
 UIViewController *visible = ((UINavigationController *)topController).visibleViewController;
 if (visible) {
topController = visible;
 }
}
 return (topController != cont ? topController : nil);
 }
 static UIViewController *topMostController() {
 UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
 UIViewController *next = nil;
  while ((next = _topMostController(topController)) != nil) {
 topController = next;
 }
 return topController;
}

 

static void Alert(float Timer,id Message, ...) {

    va_list args;
    va_start(args, Message);
    NSString *Formated = [[NSString alloc] initWithFormat:Message arguments:args];
    va_end(args);

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Timer * NSEC_PER_SEC), dispatch_get_main_queue(), ^{

		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hola" message:Formated preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		}];

		[alert addAction:action];

		[topMostController() presentViewController:alert animated:true completion:nil];
 
    });


}
 


static NSString *SWF(id Value, ...) {
    va_list args;
    va_start(args, Value);
    NSString *Formated = [[NSString alloc] initWithFormat:Value arguments:args];
    va_end(args);
    return Formated;
}


 
 // inAppTweak.xm

#include <xpc/xpc.h>
#import <Foundation/Foundation.h>
#import "libxpcToolStrap.h"
#include <dlfcn.h>
#include <libhooker/libhooker.h>

@interface SBServer : NSObject

-(void) handleMSG:(NSString *)msgId userInfo:(NSDictionary *)userInfo;

@end 

@implementation SBServer

-(id)init {

	if ((self = [super init])){ 

	CLog(@"[+] In_App ");

  
	void *xpcToolHandle = dlopen("/var/jb/usr/lib/libxpcToolStrap.dylib", RTLD_LAZY);
	if (xpcToolHandle) {

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{


    	libxpcToolStrap *libTool = [objc_getClass("libxpcToolStrap") shared];

        NSString *uName = [libTool defineUniqueName:@"com.crazymind90.uniqueName"];

		[libTool addTarget:self selector:@selector(handleMSG:userInfo:) forMsgID:@"UDID_Sender" uName:uName];
		[libTool postToClientAndReceiveReplyWithMsgID:@"UDID_Sender" uName:uName  userInfo:@{@"action":@"getUDID"}];
		

		});

	}
       
       
    }
    return self;
}
 


-(void) handleMSG:(NSString *)msgId userInfo:(NSDictionary *)userInfo {

		Alert(1,@"UDID : %@",userInfo[@"UDID"]);
}



@end


 

%ctor
{		
	[SBServer new];
}