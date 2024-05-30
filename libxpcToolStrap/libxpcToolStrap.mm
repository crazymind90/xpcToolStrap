//  Created by CrazyMind90 ~ 2024.


 

#import <Foundation/Foundation.h>
#include <dlfcn.h>
#import "../XPCToolStrapd.h"
#import "../libxpcToolStrap.h"


#pragma GCC diagnostic ignored "-Wunused-variable"
#pragma GCC diagnostic ignored "-Wunused-function"
#pragma GCC diagnostic ignored "-Wunused-result"
#pragma GCC diagnostic ignored "-Wunknown-pragmas"



#define CLog(format, ...) NSLog(@"CM90~[libxpcToolStrap] : " format, ##__VA_ARGS__)

#define _serviceName "com.cm90.xpcToolStrap"
 


@interface libxpcToolStrap (XPC)
 
#pragma mark - Private
@property (nonatomic, strong) NSMutableDictionary <id, NSArray *> *registeredTargets;
@property (nonatomic, strong) NSMutableArray <NSString *> *uNames;
@property (nonatomic, strong) NSMutableArray <NSString *> *msgIds;



#pragma mark - Useless 
@property void (^constHandler)(NSString *msgID,NSDictionary *userInfo);
@property void (^constReplyHandler)(NSString *msgID,NSDictionary *userInfo);

@end



@implementation libxpcToolStrap
  




+ (instancetype) shared {
    static libxpcToolStrap *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        #pragma mark - Call libSandy first to give the lib the ability to connect to daemon

        void *sandyHandle = dlopen("/var/jb/usr/lib/libsandy.dylib", RTLD_LAZY);
        if (sandyHandle) {
            int (*__dyn_libSandy_applyProfile)(const char *profileName) = (int (*)(const char *))dlsym(sandyHandle, "libSandy_applyProfile");

                    __dyn_libSandy_applyProfile("xpcToolStrap");

                    shared = [[libxpcToolStrap alloc] init];

                        @try {
                            shared.registeredTargets = [NSMutableDictionary dictionary];
                            shared.uNames = [NSMutableArray array];
                            shared.msgIds = [NSMutableArray array];
                        }
                        @catch (NSException *exception) {
                            // CLog(@"Exception: %@", exception);
                        }
             
                    } 
              });

    return shared;
}


- (NSMutableDictionary<id, NSArray *> *)registeredTargets {
    return objc_getAssociatedObject(self, @selector(registeredTargets));
}

- (void)setRegisteredTargets:(NSMutableDictionary<id, NSArray *> *)registeredTargets {
    objc_setAssociatedObject(self, @selector(registeredTargets), registeredTargets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableArray<NSString *> *)uNames {
    return objc_getAssociatedObject(self, @selector(uNames));
}

- (void)setUNames:(NSMutableArray<NSString *> *)uNames {
    objc_setAssociatedObject(self, @selector(uNames), uNames, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableArray<NSString *> *)msgIds {
    return objc_getAssociatedObject(self, @selector(msgIds));
}

- (void)setMsgIds:(NSMutableArray<NSString *> *)msgIds {
    objc_setAssociatedObject(self, @selector(msgIds), msgIds, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

 
 
#pragma  --------------------------------------------- Send MSG ----------------------------------------------------



- (void) _postToClientWithMsgID:(NSString *)msgID uName:(NSString *)uName userInfo:(NSDictionary *)dict isWithReply:(BOOL)isWithReply {

        if (![self isValidUname:uName]) {
            // CLog(@"uName is empty, you must use -[defineUniqueName:]");
            return;
        }

        if (!msgID || ![msgID isKindOfClass:[NSString class]]) {
            // CLog(@"Invalid msgID");
            return;
        }
        
    #pragma mark - Create XPC connection
        xpc_connection_t connection = xpc_connection_create_mach_service(
            _serviceName,
            NULL,
            XPC_CONNECTION_MACH_SERVICE_PRIVILEGED
        );

        if (connection == NULL) {
            // CLog(@"Failed to create XPC connection");
            return;
        }

    #pragma mark - Create a message
        xpc_object_t xpcMessage = xpc_dictionary_create(NULL, NULL, 0);
        if (!xpcMessage) {
            // CLog(@"Failed to create XPC message dictionary");
            xpc_release(connection);
            return;
        }


    #pragma mark - Convert to XPCDictionary
        xpc_object_t xpcDict = convertNSDictionaryToXPCDictionary(dict);
        if (!xpcDict) {
            // CLog(@"Failed to convert NSDictionary to XPC dictionary");
            xpc_release(xpcMessage);
            xpc_release(connection);
            return;
        }
 


    #pragma mark - Create dictionary
        xpc_dictionary_set_string(xpcMessage, "XPC_UNIQUE_NAME", uName.UTF8String);
        xpc_dictionary_set_string(xpcMessage, "XPC_MSG_ID", isWithReply ? SWF(@"%@",msgID).UTF8String : SWF(@"%@~%@",uName,msgID).UTF8String);
        xpc_dictionary_set_string(xpcMessage, "XPC_SENDER", [@"POSTER" UTF8String]);
        xpc_dictionary_set_value(xpcMessage, "XPC_MSG_CONTENT", xpcDict);
        xpc_dictionary_set_string(xpcMessage, "XPC_SHOULD_REPLY", "NO");
        if (isWithReply) {
        xpc_dictionary_set_string(xpcMessage, "XPC_IS_WITH_REPLY", "YES");
        }
        

        xpc_connection_set_event_handler(connection, ^(xpc_object_t message) {
        });


    #pragma mark - Send the message
        xpc_connection_send_message(connection, xpcMessage);


        xpc_connection_resume(connection);


        xpc_release(xpcMessage);
        xpc_release(connection);

}


- (void) postToClientAndReceiveReplyWithMsgID:(NSString *)msgID uName:(NSString *)uName userInfo:(NSDictionary *)dict {
    
   
    if (![self isValidUname:uName]) {
        // CLog(@"uName is empty, you must use -[defineUniqueName:]");
        return;
    }

     
    if (!msgID || ![msgID isKindOfClass:[NSString class]]) {
        // CLog(@"Invalid msgID");
        return;
    }
    
  
    #pragma mark - Create XPC connection
        xpc_connection_t connection = xpc_connection_create_mach_service(
            _serviceName,
            NULL,
            XPC_CONNECTION_MACH_SERVICE_PRIVILEGED
        );

        if (connection == NULL) {
            // CLog(@"Failed to create XPC connection");
            return;
        }

    #pragma mark - Create a message
        xpc_object_t xpcMessage = xpc_dictionary_create(NULL, NULL, 0);
        if (!xpcMessage) {
            // CLog(@"Failed to create XPC message dictionary");
            xpc_release(connection);
            return;
        }


    #pragma mark - Convert to XPCDictionary
        xpc_object_t xpcDict = convertNSDictionaryToXPCDictionary(dict);
        if (!xpcDict) {
            // CLog(@"Failed to convert NSDictionary to XPC dictionary");
            xpc_release(xpcMessage);
            xpc_release(connection);
            return;
        }
 


    #pragma mark - Create dictionary
        xpc_dictionary_set_string(xpcMessage, "XPC_UNIQUE_NAME", uName.UTF8String);
        xpc_dictionary_set_string(xpcMessage, "XPC_MSG_ID", SWF(@"%@~%@",uName,msgID).UTF8String);
        xpc_dictionary_set_string(xpcMessage, "XPC_SENDER", [@"POSTER" UTF8String]);
        xpc_dictionary_set_value(xpcMessage, "XPC_MSG_CONTENT", xpcDict);
        xpc_dictionary_set_string(xpcMessage, "XPC_SHOULD_REPLY", "YES");
        xpc_dictionary_set_string(xpcMessage, "XPC_REPLY_MSG_ID", SWF(@"%@~%@~XPC_REPLY",uName,msgID).UTF8String);
        
        xpc_connection_set_event_handler(connection, ^(xpc_object_t message) {
        });

        [self startEventWithMessageIDs:@[SWF(@"%@~%@~XPC_REPLY",uName,msgID)] uName:uName];


        #pragma mark - Send the message
        xpc_connection_send_message(connection, xpcMessage);
        xpc_connection_resume(connection);
        
        xpc_release(xpcMessage);
        xpc_release(connection);
 
}


#pragma  --------------------------------------------- Receive MSG Event ----------------------------------------------------

- (void) _startEventWithMessageIDs:(NSArray<NSString *> *)ids uName:(NSString *)uName {

    @autoreleasepool {
  
        if (![self isValidUname:uName]) {
        // CLog(@"uName is empty, you must use -[defineUniqueName:]");
        return;
        }
   
        if (!ids || ids.count == 0) {
            // CLog(@"[-] No message IDs provided");
            return;
        }


    #pragma mark - Create XPC connection

            xpc_connection_t connection = xpc_connection_create_mach_service(
                _serviceName,
                NULL,
                XPC_CONNECTION_MACH_SERVICE_PRIVILEGED
            );
            if (connection == NULL) {
                // CLog(@"Failed to create XPC connection");
                return;
            }
            
    #pragma mark - Create main dictionary
            xpc_object_t xpcMessage = xpc_dictionary_create(NULL, NULL, 0);
            if (!xpcMessage) {
                // CLog(@"Failed to create XPC message dictionary");
                xpc_release(connection);
                return;
            }

    #pragma mark - Add all IDs to array 

        //     for (NSString *eachMsgId in ids) {

        //         if (eachMsgId && [eachMsgId isKindOfClass:[NSString class]]) {
        //         if ([eachMsgId containsString:@"XPC_REPLY"]) { 

        //         if (![libxpcToolStrap.shared.msgIds containsObject:SWF(@"%@",eachMsgId)]) { 
        //              [libxpcToolStrap.shared.msgIds addObject:SWF(@"%@",eachMsgId)];
        //             }
        //         } else {
        //             if (![libxpcToolStrap.shared.msgIds containsObject:SWF(@"%@~%@",uName,eachMsgId)]) { 
        //                  [libxpcToolStrap.shared.msgIds addObject:SWF(@"%@~%@",uName,eachMsgId)];
        //          }
        //       }
        //     }
        //   }
        

            xpc_object_t xpc_msgIds = convertNSArrayToXPCArray(libxpcToolStrap.shared.msgIds);


            if (!xpc_msgIds) {
                // CLog(@"Failed to create XPC array");
                xpc_release(xpcMessage);
                xpc_release(connection);
                return;
            }
 
    #pragma mark - Finalize dictionary
            xpc_dictionary_set_string(xpcMessage, "XPC_UNIQUE_NAME", uName.UTF8String);
            xpc_dictionary_set_value(xpcMessage, "XPC_MULTI_MSG_IDS", xpc_msgIds);
            xpc_dictionary_set_string(xpcMessage, "XPC_SENDER", [@"CLIENT" UTF8String]);


            xpc_connection_set_event_handler(connection, ^(xpc_object_t message) {
            });


    #pragma mark - Send a message and wait for reply 
            xpc_connection_send_message_with_reply(connection, xpcMessage, dispatch_get_main_queue(), ^(xpc_object_t reply) {
                if (reply) { 
                    const char *_msgID = xpc_dictionary_get_string(reply, "XPC_MSG_ID"); 
                    const char *_uname = xpc_dictionary_get_string(reply, "XPC_UNIQUE_NAME");
                    xpc_object_t rep = xpc_dictionary_get_value(reply, "XPC_MSG_CONTENT");
                    if (_msgID && rep) {

                    bool shouldReply = [toString(xpc_dictionary_get_string(reply, "XPC_SHOULD_REPLY")) isEqual:@"YES"]; 
                    const char *_replyMsgId = xpc_dictionary_get_string(reply, "XPC_REPLY_MSG_ID");

    #pragma mark - Check of [addTarget:selector:forMsgID:] is used and validate it       
                        
                if (shouldReply) {

                if ([self isValidTargetForMsgId:toString(_msgID)]) {
            NSDictionary *dict = [self callMsgIdTarget:toString(_msgID) 
                                            userInfo:convertXPCDictionaryToNSDictionary(rep)];

            [self _postToClientWithMsgID:toString(_replyMsgId) 
                      uName:toString(_uname) 
                           userInfo:(dict.allKeys.count > 0) ? dict : @{@"WT?":@"NOT A DICTIONARY"} isWithReply:YES];
                }
            } else {     
                if ([self isValidTargetForMsgId:toString(_msgID)]) {
                [self callMsgIdTarget:toString(_msgID) userInfo:convertXPCDictionaryToNSDictionary(rep)];
                }
            }
                        

                        NSDictionary *replyDict = convertXPCDictionaryToNSDictionary(xpc_dictionary_get_value(reply, "XPC_MSG_CONTENT")); 
                        bool isWithReply = [toString(xpc_dictionary_get_string(reply, "XPC_IS_WITH_REPLY")) isEqual:@"YES"]; 
    #pragma mark - Check here if it's a reply to choose which handler to trigger
                        if (isWithReply) { 
                            
                        NSString *origMsgId = [toString(_msgID) stringByReplacingOccurrencesOfString:@"~XPC_REPLY" withString:@""];


                        if ([self isValidTargetForMsgId:origMsgId]) {
                        [self callMsgIdTarget:origMsgId userInfo:replyDict];
                        }
                        [libxpcToolStrap.shared.msgIds removeObject:SWF(@"%s",_msgID)];
 
                        } else { 

                        }

                         

                    } else {

                    }
                } else {

                }
            });

            xpc_connection_resume(connection);
            xpc_release(xpcMessage);
            xpc_release(connection);
 
        }
}

#pragma  --------------------------------------------- Private ----------------------------------------------------

 

- (void)startEventWithMessageIDs:(NSArray<NSString *> *)ids uName:(NSString *)uName {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self scheduleEventWithMessageIDs:ids uName:uName];
    });
}

- (void)scheduleEventWithMessageIDs:(NSArray<NSString *> *)ids uName:(NSString *)uName {

    for (NSString *eachMsgId in ids) {
        if (eachMsgId && [eachMsgId isKindOfClass:[NSString class]]) {
        if ([eachMsgId containsString:@"XPC_REPLY"]) { 

        if (![libxpcToolStrap.shared.msgIds containsObject:SWF(@"%@",eachMsgId)]) { 
                [libxpcToolStrap.shared.msgIds addObject:SWF(@"%@",eachMsgId)];
            }
        } else {
            if (![libxpcToolStrap.shared.msgIds containsObject:SWF(@"%@~%@",uName,eachMsgId)]) { 
                    [libxpcToolStrap.shared.msgIds addObject:SWF(@"%@~%@",uName,eachMsgId)];
            }
        }
      }
    }

    NSMutableDictionary *dict = [PlistManager.shared loadPlist];

    for (NSString *eachKey in dict.allKeys) {
        
        if ([libxpcToolStrap.shared.msgIds containsObject:eachKey]) {
            // CLog(@"msg found for : %@",eachKey);
            [self _startEventWithMessageIDs:ids uName:uName];
            [PlistManager.shared removeObjectForKey:eachKey];
        }
    }


    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), 
                   dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        [self scheduleEventWithMessageIDs:ids uName:uName];
    });
}

  

- (void) postToClientWithMsgID:(NSString *)msgID uName:(NSString *)uName userInfo:(NSDictionary *)dict {
   [self _postToClientWithMsgID:msgID uName:uName userInfo:dict isWithReply:NO];
}

  
#pragma  --------------------------------------------- Extras ----------------------------------------------------



- (NSString *) purgeMsgId:(const char *)_msgID uName:(const char *)uName {
     NSString *cc = [toString(_msgID) stringByReplacingOccurrencesOfString:@"~XPC_REPLY" withString:@""];
     return [cc stringByReplacingOccurrencesOfString:SWF(@"%s~",uName) withString:@""];
}

- (BOOL) isValidUname:(NSString *)uName {

    if (uName.length < 1) {
        return NO;
    }

    if ([libxpcToolStrap.shared.uNames containsObject:uName]) return YES;
    return NO;
}

- (NSString *) defineUniqueName:(NSString *)uName {

    for (NSString *eachUname in libxpcToolStrap.shared.uNames) { 
        if ([eachUname containsString:uName]) {
            return eachUname;
            break;
        }
    }
 
   [libxpcToolStrap.shared.uNames addObject:uName];
   return uName;
}

- (void) addTarget:(id)target selector:(SEL)sel forMsgID:(NSString *)msgID uName:(NSString *)uName {
    [libxpcToolStrap.shared.registeredTargets setObject:@[target,NSStringFromSelector(sel)] forKey:SWF(@"%@~%@",uName,msgID)];
}

-(NSDictionary *) callMsgIdTarget:(NSString *)msgID userInfo:(NSDictionary *)dict {

    id target = libxpcToolStrap.shared.registeredTargets[msgID][0];
    SEL selector = NSSelectorFromString(libxpcToolStrap.shared.registeredTargets[msgID][1]);
	return [target performSelector:selector withObject:msgID withObject:dict];
}

-(BOOL) isValidTargetForMsgId:(NSString *)msgID {
    if ([libxpcToolStrap.shared.registeredTargets objectForKey:msgID]) return YES;
    return NO;
}






 


-(id) init {
    if ((self = [super init])){}
    return self;
}
 

@end

