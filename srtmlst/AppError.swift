//
//  AppError.swift
//  srtmlst
//
//  Created by George Madrid on 4/14/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

/**
 * A protocol for things that can be converted to NSError
 */
protocol CustomErrorConvertible {
  var domain: String { get }
  var errorCode: Int { get }
  var userInfo: [String : AnyObject]? { get }
}

extension CustomErrorConvertible {
  /** Function that converts object to an NSError */
  func toError() -> NSError {
    return NSError(domain: self.domain, code: self.errorCode, userInfo: self.userInfo)
  }
}

enum AppError : ErrorType, CustomErrorConvertible {
  case CompositeError(errors: [NSError])
  case MissingResult(className: String)
  case MissingValue(name: String)

  var domain: String { return "AppError" }
  var errorCode: Int {
    switch self {
    case .CompositeError:
      return 1
    case .MissingResult:
      return 2
    case .MissingValue:
      return 3
    }
  }
  var userInfo: [String : AnyObject]? {
    var result = [String : AnyObject]()
    result["ErrorType"] = String(self)

    switch self {
    case .CompositeError(let errors):
      result["ContainedErrors"] = errors

    case .MissingResult(let className):
      result["ClassName"] = className

    case .MissingValue(let name):
      result["ValueName"] = name
    }
    return result
  }

  static func makeCompositeError(errors: [NSError]) -> ErrorType {
    if errors.count == 1 {
      return errors.first!
    }
    return AppError.CompositeError(errors: errors)
  }
}

/** Frequently, we have ErrorType objects that we want to express as NSError.
 *  This extension provides a default way to make the conversion
 */
extension ErrorType {
  var nserror: NSError {
    return NSError(domain:"NSError",
                   code: -1,
                   userInfo: ["UnderlyingError" : self as? AnyObject ?? "uncovertable"])
  }
}

/** If an ErrorType is an NSError, we can just use the object */
extension ErrorType where Self : NSError {
  var nserror: NSError { return self }
}

/** If the ErrorType is CustomErrorConvertible, then use the protocol to convert to NSError */
extension ErrorType where Self : CustomErrorConvertible {
  var nserror: NSError { return self.toError() }
}