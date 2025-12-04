// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import ParserCore

public class XcodeParser {
    
    let parserCore : ParserCore?
    
    public init() {
        self.parserCore = ParserCore()
    }
    
    public func parse() -> [URL]? {
        guard let parserCore = parserCore else { return nil }
        
        guard let urls = parserCore.getXcodeItems() as? [URL] else {
            print("Failed to get Xcode items")
            return nil
        }
        return urls
    }
}

public class PlistParser {
    let parserCore : ParserCore?
    
    public init() {
        self.parserCore = ParserCore()
    }
    
    public func parse(path: URL?) {
        
        parserCore?.readPlistFile(path)
//        do {
//            guard let plist = try parserCore?.readPlistFile(path) as? String else {
//                print("Failed To Read Plist File")
//                return
//            }
//            print(plist)
//        } catch {
//            print("There Was A Error Parsing")
//            return
//        }
    }
}
