import 'package:flutter/material.dart';

FocusNode? focusNode;

/// Hide the soft keyboard.
void hideKeyboard(BuildContext context) {
  FocusScope.of(context).requestFocus(FocusNode());
}

/// Show or focus soft keyboard.
void showKeyboard(BuildContext context) {
  FocusScope.of(context).requestFocus(FocusNode());
}

/// Show or focus soft keyboard.
void showSoftKeyboard() {
  focusNode!.requestFocus();
}

/// Hide the soft keyboard.
void dismissKeyboard() {
  focusNode!.unfocus();
}