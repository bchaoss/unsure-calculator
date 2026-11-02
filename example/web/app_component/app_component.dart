import 'dart:html';
import 'package:unsure_web/unsure_result_message.dart';

class AppComponent {
  late HtmlElement _root;
  late InputElement _formulaInput;
  late HtmlElement _output;
  late HtmlElement _loader;
  late HtmlElement _resultElement;
  late HtmlElement _noteElement;
  late HtmlElement _histogramSection;
  late HtmlElement _histogramElement;
  late HtmlElement _percentilesSection;
  late HtmlElement _percentilesElement;

  late Worker _worker;

  String formulaString = '100 / 4~6';
  String simpleResult = '';
  String histogram = '';
  String percentiles = '';
  String note = 'Write a formula and hit Enter, or press =.';

  bool showHistogram = true;

  bool showPercentiles = false;

  bool isComputing = false;

  Future<void> init() async {
    _root = document.querySelector('#unsure-calc') as HtmlElement;

    final template =
        await HttpRequest.getString('app_component/app_component.html');
    _root.setInnerHtml(
      template,
      treeSanitizer: NodeTreeSanitizer.trusted,
    );

    _formulaInput = _root.querySelector('#formula-input') as InputElement;
    _output = _root.querySelector('.calculator-output') as HtmlElement;
    _loader = _root.querySelector('.loader') as HtmlElement;
    _resultElement = _root.querySelector('.result') as HtmlElement;
    _noteElement = _root.querySelector('.note') as HtmlElement;
    _histogramSection =
        _root.querySelector('.histogram-section') as HtmlElement;
    _histogramElement = _root.querySelector('.histogram') as HtmlElement;
    _percentilesSection =
        _root.querySelector('.percentiles-section') as HtmlElement;
    _percentilesElement = _root.querySelector('.percentiles') as HtmlElement;

    _worker = Worker('worker.dart.js');
    _worker.onMessage.listen(_receiveResult);

    _formulaInput.value = formulaString;

    _root.on['pointerdown'].listen((event) {
      final target = event.target;
      if (target is Element && target.closest('.keypad button') != null) {
        event.preventDefault();
      }
    });

    _root.onClick.listen(_handleClick);
    _formulaInput.onKeyUp.listen((event) {
      if (event.keyCode == KeyCode.ENTER) {
        startComputation(_formulaInput.value ?? '');
      }
    });

    _extractHashIntoFormula(window.location.hash);
    _formulaInput.focus();
    _render();
  }

  void add(String value) {
    _updateFormulaString();
    formulaString = '$formulaString$value';
    _formulaInput.value = formulaString;
  }

  void delete() {
    _updateFormulaString();
    if (formulaString.isEmpty) return;
    formulaString = formulaString.substring(0, formulaString.length - 1);
    while (formulaString.endsWith(' ')) {
      formulaString = formulaString.substring(0, formulaString.length - 1);
    }

    _formulaInput.value = formulaString;
  }

  void startComputation(String formula) {
    if (isComputing) return;

    formulaString = formula;
    isComputing = true;
    note = 'Please wait...';
    simpleResult = '';
    histogram = '';
    percentiles = '';

    _render();
    _worker.postMessage(formula);
  }

  void _receiveResult(MessageEvent event) {
    final result = BaseResultMessage.fromData(event.data as String);

    simpleResult = result.simpleResult;
    isComputing = false;

    if (result is FailureResultMessage) {
      note = 'There was a problem with your formula ${result.message}.';
      histogram = '';
      percentiles = '';
    } else if (result is InvalidResultMessage) {
      note = 'Most or all of the results of this computation '
          'were invalid values. '
          'It doesn\'t make sense to run statistics on this formula.';
      histogram = '';
      percentiles = '';
    } else if (result is StochasticResultMessage) {
      histogram = result.histogram;
      percentiles = result.percentiles;
      note = '';
    } else if (result is NonStochasticResultMessage) {
      note = 'Try to make some inputs a bit more unsure, '
          'such as writing 4~6 instead of 4.';
      histogram = '';
      percentiles = '';
    } else {
      throw ArgumentError('$result is not one of the messages we expect');
    }

    _render();
    _formulaInput.focus();
  }

  void _handleClick(MouseEvent event) {
    final target = event.target;
    if (target is! Element) return;

    final button = target.closest('button');
    if (button != null) {
      if (isComputing) return;

      switch (button.dataset['action']) {
        case 'add':
          add(button.dataset['value']!);
          break;
        case 'delete':
          delete();
          break;
        case 'calculate':
          startComputation(_formulaInput.value ?? '');
          break;
      }
      return;
    }

    final link = target.closest('a');
    if (link == null) return;

    final action = link.dataset['action'];
    if (action == 'toggle-histogram') {
      event.preventDefault();
      showHistogram = !showHistogram;
      _render();
    } else if (action == 'toggle-percentiles') {
      event.preventDefault();
      showPercentiles = !showPercentiles;
      _render();
    }
  }

  void _extractHashIntoFormula(String urlHash) {
    final fIndex = urlHash.indexOf('f=');
    if (fIndex == -1) return;

    final startIndex = fIndex + 2;
    if (startIndex >= urlHash.length) return;

    var endIndex = urlHash.length;
    final andIndex = urlHash.indexOf('&', startIndex);
    if (andIndex != -1) {
      endIndex = andIndex;
    }

    final encodedFormula = urlHash.substring(startIndex, endIndex);
    if (encodedFormula.isEmpty) return;

    formulaString = Uri.decodeComponent(encodedFormula);
    _formulaInput.value = formulaString;
    startComputation(formulaString);
  }

  void _updateFormulaString() {
    formulaString = _formulaInput.value ?? '';
  }

  void _render() {
    _formulaInput.disabled = isComputing;

    for (final button in _root.querySelectorAll('button')) {
      (button as ButtonElement).disabled = isComputing;
    }

    _loader.hidden = !isComputing;
    _output.classes.toggle('grayout', isComputing);

    _resultElement.text = simpleResult;
    _resultElement.hidden = simpleResult.isEmpty || isComputing;

    _noteElement.text = note;
    _noteElement.hidden = note.isEmpty;

    _histogramSection.hidden = histogram.isEmpty;
    _histogramElement.text = histogram;
    _histogramElement.hidden = !showHistogram;

    final histogramLink = _histogramSection.querySelector('a')!;
    histogramLink.querySelector('span')!.text = showHistogram ? 'hide' : 'show';

    _percentilesSection.hidden = percentiles.isEmpty;
    _percentilesElement.text = percentiles;
    _percentilesElement.hidden = !showPercentiles;

    final percentilesLink = _percentilesSection.querySelector('a')!;
    percentilesLink.querySelector('span')!.text =
        showPercentiles ? 'hide' : 'show';
  }
}
