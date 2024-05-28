//  Created by CrazyMind90 ~ 2024.




#import "../XPCToolStrapd.h"



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
#pragma GCC diagnostic ignored "-Wignored-attributes"

#define CLog(format, ...) NSLog(@"CM90~[private] : " format, ##__VA_ARGS__)


@interface XPCToolStrapd : NSObject

@property NSMutableDictionary *sharedMessages;
@property dispatch_queue_t sharedMessagesQueue;


- (void) _handleConnection:(xpc_connection_t)connection withName:(const char *)serviceName;
- (void) _privateBasicService;
+ (instancetype) shared;

@end 

@implementation XPCToolStrapd
 

+(void) load {
	[self shared];
}

+ (instancetype) shared {

    static XPCToolStrapd *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        shared = [[self alloc] init];
        shared.sharedMessages = [[NSMutableDictionary alloc] init];
        shared.sharedMessagesQueue = dispatch_queue_create("com.cm90.sharedMessagesQueue", NULL);
        [shared _privateBasicService];
  
    });
    return shared;
}


  
- (void) _handleConnection:(xpc_connection_t)connection withName:(const char *)serviceName {

    xpc_connection_set_event_handler(connection, ^(xpc_object_t connection) {
        xpc_type_t type = xpc_get_type(connection);

    #pragma mark - Check if XPC connection is not restricted
            if (type == XPC_TYPE_CONNECTION) {
                xpc_connection_set_event_handler(connection, ^(xpc_object_t message) {
                    xpc_type_t messageType = xpc_get_type(message);

    #pragma mark - Check if received MSG is dictionary
                    if (messageType == XPC_TYPE_DICTIONARY) {

    #pragma mark - Get [XPC_SENDER] value 
                        const char *sender = xpc_dictionary_get_string(message, "XPC_SENDER");
                        if (!sender) {
                            // CLog(@"[-] This is a messed up");
                            return;
                        }

    #pragma mark - Check if [Client] or [Poster]
                        BOOL isPoster = [toString(sender) isEqual:@"POSTER"];

                        if (isPoster) { 
                            
    #pragma mark - Store the MSG received from [Poster] to redirect it later
                            dispatch_sync(XPCToolStrapd.shared.sharedMessagesQueue, ^{

                                const char *_msgID = xpc_dictionary_get_string(message, "XPC_MSG_ID");

                                if (_msgID) {
    #pragma mark - The [XPC_MSG_CONTENT] came from -[postToClientWithMsgID:userInfo]
                                    xpc_object_t xpc_dataContent = xpc_dictionary_get_value(message, "XPC_MSG_CONTENT");
                                    NSString *shouldReply = toString(xpc_dictionary_get_string(message,"XPC_SHOULD_REPLY"));
                                    NSString *isWithReply = toString(xpc_dictionary_get_string(message,"XPC_IS_WITH_REPLY"));
                                    const char *_replyMsgId = xpc_dictionary_get_string(message, "XPC_REPLY_MSG_ID");
                                    const char *_uname = xpc_dictionary_get_string(message, "XPC_UNIQUE_NAME");
                                    if (xpc_dataContent) {
    #pragma mark - Store [Poster]'s dictionary in [sharedMessages] for key : [XPC_UNIQUE_NAMES] & [XPC_MSG_ID]
             [XPCToolStrapd.shared.sharedMessages setObject:@[xpc_dataContent,shouldReply,toString(_replyMsgId),isWithReply,toString(_uname)] forKey:toString(_msgID)];
                                    } else {
                                    }
                                } else {
                                }
                            });


                        }
                        


    #pragma mark - Prepare the reply
                        xpc_object_t reply = xpc_dictionary_create_reply(message);
                        if (reply && !isPoster) {
    #pragma mark - [Poster] can not reach this point - it's [Client]


    #pragma mark - get [XPC_UNIQUE_NAME] from Client
                            const char *_uname = xpc_dictionary_get_string(message, "XPC_UNIQUE_NAME"); 
                            NSString *shouldReply = NULL;
                            NSString *isWithReply = NULL;
                            NSString *_replyMsgId = NULL;
                            const char *requested_msgID = NULL;
                            NSString *uKey = NULL;
                            xpc_object_t dataContent = NULL;
                        
    #pragma mark - get [XPC_MULTI_MSG_IDS] this is the array of IDs from -[startEventWithMessageIDs:]
                                xpc_object_t xpc_reply_array = xpc_dictionary_get_value(message, "XPC_MULTI_MSG_IDS");

    #pragma mark - check if [XPC_MULTI_MSG_IDS] is not null to avoid crashes 
                                if (xpc_reply_array != NULL && xpc_get_type(xpc_reply_array) == XPC_TYPE_ARRAY) {
                                    size_t count = xpc_array_get_count(xpc_reply_array);

    #pragma mark - go through each id in [XPC_MULTI_MSG_IDS] array 
                                    for (size_t i = 0; i < count; i++) {
                                        xpc_object_t element = xpc_array_get_value(xpc_reply_array, i);
                                        if (xpc_get_type(element) == XPC_TYPE_STRING) {
                                            const char *eachId = xpc_string_get_string_ptr(element);
                                            if (eachId) {
    #pragma mark - go through stored key to match it with [XPC_UNIQUE_NAME]~[eachId]
                                                for (NSString *eachStoredKeys in XPCToolStrapd.shared.sharedMessages.allKeys) {

                                                    if ([eachStoredKeys isEqual:toString(eachId)]) {
                                                         
                                                        requested_msgID = eachId;
                                                        uKey = toString(eachId);
                                                        dataContent = (xpc_object_t)[XPCToolStrapd.shared.sharedMessages objectForKey:eachStoredKeys][0];
                                                        shouldReply = (NSString *)[XPCToolStrapd.shared.sharedMessages objectForKey:eachStoredKeys][1];
                                                        _replyMsgId = (NSString *)[XPCToolStrapd.shared.sharedMessages objectForKey:eachStoredKeys][2];
                                                        isWithReply = (NSString *)[XPCToolStrapd.shared.sharedMessages objectForKey:eachStoredKeys][3];
 
    #pragma mark - Here : we found all keys and we should break the loop 
                                                        break;
                                                    }
                                                }
                                            } 
                                        }
                                    }
                                }
                            
    #pragma mark - Check if stored dictionary is not null
                            if (dataContent) { 

    #pragma mark - Smoothly inject the stored dictionary into the reply
                                xpc_dictionary_set_string(reply, "XPC_UNIQUE_NAME", _uname);
                                xpc_dictionary_set_string(reply, "XPC_MSG_ID", requested_msgID);
                                xpc_dictionary_set_string(reply, "XPC_SHOULD_REPLY", shouldReply.UTF8String);  
                                xpc_dictionary_set_string(reply, "XPC_IS_WITH_REPLY", isWithReply.UTF8String);
                                xpc_dictionary_set_string(reply, "XPC_REPLY_MSG_ID", _replyMsgId.UTF8String);
                                xpc_dictionary_set_value(reply, "XPC_MSG_CONTENT", dataContent);

    #pragma mark - Send reply with the dictionary to [Client]  
                                xpc_connection_send_message(connection, reply);
    #pragma mark - Cleanup the key to avoid repeating
                                [XPCToolStrapd.shared.sharedMessages removeObjectForKey:uKey];
                            }
                        } 
                    }
                });
                xpc_connection_resume(connection);
            }
        });

        xpc_connection_resume(connection);
}


   
- (void) _privateBasicService {
    
    
  #pragma mark - Create main [Listener] XPC connection

    xpc_connection_t service = xpc_connection_create_mach_service(
        "com.cm90.xpcToolStrap",
        NULL,
        XPC_CONNECTION_MACH_SERVICE_LISTENER
    );

    if (!service) {
        // CLog(@"Failed to create XPC service");
        return;
    } else {
        // CLog(@"[+] Successfully created [com.cm90.xpcToolStrap] service");
    }

    [self _handleConnection:service withName:"com.cm90.xpcToolStrap"];
}


@end
  
 

int main(int argc, char** argv, char** envp)
{
	@autoreleasepool
	{
		
	static dispatch_once_t once = 0;
	dispatch_once(&once, ^{

        [XPCToolStrapd load];
 
 #pragma mark - To prevent this daemon from restarting each 3 seconds
        // NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
        // for (;;)
        // [runLoop run];
        dispatch_main();

	});

		return 0;
	}
}
