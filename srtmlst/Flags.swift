//
//  Flags.swift
//  srtmlst
//
//  Created by George Madrid on 4/19/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

func getCommandFlags() -> [String:String] {
  let args = Process.arguments.dropFirst().filter { $0.hasPrefix("--") }

  var flags = [String:String]()
  for arg in args {
    let pieces = arg.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "="))
    let name = (pieces[0] as NSString).substringFromIndex(2)
    let rest = pieces.dropFirst()
    let value = rest.joinWithSeparator("")

    flags[name] = value
  }

  return flags
}