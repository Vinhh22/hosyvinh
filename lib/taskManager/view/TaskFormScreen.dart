import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:taskmanager/taskManager/db/TaskDatabase.dart';
import 'package:taskmanager/taskManager/model/TaskModel.dart';
import 'package:taskmanager/taskManager/model/UserModel.dart';
import 'package:taskmanager/main.dart';

class TaskFormScreen extends StatefulWidget {
  final User currentUser;
  final Task? task;

  const TaskFormScreen({super.key, required this.currentUser, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  TaskStatus _status = TaskStatus.chuaLam;
  String _priority = 'Trung bình';
  DateTime? _dueDate;
  List<String> _attachments = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _categoryController = TextEditingController(text: widget.task?.category ?? '');
    _status = widget.task?.status ?? TaskStatus.chuaLam;
    _priority = widget.task != null ? _priorityToString(widget.task!.priority) : 'Trung bình';
    _dueDate = widget.task?.dueDate;
    _attachments = widget.task?.attachments ?? [];
    print('Initial attachments: $_attachments');

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );
    _animationController.forward();
  }

  String _priorityToString(int priority) {
    switch (priority) {
      case 1:
        return 'Cao';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Thấp';
      default:
        return 'Trung bình';
    }
  }

  int _stringToPriority(String priority) {
    switch (priority) {
      case 'Cao':
        return 1;
      case 'Trung bình':
        return 2;
      case 'Thấp':
        return 3;
      default:
        return 2;
    }
  }

  String _getStatusDisplay(TaskStatus status) {
    switch (status) {
      case TaskStatus.chuaLam:
        return 'Chưa làm';
      case TaskStatus.dangLam:
        return 'Đang làm';
      case TaskStatus.hoanThanh:
        return 'Hoàn thành';
      case TaskStatus.daHuy:
        return 'Đã hủy';
    }
  }

  Future<void> _pickDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[900]!.withOpacity(0.9),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _dueDate = pickedDate;
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _attachments.add(pickedFile.path);
        print('Added camera image: ${pickedFile.path}');
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _attachments.add(pickedFile.path);
        print('Added gallery image: ${pickedFile.path}');
      });
    }
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['doc', 'docx', 'pdf'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _attachments.addAll(result.paths.map((path) => path!).toList());
        print('Added documents: ${result.paths}');
      });
    }
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: widget.task?.id ?? const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        status: _status,
        priority: _stringToPriority(_priority),
        dueDate: _dueDate,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        assignedTo: widget.currentUser.id,
        createdBy: widget.currentUser.id,
        category: _categoryController.text.isEmpty ? null : _categoryController.text,
        attachments: _attachments.isEmpty ? null : _attachments,
        completed: widget.task?.completed ?? false,
      );

      try {
        if (widget.task == null) {
          await TaskDatabase.instance.insertTask(task);
        } else {
          await TaskDatabase.instance.updateTask(task);
        }
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu công việc: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeSwitching = ThemeSwitchingWidget.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: themeSwitching.isDarkMode
                ? [Colors.grey[900]!, Colors.blueGrey[900]!, Colors.indigo[900]!]
                : [Colors.blue[600]!, Colors.purple[600]!, Colors.pink[400]!],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.task == null ? 'Công việc' : 'Chỉnh sửa Công việc',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.blueAccent,
                                blurRadius: 15,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                        _buildIconButton(
                          icon: themeSwitching.isDarkMode
                              ? Icons.brightness_7
                              : Icons.brightness_4,
                          onPressed: themeSwitching.toggleTheme,
                          tooltip: 'Đổi giao diện',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: themeSwitching.isDarkMode
                            ? Colors.black.withOpacity(0.35)
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 50,
                            spreadRadius: 5,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildTextFormField(
                              controller: _titleController,
                              hintText: 'Tiêu đề',
                              icon: Icons.title,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập tiêu đề';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildTextFormField(
                              controller: _descriptionController,
                              hintText: 'Mô tả',
                              icon: Icons.description,
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập mô tả';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<TaskStatus>(
                              value: _status,
                              decoration: _buildInputDecoration(
                                hintText: 'Trạng thái',
                                icon: Icons.check_circle,
                              ),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Montserrat'),
                              dropdownColor: themeSwitching.isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.white.withOpacity(0.9),
                              items: TaskStatus.values
                                  .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(
                                  _getStatusDisplay(status),
                                  style: const TextStyle(
                                      fontFamily: 'Montserrat'),
                                ),
                              ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _status = value;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value: _priority,
                              decoration: _buildInputDecoration(
                                hintText: 'Độ ưu tiên',
                                icon: Icons.priority_high,
                              ),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Montserrat'),
                              dropdownColor: themeSwitching.isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.white.withOpacity(0.9),
                              items: const [
                                DropdownMenuItem(
                                    value: 'Cao',
                                    child: Text('Cao', style: TextStyle(fontFamily: 'Montserrat'))),
                                DropdownMenuItem(
                                    value: 'Trung bình',
                                    child:
                                    Text('Trung bình', style: TextStyle(fontFamily: 'Montserrat'))),
                                DropdownMenuItem(
                                    value: 'Thấp',
                                    child: Text('Thấp', style: TextStyle(fontFamily: 'Montserrat'))),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _priority = value;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildTextFormField(
                              controller: _categoryController,
                              hintText: 'Danh mục (tùy chọn)',
                              icon: Icons.category,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Hạn hoàn thành: ${_dueDate != null ? _dueDate.toString().split(' ')[0] : 'Chưa chọn'}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 16,
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                ),
                                _buildSmallButton(
                                  text: 'Chọn ngày',
                                  onPressed: _pickDueDate,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tệp đính kèm:',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'camera') {
                                      _pickImageFromCamera();
                                    } else if (value == 'gallery') {
                                      _pickImageFromGallery();
                                    } else if (value == 'document') {
                                      _pickDocument();
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    const PopupMenuItem(
                                      value: 'camera',
                                      child: Text('Chụp ảnh từ camera',
                                          style: TextStyle(fontFamily: 'Montserrat')),
                                    ),
                                    const PopupMenuItem(
                                      value: 'gallery',
                                      child: Text('Chọn ảnh từ thư viện',
                                          style: TextStyle(fontFamily: 'Montserrat')),
                                    ),
                                    const PopupMenuItem(
                                      value: 'document',
                                      child: Text('Chọn tài liệu (Word, PDF)',
                                          style: TextStyle(fontFamily: 'Montserrat')),
                                    ),
                                  ],
                                  child: _buildSmallButton(
                                    text: 'Thêm tệp',
                                    onPressed: null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _attachments.isNotEmpty
                                ? Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _attachments
                                  .map((attachment) => Chip(
                                label: Text(
                                  attachment.split('/').last,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Montserrat'),
                                ),
                                backgroundColor:
                                Colors.blueAccent.withOpacity(0.4),
                                avatar: Icon(
                                  Icons.insert_drive_file,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color:
                                      Colors.white.withOpacity(0.2)),
                                ),
                                elevation: 5,
                                shadowColor:
                                Colors.black.withOpacity(0.2),
                                deleteIconColor: Colors.white,
                                onDeleted: () {
                                  setState(() {
                                    _attachments.remove(attachment);
                                  });
                                },
                              ))
                                  .toList(),
                            )
                                : Text(
                              'Chưa có tệp đính kèm',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            const SizedBox(height: 32),
                            AnimatedScale(
                              scale: _formKey.currentState?.validate() == true ? 1.0 : 0.95,
                              duration: const Duration(milliseconds: 300),
                              child: SizedBox(
                                width: double.infinity,
                                height: 64,
                                child: ElevatedButton(
                                  onPressed: _saveTask,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent.withOpacity(0.95),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    elevation: 15,
                                    shadowColor: Colors.black.withOpacity(0.4),
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    textStyle: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Montserrat',
                                    ),
                                    side: BorderSide(
                                        color: Colors.blueAccent.withOpacity(0.4),
                                        width: 2),
                                  ),
                                  child: Text(
                                    widget.task == null ? 'Tạo' : 'Lưu',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.6), fontFamily: 'Montserrat'),
      prefixIcon: Icon(icon, color: Colors.white70, size: 24),
      filled: true,
      fillColor: Colors.white.withOpacity(0.15),
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: _buildInputDecoration(hintText: hintText, icon: icon),
      style: const TextStyle(
          color: Colors.white, fontSize: 16, fontFamily: 'Montserrat'),
      validator: validator,
    );
  }

  Widget _buildSmallButton({required String text, required VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
        side: BorderSide(color: Colors.blueAccent.withOpacity(0.4), width: 1.5),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat'),
      ),
    );
  }

  Widget _buildIconButton(
      {required IconData icon, required VoidCallback onPressed, required String tooltip}) {
    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 200),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}