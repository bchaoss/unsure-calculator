import 'dart:html';
import 'app_component/app_component.dart';

void main() {
  AppComponent().init();
  
  final serviceWorker = window.navigator.serviceWorker;
  if (serviceWorker != null) {
    serviceWorker.register('service-worker.js');
  }
}
