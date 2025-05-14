import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://localhost/expense_api/api";

  static Future<bool> addExpense({
    required int userId,
    required String category,
    required double amount,
    required String date,
    required String note,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/post/add_expense.php'),
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
      Uri.parse('$baseUrl/get/get_expenses.php?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      return [];
    }
  }

  static Future<List<double>> getYearlyAverages(int userId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/get/get_yearly_averages.php?user_id=$userId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => double.tryParse(e['average_spending'].toString()) ?? 0.0)
          .toList();
    } else {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getCurrentAllowance(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get/get_current_allowance.php?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      return {"amount": 0};
    }
  }

  static Future<bool> updateExpense(Map<String, dynamic> expense) async {
    final response = await http.post(
      Uri.parse('$baseUrl/put/update_expense.php'),
      body: jsonEncode(expense),
      headers: {"Content-Type": "application/json"},
    );
    return jsonDecode(response.body)['success'];
  }

  static Future<bool> deleteExpense(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/delete/delete_expense.php'),
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
      Uri.parse('$baseUrl/post/log_emergency.php'),
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
      Uri.parse('$baseUrl/get/get_emergencies.php?user_id=$userId'),
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
    required String duration,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/post/set_category_limit.php'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "category": category,
        "limit_amount": limitAmount,
        "duration": duration,
      }),
    );
    return jsonDecode(response.body)['success'];
  }

  static Future<Map<String, double>> getCategoryLimits(
      int userId, String duration) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/get/get_category_limits.php?user_id=$userId&duration=$duration'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return {
        for (var item in data)
          item['category']:
              double.tryParse(item['limit_amount'].toString()) ?? 0.0
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
      Uri.parse('$baseUrl/post/add_allowance.php'),
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
        ? '$baseUrl/get/get_user.php?user_id=$userId'
        : '$baseUrl/get/get_user.php';

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
      Uri.parse('$baseUrl/put/update_user.php'),
      body: jsonEncode({
        "user_id": userId,
        "name": name,
        "avatar": avatar,
        "currency": currency,
        "email": email,
      }),
      headers: {"Content-Type": "application/json"},
    );
    print("Update response: ${response.body}");
    return jsonDecode(response.body)['success'];
  }

  static Future<int?> insertUser({
    required String name,
    required String avatar,
    required String currency,
    String? email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/post/insert_user.php'),
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
