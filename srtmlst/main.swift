//
//  main.swift
//  srtmlst
//
//  Created by George Madrid on 4/12/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

let defaultConfigFileName = ".rtmcli"

let queue = OperationQueue()

class GetTokenOp : Operation, ResultConsumer {
  var consumedResult: RTMClient?

  override func execute() {
    finish()
  }
}

func buildAndEnqueueOperations() {
  var ops = [Operation]()

  let loadConfigOp = LoadConfigOperation(configFileName: defaultConfigFileName)
  ops.append(loadConfigOp)

  let createClientOp = CreateClientOperation()
  createClientOp.addResultDependency(loadConfigOp)
  ops.append(createClientOp)

  let getTokenOp = GetTokenOp()
  getTokenOp.addResultDependency(createClientOp)
  ops.append(getTokenOp)

  queue.addOperations(ops, waitUntilFinished: false)
}

func doMain() throws {
  let config = try! LoadSimplePropertiesFromPath("/Users/gmadrid/.rtmcli")
  guard let apiKey = config["apiKey"] else {
    print("Missing apiKey")
    return
  }
  guard let secret = config["secret"] else {
    print("Missing secret")
    return
  }

  let rtmClient = RTMClient(key: apiKey, secret: secret, queue: queue)
  if let token = config["token"] {
    rtmClient.token = token
  } else {
    rtmClient.acquireToken() { token, error in
      print("GOT A TOKEN: \(token)")
      print("OR ERROR: \(error)")
    }
  }

  dispatch_main()
}

buildAndEnqueueOperations()
try! doMain()
