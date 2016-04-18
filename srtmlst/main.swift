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

class PrintListOperation : Operation, ResultConsumer {
  var consumedResult: (RTMClient, [RTMClient.RTMList])?

  override func execute() {
    do {
      guard let (client, lists) = consumedResult else {
        throw AppError.MissingResult(className: "PrintListOperation")
      }

      guard let index = (lists.indexOf { $0.name == "Next week and next actions" }) else {
        // XXX TODO fill out this error. It's user facing.
        throw AppError.GenericError(msg: "Missing the requested list")
      }

      let id = lists[index].id

      client.getTasks(id) { [weak self] tasks, error in
        guard error == nil else {
          self?.finishWithError(error?.nserror)
          return
        }

        let filtered = tasks!.filter { !$0.completed }
        let sorted = filtered.sort {
          if $0.due != $1.due {
            if $0.due == nil {
              return false
            } else if $1.due == nil {
              return true
            }
            return $0.due!.compare($1.due!) == .OrderedAscending
          }

          if $0.priority != $1.priority {
            return $0.priority < $1.priority
          }

          return $0.name.caseInsensitiveCompare($1.name) == .OrderedAscending
        }
        for task in sorted {
          print("\(task.priority): \u{1b}[31m\(task.name)\u{1b}[0m")
        }

        self?.finish()
      }
    } catch {
      finishWithError(error.nserror)
    }
  }
}

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

  let printListOp = PrintListOperation()
  printListOp.addResultDependency(getListsOp)
  ops.append(printListOp)

//  let dumpOp = DumpErrorsOperation(otherOp: printListOp)
//  ops.append(dumpOp)

  let doneOp = QuitAfterOperation(predecessor: printListOp)
  ops.append(doneOp)

  queue.addOperations(ops, waitUntilFinished: false)
}

buildAndEnqueueOperations()
dispatch_main()
