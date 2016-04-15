//
//  FailureCondition.swift
//  srtmlst
//
//  Created by George Madrid on 4/14/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

/** A Condition that always fails with the error provided to the ctor. */
class FailureCondition : OperationCondition {
  static var name = "FailureCondition"
  static var isMutuallyExclusive = false

  let error: NSError

  init(error: NSError) {
    self.error = error
  }

  func dependencyForOperation(operation: Operation) -> NSOperation? { return nil }
  func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
    completion(.Failed(error))
  }
}
