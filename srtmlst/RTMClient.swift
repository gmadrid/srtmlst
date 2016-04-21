//
//  rtm.swift
//  srtmlst
//
//  Created by George Madrid on 4/12/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

class RTMClient {
  let signer: RTMParamSigner
  let queue: NSOperationQueue
  let session: NSURLSession
  var token: String?

  init(key: String, secret: String, queue: NSOperationQueue? = nil, session: NSURLSession? = nil) {
    self.signer = RTMParamSigner(apiKey: key, secret: secret)
    self.queue = queue ?? NSOperationQueue()
    if session != nil {
      self.session = session!
    } else {
      let sess = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration(), delegate: nil, delegateQueue: self.queue)
      sess.sessionDescription = "RTMClient Session"
      self.session = sess
    }
  }

  func checkToken(token: String, cb: (String?, ErrorType?) -> Void) {
    processAPIMethod(.CheckToken(token: token), cb: cb) { rsp in
      let authDict: [String:AnyObject] = try RTMClient.getField(rsp, "auth")
      return try RTMClient.getField(authDict, "token")
    }
  }

  func getFrob(cb: (String?, ErrorType?) -> Void) {
    processAPIMethod(.GetFrob, cb: cb) { rsp in
      return try RTMClient.getField(rsp, "frob")
    }
  }

  func getToken(frob: String, cb: (String?, ErrorType?) -> Void) {
    processAPIMethod(.GetToken(frob: frob), cb: cb) { rsp in
      let authDict : [String:AnyObject] = try RTMClient.getField(rsp, "auth")
      return try RTMClient.getField(authDict, "token")
    }
  }

  class RTMList {
    let id: String
    let name: String

    init(dict: [String:AnyObject]) throws {
      id = try RTMClient.getField(dict, "id")
      name = try RTMClient.getField(dict, "name")
    }
  }

  class RTMTask : CustomStringConvertible {
    let listId: String
    let taskSeriesId: String
    let taskId: String

    let name: String
    let completed: Bool  // TODO: make this a date
    let priority: String // TODO: make this an enum
    let due: NSDate?

    var description: String {
      return "\(listId)/\(taskSeriesId)/\(taskId)"
    }

    init(listId: String, taskSeriesDict: [String:AnyObject], taskDict: [String:AnyObject]) throws {
      self.listId = listId
      do {
        self.taskSeriesId = try RTMClient.getField(taskSeriesDict, "id")
      } catch {
        throw error
      }
      self.taskId = try RTMClient.getField(taskDict, "id")

      self.name = try RTMClient.getField(taskSeriesDict, "name")
      if let completedString: String = RTMClient.getOptionalField(taskDict, "completed") {
        self.completed = !completedString.isEmpty
      } else {
        self.completed = false
      }
      self.priority = RTMClient.getOptionalField(taskDict, "priority") ?? "4"
      let dueString: String = RTMClient.getOptionalField(taskDict, "due") ?? ""

      // 2016-04-12T04:00:00Z
      let formatter = NSDateFormatter()
      formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
      formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
      formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)

      // TODO: Add support in here to have due times.
      if let rawDate = formatter.dateFromString(dueString) {
        let components = NSCalendar.currentCalendar().components([.Year, .Month, .Day], fromDate: rawDate)
        due = NSCalendar.currentCalendar().dateFromComponents(components)
      } else {
        due = NSDate.distantFuture()
      }
    }

  }

  func getLists(cb: ([RTMList]?, ErrorType?) -> Void) {
    processAPIMethod(.GetLists(token: token!), cb: cb) { rsp in
      let listsDict : [String:AnyObject] = try RTMClient.getField(rsp, "lists")
      let listList : [AnyObject] = try RTMClient.getField(listsDict, "list")

      var result = [RTMList]()
      for listDict in listList {
        do {
          guard let typedList = listDict as? [String:AnyObject] else {
            throw AppError.BadlyFormattedJSON(desc: "List item of wrong type")
          }
          result.append(try RTMList(dict: typedList))
        } catch {
          cb(nil, error)
        }
      }
      return result
    }
  }

  func getTasks(listId: String?, cb: ([RTMTask]?, ErrorType?) -> Void) {
    processAPIMethod(.GetList(token: token!, listId: listId), cb: cb) { rsp in
      var result = [RTMTask]()

      let tasksDict : [String:AnyObject] = try RTMClient.getField(rsp, "tasks")
      let listsList : [[String:AnyObject]] = try RTMClient.getField(tasksDict, "list")

      for listDict in listsList {
        let listId : String = try RTMClient.getField(listDict, "id")
        let taskSeriesList: [[String:AnyObject]]
        do {
          taskSeriesList = try RTMClient.getSublist(listDict, "taskseries")
        } catch {
          throw error
        }

        for taskSeriesDict in taskSeriesList {
          let taskList = try RTMClient.getSublist(taskSeriesDict, "task")
          for taskDict in taskList {
            // TODO XXX Throwing on any failed task creation might be too strict - allows death task.
            result.append(try RTMTask(listId: listId, taskSeriesDict: taskSeriesDict, taskDict: taskDict))
          }
        }
      }

      return result
    }
  }

  private static func getField<T>(obj: [String:AnyObject], _ name: String) throws -> T {
    guard let result = obj[name] as? T else {
      throw AppError.MissingValue(name: name)
    }
    return result
  }

  private static func getOptionalField<T>(obj: [String:AnyObject], _ name: String) -> T? {
    return obj[name] as? T
  }

  private static func getSublist(obj: [String:AnyObject], _ name: String) throws -> [[String:AnyObject]] {
    if let resultArray = obj[name] as? [[String:AnyObject]] {
      return resultArray
    }

    if let resultObj = obj[name] as? [String:AnyObject] {
      return [resultObj]
    }

    return []
  }

  private func processAPIMethod<ResultType>(method: RTMMethod, cb: (ResultType?, ErrorType?) -> Void, processor: ([String:AnyObject]) throws -> ResultType) {
    do {
      let url = try signer.makeURL(method)
      session.dataTaskWithURL(url) { data, _, error in
        do {
          guard error == nil else {
            throw error!
          }

          guard let data = data else {
            throw AppError.MissingDataForMethod(methodName: method.method)
          }

//          let foo = String(data:data, encoding:NSASCIIStringEncoding)
//          print(foo)

          guard let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? [String:AnyObject] else {
            throw AppError.BadlyFormattedJSON(desc: "Top-level object parse failed")
          }

          let rsp : [String:AnyObject] = try RTMClient.getField(json, "rsp")
          let stat : String = try RTMClient.getField(rsp, "stat")

          guard stat == "ok" else {
            let msg: String = rsp["err"] as? String ?? "Missing \"err\" on error response"
            throw AppError.RTMError(err: msg)
          }

          let val = try processor(rsp)
          cb(val, nil)
        } catch {
          cb(nil, error)
        }
        }.resume()
    } catch {
      cb(nil, error)
    }
  }
}
