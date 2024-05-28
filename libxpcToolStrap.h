
@import CoreFoundation;
@import Foundation;
#include <dlfcn.h>

@interface libxpcToolStrap : NSObject

- (NSString *) defineUniqueName:(NSString *)uname;
- (void) postToClientWithMsgID:(NSString *)msgID uName:(NSString *)uname userInfo:(NSDictionary *)dict;
- (void) postToClientAndReceiveReplyWithMsgID:(NSString *)msgID uName:(NSString *)uname userInfo:(NSDictionary *)dict;
- (void) addTarget:(id)target selector:(SEL)sel forMsgID:(NSString *)msgID uName:(NSString *)uName;
- (void) startEventWithMessageIDs:(NSArray<NSString *> *)ids uName:(NSString *)uName;

+ (instancetype) shared;
@end
 