import 'package:flutter/material.dart';
import '../Common/select_edit_box.dart';
import '../Common/editable_field.dart'; // 导入 EditableField widget
import '../Common/password_field.dart'; // 导入 PasswordField widget

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PersonalInfoPage(),
      // ... (theme 保持不变)
    );
  }
}

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  PersonalInfoPageState createState() => PersonalInfoPageState();
}

class PersonalInfoPageState extends State<PersonalInfoPage> {
  // 定义密码字段的可见性状态
  bool _showOriginalPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  // Controllers for editable profile fields
  final TextEditingController _firstNameController = TextEditingController(text: 'Ethan');
  final TextEditingController _lastNameController = TextEditingController(text: 'Yang');
  // Controllers for password fields
  final TextEditingController _originalPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();


  final List<Map<String, String>> _addresses = [
    {'id': 'home_address', 'label': 'Home', 'value': 'Ghelph St Manitoba MB'},
    {'id': 'work_address', 'label': 'Work', 'value': 'Grant Park St Manitoba MB'},
  ];
  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    _selectedAddressId = 'home_address';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _originalPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleAddressSelection(String id) {
    setState(() {
      _selectedAddressId = id;
    });
    print('Selected address: $id');
  }

  void _deleteAddress(String id) {
    setState(() {
      _addresses.removeWhere((address) => address['id'] == id);
      if (_selectedAddressId == id) {
        _selectedAddressId = _addresses.isNotEmpty ? _addresses[0]['id'] : null;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Address deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.deepOrange,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'PERSONAL INFO',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              // 使用 EditableField widget
              EditableField(
                label: 'First Name *',
                controller: _firstNameController,
                isLocked: false, // 现在默认为 false，更符合编辑需求
              ),
              SizedBox(height: 10),
              EditableField(
                label: 'Last Name *',
                controller: _lastNameController,
                isLocked: false,
              ),
              SizedBox(height: 10),
              SelectEditBox(
                key: const ValueKey('phone_number_field'),
                label: 'Phone number *',
                value: '431232345',
                onTap: () => print('Show edit dialog for Phone number.'),
                onIconTap: () {
                  print('Show Dialog for Phone number.');
                },
              ),
              SizedBox(height: 10),
              SelectEditBox(
                key: const ValueKey('email_address_field'),
                label: 'Email Address *',
                value: 'veinyyang@gmail.com',
                onTap: () => print('Show edit dialog for Email Address.'),
                onIconTap: () {
                  print('Show Dialog for Email Address.');
                },
              ),
              SizedBox(height: 20),
              Text(
                'Delibery Address List',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ..._addresses.map((address) {
                return Dismissible(
                  key: Key(address['id']!),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _deleteAddress(address['id']!);
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20.0),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  child: SelectEditBox(
                    key: Key('${address['id']}_select'),
                    id: address['id'],
                    label: address['label']!,
                    value: address['value']!,
                    isSelected: _selectedAddressId == address['id'],
                    onTap: () => _handleAddressSelection(address['id']!),
                    onIconTap: () {
                      print('Edit ${address['value']}');
                    },
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Confirm Delete'),
                        content: Text('Are you sure you want to delete this address?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
              SizedBox(height: 10),
              _buildAddAddressButton(),
              SizedBox(height: 20),
              Text(
                'Password',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              // 使用 PasswordField widget
              PasswordField(
                label: 'Original*',
                controller: _originalPasswordController,
                isVisible: _showOriginalPassword,
                onToggle: (value) {
                  setState(() {
                    _showOriginalPassword = value;
                  });
                },
              ),
              SizedBox(height: 10),
              PasswordField(
                label: 'New*',
                controller: _newPasswordController,
                isVisible: _showNewPassword,
                onToggle: (value) {
                  setState(() {
                    _showNewPassword = value;
                  });
                },
              ),
              SizedBox(height: 10),
              PasswordField(
                label: 'Confirm*',
                controller: _confirmPasswordController,
                isVisible: _showConfirmPassword,
                onToggle: (value) {
                  setState(() {
                    _showConfirmPassword = value;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Access updated values from controllers
                  print('First Name: ${_firstNameController.text}');
                  print('Last Name: ${_lastNameController.text}');
                  print('Original Password: ${_originalPasswordController.text}');
                  print('New Password: ${_newPasswordController.text}');
                  print('Confirm Password: ${_confirmPasswordController.text}');
                  print('Update profile');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Update',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // _buildEditableTextField 函数已移除
  // _buildPasswordField 函数已移除

  Widget _buildAddAddressButton() {
    return GestureDetector(
      onTap: () {
        print('Add new address');
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Add a new Address',
              style: TextStyle(fontSize: 16, color: Colors.deepOrange),
            ),
            Icon(Icons.add, color: Colors.deepOrange),
          ],
        ),
      ),
    );
  }
}