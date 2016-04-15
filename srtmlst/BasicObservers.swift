//
//  BasicObservers.swift
//  srtmlst
//
//  Created by George Madrid on 4/14/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

/**
 * Add no-op versions of all of the OperationObserver methods so that subclasses of
 * OperationObserver can only implement the ones that they care about.
 */
extension OperationObserver {
  func operationDidStart(operation: Operation) { /* no-op */ }
  func operationDidFinish(operation: Operation, errors: [NSError]) { /* no-op */ }
  func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
    /* no-op */
  }
}

class DidFinishObserver : OperationObserver {
  let cb: (Operation, [NSError]) -> Void

  init(cb : (Operation, [NSError]) -> Void) {
    self.cb = cb
  }

  func operationDidFinish(operation: Operation, errors: [NSError]) {
    cb(operation, errors)
  }
}
