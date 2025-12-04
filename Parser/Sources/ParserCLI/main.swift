//
//  main.swift
//  Parser
//
//  Created by Aryan Rogye on 11/18/25.
//

import Parser
import Foundation

let plistParser = PlistParser()

let path = ("~/Library/Preferences/com.apple.dock.plist" as NSString).expandingTildeInPath
let url  = URL(fileURLWithPath: path)

let secondPath = ("/Users/aryanrogye/Library/Preferences/com.apple.spaces.plist" as NSString).expandingTildeInPath
let url2  = URL(fileURLWithPath: secondPath)

//plistParser.parse(path: url)
plistParser.parse(path: url2)
