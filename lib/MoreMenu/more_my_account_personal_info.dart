import 'package:flutter/material.dart';
import '../Common/select_edit_box.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PersonalInfoPage(),
      /*theme: ThemeData(
        primarySwatch: Colors.orange,
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),*/
    );
  }
}

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  PersonalInfoPageState createState() => PersonalInfoPageState();
}

class PersonalInfoPageState extends State<PersonalInfoPage> {
  bool _showOriginalPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  // 存储地址列表，包含 id 和地址信息
  final List<Map<String, String>> _addresses = [
    {'id': 'home_address', 'label': 'Home', 'value': 'Ghelph St Manitoba MB'},
    {'id': 'work_address', 'label': 'Work', 'value': 'Grant Park St Manitoba MB'},
  ];
  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    // 默认选中“Home”地址
    _selectedAddressId = 'home_address';
  }

  // 处理地址选择
  void _handleAddressSelection(String id) {
    setState(() {
      _selectedAddressId = id;
    });
    print('Selected address: $id');
  }

  // 删除地址
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
              _buildTextField('First Name *', 'Ethan', true),
              SizedBox(height: 10),
              _buildTextField('Last Name *', 'Yang', true),
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
              // 使用 ListView.builder 渲染可删除的地址列表
              ..._addresses.map((address) {
                return Dismissible(
                  key: Key(address['id']!),
                  direction: DismissDirection.endToStart, // 向左拖动删除
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
              _buildPasswordField('Original*', _showOriginalPassword, (value) {
                setState(() {
                  _showOriginalPassword = value;
                });
              }),
              SizedBox(height: 10),
              _buildPasswordField('New*', _showNewPassword, (value) {
                setState(() {
                  _showNewPassword = value;
                });
              }),
              SizedBox(height: 10),
              _buildPasswordField('Confirm*', _showConfirmPassword, (value) {
                setState(() {
                  _showConfirmPassword = value;
                });
              }),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
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

  Widget _buildTextField(String label, String value, bool isLocked) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (isLocked) Icon(Icons.lock, color: Colors.grey[600]),
        ],
      ),
    );
  }

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

  Widget _buildPasswordField(String label, bool isVisible, Function(bool) onToggle) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 1),
              SizedBox(
                width: 200,
                child: TextField(
                  obscureText: !isVisible,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '********',
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey[600],
            ),
            onPressed: () {
              onToggle(!isVisible);
            },
          ),
        ],
      ),
    );
  }
}