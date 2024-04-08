// Copyright (c) 2021 Simform Solutions. All rights reserved.
// Use of this source code is governed by a MIT-style license
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import '../calendar_view.dart';

T? ambiguate<T>(T? object) => object;

extension DateTimeExtensions on DateTime {
  /// Compares only [day], [month] and [year] of [DateTime].
  bool compareWithoutTime(DateTime date) {
    return day == date.day && month == date.month && year == date.year;
  }

  /// Gets difference of months between [date] and calling object.
  int getMonthDifference(DateTime date) {
    if (year == date.year) return ((date.month - month).abs() + 1);

    var months = ((date.year - year).abs() - 1) * 12;

    if (date.year >= year) {
      months += date.month + (13 - month);
    } else {
      months += month + (13 - date.month);
    }

    return months;
  }

  /// Gets difference of days between [date] and calling object.
  int getDayDifference(DateTime date) => DateTime.utc(year, month, day)
      .difference(DateTime.utc(date.year, date.month, date.day))
      .inDays
      .abs();

  /// Gets difference of weeks between [date] and calling object.
  int getWeekDifference(DateTime date, {WeekDays start = WeekDays.monday}) =>
      (firstDayOfWeek(start: start)
                  .difference(date.firstDayOfWeek(start: start))
                  .inDays
                  .abs() /
              7)
          .ceil();

  /// Returns The List of date of Current Week, all of the dates will be without
  /// time.
  /// Day will start from Monday to Sunday.
  ///
  /// ex: if Current Date instance is 8th and day is wednesday then weekDates
  /// will return dates
  /// [6,7,8,9,10,11,12]
  /// Where on 6th there will be monday and on 12th there will be Sunday
  List<DateTime> datesOfWeek({WeekDays start = WeekDays.monday}) {
    // Here %7 ensure that we do not subtract >6 and <0 days.
    // Initial formula is,
    //    difference = (weekday - startInt)%7
    // where weekday and startInt ranges from 1 to 7.
    // But in WeekDays enum index ranges from 0 to 6 so we are
    // adding 1 in index. So, new formula with WeekDays is,
    //    difference = (weekdays - (start.index + 1))%7
    //
    final startDay =
        DateTime(year, month, day - (weekday - start.index - 1) % 7);

    return [
      startDay,
      DateTime(startDay.year, startDay.month, startDay.day + 1),
      DateTime(startDay.year, startDay.month, startDay.day + 2),
      DateTime(startDay.year, startDay.month, startDay.day + 3),
      DateTime(startDay.year, startDay.month, startDay.day + 4),
      DateTime(startDay.year, startDay.month, startDay.day + 5),
      DateTime(startDay.year, startDay.month, startDay.day + 6),
    ];
  }

  /// Returns the first date of week containing the current date
  DateTime firstDayOfWeek({WeekDays start = WeekDays.monday}) =>
      DateTime(year, month, day - ((weekday - start.index - 1) % 7));

  /// Returns the last date of week containing the current date
  DateTime lastDayOfWeek({WeekDays start = WeekDays.monday}) =>
      DateTime(year, month, day + (6 - (weekday - start.index - 1) % 7));

  /// Returns list of all dates of [month].
  /// All the dates are week based that means it will return array of size 42
  /// which will contain 6 weeks that is the maximum number of weeks a month
  /// can have.
  List<DateTime> datesOfMonths({WeekDays startDay = WeekDays.monday}) {
    final monthDays = <DateTime>[];
    for (var i = 1, start = 1; i < 7; i++, start += 7) {
      monthDays
          .addAll(DateTime(year, month, start).datesOfWeek(start: startDay));
    }
    return monthDays;
  }

  /// Gives formatted date in form of 'month - year'.
  String get formatted => "$month-$year";

  /// Returns total minutes this date is pointing at.
  /// if [DateTime] object is, DateTime(2021, 5, 13, 12, 4, 5)
  /// Then this getter will return 12*60 + 4 which evaluates to 724.
  int get getTotalMinutes => hour * 60 + minute;

  /// Returns a new [DateTime] object with hour and minutes calculated from
  /// [totalMinutes].
  DateTime copyFromMinutes([int totalMinutes = 0]) => DateTime(
        year,
        month,
        day,
        totalMinutes ~/ 60,
        totalMinutes % 60,
      );

  /// Returns [DateTime] without timestamp.
  DateTime get withoutTime => DateTime(year, month, day);

  /// Compares time of two [DateTime] objects.
  bool hasSameTimeAs(DateTime other) {
    return other.hour == hour &&
        other.minute == minute &&
        other.second == second &&
        other.millisecond == millisecond &&
        other.microsecond == microsecond;
  }

  bool get isDayStart => hour % 24 == 0 && minute % 60 == 0;

  @Deprecated(
      "This extension is not being used in this package and will be removed "
      "in next major release. Please use withoutTime instead.")
  DateTime get dateYMD => DateTime(year, month, day);

  int getRowCount({int startingDayOfWeek = DateTime.monday}) {
    final first = _firstDayOfMonth(this);
    final daysBefore = _getDaysBefore(first, startingDayOfWeek);
    final firstToDisplay = first.subtract(Duration(days: daysBefore));

    final last = _lastDayOfMonth(this);
    final daysAfter = _getDaysAfter(last, startingDayOfWeek);
    final lastToDisplay = last.add(Duration(days: daysAfter));

    return (lastToDisplay.difference(firstToDisplay).inDays + 1) ~/ 7;
  }

  int _getDaysBefore(DateTime firstDay, int startingDayOfWeek) {
    return (firstDay.weekday + 7 - getWeekdayNumber(startingDayOfWeek)) % 7;
  }

  int _getDaysAfter(DateTime lastDay, int startingDayOfWeek) {
    int invertedStartingWeekday = 8 - getWeekdayNumber(startingDayOfWeek);

    int daysAfter = 7 - ((lastDay.weekday + invertedStartingWeekday) % 7);
    if (daysAfter == 7) {
      daysAfter = 0;
    }

    return daysAfter;
  }

  int getWeekdayNumber(int startingDayOfWeek) {
    return startingDayOfWeek;
  }

  DateTime _firstDayOfMonth(DateTime month) {
    return DateTime.utc(month.year, month.month, 1);
  }

  DateTime _lastDayOfMonth(DateTime month) {
    final date = month.month < 12
        ? DateTime.utc(month.year, month.month + 1, 1)
        : DateTime.utc(month.year + 1, 1, 1);
    return date.subtract(const Duration(days: 1));
  }

  /// Returns true if [other] is in the same year as [this].
  ///
  /// Does not account for timezones.
  bool isAtSameYearAs(DateTime other) => year == other.year;

  /// Returns true if [other] is in the same month as [this].
  ///
  /// This means the exact month, including year.
  ///
  /// Does not account for timezones.
  bool isAtSameMonthAs(DateTime other) =>
      isAtSameYearAs(other) && month == other.month;

  /// Returns true if [other] is on the same day as [this].
  ///
  /// This means the exact day, including year and month.
  ///
  /// Does not account for timezones.
  bool isAtSameDayAs(DateTime other) =>
      isAtSameMonthAs(other) && day == other.day;

  /// Returns true if [other] is at the same hour as [this].
  ///
  /// This means the exact hour, including year, month and day.
  ///
  /// Does not account for timezones.
  bool isAtSameHourAs(DateTime other) =>
      isAtSameDayAs(other) && hour == other.hour;

  /// Returns true if [other] is at the same minute as [this].
  ///
  /// This means the exact minute, including year, month, day and hour.
  ///
  /// Does not account for timezones.
  bool isAtSameMinuteAs(DateTime other) =>
      isAtSameHourAs(other) && minute == other.minute;

  /// Returns true if [other] is at the same second as [this].
  ///
  /// This means the exact second, including year, month, day, hour and minute.
  ///
  /// Does not account for timezones.
  bool isAtSameSecondAs(DateTime other) =>
      isAtSameMinuteAs(other) && second == other.second;
}

extension ColorExtension on Color {
  Color get accent =>
      (blue / 2 >= 255 / 2 || red / 2 >= 255 / 2 || green / 2 >= 255 / 2)
          ? Colors.black
          : Colors.white;
}

extension MaterialColorExtension on MaterialColor {
  @Deprecated(
      "This extension is not being used in this package and will be removed "
      "in next major release.")
  Color get accent =>
      (blue / 2 >= 255 / 2 || red / 2 >= 255 / 2 || green / 2 >= 255 / 2)
          ? Colors.black
          : Colors.white;
}

extension MinutesExtension on MinuteSlotSize {
  /// Returns minutes for respective [MinuteSlotSize]
  int get minutes {
    switch (this) {
      case MinuteSlotSize.minutes15:
        return 15;
      case MinuteSlotSize.minutes30:
        return 30;
      case MinuteSlotSize.minutes60:
        return 60;
    }
  }
}

extension MyList<T extends Object?> on List<CalendarEventData<T>> {
  // Below function will add the new event in sorted manner(startTimeWise) in
  // the existing list of CalendarEventData.

  void addEventInSortedManner(
    CalendarEventData<T> event, [
    EventSorter<T>? sorter,
  ]) {
    var addIndex = -1;

    for (var i = 0; i < this.length; i++) {
      var result = (sorter ?? defaultEventSorter).call(event, this[i]);
      if (result <= 0) {
        addIndex = i;
        break;
      }
    }

    if (addIndex > -1) {
      insert(addIndex, event);
    } else {
      add(event);
    }
  }
}

/// Default [EventSorter] for [CalendarEventData]
/// It will sort the events based on their [CalendarEventData.startTime].
int defaultEventSorter<T extends Object?>(
  CalendarEventData<T> a,
  CalendarEventData<T> b,
) {
  return (a.startTime?.getTotalMinutes ?? 0) -
      (b.startTime?.getTotalMinutes ?? 0);
}

extension TimerOfDayExtension on TimeOfDay {
  int get getTotalMinutes => hour * 60 + minute;
}

extension IntExtension on int {
  String appendLeadingZero() {
    return toString().padLeft(2, '0');
  }
}

extension NumTimeExtension<T extends num> on T {
  /// Returns a Duration represented in days
  Duration get days => milliseconds * Duration.millisecondsPerDay;

  /// Returns a Duration represented in hours
  Duration get hours => milliseconds * Duration.millisecondsPerHour;

  /// Returns a Duration represented in minutes
  Duration get minutes => milliseconds * Duration.millisecondsPerMinute;

  /// Returns a Duration represented in seconds
  Duration get seconds => milliseconds * Duration.millisecondsPerSecond;

  /// Returns a Duration represented in milliseconds
  Duration get milliseconds => Duration(
      microseconds: (this * Duration.microsecondsPerMillisecond).toInt());

  /// Returns a Duration represented in microseconds
  Duration get microseconds =>
      milliseconds ~/ Duration.microsecondsPerMillisecond;
}
