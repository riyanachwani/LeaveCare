import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> fetchUserData(void Function(String, String) setState, bool isDisposed) async {
  try {
    if (isDisposed) return; // Check if the widget is disposed before fetching data
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    DocumentSnapshot<Map<String, dynamic>> userData =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (!isDisposed) { // Check if the widget is still mounted
      if (userData.exists) {
        Map<String, dynamic> data = userData.data() ?? {};
        String phoneNumber = data['Phone Number'] ?? 'Unknown';
        String department = data['Department'] ?? 'Unknown';
        
        // Update the state with the retrieved data
        setState(phoneNumber, department);
      }
    }
  } catch (e) {
    print('Error fetching user data: $e');
  }
}
