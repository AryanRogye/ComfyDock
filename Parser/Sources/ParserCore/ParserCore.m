//
//  ParserCore.m
//  Parser
//
//  Created by Aryan Rogye on 11/8/25.
//
//  Summary:
//  This file implements a parser that reads and decodes Xcode’s
//  recent-projects list stored in the binary `.sfl4` file located at:
//
//  ~/Library/Application Support/com.apple.sharedfilelist/
//  com.apple.LSSharedFileList.ApplicationRecentDocuments/
//  com.apple.dt.xcode.sfl4
//
//  The parser extracts bookmark data entries, resolves them into
//  valid file URLs, and returns an array of recent project paths.
//
//  Notes:
//  - The `.sfl4` file is a keyed archive (binary property list).
//  - Access may require Full Disk Access permissions.
//  - This utility is for debugging and educational use only.
//


#include "ParserCore.h"

@implementation ParserCore

- (instancetype) init {
    self = [super init];
    if (self) {
        NSURL *homeDir = [[NSFileManager defaultManager] homeDirectoryForCurrentUser];
        xcode_sfl4_path = [[[[[homeDir URLByAppendingPathComponent:@"Library"]
                              URLByAppendingPathComponent:@"Application Support"]
                             URLByAppendingPathComponent:@"com.apple.sharedfilelist"]
                            URLByAppendingPathComponent:@"com.apple.LSSharedFileList.ApplicationRecentDocuments"]
                           URLByAppendingPathComponent:@"com.apple.dt.xcode.sfl4"];
        NSError *err = nil;
        
        xcode_sfl4_contents = [NSData dataWithContentsOfURL:xcode_sfl4_path options:0 error: &err];
        xcode_sfl4_contents_error = err;
    }
    return self;
}

/// First step is to try to unarchive it
- (id) unarchiveBinaryPlist:(NSData *)data {
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (NSArray*) getItemsFromDictionary: (id) dict {
    return dict[@"items"];
}

- (NSArray*) getPropertyListFile:(NSData *)data {
    
    NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
    
    NSError* err;
    return [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:&format error:&err];
}

- (NSArray*) getXcodeItems {
    
    /// If No Data
    if (!xcode_sfl4_contents) {
        NSLog(@"Xcode SFl4 Contents Nil: %@", xcode_sfl4_contents_error);
        return nil;
    }
    
    /// Get Binary Items
    NSArray *items = [self getItemsFromDictionary:[self unarchiveBinaryPlist:xcode_sfl4_contents]];
    
    NSMutableArray *contents = [NSMutableArray array];
    
    for (NSDictionary *item in items) {
        NSData *bm = item[@"Bookmark"] ?: item[@"bookmark"];
        if (!bm) continue;
        
        BOOL stale = NO;
        NSError *berr = nil;
        NSURL *url = [NSURL URLByResolvingBookmarkData:bm
                                               options:(NSURLBookmarkResolutionWithoutUI |
                                                        NSURLBookmarkResolutionWithoutMounting)
                                         relativeToURL:nil
                                   bookmarkDataIsStale:&stale
                                                 error:&berr];
        if (url) {
            [contents addObject:url];
        }
    }
    return contents;
}

- (NSString*) readPlistFile:(NSURL *)url {
    
    NSError* err;
    
    NSData* data = [NSData dataWithContentsOfURL:url options:0 error:&err];
    
    if (err != nil) {
        NSLog(@"Error Extracting Data: %@", err);
        return @"";
    }
    NSLog(@"Data Extracted From: %@ Contents: %@", url, data);
    NSArray* unarchived = [self getPropertyListFile:data];
    NSLog(@"Unarchived: %@", unarchived);
    
    return @"";
}

@end
