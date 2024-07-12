import 'package:url_launcher/url_launcher.dart';

void sendEmail(String userEmail) async {
  final Uri emailLaunchUri = Uri(
    scheme: 'mailto',
    path: 'riyanachwani22@gmail.com',
    queryParameters: {
      'subject': 'Leave Request',
      'body': _composeEmailBody(userEmail),
    },
  );


  if (await canLaunchUrl(emailLaunchUri)) {
    await launchUrl(emailLaunchUri);
    print(
        "Email app launched for composing your leave request."); // Informative message
  } else {
    print("Could not launch email app. Please check your email configuration.");
  }
}

String _composeEmailBody(String? userEmail) {
  // Consider using string interpolation for clarity
  return """
Dear Ma'am,

I am writing to request a leave of absence of [Number] [Type of Leave] from [Start Date] to [End Date]. This will be [Total Time Off - e.g., 5 working days, 2 weeks with 10 vacation days]. You can reach [Colleague Name] at [Colleague Email] if needed. Thank you for your consideration.

Sincerely,
${userEmail ?? 'Your Name'}
""";
}
