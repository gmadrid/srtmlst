//
//  keyfile.swift
//  srtmlst
//
//  Created by George Madrid on 4/12/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

/**
 * Load a file with key/value pairs of the form:
 *  key = value
 *
 * Leading/trailing spaces are not currently supported.
 */
class Keyfile : CustomStringConvertible {
  enum Error : ErrorType {
    case CouldNotEncodeContents
    case CouldNotReadFile(filename: String)
    case CouldNotWriteFile(filename: String)
    case LineIsMisformed(line: String)
  }

  var valueMap : [String: String] = [:]
  var filename : String

  var description: String {
    var out = ""
    for kvp in valueMap {
      out += kvp.0 + " = " + kvp.1 + "\n"
    }
    return out
  }

  init(filename: String) throws {
    // Save this for later.
    //    let configFilename = (NSHomeDirectory() as NSString).stringByAppendingPathComponent(".rtmcli")

    self.filename = filename

    guard let configData = NSFileHandle(forReadingAtPath: filename)?.readDataToEndOfFile() else {
      throw Error.CouldNotReadFile(filename: filename)
    }

    guard let configString = String(data: configData, encoding: NSASCIIStringEncoding) else {
      throw Error.CouldNotEncodeContents
    }

    let lines = configString.characters.split("\n").map(String.init)
    for line in lines {
      let pieces = line.characters.split("=").map(String.init).map { $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) }

      if pieces.count != 2 {
        throw Error.LineIsMisformed(line: line)
      }

      valueMap[pieces[0]] = pieces[1]
    }
  }

  func write(filename: String) throws {
    guard let data = description.dataUsingEncoding(NSASCIIStringEncoding) else {
      throw Error.CouldNotEncodeContents
    }
    guard let outFile = NSFileHandle(forWritingAtPath: filename) else {
      throw Error.CouldNotWriteFile(filename: filename)
    }
    outFile.writeData(data)
  }

  subscript(index: String) -> String? {
    get { return valueMap[index] }
    set { valueMap[index] = newValue }
  }
}