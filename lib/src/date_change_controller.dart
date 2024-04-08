// Copyright (c) 2021 Simform Solutions. All rights reserved.
// Use of this source code is governed by a MIT-style license
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';

class DateChangeController extends ChangeNotifier {
  DateChangeController(
    DateTime initDateTime,
  ) : _initDateTime = initDateTime;

  DateTime _initDateTime;

  animateToDate(DateTime dateTime) {
    _initDateTime = dateTime;
    notifyListeners();
  }

  DateTime get initDateTime => _initDateTime;
}
