import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_config.dart';
import 'firebase_options.dart';

final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool cloudReady = false;

  if (FirebaseConfig.enabled) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      cloudReady = true;
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title ?? 'إشعار جديد';
        final body = message.notification?.body ?? '';
        final messenger = appMessengerKey.currentState;
        if (messenger != null) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(body.isEmpty ? title : '$title\n$body'),
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
      });
    } catch (error) {
      debugPrint('Firebase initialization failed: $error');
    }
  }

  runApp(SajidApp(cloudReady: cloudReady));
}

class AppColors {
  static const background = Color(0xFF08131F);
  static const surface = Color(0xFF102131);
  static const surfaceLight = Color(0xFF172C3D);
  static const primary = Color(0xFF22B8A5);
  static const primaryDark = Color(0xFF087E78);
  static const gold = Color(0xFFE5BD72);
  static const text = Color(0xFFF3F7FA);
  static const muted = Color(0xFF9BAFBD);
  static const danger = Color(0xFFE16D72);
  static const success = Color(0xFF57C69A);
  static const border = Color(0xFF294052);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    surface: AppColors.surface,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme.copyWith(
      primary: AppColors.primary,
      secondary: AppColors.gold,
      surface: AppColors.surface,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'sans-serif',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      centerTitle: false,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      hintStyle: const TextStyle(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        );
      }),
    ),
  );
}

class SajidApp extends StatelessWidget {
  const SajidApp({super.key, required this.cloudReady});
  final bool cloudReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ساجد | الجامعة',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      scaffoldMessengerKey: appMessengerKey,
      home: IntroPage(cloudReady: cloudReady),
    );
  }
}

class IntroPage extends StatefulWidget {
  const IntroPage({super.key, required this.cloudReady});
  final bool cloudReady;

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
    if (widget.cloudReady) {
      Future.delayed(const Duration(milliseconds: 3200), () async {
        if (!mounted) return;
        try {
          await FirebaseMessaging.instance.requestPermission();
          await FirebaseMessaging.instance.subscribeToTopic('all_users');
        } catch (error) {
          debugPrint('FCM permission/subscription failed: $error');
        }
      });
    }
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainShell(cloudReady: widget.cloudReady),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF123C48), AppColors.background, Color(0xFF0A1728)],
          ),
        ),
        child: FadeTransition(
          opacity: _fade,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 94,
                  height: 94,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.gold,
                    size: 46,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'سَاجِد',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'مساحتك لتنظيم يومك الجامعي',
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                ),
                const SizedBox(height: 54),
                const Text(
                  'اللهم صلِّ وسلِّم على نبينا محمد ﷺ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 20,
                    height: 1.8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.055),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '«مَن صَلَّى عَلَيَّ صَلَاةً صَلَّى اللَّهُ عَلَيْهِ بِهَا عَشْرًا»',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 17,
                          height: 1.9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'رواه مسلم',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.cloudReady});
  final bool cloudReady;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const PersonalTasksPage(),
      CommunityPage(cloudReady: widget.cloudReady),
      AdminPage(cloudReady: widget.cloudReady),
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.checklist_rounded),
              selectedIcon: Icon(Icons.checklist_rounded),
              label: 'مهامي',
            ),
            NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign_rounded),
              label: 'الجامعة',
            ),
            NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings_rounded),
              label: 'الإدارة',
            ),
          ],
        ),
      ),
    );
  }
}

class PersonalTask {
  PersonalTask({
    required this.id,
    required this.title,
    this.done = false,
    required this.createdAt,
  });

  final String id;
  final String title;
  bool done;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'done': done,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PersonalTask.fromJson(Map<String, dynamic> json) => PersonalTask(
        id: json['id'] as String,
        title: json['title'] as String,
        done: json['done'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

enum PersonalFilter { all, active, completed }

class PersonalTasksPage extends StatefulWidget {
  const PersonalTasksPage({super.key});

  @override
  State<PersonalTasksPage> createState() => _PersonalTasksPageState();
}

class _PersonalTasksPageState extends State<PersonalTasksPage> {
  static const _storageKey = 'sajid_personal_tasks_v2';
  final List<PersonalTask> _tasks = [];
  final TextEditingController _search = TextEditingController();
  PersonalFilter _filter = PersonalFilter.all;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _tasks.addAll(decoded.map(
          (item) => PersonalTask.fromJson(item as Map<String, dynamic>),
        ));
      }
    } catch (error) {
      debugPrint('Could not load personal tasks: $error');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_tasks.map((task) => task.toJson()).toList()),
    );
  }

  List<PersonalTask> get _visibleTasks {
    Iterable<PersonalTask> result = _tasks;
    if (_filter == PersonalFilter.active) {
      result = result.where((task) => !task.done);
    } else if (_filter == PersonalFilter.completed) {
      result = result.where((task) => task.done);
    }
    final query = _search.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((task) => task.title.toLowerCase().contains(query));
    }
    return result.toList();
  }

  Future<void> _addTask() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مهمة شخصية'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.pop(context, value),
          decoration: const InputDecoration(hintText: 'مثال: مراجعة محاضرة الشبكات'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty) return;
    setState(() {
      _tasks.insert(
        0,
        PersonalTask(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: title.trim(),
          createdAt: DateTime.now(),
        ),
      );
    });
    await _saveTasks();
    HapticFeedback.lightImpact();
  }

  Future<void> _deleteTask(PersonalTask task) async {
    setState(() => _tasks.removeWhere((item) => item.id == task.id));
    await _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    final total = _tasks.length;
    final done = _tasks.where((task) => task.done).length;
    final active = total - done;
    final progress = total == 0 ? 0.0 : done / total;
    final visible = _visibleTasks;

    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _PageHeader(
                  eyebrow: 'مساحتك اليومية',
                  title: 'مهامي',
                  subtitle: 'رتّب يومك، وأنجز خطوة بعد خطوة',
                  trailing: IconButton.filledTonal(
                    onPressed: _addTask,
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'إضافة مهمة',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
                  child: _ProgressCard(
                    total: total,
                    active: active,
                    done: done,
                    progress: progress,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن مهمة...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                  child: Row(
                    children: [
                      _FilterButton(
                        label: 'الكل',
                        count: total,
                        selected: _filter == PersonalFilter.all,
                        onTap: () => setState(() => _filter = PersonalFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterButton(
                        label: 'قيد التنفيذ',
                        count: active,
                        selected: _filter == PersonalFilter.active,
                        onTap: () => setState(() => _filter = PersonalFilter.active),
                      ),
                      const SizedBox(width: 8),
                      _FilterButton(
                        label: 'مكتملة',
                        count: done,
                        selected: _filter == PersonalFilter.completed,
                        onTap: () => setState(() => _filter = PersonalFilter.completed),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? const _EmptyState(
                          icon: Icons.task_alt_rounded,
                          title: 'لا توجد مهام هنا',
                          description: 'أضف أول مهمة وابدأ إنجاز يومك',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final task = visible[index];
                            return _PersonalTaskTile(
                              task: task,
                              onToggle: () async {
                                setState(() => task.done = !task.done);
                                await _saveTasks();
                              },
                              onDelete: () => _deleteTask(task),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key, required this.cloudReady});
  final bool cloudReady;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const _PageHeader(
            eyebrow: 'كل جديد يصلك هنا',
            title: 'لوحة الجامعة',
            subtitle: 'إعلانات ومهام عامة ينشرها مشرف التطبيق',
          ),
          if (!cloudReady)
            const Expanded(
              child: _CloudSetupNotice(
                title: 'لوحة الجامعة غير متصلة بعد',
                description:
                    'أضف إعدادات Firebase للمشروع حتى تظهر المنشورات فور نشرها وتصل الإشعارات إلى الأجهزة.',
              ),
            )
          else
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('announcements')
                    .orderBy('createdAt', descending: true)
                    .limit(100)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const _CloudSetupNotice(
                      title: 'تعذر تحميل المنشورات',
                      description:
                          'تحقق من اتصال الإنترنت وقواعد Firestore في Firebase.',
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const _EmptyState(
                      icon: Icons.campaign_outlined,
                      title: 'لا توجد إعلانات حالياً',
                      description: 'عندما ينشر المشرف إعلاناً سيظهر هنا للجميع',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _AnnouncementCard(
                      data: docs[index].data(),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key, required this.cloudReady});
  final bool cloudReady;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  bool _adminVerified = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    if (widget.cloudReady) _restoreAdminSession();
  }

  Future<void> _restoreAdminSession() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final token = await user.getIdTokenResult(true);
      if (!mounted) return;
      if (token.claims?['admin'] == true) {
        setState(() => _adminVerified = true);
      } else {
        await FirebaseAuth.instance.signOut();
      }
    } catch (error) {
      debugPrint('Could not restore admin session: $error');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!widget.cloudReady) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _message = 'أدخل البريد الإلكتروني وكلمة المرور.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final token = await credential.user!.getIdTokenResult(true);
      if (token.claims?['admin'] == true) {
        setState(() {
          _adminVerified = true;
          _message = null;
        });
      } else {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _adminVerified = false;
          _message = 'هذا الحساب لا يملك صلاحية مشرف التطبيق.';
        });
      }
    } on FirebaseAuthException catch (error) {
      setState(() => _message = _authError(error.code));
    } catch (error) {
      setState(() => _message = 'حدث خطأ أثناء تسجيل الدخول. حاول مجدداً.');
      debugPrint('Admin sign in failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'بيانات الدخول غير صحيحة.';
      case 'too-many-requests':
        return 'محاولات كثيرة. انتظر قليلاً ثم حاول مجدداً.';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت.';
      default:
        return 'تعذر تسجيل الدخول ($code).';
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      setState(() {
        _adminVerified = false;
        _passwordController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const _PageHeader(
            eyebrow: 'إدارة المحتوى المركزي',
            title: 'لوحة التحكم',
            subtitle: 'انشر إعلاناً أو مهمة لتظهر لدى جميع مستخدمي التطبيق',
          ),
          Expanded(
            child: !widget.cloudReady
                ? const _CloudSetupNotice(
                    title: 'يلزم ربط Firebase أولاً',
                    description:
                        'بعد إعداد Firebase وتفعيل تسجيل الدخول والبناء السحابي، يمكنك الدخول بحساب المشرف وإدارة المنشورات.',
                  )
                : _adminVerified
                    ? _AdminDashboard(onSignOut: _signOut)
                    : _loginForm(),
          ),
        ],
      ),
    );
  }

  Widget _loginForm() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.gold,
                size: 48,
              ),
              const SizedBox(height: 14),
              const Text(
                'دخول المشرف',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'هذه المنطقة مخصصة للمسؤول المعتمد فقط',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 13),
              TextField(
                controller: _passwordController,
                obscureText: !_showPassword,
                textDirection: TextDirection.ltr,
                onSubmitted: (_) => _signIn(),
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 14),
                Text(
                  _message!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _busy ? null : _signIn,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login_rounded),
                label: Text(_busy ? 'جارٍ التحقق...' : 'تسجيل الدخول'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _InfoStrip(
          icon: Icons.verified_user_outlined,
          text:
              'صلاحية الإدارة تُمنح من Firebase فقط. إنشاء حساب عادي لا يمنح صاحبه حق النشر أو الحذف.',
        ),
      ],
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard({required this.onSignOut});
  final VoidCallback onSignOut;

  Future<void> _createPost(BuildContext context) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String type = 'announcement';
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              22,
              20,
              MediaQuery.of(context).viewInsets.bottom + 22,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'منشور جديد للجميع',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'announcement',
                        label: Text('إعلان'),
                        icon: Icon(Icons.campaign_outlined),
                      ),
                      ButtonSegment(
                        value: 'task',
                        label: Text('مهمة جامعة'),
                        icon: Icon(Icons.assignment_outlined),
                      ),
                    ],
                    selected: {type},
                    onSelectionChanged: (selection) {
                      setSheetState(() => type = selection.first);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleController,
                    maxLength: 90,
                    decoration: const InputDecoration(labelText: 'العنوان'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyController,
                    maxLength: 1200,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'التفاصيل',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty ||
                          bodyController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('أدخل العنوان والتفاصيل.')),
                        );
                        return;
                      }
                      final user = FirebaseAuth.instance.currentUser;
                      try {
                        await FirebaseFirestore.instance
                            .collection('announcements')
                            .add({
                          'title': titleController.text.trim(),
                          'body': bodyController.text.trim(),
                          'type': type,
                          'createdAt': FieldValue.serverTimestamp(),
                          'createdBy': user?.uid ?? '',
                        });
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext, true);
                        }
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تعذر النشر. تحقق من صلاحيات Firestore.'),
                            ),
                          );
                        }
                        debugPrint('Create announcement failed: $error');
                      }
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('نشر للجميع'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    titleController.dispose();
    bodyController.dispose();
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم النشر، وسيظهر لدى المستخدمين المتصلين.')),
      );
    }
  }

  Future<void> _deletePost(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنشور؟'),
        content: const Text('سيختفي المنشور من لوحة الجامعة لدى الجميع.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await FirebaseFirestore.instance.collection('announcements').doc(id).delete();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حذف المنشور. تحقق من الصلاحيات.')),
        );
      }
      debugPrint('Delete announcement failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
          child: Row(
            children: [
              const Expanded(
                child: _InfoStrip(
                  icon: Icons.admin_panel_settings_rounded,
                  text: 'أنت داخل لوحة المشرف',
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onSignOut,
                tooltip: 'تسجيل الخروج',
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: FilledButton.icon(
            onPressed: () => _createPost(context),
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('إضافة إعلان أو مهمة للجامعة'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.primaryDark,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'المنشورات الحالية',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('announcements')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('تعذر تحميل قائمة المنشورات.'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const _EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'لا توجد منشورات بعد',
                  description: 'ابدأ بإضافة أول إعلان أو مهمة جامعية',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return _AdminPostTile(
                    data: doc.data(),
                    onDelete: () => _deletePost(context, doc.id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
  });
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.total,
    required this.active,
    required this.done,
    required this.progress,
  });
  final int total;
  final int active;
  final int done;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF126B70), Color(0xFF123A4E)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'إنجازك اليوم',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(label: 'الإجمالي', value: total),
              const SizedBox(width: 22),
              _MiniStat(label: 'قيد التنفيذ', value: active),
              const SizedBox(width: 22),
              _MiniStat(label: 'مكتملة', value: done),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.16)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonalTaskTile extends StatelessWidget {
  const _PersonalTaskTile({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });
  final PersonalTask task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: task.done ? AppColors.success.withValues(alpha: 0.35) : AppColors.border,
        ),
      ),
      child: ListTile(
        onTap: onToggle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: task.done ? AppColors.success : Colors.transparent,
            border: Border.all(
              color: task.done ? AppColors.success : AppColors.muted,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: task.done
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : null,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            color: task.done ? AppColors.muted : AppColors.text,
            decoration: task.done ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            _relativeDate(task.createdAt),
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ),
        trailing: IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.muted),
          tooltip: 'حذف',
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final isTask = data['type'] == 'task';
    final created = data['createdAt'];
    final date = created is Timestamp ? _relativeDate(created.toDate()) : 'حديثاً';
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: (isTask ? AppColors.gold : AppColors.primary)
                      .withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isTask ? Icons.assignment_outlined : Icons.campaign_outlined,
                      color: isTask ? AppColors.gold : AppColors.primary,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isTask ? 'مهمة جامعية' : 'إعلان',
                      style: TextStyle(
                        color: isTask ? AppColors.gold : AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(date, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            data['title'] as String? ?? 'بدون عنوان',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['body'] as String? ?? '',
            style: const TextStyle(color: AppColors.muted, height: 1.7, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _AdminPostTile extends StatelessWidget {
  const _AdminPostTile({required this.data, required this.onDelete});
  final Map<String, dynamic> data;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isTask = data['type'] == 'task';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            isTask ? Icons.assignment_outlined : Icons.campaign_outlined,
            color: isTask ? AppColors.gold : AppColors.primary,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] as String? ?? 'بدون عنوان',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data['body'] as String? ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            tooltip: 'حذف من الجميع',
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: AppColors.primary, size: 42),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.6, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudSetupNotice extends StatelessWidget {
  const _CloudSetupNotice({required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.gold, size: 42),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.7, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.muted, fontSize: 11, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

String _relativeDate(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.isNegative || difference.inMinutes < 1) return 'الآن';
  if (difference.inHours < 1) return 'منذ ${difference.inMinutes} دقيقة';
  if (difference.inDays < 1) return 'منذ ${difference.inHours} ساعة';
  if (difference.inDays == 1) return 'أمس';
  if (difference.inDays < 30) return 'منذ ${difference.inDays} يوم';
  return '${date.day}/${date.month}/${date.year}';
}