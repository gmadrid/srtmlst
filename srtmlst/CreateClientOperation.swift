//
//  CreateClientOperation.swift
//  srtmlst
//
//  Created by George Madrid on 4/14/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

class CreateClientOperation : Operation, ResultConsumer, ResultProvider {
  var consumedResult: [String:String]?
  private(set) var providedResult: RTMClient?

  override func execute() {
    guard let config = consumedResult else {
      finishWithError(AppError.MissingResult(className: self.className).nserror)
      return
    }

    guard let apiKey = config["apiKey"] else {
      finishWithError(AppError.MissingValue(name: "apiKey").nserror)
      return
    }

    guard let secret = config["secret"] else {
      finishWithError(AppError.MissingValue(name: "secret").nserror)
      return
    }

    providedResult = RTMClient(key: apiKey, secret: secret)
    if let token = config["token"] {
      providedResult?.token = token
    }

    finish()
  }
}
