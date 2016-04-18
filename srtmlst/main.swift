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

class GetListsOperation : Operation, ResultConsumer {
  var consumedResult: RTMClient?

  override func execute() {
    do {
      print("HERE EXECUTING")
      guard let client = consumedResult else {
        throw AppError.MissingResult(className: "GetListsOperation")
      }

      print("WOOAIT")
      client.getLists() { lists, error in
        print("WHATWHAT")
      }
    } catch {
      finishWithError(error.nserror)
    }
  }
}

func buildAndEnqueueOperations() {
  var ops = [Operation]()

  let loadConfigOp = LoadConfigOperation(configFileName: defaultConfigFileName)
  ops.append(loadConfigOp)

  let authOp = AuthOperationGroup()
  authOp.addResultDependency(loadConfigOp)
  ops.append(authOp)

  let getListsOp = GetListsOperation()
  getListsOp.addResultDependency(authOp)
  ops.append(getListsOp)

//  let listTasks = ListTasksOperation()
//  authOp.addResultDependency(authOp)
//  ops.append(listTasks)

  let dumpOp = DumpErrorsOperation(otherOp: getListsOp)
  ops.append(dumpOp)

  queue.addOperations(ops, waitUntilFinished: false)
}

func doMain() throws {
//  let config = try! LoadSimplePropertiesFromPath("/Users/gmadrid/.rtmcli")
//  guard let apiKey = config["apiKey"] else {
//    print("Missing apiKey")
//    return
//  }
//  guard let secret = config["secret"] else {
//    print("Missing secret")
//    return
//  }
//
//  let rtmClient = RTMClient(key: apiKey, secret: secret, queue: queue)
//  if let token = config["token"] {
//    rtmClient.token = token
//  } else {
//    rtmClient.acquireToken() { token, error in
//      print("GOT A TOKEN: \(token)")
//      print("OR ERROR: \(error)")
//    }
//  }

  dispatch_main()
}

buildAndEnqueueOperations()
try! doMain()
