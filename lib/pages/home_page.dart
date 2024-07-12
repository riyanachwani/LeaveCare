import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:leavecare/utils/email.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:leavecare/utils/routes.dart';
import 'package:leavecare/utils/fetchData.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  String _updatedPhoneNumber = '';
  String _updatedDepartment = '';
  bool _profileClicked = false;
  bool _isDisposed = false;
  String userPhone = '';
  String userDept = '';
  String userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Unknown';
  List<Map<String, dynamic>> _leaveRequests = [];
  String _supervisorName = '';

  String _leaveType = '';

  var _timeOff = '';

  String _supervisorEmail = '';

  @override
  void initState() {
    super.initState();
    fetchData();
    _fetchLeaveRequests();
    _startDateController = TextEditingController();
    _endDateController = TextEditingController();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _isDisposed = true;
    super.dispose();
  }

  Future<void> fetchData() async {
    fetchUserData((phoneNumber, department) {
      setState(() {
        userPhone = phoneNumber;
        userDept = department;
      });
    }, _isDisposed);
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        final formattedDate =
            "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
        controller.text =
            formattedDate; // Update the text field with the selected date
      });
    }
  }

  Future<void> _logout() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    await auth.signOut();
    await _saveLoginStatus(false); // Set login status to false
    Navigator.of(context).pushReplacementNamed(MyRoutes.loginRoute);
  }

  Future<void> _saveLoginStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }

  @override
  Widget build(BuildContext context) {
    fetchData();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: SvgPicture.asset(
          "assets/images/completelogo.svg",
          width: 300,
          height: 60,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_selectedIndex == 0) _buildLeaveRequestForm(context),
            if (_selectedIndex == 1) _buildLeaveHistory(context),
            if (_selectedIndex == 2) _buildLeaveApproval(context),
            if (_selectedIndex == 3) _buildProfileContentCard(context),
          ],
        ),
      ),
      bottomNavigationBar: ClipRect(
        clipBehavior: Clip.antiAlias,
        child: Container(
          color: Color(0xFF69BF6F),
          height: 75,
          padding: EdgeInsets.only(left: 10.0, right: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavBarIcon(CupertinoIcons.house, 0),
              _buildBottomNavBarIcon(CupertinoIcons.time, 1),
              _buildBottomNavBarIcon(CupertinoIcons.ticket_fill, 2),
              _buildBottomNavBarIcon(
                CupertinoIcons.profile_circled,
                3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitLeaveRequest() {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get()
          .then((userDoc) {
        if (userDoc.exists) {
          String supervisorEmail = userDoc['supervisor_email'] ?? '';
          String supervisorName = userDoc['supervisor_name'] ?? '';

          // Create a new leave request object
          Map<String, dynamic> leaveRequest = {
            'leaveType': _leaveType,
            'startDate': _startDateController.text,
            'endDate': _endDateController.text,
            'timeOff': _timeOff,
            'supervisorName': supervisorName,
            'supervisorEmail': supervisorEmail,
            'status': 'Pending',
          };

          // Update the user's document with the new leave request
          FirebaseFirestore.instance.collection('users').doc(userId).update({
            'leave_requests': FieldValue.arrayUnion([leaveRequest]),
          }).then((_) {
            // Refresh leave requests after submission
            _fetchLeaveRequests();

            // Add a leave approval entry in the supervisor's document
            if (supervisorEmail.isNotEmpty) {
              // Create a new leave approval entry
              Map<String, dynamic> newLeaveApproval = {
                'leave_type': _leaveType,
                'start_date': _startDateController.text,
                'end_date': _endDateController.text,
                'time_off': _timeOff,
                'user_email': FirebaseAuth.instance.currentUser?.email ??
                    '', // Add user's email
                'user_phone':
                    userDoc['phone_number'] ?? '', // Add user's phone number
              };

              // Add the new entry to the 'leave_approvals' array in supervisor's document
              FirebaseFirestore.instance
                  .collection('supervisor')
                  .doc(supervisorEmail)
                  .update({
                'leave_approvals': FieldValue.arrayUnion([newLeaveApproval])
              }).then((_) {
                print('Leave approval added successfully.');
              }).catchError((error) {
                print('Error updating leave approvals: $error');
                // Handle the error if other issues occur
              });
            }
          }).catchError((error) {
            // Handle errors if any
            print('Error submitting leave request: $error');
          });
        } else {
          print('User document not found.');
        }
      }).catchError((error) {
        // Handle errors if any
        print('Error fetching user document: $error');
      });
    }
  }

  Widget _buildLeaveApproval(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 5),
            child: Text(
              'Leave Approval',
              style: TextStyle(
                color: Color(0xFF69BF6F),
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 15),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchLeaveApprovals(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No leave approvals found.'));
              } else {
                List<Map<String, dynamic>> leaveApprovals = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: leaveApprovals.length,
                  itemBuilder: (context, index) {
                    final approval = leaveApprovals[index];
                    return _buildLeaveApprovalCard(
                        context, approval, userEmail, index);
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveApprovalCard(BuildContext context,
      Map<String, dynamic> approval, String supervisorEmail, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF69BF6F), Color(0xFF69BF6F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Text(
                  'Leave Type: ${approval['leave_type'] ?? ''}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Start Date: ${approval['start_date'] ?? ''}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'End Date: ${approval['end_date'] ?? ''}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Time Off: ${approval['time_off'] ?? ''}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'From: ${approval['user_email'] ?? ''}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Phone: ${approval['user_phone'] ?? ''}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () {
                            _handleLeaveDecision(
                                context, 'accepted', supervisorEmail, index);
                          },
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            child: Text(
                              "Accept",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF69BF6F),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () {
                            _handleLeaveDecision(
                                context, 'rejected', supervisorEmail, index);
                          },
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            child: Text(
                              "Reject",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF69BF6F),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLeaveDecision(BuildContext context, String decision,
      String supervisorEmail, int index) async {
    try {
      // Fetch the supervisor document
      DocumentReference supervisorDocRef = FirebaseFirestore.instance
          .collection('supervisor')
          .doc(supervisorEmail);
      DocumentSnapshot supervisorDoc = await supervisorDocRef.get();

      if (supervisorDoc.exists) {
        // Get the leave_approvals array
        List<dynamic> leaveApprovals = supervisorDoc['leave_approvals'] ?? [];

        // Remove the element at the specified index
        leaveApprovals.removeAt(index);

        // Update the leave_approvals array in the document
        await supervisorDocRef.update({'leave_approvals': leaveApprovals});

        _showDialog(
            context, 'Leave $decision', 'The leave has been $decision.');
      } else {
        _showDialog(context, 'Error', 'Supervisor document does not exist.');
      }
    } catch (e) {
      _showDialog(context, 'Error',
          'An error occurred while updating the leave status: $e');
    }
  }

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchLeaveApprovals() async {
    String userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    if (userEmail.isNotEmpty) {
      try {
        DocumentSnapshot supervisorDoc = await FirebaseFirestore.instance
            .collection('supervisor')
            .doc(userEmail)
            .get();
        if (supervisorDoc.exists) {
          List<dynamic> leaveApprovals = supervisorDoc['leave_approvals'] ?? [];
          return leaveApprovals.cast<Map<String, dynamic>>();
        } else {
          print('Supervisor document does not exist');
        }
      } catch (e) {
        print('Error fetching leave approvals: $e');
      }
    } else {
      print('User email is empty');
    }
    return []; // Return an empty list if no data is found
  }

  Widget _buildLeaveHistory(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 5),
            child: Text(
              'Leave History',
              style: TextStyle(
                color: Color(0xFF69BF6F),
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 15),
          if (_leaveRequests != null && _leaveRequests.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _leaveRequests.length,
              itemBuilder: (context, index) {
                final request = _leaveRequests[index];
                if (request != null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Card(
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF69BF6F), Colors.white],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 20),
                              Text(
                                'Leave Type: ${request['leave_type'] ?? ''}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Supervisor: ${request['supervisor_name'] ?? ''}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Start Date: ${request['start_date'] ?? ''}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'End Date: ${request['end_date'] ?? ''}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Time Off: ${request['time_off'] ?? ''}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return SizedBox.shrink();
                }
              },
            )
          else
            Center(
              child: Text(
                'No leave requests found.',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeaveRequestForm(BuildContext context) {
    fetchData();
    return Card(
      elevation: 5,
      margin: EdgeInsets.all(15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF69BF6F), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leave Request Form',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15),
              Text(
                'Email: $userEmail',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 15),
              Text(
                'Phone: $userPhone',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 15),
              Text(
                'Department: $userDept',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 15),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Leave Type',
                  labelStyle: TextStyle(
                    color: Color(0xFF1f3921),
                    fontSize: 18,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1f3921)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1f3921)),
                  ),
                ),
                items: ['Vacation', 'Sick Leave', 'Personal Reasons', 'Other']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(color: Colors.black, fontSize: 18),
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  _leaveType = value ?? '';
                },
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      onTap: () {
                        _selectDate(context, _startDateController);
                      },
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        labelStyle: TextStyle(color: Color(0xFF1f3921)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF1f3921)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF1f3921)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: TextFormField(
                      controller: _endDateController,
                      onTap: () {
                        _selectDate(context, _endDateController);
                      },
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        labelStyle: TextStyle(color: Color(0xFF1f3921)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF1f3921)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF1f3921)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Time Off',
                  labelStyle: TextStyle(color: Color(0xFF1f3921)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1f3921)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1f3921)),
                  ),
                ),
                items: [
                  'Multiple Days',
                  'Full Day',
                  'Half Day',
                  'Specific Hours'
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(color: Colors.black, fontSize: 18),
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  _timeOff = value ?? '';
                },
              ),
              SizedBox(height: 15),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Supervisor Name',
                  labelStyle: TextStyle(color: Color(0xFF1f3921)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1f3921)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1f3921)),
                  ),
                ),
                onChanged: (value) {
                  _supervisorName = value;
                },
              ),
              SizedBox(height: 15),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Supervisor Email',
                  labelStyle: TextStyle(color: Color(0xFF1f3921)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1f3921)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1f3921)),
                  ),
                ),
                onChanged: (value) {
                  _supervisorEmail = value;
                },
              ),
              SizedBox(height: 15),
              Material(
                color: Color(0xFF69BF6F),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () {
                    // Call function to save leave request data to Firestore
                    sendEmail(userEmail);
                    _saveLeaveRequestData();
                  },
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: Text(
                      "Send Email",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveLeaveRequestData() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    String supervisorEmail = _supervisorEmail;

    if (userId.isNotEmpty) {
      // Create a new leave request entry
      Map<String, dynamic> newLeaveRequest = {
        'leave_type': _leaveType,
        'start_date': _startDateController.text,
        'end_date': _endDateController.text,
        'time_off': _timeOff,
        'supervisor_name': _supervisorName,
        'supervisor_email': _supervisorEmail,
      };

      // Add the new entry to the 'leave_requests' array
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'leave_requests': FieldValue.arrayUnion([newLeaveRequest])
      });
    }

    if (supervisorEmail.isNotEmpty) {
      // Create a new leave approval entry
      Map<String, dynamic> newLeaveApproval = {
        'leave_type': _leaveType,
        'start_date': _startDateController.text,
        'end_date': _endDateController.text,
        'time_off': _timeOff,
        'user_email': userEmail, // Add user's email
        'user_phone': userPhone, // Add user's phone number
      };

      try {
        // Add the new entry to the 'leave_approvals' array in supervisor's document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(supervisorEmail)
            .update({
          'leave_approvals': FieldValue.arrayUnion([newLeaveApproval])
        });
        print('Leave approval added successfully.');
      } catch (e) {
        print('Error updating leave approvals: $e');
        // Handle the error if other issues occur
      }
    }
  }

  Widget _buildBottomNavBarIcon(IconData icon, int index, {String? text}) {
    return Column(
      children: [
        SizedBox(
          height: 5.0,
          width: 28,
          child: _selectedIndex == index
              ? Container(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20.0),
                        bottomRight: Radius.circular(20.0),
                      ),
                    ),
                  ),
                )
              : SizedBox.shrink(),
        ),
        InkWell(
          onTap: () {
            setState(() {
              if (_selectedIndex == index) {
                if (_selectedIndex == 2) {
                  _profileClicked = !_profileClicked;
                }
              } else {
                _selectedIndex = index;
                _profileClicked = false;
              }
            });
          },
          child: SizedBox(
            height: 50,
            child: Icon(
              icon,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileContentCard(BuildContext context) {
    fetchData();
    return Center(
      child: Container(
        child: Card(
          color: Color(0xFF69BF6F),
          elevation: 5,
          margin: EdgeInsets.all(20),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Text(
                  'Email: $userEmail',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Phone Number: $userPhone',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _showEditDialog(
                            context); // Pass context to showEditDialog function
                      },
                      child: Text('Edit'),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Department: $userDept',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    SizedBox(width: 20),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: _logout,
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            child: Text(
                              "Logout",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF69BF6F),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Profile',
          style: TextStyle(fontSize: 20), // Increase font size
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: userPhone, // Use initial values from Firestore
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(fontSize: 18), // Increase font size
              ),
              style: TextStyle(fontSize: 18), // Increase font size
              onChanged: (value) {
                _updatedPhoneNumber = value;
              },
            ),
            TextFormField(
              initialValue: userDept, // Use initial values from Firestore
              decoration: InputDecoration(
                labelText: 'Department',
                labelStyle: TextStyle(fontSize: 18), // Increase font size
              ),
              style: TextStyle(fontSize: 18), // Increase font size
              onChanged: (value) {
                // Update the department when the user types
                _updatedDepartment = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Save updated values to Firestore
              _saveUserData();
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: TextStyle(fontSize: 18), // Increase font size
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 18), // Increase font size
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchLeaveRequests() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (userDoc.exists) {
          List<dynamic> leaveRequests = userDoc['leave_requests'] ?? [];
          if (!_isDisposed) {
            setState(() {
              _leaveRequests = leaveRequests
                  .cast<Map<String, dynamic>>(); // Cast to the correct type
            });
          }
        }
      } catch (e) {
        // Handle error here
        print('Error fetching leave requests: $e');
        if (!_isDisposed) {
          setState(() {
            _leaveRequests = []; // Clear leave requests
          });
        }
      }
    }
  }

  // Function to save updated user data to Firestore
  void _saveUserData() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      print(userId);
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'Phone Number': _updatedPhoneNumber,
        'Department': _updatedDepartment,
      });
    }
  }
}
