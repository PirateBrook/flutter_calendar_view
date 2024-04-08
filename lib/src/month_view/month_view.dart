// Copyright (c) 2021 Simform Solutions. All rights reserved.
// Use of this source code is governed by a MIT-style license
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import '../calendar_constants.dart';
import '../calendar_controller_provider.dart';
import '../calendar_event_data.dart';
import '../components/components.dart';
import '../constants.dart';
import '../date_change_controller.dart';
import '../enumerations.dart';
import '../event_controller.dart';
import '../extensions.dart';
import '../typedefs.dart';

class MonthView<T extends Object?> extends StatefulWidget {
  /// A function that returns a [Widget] that determines appearance of
  /// each cell in month calendar.
  final CellBuilder<T>? cellBuilder;

  /// Builds month page title.
  ///
  /// Used default title builder if null.
  final DateWidgetBuilder? headerBuilder;

  /// Called when user changes month.
  final CalendarPageChangeCallBack? onPageChange;

  /// This function will be called when user taps on month view cell.
  final CellTapCallback<T>? onCellTap;

  /// This function will be called when user will tap on a single event
  /// tile inside a cell.
  ///
  /// This function will only work if [cellBuilder] is null.
  final TileTapCallback<T>? onEventTap;

  /// Builds the name of the weeks.
  ///
  /// Used default week builder if null.
  ///
  /// Here day will range from 0 to 6 starting from Monday to Sunday.
  final WeekDayBuilder? weekDayBuilder;

  /// Determines the lower boundary user can scroll.
  ///
  /// If not provided [CalendarConstants.epochDate] is default.
  final DateTime? minMonth;

  /// Determines upper boundary user can scroll.
  ///
  /// If not provided [CalendarConstants.maxDate] is default.
  final DateTime? maxMonth;

  /// Defines initial display month.
  ///
  /// If not provided [DateTime.now] is default date.
  final DateTime? initialMonth;

  /// Defines whether to show default borders or not.
  ///
  /// Default value is true
  ///
  /// Use [borderSize] to define width of the border and
  /// [borderColor] to define color of the border.
  final bool showBorder;

  /// Defines width of default border
  ///
  /// Default value is [Colors.blue]
  ///
  /// It will take affect only if [showBorder] is set.
  final Color borderColor;

  /// Page transition duration used when user try to change page using
  /// [MonthView.nextPage] or [MonthView.previousPage]
  final Duration pageTransitionDuration;

  /// Page transition curve used when user try to change page using
  /// [MonthView.nextPage] or [MonthView.previousPage]
  final Curve pageTransitionCurve;

  /// A required parameters that controls events for month view.
  ///
  /// This will auto update month view when user adds events in controller.
  /// This controller will store all the events. And returns events
  /// for particular day.
  ///
  /// If [controller] is null it will take controller from
  /// [CalendarControllerProvider.controller].
  final EventController<T>? controller;

  /// Defines width of default border
  ///
  /// Default value is 1
  ///
  /// It will take affect only if [showBorder] is set.
  final double borderSize;

  /// Defines aspect ratio of day cells in month calendar page.
  final double cellAspectRatio;

  /// Width of month view.
  ///
  /// If null is provided then It will take width of closest [MediaQuery].
  final double width;

  final double height;

  /// This method will be called when user long press on calendar.
  final DatePressCallback? onDateSelect;

  ///   /// Defines the day from which the week starts.
  ///
  /// Default value is [WeekDays.monday].
  final WeekDays startDay;

  final bool showLunar;
  final bool showHoliday;

  final DateChangeController? dateChangeController;

  final Widget Function(DateTime checked) openedListBuilder;

  /// Main [Widget] to display month view.
  const MonthView({
    Key? key,
    this.dateChangeController,
    this.showBorder = true,
    this.borderColor = Constants.defaultBorderColor,
    this.cellBuilder,
    this.minMonth,
    this.maxMonth,
    this.controller,
    this.initialMonth,
    this.borderSize = 0.5,
    this.cellAspectRatio = 0.55,
    this.headerBuilder,
    this.weekDayBuilder,
    this.pageTransitionDuration = const Duration(milliseconds: 300),
    this.pageTransitionCurve = Curves.ease,
    required this.width,
    required this.height,
    this.onPageChange,
    this.onCellTap,
    this.onEventTap,
    this.onDateSelect,
    this.startDay = WeekDays.monday,
    this.showLunar = false,
    this.showHoliday = false,
    required this.openedListBuilder,
  }) : super(key: key);

  @override
  MonthViewState<T> createState() => MonthViewState<T>();
}

/// State of month view.
class MonthViewState<T extends Object?> extends State<MonthView<T>> {
  late DateTime _minDate;
  late DateTime _maxDate;

  late DateTime _currentDate;

  late int _currentIndex;

  int _totalMonths = 0;

  late PageController _pageController;

  late double _width;
  late double _height;

  late double _cellWidth;
  late double _cellHeight;

  late CellBuilder<T> _cellBuilder;

  late WeekDayBuilder _weekBuilder;

  late DateWidgetBuilder _headerBuilder;

  EventController<T>? _controller;

  late VoidCallback _reloadCallback;

  late VoidCallback _dateChangeCallback;

  DateChangeController? _dateChangeController;

  @override
  void initState() {
    super.initState();

    _reloadCallback = _reload;
    _dateChangeCallback = _dateChanged;
    _setDateRange();

    // Initialize current date.
    _currentDate = (widget.initialMonth ?? DateTime.now()).withoutTime;

    _regulateCurrentDate();

    // Initialize page controller to control page actions.
    _pageController = PageController(initialPage: _currentIndex);

    _assignBuilders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newController = widget.controller ??
        CalendarControllerProvider.of<T>(context).controller;

    if (newController != _controller) {
      _controller = newController;

      _controller!
        // Removes existing callback.
        ..removeListener(_reloadCallback)

        // Reloads the view if there is any change in controller or
        // user adds new events.
        ..addListener(_reloadCallback);
    }

    updateViewDimensions();
  }

  @override
  void didUpdateWidget(MonthView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller.
    final newController = widget.controller ??
        CalendarControllerProvider.of<T>(context).controller;

    if (newController != _controller) {
      _controller?.removeListener(_reloadCallback);
      _controller = newController;
      _controller?.addListener(_reloadCallback);
    }

    final newDateController = widget.dateChangeController;
    if (newDateController != _dateChangeController) {
      _dateChangeController?.removeListener(_dateChangeCallback);
      _dateChangeController = newDateController;
      _dateChangeController?.addListener(_dateChangeCallback);
    }

    // Update date range.
    if (widget.minMonth != oldWidget.minMonth ||
        widget.maxMonth != oldWidget.maxMonth) {
      _setDateRange();
      _regulateCurrentDate();

      _pageController.jumpToPage(_currentIndex);
    }

    // Update builders and callbacks
    _assignBuilders();

    updateViewDimensions();
  }

  @override
  void dispose() {
    _controller?.removeListener(_reloadCallback);
    _dateChangeController?.removeListener(_dateChangeCallback);
    _pageController.dispose();
    super.dispose();
  }

  _buildWeekIndicator() {
    final weekDays = DateTime.now().datesOfWeek(start: widget.startDay);

    return SizedBox(
      width: _width,
      child: Row(
        children: List.generate(
          7,
          (index) => Expanded(
            child: SizedBox(
              width: _cellWidth,
              child: _weekBuilder(weekDays[index].weekday - 1),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        width: _width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeekIndicator(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChange,
                itemBuilder: (_, index) {
                  final date = DateTime(_minDate.year, _minDate.month + index);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _MonthPageBuilder<T>(
                          key: ValueKey(date.toIso8601String()),
                          onCellTap: widget.onCellTap,
                          onDateSelect: widget.onDateSelect,
                          width: _width,
                          height: _height,
                          controller: controller,
                          date: date,
                          startDay: widget.startDay,
                          showLunar: widget.showLunar,
                          showHoliday: widget.showHoliday,
                          openedListBuilder: widget.openedListBuilder,
                          cellBuilder: _cellBuilder,
                        ),
                      ),
                    ],
                  );
                },
                itemCount: _totalMonths,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns [EventController] associated with this Widget.
  ///
  /// This will throw [AssertionError] if controller is called before its
  /// initialization is complete.
  EventController<T> get controller {
    if (_controller == null) {
      throw "EventController is not initialized yet.";
    }

    return _controller!;
  }

  void _reload() {
    if (mounted) {
      setState(() {});
    }
  }

  void _dateChanged() {
    if (mounted) {
      animateToMonth(_dateChangeController?.initDateTime.withoutTime ??
          DateTime.now().withoutTime);
    }
  }

  void updateViewDimensions() {
    _width = widget.width;
    _height = widget.height;

    _cellWidth = _width / 7;
    _cellHeight = _height / 5;
  }

  void _assignBuilders() {
    // Initialize cell builder. Assign default if widget.cellBuilder is null.
    _cellBuilder = widget.cellBuilder ?? _defaultCellBuilder;

    // Initialize week builder. Assign default if widget.weekBuilder is null.
    // This widget will come under header this will display week days.
    _weekBuilder = widget.weekDayBuilder ?? _defaultWeekDayBuilder;

    // Initialize header builder. Assign default if widget.headerBuilder
    // is null.
    //
    // This widget will be displayed on top of the page.
    // from where user can see month and change month.
    _headerBuilder = widget.headerBuilder ?? _defaultHeaderBuilder;
  }

  /// Sets the current date of this month.
  ///
  /// This method is used in initState and onUpdateWidget methods to
  /// regulate current date in Month view.
  ///
  /// If maximum and minimum dates are change then first call _setDateRange
  /// and then _regulateCurrentDate method.
  ///
  void _regulateCurrentDate() {
    // make sure that _currentDate is between _minDate and _maxDate.
    if (_currentDate.isBefore(_minDate)) {
      _currentDate = _minDate;
    } else if (_currentDate.isAfter(_maxDate)) {
      _currentDate = _maxDate;
    }

    // Calculate the current index of page view.
    _currentIndex = _minDate.getMonthDifference(_currentDate) - 1;
  }

  /// Sets the minimum and maximum dates for current view.
  void _setDateRange() {
    // Initialize minimum date.
    _minDate = (widget.minMonth ?? CalendarConstants.epochDate).withoutTime;

    // Initialize maximum date.
    _maxDate = (widget.maxMonth ?? CalendarConstants.maxDate).withoutTime;

    assert(
      _minDate.isBefore(_maxDate),
      "Minimum date should be less than maximum date.\n"
      "Provided minimum date: $_minDate, maximum date: $_maxDate",
    );

    // Get number of months between _minDate and _maxDate.
    // This number will be number of page in page view.
    _totalMonths = _maxDate.getMonthDifference(_minDate);
  }

  /// Calls when user changes page using gesture or inbuilt methods.
  void _onPageChange(int value) {
    if (mounted) {
      setState(() {
        _currentDate = DateTime(
          _currentDate.year,
          _currentDate.month + (value - _currentIndex),
        );
        _currentIndex = value;
      });
    }
    widget.onPageChange?.call(_currentDate, _currentIndex);
  }

  /// Default month view header builder
  Widget _defaultHeaderBuilder(DateTime date) {
    return MonthPageHeader(
      onTitleTapped: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: _minDate,
          lastDate: _maxDate,
        );

        if (selectedDate == null) return;
        jumpToMonth(selectedDate);
      },
      onPreviousMonth: previousPage,
      date: date,
      onNextMonth: nextPage,
    );
  }

  /// Default builder for week line.
  Widget _defaultWeekDayBuilder(int index) {
    return WeekDayTile(
      dayIndex: index,
    );
  }

  /// Default cell builder. Used when [widget.cellBuilder] is null
  Widget _defaultCellBuilder(
      date, List<CalendarEventData<T>> events, isToday, isInMonth) {
    return FilledCell<T>(
      date: date,
      shouldHighlight: isToday,
      backgroundColor: isInMonth ? Constants.white : Constants.offWhite,
      events: events,
      onTileTap: widget.onEventTap,
    );
  }

  /// Animate to next page
  ///
  /// Arguments [duration] and [curve] will override default values provided
  /// as [MonthView.pageTransitionDuration] and [MonthView.pageTransitionCurve]
  /// respectively.
  void nextPage({Duration? duration, Curve? curve}) {
    _pageController.nextPage(
      duration: duration ?? widget.pageTransitionDuration,
      curve: curve ?? widget.pageTransitionCurve,
    );
  }

  /// Animate to previous page
  ///
  /// Arguments [duration] and [curve] will override default values provided
  /// as [MonthView.pageTransitionDuration] and [MonthView.pageTransitionCurve]
  /// respectively.
  void previousPage({Duration? duration, Curve? curve}) {
    _pageController.previousPage(
      duration: duration ?? widget.pageTransitionDuration,
      curve: curve ?? widget.pageTransitionCurve,
    );
  }

  /// Jumps to page number [page]
  void jumpToPage(int page) {
    _pageController.jumpToPage(page);
  }

  /// Animate to page number [page].
  ///
  /// Arguments [duration] and [curve] will override default values provided
  /// as [MonthView.pageTransitionDuration] and [MonthView.pageTransitionCurve]
  /// respectively.
  Future<void> animateToPage(int page,
      {Duration? duration, Curve? curve}) async {
    await _pageController.animateToPage(page,
        duration: duration ?? widget.pageTransitionDuration,
        curve: curve ?? widget.pageTransitionCurve);
  }

  /// Returns current page number.
  int get currentPage => _currentIndex;

  /// Jumps to page which gives month calendar for [month]
  void jumpToMonth(DateTime month) {
    if (month.isBefore(_minDate) || month.isAfter(_maxDate)) {
      throw "Invalid date selected.";
    }
    _pageController.jumpToPage(_minDate.getMonthDifference(month) - 1);
  }

  /// Animate to page which gives month calendar for [month].
  ///
  /// Arguments [duration] and [curve] will override default values provided
  /// as [MonthView.pageTransitionDuration] and [MonthView.pageTransitionCurve]
  /// respectively.
  Future<void> animateToMonth(DateTime month,
      {Duration? duration, Curve? curve}) async {
    if (month.isBefore(_minDate) || month.isAfter(_maxDate)) {
      throw "Invalid date selected.";
    }
    await _pageController.animateToPage(
      _minDate.getMonthDifference(month) - 1,
      duration: duration ?? widget.pageTransitionDuration,
      curve: curve ?? widget.pageTransitionCurve,
    );
  }

  /// Returns the current visible date in month view.
  DateTime get currentDate => DateTime(_currentDate.year, _currentDate.month);
}

/// A single month page.
class _MonthPageBuilder<T> extends StatefulWidget {
  final GlobalKey _globalKey = GlobalKey();

  final DateTime date;
  final EventController<T> controller;
  final double width;
  final double height;
  final CellTapCallback<T>? onCellTap;
  final DatePressCallback? onDateSelect;
  final WeekDays startDay;
  final bool showLunar;
  final bool showHoliday;

  final Widget Function(DateTime checked) openedListBuilder;

  final CellBuilder<T> cellBuilder;

  _MonthPageBuilder({
    Key? key,
    required this.date,
    required this.controller,
    required this.width,
    required this.height,
    required this.onCellTap,
    required this.onDateSelect,
    required this.startDay,
    this.showLunar = false,
    this.showHoliday = false,
    required this.openedListBuilder,
    required this.cellBuilder,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MonthPageBuilderState();
  }
}

class _MonthPageBuilderState<T> extends State<_MonthPageBuilder<T>> {
  final fiveLineOffset = [
    [0, 3, 3, 3, 3],
    [-1, -1, 2, 2, 2],
    [-2, -2, -2, 1, 1],
    [-3, -3, -3, -3, 0],
    [-3, -3, -3, -3, -3],
  ];

  final sixLineOffset = [
    [0, 4, 4, 4, 4, 4],
    [-1, -1, 3, 3, 3, 3],
    [-2, -2, -2, 2, 2, 2],
    [-3, -3, -3, -3, 1, 1],
    [-4, -4, -4, -4, -4, 0],
    [-4, -4, -4, -4, -4, -4],
  ];

  final fiveDetailYOffset = [
    1,
    1,
    1,
    1,
    2,
  ];

  final sixDetailYOffset = [
    1,
    1,
    1,
    1,
    1,
    2,
  ];

  var offset0 = const Offset(0, 0);
  var offset1 = const Offset(0, 0);
  var offset2 = const Offset(0, 0);
  var offset3 = const Offset(0, 0);
  var offset4 = const Offset(0, 0);
  var offset5 = const Offset(0, 0);

  var isOpenedDetail = false;
  int? openedDetailIndex;
  DateTime? openedDateTime;

  var detailHeight = 0.0;
  var detailY = 0.0;
  var lineHeight = 0.0;
  var lines = 5;

  void _open(DateTime dateTime, int index) {
    if (isOpenedDetail) {
      if (openedDetailIndex == index) {
        openedDateTime = dateTime;
        return;
      } else {
        _close(index);
      }
    }
    openedDateTime = dateTime;
    if (widget.onDateSelect != null) {
      widget.onDateSelect!(openedDateTime!);
    }
    final boundSize =
        widget._globalKey.currentContext?.findRenderObject()?.paintBounds.size;
    isOpenedDetail = true;
    if (lines == 5) {
      lineHeight = (boundSize?.height ?? 0) * (1 / 5);
      detailHeight = lineHeight * 3;
      detailY = lineHeight * fiveDetailYOffset[index];
      final offsetYList = fiveLineOffset[index];
      setState(() {
        offset0 += Offset(0, offsetYList[0].toDouble());
        offset1 += Offset(0, offsetYList[1].toDouble());
        offset2 += Offset(0, offsetYList[2].toDouble());
        offset3 += Offset(0, offsetYList[3].toDouble());
        offset4 += Offset(0, offsetYList[4].toDouble());
      });
    } else {
      lineHeight = (boundSize?.height ?? 0) * (1 / 6);
      detailHeight = lineHeight * 4;
      detailY = lineHeight * sixDetailYOffset[index];
      final offsetYList = sixLineOffset[index];
      setState(() {
        offset0 += Offset(0, offsetYList[0].toDouble());
        offset1 += Offset(0, offsetYList[1].toDouble());
        offset2 += Offset(0, offsetYList[2].toDouble());
        offset3 += Offset(0, offsetYList[3].toDouble());
        offset4 += Offset(0, offsetYList[4].toDouble());
        offset5 += Offset(0, offsetYList[5].toDouble());
      });
    }
  }

  void _close(int index) {
    isOpenedDetail = false;
    openedDateTime = null;
    detailHeight = 0;
    setState(() {
      offset0 = Offset.zero;
      offset1 = Offset.zero;
      offset2 = Offset.zero;
      offset3 = Offset.zero;
      offset4 = Offset.zero;
      offset5 = Offset.zero;
    });
  }

  @override
  void initState() {
    lines =
        widget.date.getRowCount(startingDayOfWeek: widget.startDay.index + 1);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthDays = widget.date.datesOfMonths(startDay: widget.startDay);
    final date = widget.date;

    Widget _buildRow({
      required int index,
      Offset offset = Offset.zero,
    }) {
      Widget _buildDay(DateTime dateTime, int index) {
        final dataList = widget.controller.getEventsOnDay(dateTime);

        _openDetail(DateTime dateTime, int index) {
          if (isOpenedDetail &&
              openedDateTime?.isAtSameDayAs(dateTime) == true) {
            _close(index);
            return;
          }
          _open(dateTime, index);
        }

        return Expanded(
          child: Material(
            color: theme.cardColor,
            child: InkWell(
              onTap: () {
                _openDetail(dateTime, index);
              },
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor, width: 0.25)),
                child: dateTime.isAtSameMonthAs(date)
                    ? widget.cellBuilder(
                        date,
                        dataList,
                        dateTime.isAtSameDayAs(DateTime.now()),
                        monthDays.contains(dateTime),
                      )
                    : const Center(),
              ),
            ),
          ),
        );
      }

      DateTime dateTime = monthDays[index * 7];

      return Expanded(
        child: AnimatedSlide(
          offset: offset,
          duration: const Duration(milliseconds: 350),
          child: Row(
            children: [
              _buildDay(dateTime.add(0.days), index),
              _buildDay(dateTime.add(1.days), index),
              _buildDay(dateTime.add(2.days), index),
              _buildDay(dateTime.add(3.days), index),
              _buildDay(dateTime.add(4.days), index),
              _buildDay(dateTime.add(5.days), index),
              _buildDay(dateTime.add(6.days), index),
            ],
          ),
        ),
      );
    }

    return Stack(
      key: widget._globalKey,
      children: [
        Positioned(
          top: detailY,
          width: widget.width,
          child: Container(
            color: theme.scaffoldBackgroundColor,
            height: detailHeight,
            child: openedDateTime != null
                ? widget.openedListBuilder(openedDateTime!)
                : Center(),
          ),
        ),
        Column(
          children: [
            _buildRow(index: 0, offset: offset0),
            _buildRow(index: 1, offset: offset1),
            _buildRow(index: 2, offset: offset2),
            _buildRow(index: 3, offset: offset3),
            _buildRow(index: 4, offset: offset4),
            (lines == 6)
                ? _buildRow(index: 5, offset: offset5)
                : const SizedBox.shrink(),
          ],
        ),
      ],
    );
  }
}
