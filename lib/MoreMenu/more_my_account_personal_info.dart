import 'package:flutter/material.dart';

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
  // 初始时可以设置为 null 或一个默认选中地址的 ID
  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    // 可以在这里设置默认选中的地址，例如默认选中“Home”
    _selectedAddressId = 'home_address';
  }

  // 新增：处理地址选择的函数
  void _handleAddressSelection(String id) {
    setState(() {
      _selectedAddressId = id;
    });
    print('Selected address: $id');
    // 如果你还需要在选中某个地址时执行其他操作，可以在这里添加
    // 例如，弹出对话框提示用户“您已选择此地址为默认地址”等
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
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
              // 这些是非组选择的 SelectEditBox，它们不需要 id 和 isSelected
              SelectEditBox(
                key: const ValueKey('phone_number_field'),
                label: 'Phone number *',
                value: '431232345',
                // 这里 onTap 可以是 null 或者执行其他非选择组操作
                // 例如，显示编辑对话框，而不是将其设为选中状态
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
              // !!! 组选择的 SelectEditBox 配置如下 !!!
              SelectEditBox(
                key: const ValueKey('home_address_field'), // 确保 Key 仍然唯一
                id: 'home_address', // 为“家”地址设置一个唯一ID
                label: 'Home',
                value: 'Ghelph St Manitoba MB',
                // 检查当前 ID 是否与 _selectedAddressId 匹配来设置 isSelected
                isSelected: _selectedAddressId == 'home_address',
                // 当这个框体被点击时，调用 _handleAddressSelection 更新选中状态
                onTap: () => _handleAddressSelection('home_address'),
                onIconTap: () {
                  print('Edit Ghelph St address.');
                },
              ),
              SizedBox(height: 10),
              SelectEditBox(
                key: const ValueKey('work_address_field'), // 确保 Key 仍然唯一
                id: 'work_address', // 为“工作”地址设置一个唯一ID
                label: 'Work',
                value: 'Grant Park St Manitoba MB',
                // 检查当前 ID 是否与 _selectedAddressId 匹配来设置 isSelected
                isSelected: _selectedAddressId == 'work_address',
                // 当这个框体被点击时，调用 _handleAddressSelection 更新选中状态
                onTap: () => _handleAddressSelection('work_address'),
                onIconTap: () {
                  print('Edit Grant Park St Manitoba MB.');
                },
              ),
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
              //SizedBox(height: 4),
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

class SelectEditBox extends StatefulWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;       // 整个框体的点击事件，现在用于通知父级我被选中了
  final VoidCallback onIconTap;   // 右侧图标的点击事件
  final String? id;               // 新增：可选的唯一标识符，用于组选择
  final bool isSelected;          // 新增：由父级控制的选中状态

  const SelectEditBox({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    required this.onIconTap,
    this.id,                      // 允许传入 id
    this.isSelected = false,      // 默认不选中
  });

  @override
  State<SelectEditBox> createState() => _SelectEditBoxState();
}

class _SelectEditBoxState extends State<SelectEditBox> {
  // 移除了 bool _isSelected 状态

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 整个框体的点击事件，直接使用 widget.onTap
      // 这个 onTap 将由父级提供，用于更新父级的选中状态
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          // 根据 widget.isSelected 状态改变边框颜色
          border: Border.all(color: widget.isSelected ? Colors.deepOrange : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.value.isEmpty ? widget.label : widget.value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              color: Colors.deepOrange,
              onPressed: widget.onIconTap,
            ),
          ],
        ),
      ),
    );
  }
}