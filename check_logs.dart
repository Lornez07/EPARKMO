import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://firestore.googleapis.com/v1/projects/e-park-mo-fe42a/databases/(default)/documents/parkingLogs');
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final docs = data['documents'] as List<dynamic>?;
      if (docs == null) {
         print('0 DOCS in parkingLogs!');
      } else {
         print('FOUND ${docs.length} DOCS!');
      }
    } else {
      print('ERROR: ${response.body}');
    }
  } catch (e) {
    print('EXCEPTION: $e');
  }
}
