//
//  PrintListOperation.swift
//  srtmlst
//
//  Created by George Madrid on 4/18/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

func idfunc<T>(lhs: T) -> T {
  return lhs
}

func red(str: String) -> String {
  return "\u{1b}[31m\(str)\u{1b}[0m"
}

func bold(str: String) -> String {
  return "\u{1b}[1m\(str)\u{1b}[0m"
}

class PrintListOperation : Operation, ResultConsumer {
  var consumedResult: (RTMClient, [RTMClient.RTMList])?

  private static var relativeFormatter: NSDateFormatter = {
    let result = NSDateFormatter()
    result.dateStyle = .ShortStyle
    result.doesRelativeDateFormatting = true
    return result
  }()

  private static var dowFormatter: NSDateFormatter = {
    let result = NSDateFormatter()
    result.dateFormat = "ccc"
    return result
  }()

  private static func relativeDate(date: NSDate) -> String {
    // We want:
    // * before today: "Overdue"
    // * today:        "Today"
    // * tomorrow:     "Tomorrow"
    // * in next week: "Wed" (or whatever)
    // * otherwise:    "Jan 2, 2017"

    let calendar = NSCalendar.currentCalendar()
    let now = NSDate()

    if calendar.compareDate(date, toDate: now, toUnitGranularity: .Day) == .OrderedAscending {
      return "Overdue"
    }

    if calendar.isDateInToday(date) || calendar.isDateInTomorrow(date) {
      return relativeFormatter.stringFromDate(date)
    }

    let weekFromToday = calendar.dateByAddingUnit(.WeekOfYear, value: 1, toDate: now, options: [])
    if calendar.compareDate(date, toDate: weekFromToday!, toUnitGranularity: .Day) == .OrderedAscending {
      return dowFormatter.stringFromDate(date)
    }

    return relativeFormatter.stringFromDate(date)
  }

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
        var lastHeader = ""
        var lastPriority: String? = nil
        var showingIntense = false
        for task in sorted {
          let thisHeader = PrintListOperation.relativeDate(task.due ?? NSDate.distantFuture())
          if thisHeader != lastHeader {
            print("========== \(thisHeader) =========")
            if ["Overdue", ""].contains(lastHeader) && thisHeader != "Overdue" {
              // We just changed from overdue or this is our first header (that is not Overdue),
              // so the next header priority combination is intense.
              lastPriority = task.priority
              showingIntense = true
            } else if showingIntense {
              showingIntense = false
            }
            lastHeader = thisHeader
          }

          if task.priority != lastPriority {
            showingIntense = false
          }

          // TODO: this is ugly as hell
          var val = "\(task.priority): \(task.name)"
          if thisHeader == "Overdue" {
            val = val.red()
          } else if showingIntense {
            val = val.intense()
          }
          print(val)
        }

        self?.finish()
      }
    } catch {
      finishWithError(error.nserror)
    }
  }
}
