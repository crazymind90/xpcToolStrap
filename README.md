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

* Add `libxpcToolStrap.h` to your project .
```objective-c
#import "libxpcToolStrap.h"
```

#### This is [Poster] ~ the process you want to send the msg from
```objective-c
#include <dlfcn.h>
```
```objective-c
void *xpcToolHandle = dlopen("/var/jb/usr/lib/libxpcToolStrap.dylib", RTLD_LAZY);
	if (xpcToolHandle) {


	libxpcToolStrap *libTool = [objc_getClass("libxpcToolStrap") shared];
 
	NSString *uname = [libTool defineUniqueName:@"com.crazymind90.uniqueName"];
	
	[libTool addTarget:self selector:@selector(handleMSG:userInfo:) forMsgID:@"111" uName:uname];

        // To send and receive Msg :
  	[libTool postToClientAndReceiveReplyWithMsgID:@"111" uName:uname  userInfo:@{@"UDID":@"11111111-11111-11111"}];

        // To send a Msg only
        [libTool postToClientWithMsgID:@"222" uName:uname  userInfo:@{@"UDID":@"22222222-22222-22222"}];

 }
```

#### Here you will reveice a reply to the target you added in `-[addTarget:selector:forMsgID:uName:]`
```

-(void) handleMSG:(NSString *)msgId userInfo:(NSDictionary *)userInfo {
   NSLog(@"[+] SB~handleMSG : msgId : %@ | userInfo : %@",msgId,userInfo);
}

```



#### This is [Client] ~ the process you receive msg to
```objective-c
#include <dlfcn.h>
```
```objective-c
void *xpcToolHandle = dlopen("/var/jb/usr/lib/libxpcToolStrap.dylib", RTLD_LAZY);
	if (xpcToolHandle) {


      libxpcToolStrap *libTool = [objc_getClass("libxpcToolStrap") shared];

      NSString *uName = [libTool defineUniqueName:@"com.crazymind90.uniqueName"];
      [libTool startEventWithMessageIDs:@[@"111",@"222"] uName:uName];
      [libTool addTarget:self selector:@selector(handleMSG:userInfo:) forMsgID:@"111" uName:uName];
      // This target should return NSDictionary to get the return value if you used -[postToClientAndReceiveReplyWithMsgID:]
      // and you can make it void if you used -[postToClientWithMsgID:]


 }
```

## Important ..
* You `MUST` use `dlopen` before calling the functions
* `UniqueName` must be the same in [Poster] and [Client]
* Use `libSandy` if your msg did not reach to [Client]




## Supports ..

* `Dopamine`
* `RootHide`
  
### Tested on iOS 15 & 16 :

* `arm64e`
* `arm64`



