//
//  ComfyDock-Bridging-Header.h
//  ComfyDock
//
//  Created by Aryan Rogye on 11/8/25.
//

#import <AppKit/AppKit.h>

// MARK: - AX Private APIs

// Returns the CGWindowID of the provided AXUIElement
// macOS 10.10+
AXError _AXUIElementGetWindow(AXUIElementRef element, CGWindowID *outWindowID);

// MARK: - CoreGraphics Private APIs

// Core Graphics types
typedef uint32_t CGSConnectionID;
typedef uint32_t CGSWindowCount;
typedef uint64_t CGSSpaceID;
typedef uint64_t CGSSpaceMask;

// Get main connection ID
CGSConnectionID CGSMainConnectionID(void);

// Capture window screenshots
CFArrayRef CGSHWCaptureWindowList(
    CGSConnectionID cid,
    const uint32_t *windowList,
    CGSWindowCount count,
    uint32_t options
);

// Get spaces for windows
CFArrayRef CGSCopySpacesForWindows(
    CGSConnectionID cid,
    CGSSpaceMask mask,
    CFArrayRef windowIDs
);

// Get window level (layer)
int32_t CGSGetWindowLevel(
    CGSConnectionID cid,
    uint32_t wid,
    int32_t *outLevel
);

// Copy window property (e.g., title)
int32_t CGSCopyWindowProperty(
    CGSConnectionID cid,
    uint32_t wid,
    CFStringRef key,
    CFTypeRef *outValue
);
