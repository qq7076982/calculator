import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '计算器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _expression = '';
  String _result = '0';
  String _display = '0';
  double _fontSize = 48;

  void _onButtonPressed(String value) {
    setState(() {
      switch (value) {
        case 'C':
          _expression = '';
          _result = '0';
          _display = '0';
          _fontSize = 48;
          break;
        case '⌫':
          if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
            _updateDisplay();
          }
          break;
        case '=':
          _calculate();
          break;
        case '+':
        case '-':
        case '×':
        case '÷':
          if (_expression.isNotEmpty && !_isOperator(_expression[_expression.length - 1])) {
            _expression += value;
            _display += value;
          }
          break;
        case '.':
          _appendDecimal();
          break;
        case '%':
          _calculatePercent();
          break;
        case '±':
          _toggleSign();
          break;
        default:
          if (_isOperator(value) && _isOperator(_expression[_expression.length - 1])) {
            _expression = _expression.substring(0, _expression.length - 1);
          }
          _expression += value;
          _display = _formatDisplay(_expression);
          break;
      }
      _adjustFontSize();
    });
  }

  void _appendDecimal() {
    String lastNumber = _getLastNumber();
    if (!lastNumber.contains('.')) {
      if (lastNumber.isEmpty) {
        _expression += '0.';
        _display = _formatDisplay(_expression);
      } else {
        _expression += '.';
        _display = _formatDisplay(_expression);
      }
    }
  }

  void _calculatePercent() {
    if (_expression.isNotEmpty) {
      try {
        double evalResult = _evaluate(_expression);
        evalResult = evalResult / 100;
        _expression = _formatResult(evalResult);
        _display = _expression;
        _result = _formatResult(evalResult);
      } catch (_) {}
    }
  }

  void _toggleSign() {
    if (_expression.isNotEmpty) {
      if (_expression.startsWith('-')) {
        _expression = _expression.substring(1);
      } else {
        _expression = '-$_expression';
      }
      _display = _formatDisplay(_expression);
    }
  }

  String _getLastNumber() {
    String num = '';
    for (int i = _expression.length - 1; i >= 0; i--) {
      if (_isOperator(_expression[i]) && i > 0) {
        break;
      }
      num = _expression[i] + num;
    }
    return num;
  }

  bool _isOperator(String s) {
    return s == '+' || s == '-' || s == '×' || s == '÷';
  }

  void _updateDisplay() {
    _display = _formatDisplay(_expression);
    if (_expression.isEmpty) {
      _display = '0';
      _result = '0';
    }
  }

  String _formatDisplay(String expr) {
    return expr.replaceAll('×', '×').replaceAll('÷', '÷');
  }

  void _calculate() {
    if (_expression.isEmpty) return;
    try {
      double res = _evaluate(_expression);
      _result = _formatResult(res);
      _expression = _result;
      _display = _result;
    } catch (_) {
      _result = 'Error';
      _display = 'Error';
    }
    _fontSize = 48;
  }

  double _evaluate(String expr) {
    expr = expr.replaceAll('×', '*').replaceAll('÷', '/');
    List<String> tokens = _tokenize(expr);
    return _parseExpression(tokens);
  }

  List<String> _tokenize(String expr) {
    List<String> tokens = [];
    String num = '';
    for (int i = 0; i < expr.length; i++) {
      String c = expr[i];
      if (_isOperator(c) || c == '(' || c == ')') {
        if (num.isNotEmpty) {
          tokens.add(num);
          num = '';
        }
        tokens.add(c);
      } else {
        num += c;
      }
    }
    if (num.isNotEmpty) tokens.add(num);
    return tokens;
  }

  double _parseExpression(List<String> tokens) {
    List<double> values = [];
    List<String> ops = [];
    int i = 0;

    while (i < tokens.length) {
      String tok = tokens[i];
      if (tok == '+' || tok == '-') {
        while (ops.isNotEmpty && (ops.last == '+' || ops.last == '-')) {
          values.add(_applyOp(ops.removeLast(), values.removeLast(), values.removeLast()));
        }
        ops.add(tok);
      } else if (tok == '*' || tok == '/') {
        while (ops.isNotEmpty && (ops.last == '*' || ops.last == '/')) {
          double b = values.removeLast();
          double a = values.removeLast();
          values.add(_applyOp(ops.removeLast(), a, b));
        }
        ops.add(tok);
      } else {
        values.add(double.parse(tok));
      }
      i++;
    }

    while (ops.isNotEmpty) {
      double b = values.removeLast();
      double a = values.removeLast();
      values.add(_applyOp(ops.removeLast(), a, b));
    }

    return values.last;
  }

  double _applyOp(String op, double a, double b) {
    switch (op) {
      case '+': return a + b;
      case '-': return a - b;
      case '*': return a * b;
      case '/': return a / b;
      default: return 0;
    }
  }

  String _formatResult(double val) {
    if (val == val.truncateToDouble()) {
      return val.truncate().toString();
    }
    String s = val.toStringAsFixed(8);
    s = s.replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
    return s;
  }

  void _adjustFontSize() {
    if (_display.length > 12) {
      _fontSize = 28;
    } else if (_display.length > 8) {
      _fontSize = 36;
    } else {
      _fontSize = 48;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            Expanded(flex: 2, child: _buildDisplay()),
            Expanded(flex: 5, child: _buildButtons()),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      alignment: Alignment.bottomRight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _display,
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.w300,
              color: Colors.grey[800],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            _result == '0' ? '' : '= $_result',
            style: TextStyle(fontSize: 24, color: Colors.grey[500]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(child: Row(children: [_btn('C', Colors.orange[50]!, Colors.orange), _btn('⌫', Colors.grey[100]!, Colors.grey[700]!), _btn('%', Colors.grey[100]!, Colors.grey[700]!), _btn('÷', Colors.grey[100]!, Colors.teal)])),
          Expanded(child: Row(children: [_btn('7', Colors.white!, Colors.grey[800]!), _btn('8', Colors.white!, Colors.grey[800]!), _btn('9', Colors.white!, Colors.grey[800]!), _btn('×', Colors.grey[100]!, Colors.teal)])),
          Expanded(child: Row(children: [_btn('4', Colors.white!, Colors.grey[800]!), _btn('5', Colors.white!, Colors.grey[800]!), _btn('6', Colors.white!, Colors.grey[800]!), _btn('-', Colors.grey[100]!, Colors.teal)])),
          Expanded(child: Row(children: [_btn('1', Colors.white!, Colors.grey[800]!), _btn('2', Colors.white!, Colors.grey[800]!), _btn('3', Colors.white!, Colors.grey[800]!), _btn('+', Colors.grey[100]!, Colors.teal)])),
          Expanded(child: Row(children: [_btn('±', Colors.grey[100]!, Colors.grey[800]!), _btn('0', Colors.white!, Colors.grey[800]!), _btn('.', Colors.white!, Colors.grey[800]!), _btn('=', Colors.teal, Colors.white)])),
        ],
      ),
    );
  }

  Widget _btn(String label, Color bg, Color fg) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          elevation: 1,
          shadowColor: Colors.grey.shade300,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _onButtonPressed(label),
            child: Container(
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500, color: fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}