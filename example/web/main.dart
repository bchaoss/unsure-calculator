import 'dart:html';
import 'app_component/app_component.dart';

void main() {
  AppComponent().init();

  if (window.matchMedia('(display-mode: standalone)').matches) {
    document.documentElement!.classes.add('pwa-standalone');

    final toggle = document.getElementById('toggle-instructions');
    final instructions = document.getElementById('instructions');

    toggle?.onClick.listen((_) {
      if (instructions != null) {
        final isHidden = instructions.style.display == 'none';
        instructions.style.display = isHidden ? 'block' : 'none';
        toggle.text = isHidden ? 'Hide instructions' : 'How to use';
      }
    });
  }
  
  final serviceWorker = window.navigator.serviceWorker;
  if (serviceWorker != null) {
    serviceWorker.register('service-worker.js');
  }
}
