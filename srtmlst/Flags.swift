//
//  Flags.swift
//  srtmlst
//
//  Created by George Madrid on 4/19/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

class Flags {
  let flagDict : [String:String]

  init (flagList: [String:String]) {
    var flags = flagList

    // Collect args that begin with "--", skipping the first argument which is the command name.
    let args = Process.arguments.dropFirst().filter { $0.hasPrefix("--") }
    for arg in args {
      // Break the arg apart around the '='. First piece is the flag name.
      let pieces = arg.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "="))

      // Remove the "--" from the flag name
      var name = pieces[0]
      name = name.substringFromIndex(name.startIndex.advancedBy(2))

      // Join whatever is left. This allows '=' in a param value.
      let value = pieces.dropFirst().joinWithSeparator("")

      // TODO: usage message
      if !flagList.keys.contains(name) {
        // TODO Better error-handling
        print("Unexpected flag: \(arg)")
        exit(1)
      }

      flags[name] = value
    }

    flagDict = flags
  }

  func stringValue(flag: String) -> String {
    return flagDict[flag]!  // Crash if unknown flag.
  }

  func boolValue(flag: String) -> Bool {
    return flagDict[flag]!.boolValue  // Crash if unknown flag.
  }
}
