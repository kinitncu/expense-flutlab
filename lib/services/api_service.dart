import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://localhost/expense_api";

  static Future<bool> addExpense({
    required int userId,
    required String category,
    required double amount,
    required String date,
    required String note,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_expense.php'),
      body: jsonEncode({
        "user_id": userId,
        "category": category,
        "amount": amount,
        "date": date,
        "note": note,
      }),
      headers: {"Content-Type": "application/json"},
    );
    final data = jsonDecode(response.body);
    return data['success'];
  }

  static Future<List<Map<String, dynamic>>> getExpenses(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_expenses.php?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getCurrentAllowance(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_current_allowance.php?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      return {"amount": 0};
    }
  }

  static Future<bool> updateExpense(Map<String, dynamic> expense) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update_expense.php'),
      body: jsonEncode(expense),
      headers: {"Content-Type": "application/json"},
    );
    return jsonDecode(response.body)['success'];
  }

  static Future<bool> deleteExpense(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/delete_expense.php'),
      body: jsonEncode({"id": id}),
      headers: {"Content-Type": "application/json"},
    );
    return jsonDecode(response.body)['success'];
  }

  static Future<bool> logEmergency({
    required int userId,
    required double amount,
    required String date,
    required String note,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/log_emergency.php'),
      body: jsonEncode({
        "user_id": userId,
        "amount": amount,
        "date": date,
        "note": note,
      }),
      headers: {"Content-Type": "application/json"},
    );
    return jsonDecode(response.body)['success'];
  }

  static Future<List<Map<String, dynamic>>> getEmergencies(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_emergencies.php?user_id=$userId'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      return [];
    }
  }

  static Future<bool> setCategoryLimit({
    required int userId,
    required String category,
    required double limitAmount,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/set_category_limit.php'),
      body: jsonEncode({
        "user_id": userId,
        "category": category,
        "limit_amount": limitAmount,
      }),
      headers: {"Content-Type": "application/json"},
    );
    return jsonDecode(response.body)['success'];
  }

  static Future<Map<String, double>> getCategoryLimits(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_category_limits.php?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return {
        for (var item in data)
          item['category']: double.parse(item['limit_amount'].toString())
      };
    } else {
      return {};
    }
  }

  static Future<bool> addAllowance({
    required int userId,
    required double amount,
    required String frequency,
    required String startDate,
    double carryOver = 0,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_allowance.php'),
      body: jsonEncode({
        "user_id": userId,
        "amount": amount,
        "frequency": frequency,
        "start_date": startDate,
        "carry_over": carryOver,
      }),
      headers: {"Content-Type": "application/json"},
    );
    return jsonDecode(response.body)['success'];
  }

  static Future<Map<String, dynamic>> getUser([int? userId]) async {
    final url = userId != null
        ? '$baseUrl/get_user.php?user_id=$userId'
        : '$baseUrl/get_user.php';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      return {};
    }
  }

  static Future<bool> updateUser({
    required int userId,
    required String name,
    required String avatar,
    required String currency,
    String? email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update_user.php'),
      body: jsonEncode({
        "user_id": userId,
        "name": name,
        "avatar": avatar,
        "currency": currency,
        "email": email,
      }),
      headers: {"Content-Type": "application/json"},
    );
    return jsonDecode(response.body)['success'];
  }

  static Future<int?> insertUser({
    required String name,
    required String avatar,
    required String currency,
    String? email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/insert_user.php'),
      body: jsonEncode({
        "name": name,
        "avatar": avatar,
        "currency": currency,
        "email": email,
      }),
      headers: {"Content-Type": "application/json"},
    );

    print("Insert user response: ${response.body}");

    final body = jsonDecode(response.body);
    if (body['success'] == true) {
      return body['user_id'];
    } else {
      return null;
    }
  }
}
