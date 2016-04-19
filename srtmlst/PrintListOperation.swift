//
//  PrintListOperation.swift
//  srtmlst
//
//  Created by George Madrid on 4/18/16.
//  Copyright © 2016 George Madrid. All rights reserved.
//

import Foundation

class PrintListOperation : Operation, ResultConsumer {
  var consumedResult: (RTMClient, [RTMClient.RTMList])?

  var currentHeader: String = ""

  private static func relativeDate(date: NSDate) -> String {
    // We want:
    // * before today: "Overdue"
    // * today:        "Today"
    // * tomorrow:     "Tomorrow"
    // * in next week: "Wed" (or whatever)
    // * after that:   "Jun 18" (if this year)
    // * otherwise:    "Jan 2, 2017"

    let relativeFormatter = NSDateFormatter()
    relativeFormatter.dateStyle = .ShortStyle
    relativeFormatter.doesRelativeDateFormatting = true

    let dowFormatter = NSDateFormatter()
    dowFormatter.dateFormat = "ccc"

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
        for task in sorted {
          let thisHeader = PrintListOperation.relativeDate(task.due ?? NSDate.distantFuture())
          if thisHeader != lastHeader {
            print("========== \(thisHeader) =========")
            lastHeader = thisHeader
          }

          print("\(task.priority): \(task.name)")
        }

        self?.finish()
      }
    } catch {
      finishWithError(error.nserror)
    }
  }
}
