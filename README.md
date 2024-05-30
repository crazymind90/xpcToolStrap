# xpcToolStrap
A cross-process communication tool for sending and receiving messages on iOS 15 &amp; 16 for rootless JBs


## What does it do?

* **Send Messages :** Send a message with a value to another process .
* **Send Messages and Get a Reply :** Send a message with a value to other processes and get a reply from those processes .

## How does it work?

It functions as both a daemon and a library ..

#### Part 1 - [Poster] :
* The application posts the message to the library, which then passes it to the daemon. The daemon stores the message in a global value .


#### Part 2 - [Client] :
* The second process continuously checks the daemon for any new messages and retrieves them when found .


## Header file : 

```objective-c
@interface libxpcToolStrap : NSObject

- (NSString *) defineUniqueName:(NSString *)uname;
- (void) postToClientWithMsgID:(NSString *)msgID uName:(NSString *)uname userInfo:(NSDictionary *)dict;
- (void) postToClientAndReceiveReplyWithMsgID:(NSString *)msgID uName:(NSString *)uname userInfo:(NSDictionary *)dict;
- (void) addTarget:(id)target selector:(SEL)sel forMsgID:(NSString *)msgID uName:(NSString *)uName;
- (void) startEventWithMessageIDs:(NSArray<NSString *> *)ids uName:(NSString *)uName;

+ (instancetype) shared;
@end
```
## How to use it ?

#### For example ~ Getting UDID from SpringBoard to App ..
#### SpringBoard is [Client] and App is [Poster] ..
 
<br></br>
* Add `libxpcToolStrap.h` to your project .
```objective-c
#import "libxpcToolStrap.h"
```
 

## [Client] ~ SpringBoard :
```objective-c
void *xpcToolHandle = dlopen("/var/jb/usr/lib/libxpcToolStrap.dylib", RTLD_LAZY);
	if (xpcToolHandle) {
 
            libxpcToolStrap *libTool = [objc_getClass("libxpcToolStrap") shared];

  	    NSString *uName = [libTool defineUniqueName:@"com.crazymind90.uniqueName"];
            [libTool startEventWithMessageIDs:@[@"UDID_Sender"] uName:uName];
	    [libTool addTarget:self selector:@selector(handleMSG:userInfo:) forMsgID:@"UDID_Sender" uName:uName];
 
	}
```

#### Target method : 
```objective-c
-(NSDictionary *) handleMSG:(NSString *)msgId userInfo:(NSDictionary *)userInfo {

	if ([(NSString *)userInfo[@"action"] isEqual:@"getUDID"])
	  return @{@"UDID":[UIDevice.currentDevice sf_udidString] ?: @"No udid"};
	
	return @{};
}

```
  

## [Poster] ~ App :
```objective-c
void *xpcToolHandle = dlopen("/var/jb/usr/lib/libxpcToolStrap.dylib", RTLD_LAZY);
	if (xpcToolHandle) {


	libxpcToolStrap *libTool = [objc_getClass("libxpcToolStrap") shared];
	
	NSString *uName = [libTool defineUniqueName:@"com.crazymind90.uniqueName"];
	
	[libTool addTarget:self selector:@selector(handleMSG:userInfo:) forMsgID:@"UDID_Sender" uName:uName];
	[libTool postToClientAndReceiveReplyWithMsgID:@"UDID_Sender" uName:uName  userInfo:@{@"action":@"getUDID"}];


 }
```

#### Target method : 
```objective-c
-(void) handleMSG:(NSString *)msgId userInfo:(NSDictionary *)userInfo {
  Alert(1,@"Got UDID : %@",userInfo[@"UDID"]);
}
```
<br></br>
## Important ..
* You `MUST` use `dlopen` before calling the functions .
* `UniqueName` must be the same in [Poster] and [Client] .
* Use `libSandy` if your msg did not reach to [Client] .




## Supports ..

* `Dopamine`
* `RootHide`
  
### Tested on iOS 15 & 16 :

* `arm64e`
* `arm64`



