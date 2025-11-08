//
//  ParserCore.h
//  Parser
//
//  Created by Aryan Rogye on 11/8/25.
//

#import <Foundation/Foundation.h>

@interface ParserCore : NSObject {
    NSURL *xcode_sfl4_path;
    
    NSError *xcode_sfl4_contents_error;
    NSData *xcode_sfl4_contents;
}
- (instancetype)init;
- (NSArray*) getXcodeItems;
@end
