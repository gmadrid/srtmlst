//
//  DumpErrorsOperation.swift
//  srtmlst
//
//  Created by George Madrid on 4/14/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

/** An Operation that prints another Operation's errors when it is finished */
class DumpErrorsOperation : Operation {
  init(otherOp: Operation, name: String = "UnnamedDumpErrorsOperation") {
    otherOp.addObserver(DidFinishObserver { _, errors in
      if errors.count > 0 {
        print("\(name): \(errors)")
      } else {
        print("\(name): No errors")
      }
      })

    super.init()
    self.addDependency(otherOp)
  }

  override func execute() {
    // no-op. Everything is done by the observer.
    finish()
  }
}
