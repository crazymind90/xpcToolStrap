@import CoreFoundation;
@import Foundation;

 
#include <pthread.h>
#include <time.h>
#include <dlfcn.h>
#import <objc/runtime.h>  
#include <xpc/xpc.h>



#pragma GCC diagnostic ignored "-Wunused-function"
#pragma GCC diagnostic ignored "-Wobjc-property-no-attribute"


#define CLogLib(format, ...) NSLog(@"CM90~[libxpcToolStrap] : " format, ##__VA_ARGS__)
#define CLogBoot(format, ...) NSLog(@"CM90~[BootStrap_C] : " format, ##__VA_ARGS__)




static NSString *SWF(id Value, ...) {
    va_list args;
    va_start(args, Value);
    NSString *Formated = [[NSString alloc] initWithFormat:Value arguments:args];
    va_end(args);
    return Formated;
}

static NSDictionary *convertXPCDictionaryToNSDictionary(xpc_object_t xpcDict) {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    xpc_dictionary_apply(xpcDict, ^bool(const char *key, xpc_object_t value) {
        @try {
            if (key == NULL || value == NULL) {
                CLogLib(@"Skipping null key or value");
                return true;
            }

            NSString *nsKey = [NSString stringWithUTF8String:key];
            id nsValue = nil;
            
            xpc_type_t valueType = xpc_get_type(value);
            if (valueType == XPC_TYPE_STRING) {
                nsValue = [NSString stringWithUTF8String:xpc_string_get_string_ptr(value)];
            } else if (valueType == XPC_TYPE_INT64) {
                nsValue = [NSNumber numberWithLongLong:xpc_int64_get_value(value)];
            } else if (valueType == XPC_TYPE_BOOL) {
                nsValue = [NSNumber numberWithBool:xpc_bool_get_value(value)];
            } else if (valueType == XPC_TYPE_DOUBLE) {
                nsValue = [NSNumber numberWithDouble:xpc_double_get_value(value)];
            } else if (valueType == XPC_TYPE_ARRAY) {
            } else if (valueType == XPC_TYPE_DICTIONARY) {
                nsValue = convertXPCDictionaryToNSDictionary(value);
            } else {
                CLogLib(@"Unsupported XPC type");
            }

            if (nsValue) {
                dict[nsKey] = nsValue;
            } else {
                CLogLib(@"Null nsValue for key: %@", nsKey);
            }
        } @catch (NSException *exception) {
            CLogLib(@"Exception converting key %s: %@", key, exception);
        }

        return true;
    });
    return [dict copy];
}

static xpc_object_t convertNSDictionaryToXPCDictionary(NSDictionary *dict) {
    xpc_object_t xpcDict = xpc_dictionary_create(NULL, NULL, 0);
    
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![key isKindOfClass:[NSString class]]) {
            CLogLib(@"Skipping non-string key: %@", key);
            return;
        }

        const char *cKey = [key UTF8String];
        
        if ([obj isKindOfClass:[NSString class]]) {
            xpc_dictionary_set_string(xpcDict, cKey, [obj UTF8String]);
        } else if ([obj isKindOfClass:[NSNumber class]]) {

            const char *objCType = [obj objCType];
            if (strcmp(objCType, @encode(BOOL)) == 0) {
                xpc_dictionary_set_bool(xpcDict, cKey, [obj boolValue]);
            } else if (strcmp(objCType, @encode(int)) == 0 ||
                       strcmp(objCType, @encode(long)) == 0 ||
                       strcmp(objCType, @encode(long long)) == 0 ||
                       strcmp(objCType, @encode(short)) == 0 ||
                       strcmp(objCType, @encode(char)) == 0) {
                xpc_dictionary_set_int64(xpcDict, cKey, [obj longLongValue]);
            } else if (strcmp(objCType, @encode(float)) == 0 ||
                       strcmp(objCType, @encode(double)) == 0) {
                xpc_dictionary_set_double(xpcDict, cKey, [obj doubleValue]);
            } else {
                CLogLib(@"Unsupported NSNumber type for key: %@", key);
            }
        } else if ([obj isKindOfClass:[NSDictionary class]]) {
            xpc_object_t nestedDict = convertNSDictionaryToXPCDictionary((NSDictionary *)obj);
            xpc_dictionary_set_value(xpcDict, cKey, nestedDict);

        } else {
            CLogLib(@"Unsupported type for key: %@", key);
        }
    }];
    
    return xpcDict;
}
 
xpc_object_t convertNSArrayToXPCArray(NSArray *nsArray) {
    xpc_object_t xpcArray = xpc_array_create(NULL, 0);
    for (id obj in nsArray) {
        if ([obj isKindOfClass:[NSString class]]) {
            const char *valueCString = [(NSString *)obj UTF8String];
            xpc_array_append_value(xpcArray, xpc_string_create(valueCString));
        }
    }
    return xpcArray;
}


static NSString *toString(const char *a1) {
    return SWF(@"%s",a1);
}

































#pragma mark - XPC private functions that might come in handy later
 

// #include <libhooker/libhooker.h>

// static mach_port_t _xpc_connection_copy_listener_port(xpc_connection_t connection)
// {
//     static mach_port_t (*__xpc_connection_copy_listener_port)(xpc_connection_t);
//     if (!__xpc_connection_copy_listener_port) {
//         struct libhooker_image *libxpc = LHOpenImage("/usr/lib/system/libxpc.dylib");
//         if (!libxpc) {
//             return MACH_PORT_NULL;
//         }

//         const char *names[1] = {"__xpc_connection_copy_listener_port"};
//         void *syms[1];

//         if (!LHFindSymbols(libxpc, names, syms, 1)) {
//             CLogBoot(@"[-] _xpc_connection_copy_listener_port not found :(");
//             return MACH_PORT_NULL;
//         } else {
//             CLogBoot(@"[+++++] _xpc_connection_copy_listener_port [SYMBOL] FOUND");
//         }

//         __xpc_connection_copy_listener_port = (mach_port_t (*)(xpc_connection_t))ptrauth_sign_unauthenticated(syms[0], ptrauth_key_asia, 0);
//     }
//     return __xpc_connection_copy_listener_port(connection);
// }

  
// static kern_return_t _task_get_special_port(task_t task, int which, mach_port_t *port)
// {
//     static kern_return_t (*__task_get_special_port)(task_t, int, mach_port_t *);
//     if (!__task_get_special_port) {
//         struct libhooker_image *libSystem = LHOpenImage("/usr/lib/system/libxpc.dylib");
//         if (!libSystem) {
//             return KERN_FAILURE;
//         }

//         const char *names[1] = {"_task_get_special_port"};
//         void *syms[1];

//         if (!LHFindSymbols(libSystem, names, syms, 1)) {
//             CLogBoot(@"[-] _task_get_special_port not found :(");
//             return KERN_FAILURE;
//         } else {
//             CLogBoot(@"[+++++] _task_get_special_port [SYMBOL] FOUND");
//         }

//         __task_get_special_port = (kern_return_t (*)(task_t, int, mach_port_t *))ptrauth_sign_unauthenticated(syms[0], ptrauth_key_asia, 0);
//     }
//     return __task_get_special_port(task, which, port);
// }


// static kern_return_t _bootstrap_register(mach_port_t bp, const char *service_name, mach_port_t sp)
// {
//     static kern_return_t (*__bootstrap_register)(mach_port_t, const char *, mach_port_t);
//     if (!__bootstrap_register) {
//         struct libhooker_image *libbootstrap = LHOpenImage("/usr/lib/system/libxpc.dylib");
//         if (!libbootstrap) {
//             return KERN_FAILURE;
//         }

//         const char *names[1] = {"_bootstrap_register"};
//         void *syms[1];

//         if (!LHFindSymbols(libbootstrap, names, syms, 1)) {
//             CLogBoot(@"[-] _bootstrap_register not found :(");
//             return KERN_FAILURE;
//         } else {
//             CLogBoot(@"[+++++] _bootstrap_register [SYMBOL] FOUND");
//         }

//         __bootstrap_register = (kern_return_t (*)(mach_port_t, const char *, mach_port_t))ptrauth_sign_unauthenticated(syms[0], ptrauth_key_asia, 0);
//     }
//     return __bootstrap_register(bp, service_name, sp);
// }


// static kern_return_t _bootstrap_create_service(mach_port_t bp, const char *service_name, mach_port_t *sp)
// {
//     static kern_return_t (*__bootstrap_create_service)(mach_port_t, const char *, mach_port_t *);
//     if (!__bootstrap_create_service) {
//         struct libhooker_image *libbootstrap = LHOpenImage("/usr/lib/system/libxpc.dylib");
//         if (!libbootstrap) {
//             return KERN_FAILURE;
//         }

//         const char *names[1] = {"_bootstrap_create_service"};
//         void *syms[1];

//         if (!LHFindSymbols(libbootstrap, names, syms, 1)) {
//             CLogBoot(@"[-] _bootstrap_create_service not found :(");
//             return KERN_FAILURE;
//         } else {
//             CLogBoot(@"[+++++] _bootstrap_create_service [SYMBOL] FOUND");
//         }

//         __bootstrap_create_service = (kern_return_t (*)(mach_port_t, const char *, mach_port_t *))ptrauth_sign_unauthenticated(syms[0], ptrauth_key_asia, 0);
//     }
//     return __bootstrap_create_service(bp, service_name, sp);
// }


// static kern_return_t _bootstrap_get_root(mach_port_t bp, mach_port_t *root_port)
// {
//     static kern_return_t (*__bootstrap_get_root)(mach_port_t, mach_port_t *);
//     if (!__bootstrap_get_root) {
//         struct libhooker_image *libbootstrap = LHOpenImage("/usr/lib/system/libxpc.dylib");
//         if (!libbootstrap) {
//             return KERN_FAILURE;
//         }

//         const char *names[1] = {"_bootstrap_get_root"};
//         void *syms[1];

//         if (!LHFindSymbols(libbootstrap, names, syms, 1)) {
//             CLogBoot(@"[-] _bootstrap_get_root not found :(");
//             return KERN_FAILURE;
//         } else {
//             CLogBoot(@"[+++++] _bootstrap_get_root [SYMBOL] FOUND");
//         }

//         __bootstrap_get_root = (kern_return_t (*)(mach_port_t, mach_port_t *))ptrauth_sign_unauthenticated(syms[0], ptrauth_key_asia, 0);
//     }
//     return __bootstrap_get_root(bp, root_port);
// }
 

// static kern_return_t _bootstrap_look_up(mach_port_t bp, const char *service_name, mach_port_t *sp)
// {
//     static kern_return_t (*__bootstrap_look_up)(mach_port_t, const char *, mach_port_t *);
//     if (!__bootstrap_look_up) {
//         struct libhooker_image *libxpc = LHOpenImage("/usr/lib/system/libxpc.dylib");
//         if (!libxpc) {
//             return KERN_FAILURE;
//         }

//         const char *names[1] = {"_bootstrap_look_up"};
//         void *syms[1];

//         if (!LHFindSymbols(libxpc, names, syms, 1)) {
//             CLogBoot(@"[-] _bootstrap_look_up not found :(");
//             return KERN_FAILURE;
//         } else {
//             CLogBoot(@"[+++++] _bootstrap_look_up [SYMBOL] FOUND");
//         }

//         __bootstrap_look_up = (kern_return_t (*)(mach_port_t, const char *, mach_port_t *))ptrauth_sign_unauthenticated(syms[0], ptrauth_key_asia, 0);
//     }
//     return __bootstrap_look_up(bp, service_name, sp);
// }


// static kern_return_t _bootstrap_register2(mach_port_t bp, const char *service_name, mach_port_t sp, uint64_t flags)
// {
//     static kern_return_t (*__bootstrap_register2)(mach_port_t, const char *, mach_port_t, uint64_t);
//     if (!__bootstrap_register2) {
//         struct libhooker_image *libxpc = LHOpenImage("/usr/lib/system/libxpc.dylib");
//         if (!libxpc) {
//             return KERN_FAILURE;
//         }

//         const char *names[1] = {"_bootstrap_register2"};
//         void *syms[1];

//         if (!LHFindSymbols(libxpc, names, syms, 1)) {
//             CLogBoot(@"[-] _bootstrap_register2 not found :(");
//             return KERN_FAILURE;
//         } else {
//             CLogBoot(@"[+++++] _bootstrap_register2 [SYMBOL] FOUND");
//         }

//         __bootstrap_register2 = (kern_return_t (*)(mach_port_t, const char *, mach_port_t, uint64_t))ptrauth_sign_unauthenticated(syms[0], ptrauth_key_asia, 0);
//     }
//     return __bootstrap_register2(bp, service_name, sp, flags);
// }


// static xpc_endpoint_t _xpc_endpoint_create(mach_port_t port)
// {
// 	static xpc_endpoint_t(*__xpc_endpoint_create)(mach_port_t);
// 	if (!__xpc_endpoint_create) {
// 		struct libhooker_image *libxpc = LHOpenImage("/usr/lib/system/libxpc.dylib");
// 		if (!libxpc) {
// 			return NULL;
// 		}

// 		const char *names[1] = {"__xpc_endpoint_create"};
// 		void *syms[1];

// 		if (!LHFindSymbols(libxpc, names, syms, 1)) {
// 			CLogBoot(@"[-] __xpc_endpoint_create not found :(");
// 			return NULL;
// 		} else {
// 		    CLogBoot(@"[+++++] __xpc_endpoint_create [SYMBOL] FOUND ");
// 		}

// 		__xpc_endpoint_create = (xpc_endpoint_t (*)(mach_port_t))ptrauth_sign_unauthenticated(syms[0], ptrauth_key_asia, 0);
// 	}
// 	return __xpc_endpoint_create(port);
// }


//  static kern_return_t _bootstrap_check_in(mach_port_t bp, const char *service_name, mach_port_t *sp)
// {
//     static kern_return_t (*__bootstrap_check_in)(mach_port_t, const char *, mach_port_t *);
//     if (!__bootstrap_check_in) {
//         struct libhooker_image *libbootstrap = LHOpenImage("/usr/lib/system/libxpc.dylib");
//         if (!libbootstrap) {
//             return KERN_FAILURE;
//         }

//         const char *names[1] = {"_bootstrap_check_in"};
//         void *syms[1];

//         if (!LHFindSymbols(libbootstrap, names, syms, 1)) {
//             CLogBoot(@"[-] _bootstrap_check_in not found :(");
//             return KERN_FAILURE;
//         } else {
//             CLogBoot(@"[+++++] _bootstrap_check_in [SYMBOL] FOUND");
//         }

//         __bootstrap_check_in = (kern_return_t (*)(mach_port_t, const char *, mach_port_t *))ptrauth_sign_unauthenticated(syms[0], ptrauth_key_asia, 0);
//     }
//     return __bootstrap_check_in(bp, service_name, sp);
// }
