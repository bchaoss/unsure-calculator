import 'package:unsure/unsure.dart';
import 'package:unsure_web/unsure_result_message.dart';

class UnsureCalculator {
  BaseResultMessage calculate(String formulaString) {
    final parser = FormulaParser();
    final formula = parser.parseString(formulaString);

    if (formula.wasFailure) {
      final buf = StringBuffer();

      if (formula.failurePosition > 0) {
        buf.write('after "');
        buf.write(
          formula.failureBuffer.substring(0, formula.failurePosition),
        );
        buf.write('"');
      }

      if (formula.failurePosition > 0 &&
          formula.failurePosition < formula.failureBuffer.length - 1) {
        buf.write(' and ');
      }

      if (formula.failurePosition < formula.failureBuffer.length - 1) {
        buf.write('before "');
        buf.write(
          formula.failureBuffer.substring(
            formula.failurePosition,
            formula.failureBuffer.length,
          ),
        );
        buf.write('"');
      }

      buf.write(' (');
      buf.write(formula.failureMessage);
      buf.write(')');

      return FailureResultMessage(buf.toString());
    }

    if (!formula.isStochastic) {
      final value = formula.emit();
      final valueString = value.toString();

      return NonStochasticResultMessage(valueString);
    }

    final calculation = Calculation(formula.emit, iterations: 250000);
    final result = calculation.run();

    if (result.isInvalid) {
      return InvalidResultMessage(result.simple);
    }

    return StochasticResultMessage(
      result.simple,
      result.histogram.toString(),
      result.percentilesString,
    );
  }
}
