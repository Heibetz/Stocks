import 'dart:convert';
import 'package:http/http.dart' as http;

class FinnhubService {
  final String apiKey = 'cvsmfhhr01qhup0rnec0cvsmfhhr01qhup0rnecg';

  FinnhubService();

  Future<Map<String, dynamic>> getStockQuote(String symbol) async {
    final url = Uri.parse(
      'https://finnhub.io/api/v1/quote?symbol=$symbol&token=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load stock data');
    }
  }
}



// void main() {
//   final service = FinnhubService();
//   service.getStockQuote('AAPL').then((data) {
//     print('Current price: \$${data['c']}');
//     print('High price of the day: \$${data['h']}');
//     print('Low price of the day: \$${data['l']}');
//     print('Open price of the day: \$${data['o']}');
//     print('Previous close price: \$${data['pc']}');
//   }).catchError((error) {
//     print('Error fetching data: $error');
//   });
// }