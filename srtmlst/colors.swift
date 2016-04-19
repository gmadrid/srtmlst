//
//  colors.swift
//  srtmlst
//
//  Created by George Madrid on 4/19/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

var doColors: Bool = true

func applyEscCodes(str: String, prefix: String?, suffix: String?) -> String {
  let p = prefix ?? ""
  let s = suffix ?? ""

  return "\(p)\(str)\(s)"
}

func scrSequence(num: Int?) -> String {
  guard let num = num else {
    return ""
  }
  return "\u{1b}[\(num)m"
}

func applyScrCodes(str: String, startCode: Int?, endCode: Int?) -> String {
  return applyEscCodes(str, prefix: scrSequence(startCode), suffix: scrSequence(endCode))
}

extension String {
  func red() -> String {
    return applyScrCodes(self, startCode: 31, endCode: 39)
  }

  func intense() -> String {
    return applyScrCodes(self, startCode: 1, endCode: 0)
  }
}