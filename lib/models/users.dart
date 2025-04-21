import 'stocks.dart';

class User {
  double unusedMoney = 10000.0;
  List<Stock>? stocksBought;

  User({this.unusedMoney = 10000.0, this.stocksBought = const []});

}