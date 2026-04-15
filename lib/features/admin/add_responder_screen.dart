import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../models/responder.dart';
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import '../../services/user_repository.dart';
import '../../firebase_options.dart';

class AddResponderScreen extends StatefulWidget {
  const AddResponderScreen({super.key});

  @override
  State<AddResponderScreen> createState() => _AddResponderScreenState();
}

class _AddResponderScreenState extends State<AddResponderScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  // Form Fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _specialization = 'medical';
  XFile? _imageFile;
  
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _specializations = ['fire', 'medical', 'police', 'rescue'];

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<String> _uploadToCloudinary() async {
    if (_imageFile == null) throw Exception("No image selected");

    const String cloudName = "dvr7yfbgr"; 
    const String uploadPreset = "civicpulse"; 
    
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
    
    final request = http.MultipartRequest("POST", url);
    request.fields['upload_preset'] = uploadPreset;
    
    if (kIsWeb) {
      final bytes = await _imageFile!.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        bytes, 
        filename: 'upload.jpg'
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));
    }

    final response = await request.send();
    final responseData = await response.stream.toBytes();
    final responseString = String.fromCharCodes(responseData);
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(responseString);
      return jsonResponse['secure_url'];
    } else {
      Map<String, dynamic> jsonError = {};
      try {
        jsonError = jsonDecode(responseString);
      } catch (_) {}
      final message = jsonError['error']?['message'] ?? "Upload failed with status ${response.statusCode}";
      throw Exception("Cloudinary Error: $message");
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _imageFile == null) {
      if (_imageFile == null) {
        setState(() => _errorMessage = "Please upload a profile image");
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    FirebaseApp? secondaryApp;
    try {
      // 1. Upload Image
      final imageUrl = await _uploadToCloudinary();

      // 2. Create User in Firebase Auth (Secondary Instance to avoid signing out admin)
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final String uid = userCredential.user!.uid;

      // 3. Create Responder document in Firestore
      final responder = Responder(
        id: uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        imageUrl: imageUrl,
        specialization: _specialization,
        latitude: 0.0,
        longitude: 0.0,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      await _firestoreService.addResponder(responder);

      // 4. Create AppUser document in 'users' collection for unified login
      final userRepository = UserRepository(); // Existing service
      final appUser = AppUser(
        uid: uid,
        email: _emailController.text.trim(),
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        photoUrl: imageUrl,
        role: 'responder',
        lastActive: DateTime.now(),
      );
      await userRepository.saveUser(appUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Responder added successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1D2A),
      appBar: AppBar(
        title: const Text("ADD NEW RESPONDER", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2435),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image Picker
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white10,
                            backgroundImage: _imageFile != null 
                              ? (kIsWeb 
                                  // For web, use NetworkImage with a blob URL if needed, 
                                  // but here we can just skip or use a placeholder for simplicity 
                                  // or use a specialized preview widget.
                                  // However, for this fix I'll just use a simple approach.
                                  ? NetworkImage(_imageFile!.path) as ImageProvider
                                  : FileImage(File(_imageFile!.path)))
                              : null,
                            child: _imageFile == null 
                                ? const Icon(Icons.add_a_photo_rounded, size: 40, color: Colors.blueAccent) 
                                : null,
                          ),
                          if (_imageFile != null)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                                child: const Icon(Icons.edit, size: 16, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),

                  _buildTextField("FULL NAME", _nameController, Icons.person_rounded),
                  _buildTextField("EMAIL ADDRESS", _emailController, Icons.email_rounded, keyboardType: TextInputType.emailAddress),
                  _buildTextField("PASSWORD", _passwordController, Icons.lock_rounded, isPassword: true),
                  _buildTextField("PHONE NUMBER", _phoneController, Icons.phone_rounded, keyboardType: TextInputType.phone),

                  const Text("SPECIALIZATION", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _specialization,
                    dropdownColor: const Color(0xFF0D2435),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black12,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.stars_rounded, color: Colors.blueAccent, size: 20),
                    ),
                    items: _specializations.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                    onChanged: (val) => setState(() => _specialization = val!),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text("CREATE ACCOUNT", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isPassword = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black12,
            prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          validator: (value) => value == null || value.isEmpty ? "Required" : null,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
