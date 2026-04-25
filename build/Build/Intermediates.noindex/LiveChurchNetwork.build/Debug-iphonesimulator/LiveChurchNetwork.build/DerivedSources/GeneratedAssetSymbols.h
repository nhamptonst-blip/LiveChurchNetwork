#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "AppLogo" asset catalog image resource.
static NSString * const ACImageNameAppLogo AC_SWIFT_PRIVATE = @"AppLogo";

/// The "lcn1" asset catalog image resource.
static NSString * const ACImageNameLcn1 AC_SWIFT_PRIVATE = @"lcn1";

/// The "lcn2" asset catalog image resource.
static NSString * const ACImageNameLcn2 AC_SWIFT_PRIVATE = @"lcn2";

/// The "lcn3" asset catalog image resource.
static NSString * const ACImageNameLcn3 AC_SWIFT_PRIVATE = @"lcn3";

/// The "lcn4" asset catalog image resource.
static NSString * const ACImageNameLcn4 AC_SWIFT_PRIVATE = @"lcn4";

#undef AC_SWIFT_PRIVATE
