import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Common/editable_field.dart';
import '../Common/password_field.dart';
import '../Common/select_edit_box.dart';
import '../Controller/service_provider.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  PersonalInfoPageState createState() => PersonalInfoPageState();
}

class PersonalInfoPageState extends State<PersonalInfoPage> {
  bool _showOriginalPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _originalPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final List<Map<String, dynamic>> _addresses = [];
  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPersonalInfo());
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _originalPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonalInfo() async {
    final serviceProvider = context.read<ServiceProvider>();
    if (!serviceProvider.isLoggedIn) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Please log in to view personal info.');
      }
      return;
    }

    setState(() => _isLoading = true);
    final profileData = await serviceProvider.fetchPersonalInfo();
    if (!mounted) return;

    if (profileData == null) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to load personal info.');
      return;
    }

    final user = profileData['user'] as Map<String, dynamic>? ?? {};
    final username = _readUserText(user, ['username']) ?? '';
    final firstName = _readUserText(user, ['first_name', 'firstName']);
    final lastName = _readUserText(user, ['last_name', 'lastName']);
    final phoneNumber = _readUserText(
      user,
      ['phone_number', 'phoneNumber', 'cell_phone', 'phone'],
    );
    final nameParts = _splitUsername(username);
    final addresses = (profileData['addresses'] as List? ?? [])
        .whereType<Map>()
        .map((address) => Map<String, dynamic>.from(address))
        .toList();
    String? selectedAddressId;
    for (final address in addresses) {
      if (address['is_default'] == true) {
        selectedAddressId = address['address_id']?.toString();
        break;
      }
    }
    selectedAddressId ??=
        addresses.isNotEmpty ? addresses.first['address_id']?.toString() : null;

    setState(() {
      _firstNameController.text = firstName ?? nameParts[0];
      _lastNameController.text = lastName ?? nameParts[1];
      _phoneController.text = phoneNumber ?? '';
      _emailController.text = _readUserText(user, ['email']) ?? '';
      _addresses
        ..clear()
        ..addAll(addresses);
      _selectedAddressId = selectedAddressId;
      _isLoading = false;
    });
  }

  String? _readUserText(Map<String, dynamic> user, List<String> keys) {
    for (final key in keys) {
      final value = user[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  List<String> _splitUsername(String username) {
    final parts = username.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return ['', ''];
    if (parts.length == 1) return [parts.first, ''];
    return [parts.first, parts.sublist(1).join(' ')];
  }

  String _formatAddress(Map<String, dynamic> address) {
    return [
      address['street'],
      address['district'],
      address['city'],
      address['province'],
      address['country'],
      address['postal_code'],
    ]
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .map((value) => value.toString())
        .join(', ');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleAddressSelection(String id) async {
    setState(() {
      _selectedAddressId = id;
      for (final address in _addresses) {
        address['is_default'] = address['address_id']?.toString() == id;
      }
    });

    final success = await context.read<ServiceProvider>().setDefaultAddress(id);
    if (!mounted) return;
    if (!success) {
      _showSnackBar('Failed to set default address.');
      await _loadPersonalInfo();
    }
  }

  Future<void> _deleteAddress(String id) async {
    final success = await context.read<ServiceProvider>().deleteAddress(id);
    if (!mounted) return;

    if (success) {
      setState(() {
        _addresses.removeWhere(
          (address) => address['address_id']?.toString() == id,
        );
        if (_selectedAddressId == id) {
          _selectedAddressId = _addresses.isNotEmpty
              ? _addresses.first['address_id']?.toString()
              : null;
        }
      });
      _showSnackBar('Address deleted.');
    } else {
      _showSnackBar('Failed to delete address.');
      await _loadPersonalInfo();
    }
  }

  Future<void> _saveProfile() async {
    if (_phoneController.text.trim().isEmpty) {
      _showSnackBar('Phone number is required.');
      return;
    }

    final wantsPasswordChange = _originalPasswordController.text.isNotEmpty ||
        _newPasswordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty;
    if (wantsPasswordChange &&
        _newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('New passwords do not match.');
      return;
    }

    setState(() => _isSaving = true);
    final response = await context.read<ServiceProvider>().updatePersonalInfo(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          cellPhone: _phoneController.text,
          originalPassword:
              wantsPasswordChange ? _originalPasswordController.text : null,
          newPassword: wantsPasswordChange ? _newPasswordController.text : null,
          confirmPassword:
              wantsPasswordChange ? _confirmPasswordController.text : null,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (response == null) {
      _showSnackBar('Failed to update personal info.');
      return;
    }

    _originalPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _showSnackBar('Personal info updated.');
    await _loadPersonalInfo();
  }

  Future<void> _openAddressDialog({Map<String, dynamic>? address}) async {
    final addressData = await _showAddressDialog(address: address);
    if (addressData == null || !mounted) return;

    final serviceProvider = context.read<ServiceProvider>();
    final response = address == null
        ? await serviceProvider.createAddress(addressData)
        : await serviceProvider.updateAddress({
            ...addressData,
            'address_id': address['address_id']?.toString(),
          });

    if (!mounted) return;
    if (response == null) {
      _showSnackBar(address == null
          ? 'Failed to add address.'
          : 'Failed to update address.');
      return;
    }

    _showSnackBar(address == null ? 'Address added.' : 'Address updated.');
    await _loadPersonalInfo();
  }

  Future<Map<String, dynamic>?> _showAddressDialog({
    Map<String, dynamic>? address,
  }) async {
    final receiverController = TextEditingController(
      text: address?['receiver_name']?.toString() ??
          '${_firstNameController.text} ${_lastNameController.text}'.trim(),
    );
    final countryController = TextEditingController(
      text: address?['country']?.toString() ?? 'CA',
    );
    final provinceController = TextEditingController(
      text: address?['province']?.toString() ?? '',
    );
    final cityController = TextEditingController(
      text: address?['city']?.toString() ?? '',
    );
    final districtController = TextEditingController(
      text: address?['district']?.toString() ?? '',
    );
    final streetController = TextEditingController(
      text: address?['street']?.toString() ?? '',
    );
    final postalCodeController = TextEditingController(
      text: address?['postal_code']?.toString() ?? '',
    );
    bool isDefault = address?['is_default'] == true || _addresses.isEmpty;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(address == null ? 'Add Address' : 'Edit Address'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogTextField('Receiver Name', receiverController),
                    _dialogTextField('Street *', streetController),
                    _dialogTextField('City', cityController),
                    _dialogTextField('Province / State', provinceController),
                    _dialogTextField('District', districtController),
                    _dialogTextField('Postal Code', postalCodeController),
                    _dialogTextField('Country', countryController),
                    CheckboxListTile(
                      value: isDefault,
                      onChanged: (value) {
                        setDialogState(() => isDefault = value ?? false);
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Default delivery address'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (streetController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Street is required.')),
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, {
                      'receiver_name': receiverController.text.trim(),
                      'country': countryController.text.trim().isEmpty
                          ? 'CA'
                          : countryController.text.trim(),
                      'province': provinceController.text.trim(),
                      'city': cityController.text.trim(),
                      'district': districtController.text.trim(),
                      'street': streetController.text.trim(),
                      'postal_code': postalCodeController.text.trim(),
                      'is_default': isDefault,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    receiverController.dispose();
    countryController.dispose();
    provinceController.dispose();
    cityController.dispose();
    districtController.dispose();
    streetController.dispose();
    postalCodeController.dispose();
    return result;
  }

  Widget _dialogTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteAddress() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Are you sure you want to delete this address?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.deepOrange,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    EditableField(
                      label: 'First Name *',
                      controller: _firstNameController,
                      isLocked: false,
                    ),
                    const SizedBox(height: 10),
                    EditableField(
                      label: 'Last Name *',
                      controller: _lastNameController,
                      isLocked: false,
                    ),
                    const SizedBox(height: 10),
                    EditableField(
                      label: 'Phone number *',
                      controller: _phoneController,
                      isLocked: false,
                    ),
                    const SizedBox(height: 10),
                    EditableField(
                      label: 'Email Address *',
                      controller: _emailController,
                      isLocked: false,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Delivery Address List',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (_addresses.isEmpty)
                      Text(
                        'No delivery address yet.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ..._addresses.map((address) {
                      final addressId = address['address_id']?.toString() ?? '';
                      return Dismissible(
                        key: Key(addressId),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDeleteAddress(),
                        onDismissed: (_) => _deleteAddress(addressId),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          child:
                              const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SelectEditBox(
                            key: Key('${addressId}_select'),
                            id: addressId,
                            label: address['is_default'] == true
                                ? 'Default Delivery Address'
                                : (address['receiver_name']?.toString() ??
                                    'Delivery Address'),
                            value: _formatAddress(address),
                            isSelected: _selectedAddressId == addressId,
                            onTap: () => _handleAddressSelection(addressId),
                            onIconTap: () =>
                                _openAddressDialog(address: address),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 2),
                    _buildAddAddressButton(),
                    const SizedBox(height: 20),
                    const Text(
                      'Password',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _isSaving ? 'Updating...' : 'Update',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAddAddressButton() {
    return GestureDetector(
      onTap: () => _openAddressDialog(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
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
