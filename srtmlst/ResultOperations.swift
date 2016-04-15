//
//  ResultOperations.swift
//  srtmlst
//
//  Created by George Madrid on 4/14/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

/**
 * Operations may wish to pass results along from one to the next.
 * An Operation that implements ResultProvider can use default behavior to pass results
 * with no extra work.
 */
protocol ResultProvider : class {
  associatedtype ProvidedResultType
  var providedResult: ProvidedResultType? { get }
}

/**
 * Operations may wish to pass results along from one to the next.
 * An Operation that implements ResultConsumer can add a "result dependency" to get the
 * result with no extra work.
 */
protocol ResultConsumer : class {
  associatedtype ConsumedResultType
  var consumedResult: ConsumedResultType? { get set }
}

extension ResultConsumer where Self : Operation {
  /**
   * Add a "result dependency" to get the producedResult of the ResultProvider automatically
   * passed to the consumedResult of the ResultConsumer when the ResultProvider is finished.
   *
   * ProvidedResultType must be assignable to ConsumedResultType.
   *
   * If the ResultProvider has errors, the ResultConsumer will be finished with the propagated
   * errors.
   */
  func addResultDependency<T where
    T : Operation,
    T : ResultProvider,
    T.ProvidedResultType == ConsumedResultType>(resultProvider : T) {
    resultProvider.addObserver(DidFinishObserver { _, errors in
      if errors.isEmpty {
        self.consumedResult = resultProvider.providedResult
      } else {
        // NOTE: This is a minor hack.
        // We cannot immediately call finish(_:) since the current state of this Operation is
        // .Pending. However, this means that we have not yet evaluated the Conditions, and there
        // is an established flow for finishing due to a failed condition. Therefore, we add a 
        // condition that will always fail with the propagated errors.
        self.addCondition(FailureCondition(error: AppError.makeCompositeError(errors).nserror))
      }
      })

    (self as Operation).addDependency(resultProvider)
  }
}

