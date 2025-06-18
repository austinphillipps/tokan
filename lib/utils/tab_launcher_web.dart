import 'dart:html' as html;

void openTabImpl(String url) {
  html.window.open(url, '_blank');
}
