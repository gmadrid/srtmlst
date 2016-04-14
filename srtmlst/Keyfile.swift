//
//  keyfile.swift
//  srtmlst
//
//  Created by George Madrid on 4/12/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

enum Error : ErrorType {
  case CouldNotEncodeContents
  case CouldNotReadFile(filename: String)
  case CouldNotWriteFile(filename: String)
  case LineIsMisformed(line: String)
  case NeedARealError
}

typealias ReadDataFromPathFunc = (String) throws -> NSData
typealias WriteDataToPathFunc = (String, NSData) throws -> Void

private func StandardReadDataFromPath(path: String) throws -> NSData {
  guard let data = NSFileHandle(forReadingAtPath: path)?.readDataToEndOfFile() else {
    throw Error.CouldNotReadFile(filename: path)
  }
  return data
}

private func StandardWriteDataToPath(path: String, data: NSData) throws {
  guard let outFile = NSFileHandle(forWritingAtPath: path) else {
    throw Error.CouldNotWriteFile(filename: path)
  }
  outFile.writeData(data)
}

func LoadSimplePropertiesFromPath(filename: String,
                                  readFunc: ReadDataFromPathFunc = StandardReadDataFromPath)
  throws -> [String:String] {

    let data = try readFunc(filename)

    guard let configString = String(data: data, encoding: NSUTF8StringEncoding) else {
      throw Error.CouldNotEncodeContents
    }

    var result = [String:String]()
    let lines = configString.characters.split("\n").map(String.init)
    for line in lines {
      let pieces = line.characters.split("=").map(String.init).map { $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) }

      if pieces.count != 2 {
        throw Error.LineIsMisformed(line: line)
      }

      result[pieces[0]] = pieces[1]
    }
    return result
}

func WriteSimplePropertiesToPath(filename: String,
                                 props: [String: String],
                                 writeFunc: WriteDataToPathFunc = StandardWriteDataToPath)
  throws {
    var outString = ""
    for key in props.keys.sort() {
      outString += key + " = " + props[key]! + "\n"
    }

    guard let data = outString.dataUsingEncoding(NSUTF8StringEncoding) else {
      throw Error.CouldNotEncodeContents
    }
    try writeFunc(filename, data)
}
