import 'package:flutter/foundation.dart';

class NavigationProvider extends ChangeNotifier {
  int currentIndex = 0;

  void setIndex(int index) {
    currentIndex = index;
    notifyListeners();
  }

  void resetIndex() {
    currentIndex = 0;
    notifyListeners();
  }
}
