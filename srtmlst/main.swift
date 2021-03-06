//
//  main.swift
//  srtmlst
//
//  Created by George Madrid on 4/12/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

let flags = Flags(flagList: [
  "configfile": ".rtmcli",
  "colors": "true"
  ])

let queue = OperationQueue()

func buildAndEnqueueOperations() {
  var ops = [Operation]()

  let configFileName = flags.stringValue("configfile")
  let loadConfigOp = LoadConfigOperation(configFileName: configFileName)
  ops.append(loadConfigOp)

  let authOp = AuthOperationGroup()
  authOp.addResultDependency(loadConfigOp)
  ops.append(authOp)

  let getListsOp = GetListsOperation()
  getListsOp.addResultDependency(authOp)
  ops.append(getListsOp)

  let printListOp = PrintListOperation()
  printListOp.addResultDependency(getListsOp)
  ops.append(printListOp)

  let doneOp = QuitAfterOperation(predecessor: printListOp)
  ops.append(doneOp)

  queue.addOperations(ops, waitUntilFinished: false)
}

buildAndEnqueueOperations()
dispatch_main()
