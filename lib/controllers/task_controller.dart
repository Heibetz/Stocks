import '../services/firestore_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskController {
  factory TaskController() => _singleton;

  TaskController._internal();

  static final TaskController _singleton = TaskController._internal();

  final FirestoreService localStorage = FirestoreService();


  // Update user's unused money
  Future<void> updateUnusedMoney(String userId, double unusedMoney) {
    return localStorage.updateUnusedMoney(userId, unusedMoney);
  }

  // Update user's stocks and unused money
  Future<void> updateUserStocksAndMoney(String userId, List stocksBought, double unusedMoney) {
    return localStorage.updateUserStocksAndMoney(userId, stocksBought, unusedMoney);
  }

  // Get user's stocks and unused money
  Future<DocumentSnapshot> getUserData(String userId) {
    return localStorage.getUserData(userId);
  }

  // Add a new stock to user's stocks
  Future<void> addStock(String userId, String stockName, int sharesBought) {
    return localStorage.addStock(userId, stockName, sharesBought);
  }

  // Update a stock
  Future<void> updateStock(String userId, String stockId, int quantity) {
    return localStorage.updateStock(userId, stockId, quantity);
  }
}
