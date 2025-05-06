import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../db/TaskDatabase.dart';
import '../model/TaskModel.dart';
import '../model/UserModel.dart';
import 'TaskDetailScreen.dart';
import 'TaskFormScreen.dart';
import 'TaskItem.dart';
import 'package:taskmanager/main.dart';

class TaskListScreen extends StatefulWidget {
  final User currentUser;

  const TaskListScreen({super.key, required this.currentUser});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with SingleTickerProviderStateMixin {
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  final _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedCategory;
  late AnimationController _animationController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _loadTasks();
    _searchController.addListener(_filterTasks);
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final tasks = await TaskDatabase.instance.getAllTasks(widget.currentUser.id);
      setState(() {
        _tasks = tasks;
        _filteredTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi khi tải công việc: $e',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
            ),
          ),
        );
      }
    }
  }

  Future<void> _filterTasks() async {
    final keyword = _searchController.text;
    try {
      final tasks = await TaskDatabase.instance.searchTasks(
        keyword: keyword.isEmpty ? null : keyword,
        status: _selectedStatus,
        category: _selectedCategory,
        createdBy: widget.currentUser.id,
      );
      setState(() {
        _filteredTasks = tasks;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi khi lọc công việc: $e',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
            ),
          ),
        );
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _selectedCategory = null;
      _filteredTasks = _tasks;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Xác nhận đăng xuất',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất?',
          style: GoogleFonts.poppins(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: GoogleFonts.poppins(color: Colors.blueAccent, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Đăng xuất',
              style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      Navigator.pushReplacementNamed(context, '/login');
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

  @override
  void dispose() {
    _searchController.dispose();
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: themeSwitching.isDarkMode
                ? [Colors.grey[900]!, Colors.blueGrey[900]!, Colors.indigo[900]!]
                : [Colors.blue[400]!, Colors.purple[400]!, Colors.pink[300]!],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 134,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'DANH SÁCH CÔNG VIỆC ',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.4),
                          offset: const Offset(2, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: themeSwitching.isDarkMode
                          ? [Colors.grey[800]!, Colors.blueGrey[800]!]
                          : [Colors.blue[500]!, Colors.purple[500]!],
                    ),
                  ),
                ),
              ),
              actions: [
                _buildIconButton(
                  icon: Icons.refresh,
                  onPressed: _resetFilters,
                  tooltip: 'Đặt lại bộ lọc',
                ),
                const SizedBox(width: 8),
                _buildIconButton(
                  icon: themeSwitching.isDarkMode ? Icons.brightness_7 : Icons.brightness_4,
                  onPressed: themeSwitching.toggleTheme,
                  tooltip: 'Đổi giao diện',
                ),
                const SizedBox(width: 8),
                _buildIconButton(
                  icon: Icons.logout,
                  onPressed: _logout,
                  tooltip: 'Đăng xuất',
                ),
                const SizedBox(width: 16),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm công việc...',
                        hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.6), fontSize: 15),
                        prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 24),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.15),
                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: _buildInputDecoration(hintText: 'Trạng thái', icon: Icons.check_circle),
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                            dropdownColor: themeSwitching.isDarkMode ? Colors.grey[800] : Colors.white.withOpacity(0.9),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text('Tất cả trạng thái', style: GoogleFonts.poppins(fontSize: 15)),
                              ),
                              ...TaskStatus.values.map((status) => DropdownMenuItem(
                                value: status.toString().split('.').last,
                                child: Text(_getStatusDisplay(status), style: GoogleFonts.poppins(fontSize: 15)),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value;
                                _filterTasks();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: _buildInputDecoration(hintText: 'Danh mục', icon: Icons.category),
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                            dropdownColor: themeSwitching.isDarkMode ? Colors.grey[800] : Colors.white.withOpacity(0.9),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text('Tất cả danh mục', style: GoogleFonts.poppins(fontSize: 15)),
                              ),
                              ..._tasks
                                  .map((task) => task.category)
                                  .where((category) => category != null)
                                  .toSet()
                                  .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category!, style: GoogleFonts.poppins(fontSize: 15)),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                                _filterTasks();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              sliver: _isLoading
                  ? const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    ),
                  ),
                ),
              )
                  : _filteredTasks.isEmpty
                  ? SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Không có công việc nào',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
                  : SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => Center(
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) => Opacity(
                        opacity: _animationController.value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - _animationController.value)),
                          child: child,
                        ),
                      ),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600), // Giới hạn chiều rộng tối đa
                        child: TaskItem(
                          task: _filteredTasks[index],
                          onDelete: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.white.withOpacity(0.95),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Text(
                                  'Xác nhận xóa',
                                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                                  textAlign: TextAlign.center,
                                ),
                                content: Text(
                                  'Bạn có chắc chắn muốn xóa công việc "${_filteredTasks[index].title}" không?',
                                  style: GoogleFonts.poppins(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text(
                                      'Hủy',
                                      style: GoogleFonts.poppins(color: Colors.blueAccent, fontSize: 13),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text(
                                      'Xóa',
                                      style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              try {
                                await TaskDatabase.instance.deleteTask(_filteredTasks[index].id);
                                _loadTasks();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Đã xóa công việc',
                                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                                      ),
                                      backgroundColor: Colors.blueAccent,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Lỗi khi xóa công việc: $e',
                                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                                      ),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          onToggleComplete: () async {
                            final task = _filteredTasks[index];
                            final updatedTask = task.copyWith(
                              completed: !task.completed,
                              updatedAt: DateTime.now(),
                            );
                            await TaskDatabase.instance.updateTask(updatedTask);
                            _loadTasks();
                          },
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskDetailScreen(
                                  task: _filteredTasks[index],
                                  currentUser: widget.currentUser,
                                ),
                              ),
                            );
                            if (result == true) {
                              _loadTasks();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  childCount: _filteredTasks.length,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) => Transform.scale(
          scale: _animationController.value,
          child: child,
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TaskFormScreen(currentUser: widget.currentUser),
              ),
            );
            if (result == true) {
              _loadTasks();
            }
          },
          backgroundColor: Colors.blueAccent,
          elevation: 12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          label: Text(
            'Thêm công việc',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          icon: const Icon(Icons.add, color: Colors.white, size: 24),
          tooltip: 'Thêm công việc mới',
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.6), fontSize: 15),
      prefixIcon: Icon(icon, color: Colors.white70, size: 24),
      filled: true,
      fillColor: Colors.white.withOpacity(0.15),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onPressed, required String tooltip}) {
    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 200),
      child: Tooltip(
        message: tooltip,
        textStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}