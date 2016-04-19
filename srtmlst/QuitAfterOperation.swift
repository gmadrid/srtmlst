//
//  QuitAfterOperation.swift
//  srtmlst
//
//  Created by George Madrid on 4/18/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

class QuitAfterOperation : Operation {
  let predecessor: Operation
  var hasErrors: Bool = false

  init(predecessor: Operation) {
    self.predecessor = predecessor

    super.init()

    predecessor.addObserver(DidFinishObserver { [weak self] _, errors in
      if errors.count > 0 {
        print("ERRORS: \(errors)")
        self?.hasErrors = true
      }
      })

    addDependency(predecessor)
  }

  override func execute() {
    exit(hasErrors ? 1 : 0)
  }
}
