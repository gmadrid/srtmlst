//
//  PrintOperation.swift
//  srtmlst
//
//  Created by George Madrid on 4/14/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

/** An operation that prints a message. */
class PrintOperation : Operation {
  let msg: String

  init(msg: String) {
    self.msg = msg
  }

  override func execute() {
    print(msg)
    finish()
  }
}

