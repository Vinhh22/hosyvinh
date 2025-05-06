import 'package:flutter/material.dart';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:taskmanager/taskManager/model/TaskModel.dart';
import 'package:taskmanager/taskManager/model/UserModel.dart';
import 'package:taskmanager/taskManager/db/TaskDatabase.dart';
import 'package:taskmanager/taskManager/view/TaskFormScreen.dart';
import 'package:taskmanager/main.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final User currentUser;

  const TaskDetailScreen({super.key, required this.task, required this.currentUser});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> with SingleTickerProviderStateMixin {
  late Task _task;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    print('Attachments: ${_task.attachments}');

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );
    _animationController.forward();
  }

  Future<void> _updateStatus(TaskStatus newStatus) async {
    try {
      final updatedTask = _task.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      await TaskDatabase.instance.updateTask(updatedTask);
      setState(() {
        _task = updatedTask;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái: ${_getStatusDisplay(newStatus)}'),
            backgroundColor: Colors.blueAccent,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật trạng thái: $e')),
      );
    }
  }

  Future<void> _editTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(
          currentUser: widget.currentUser,
          task: _task,
        ),
      ),
    );

    if (result == true) {
      final updatedTask = await TaskDatabase.instance.getTask(_task.id);
      if (updatedTask != null) {
        setState(() {
          _task = updatedTask;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật công việc'),
              backgroundColor: Colors.blueAccent,
            ),
          );
          Navigator.pop(context, true);
        }
      }
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

  bool _isImageFile(String path) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp'];
    final isImage = imageExtensions.any((ext) => path.toLowerCase().endsWith(ext));
    print('Checking path: $path, isImage: $isImage');
    return isImage;
  }

  Color _getPriorityColor() {
    switch (_task.priority) {
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.orangeAccent;
      case 3:
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
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
                          'Chi tiết Công việc',
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
                        Row(
                          children: [
                            _buildIconButton(
                              icon: Icons.edit,
                              onPressed: _editTask,
                              tooltip: 'Chỉnh sửa',
                            ),
                            const SizedBox(width: 12),
                            _buildIconButton(
                              icon: themeSwitching.isDarkMode
                                  ? Icons.brightness_7
                                  : Icons.brightness_4,
                              onPressed: themeSwitching.toggleTheme,
                              tooltip: 'Đổi giao diện',
                            ),
                          ],
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getPriorityColor().withOpacity(0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  _task.title,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontFamily: 'Montserrat',
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildDetailCard('Mô tả', _task.description),
                          _buildDetailCard('Trạng thái', _getStatusDisplay(_task.status)),
                          _buildDetailCard('Độ ưu tiên', _priorityToString(_task.priority)),
                          _buildDetailCard(
                            'Hạn hoàn thành',
                            _task.dueDate != null
                                ? _task.dueDate.toString().split(' ')[0]
                                : 'Không có',
                          ),
                          _buildDetailCard(
                            'Thời gian tạo',
                            _task.createdAt.toString().split('.')[0],
                          ),
                          _buildDetailCard(
                            'Cập nhật gần nhất',
                            _task.updatedAt.toString().split('.')[0],
                          ),
                          _buildDetailCard('Người được giao', _task.assignedTo ?? 'Không có'),
                          _buildDetailCard('Người tạo', _task.createdBy),
                          _buildDetailCard('Danh mục', _task.category ?? 'Không có'),
                          _buildDetailCard('Hoàn thành', _task.completed ? 'Có' : 'Không'),
                          const SizedBox(height: 32),
                          Text(
                            'Tệp đính kèm',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _task.attachments != null && _task.attachments!.isNotEmpty
                              ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_task.attachments!.any(_isImageFile))
                                Column(
                                  children: [
                                    CarouselSlider(
                                      options: CarouselOptions(
                                        height: 240,
                                        enlargeCenterPage: true,
                                        enableInfiniteScroll: false,
                                        viewportFraction: 0.75,
                                        onPageChanged: (index, reason) {
                                          setState(() {
                                            _currentCarouselIndex = index;
                                          });
                                        },
                                      ),
                                      items: _task.attachments!
                                          .where(_isImageFile)
                                          .map((attachment) => GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => Dialog(
                                              backgroundColor:
                                              Colors.transparent,
                                              child: ClipRRect(
                                                borderRadius:
                                                BorderRadius.circular(20),
                                                child: Image.file(
                                                  File(attachment),
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context,
                                                      error, stackTrace) {
                                                    return const Text(
                                                      'Không thể tải hình ảnh',
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          margin:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                            BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.3),
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                                blurRadius: 15,
                                                spreadRadius: 3,
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                            BorderRadius.circular(18),
                                            child: Image.file(
                                              File(attachment),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                  stackTrace) {
                                                return const Center(
                                                  child: Text(
                                                    'Không thể tải',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ))
                                          .toList(),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '${_currentCarouselIndex + 1}/${_task.attachments!.where(_isImageFile).length}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: _task.attachments!
                                    .where((attachment) => !_isImageFile(attachment))
                                    .map((attachment) => Chip(
                                  label: Text(
                                    attachment.split('/').last,
                                    style: const TextStyle(
                                        color: Colors.white),
                                  ),
                                  backgroundColor: Colors.blueAccent
                                      .withOpacity(0.4),
                                  avatar: Icon(
                                    Icons.insert_drive_file,
                                    color:
                                    Colors.white.withOpacity(0.7),
                                    size: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: Colors.white
                                            .withOpacity(0.2)),
                                  ),
                                  elevation: 5,
                                  shadowColor: Colors.black
                                      .withOpacity(0.2),
                                ))
                                    .toList(),
                              ),
                            ],
                          )
                              : Text(
                            'Không có tệp đính kèm',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.7),
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Cập nhật trạng thái',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<TaskStatus>(
                            value: _task.status,
                            decoration: InputDecoration(
                              hintText: 'Trạng thái',
                              hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.6)),
                              prefixIcon: const Icon(Icons.check_circle,
                                  color: Colors.white70, size: 24),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.15),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 18, horizontal: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                    color: Colors.blueAccent, width: 2),
                              ),
                            ),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Montserrat'),
                            dropdownColor: themeSwitching.isDarkMode
                                ? Colors.grey[800]
                                : Colors.white.withOpacity(0.9),
                            isExpanded: true,
                            items: TaskStatus.values
                                .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(_getStatusDisplay(status)),
                            ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _updateStatus(value);
                              }
                            },
                          ),
                        ],
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

  Widget _buildDetailCard(String label, String value) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'Montserrat',
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
}