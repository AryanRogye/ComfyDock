//
//  ParserCore.m
//  Parser
//
//  Created by Aryan Rogye on 11/8/25.
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

@end
