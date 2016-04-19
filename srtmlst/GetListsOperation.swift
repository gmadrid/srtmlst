//
//  GetListsOperation.swift
//  srtmlst
//
//  Created by George Madrid on 4/18/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

class GetListsOperation : Operation, ResultConsumer, ResultProvider {
  var consumedResult: RTMClient?
  var providedResult: (RTMClient, [RTMClient.RTMList])?

  override func execute() {
    do {
      guard let client = consumedResult else {
        throw AppError.MissingResult(className: "GetListsOperation")
      }

      client.getLists() { [weak self] lists, error in
        // TODO XXX Error check
        self?.providedResult = (client, lists!)
        self?.finish()
      }
    } catch {
      finishWithError(error.nserror)
    }
  }
}

