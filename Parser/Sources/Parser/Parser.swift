// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import ParserCore

public class XcodeParser {
    
    let parserCore : ParserCore?
    
    public init() {
        self.parserCore = ParserCore()
    }
    
    public func parse() {
        guard let parserCore = parserCore else { return }
        
        guard let urls = parserCore.getXcodeItems() as? [URL] else {
            print("Failed to get Xcode items")
            return
        }
        
        print("IN SWIFT")
        for url in urls {
            print(url)
        }
    }
}
