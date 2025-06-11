import 'package:flutter/material.dart';
import 'package:nudgr/models/reminder_model.dart';
import 'package:nudgr/pages/login_page.dart';
import 'package:nudgr/pages/register_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vjzxvusrqlvtqbltutsu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqenh2dXNycWx2dHFibHR1dHN1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk2MzAwMTksImV4cCI6MjA2NTIwNjAxOX0.WAeFqOtCEtn1F9ye-kdS8gI4igHGS5YVPb_4Phv51OI',
  );
    // Handle OAuth redirect if on web
  final supabase = Supabase.instance.client;
  final gotrue = supabase.auth;

if (kIsWeb) {
  final url = Uri.parse(html.window.location.href);
  // Check if URL fragment contains access_token
  if (url.fragment.contains('access_token')) {
    await gotrue.getSessionFromUrl(url);
  } else {
    // No token in URL: probably initial app load, no action needed here
  }
}

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
      
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 58, 143, 183),
          brightness: Brightness.dark,
          ),
        
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, });
  final String title = '🤏 Nudgr';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ReminderModel> reminders = [];
  TimeOfDay? _selectedTime;
  final _textController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _textController.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchReminders();
  }

  Future<void> addReminder(String content, TimeOfDay alarmTime, String userId, {bool enabled = true}) async {
      try {
        await Supabase.instance.client
        .from('reminders')
        .insert({
            'content' : content,
            'created_at' : DateTime.now().toIso8601String(),
            'enabled' : enabled,
            'alarm': '${alarmTime.hour.toString().padLeft(2, '0')}:${alarmTime.minute.toString().padLeft(2, '0')}:00',
            'user_id':userId
        });
      } catch (e, stack) {
        debugPrint('Error adding reminder: $e');
        debugPrint('Stack trace: $stack');
      }
  }

  Future<void> editReminders(int id, String content, TimeOfDay alarmTime, bool enabled) async {
    final alarmString = '${alarmTime.hour.toString().padLeft(2, '0')}:${alarmTime.minute.toString().padLeft(2, '0')}:00';

    try {
      await Supabase.instance.client
          .from('reminders')
          .update({
            'content': content,
            'alarm': alarmString,
            'enabled': enabled,
          })
          .eq('id', id);
    } catch (e) {
      debugPrint('Error updating reminder: $e');
    }
  }

  Future<void> deleteReminder(int id) async {
    try {
      await Supabase.instance.client
          .from('reminders')
          .delete()
          .eq('id', id);
    } catch (e) {
      debugPrint('Error deleting reminder: $e');
    }
  }


  Future<void> fetchReminders() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final response = await Supabase.instance.client
        .from('reminders')
        .select('id, created_at, content, enabled, alarm, user_id')
        .eq('user_id', userId)
        .order('created_at');

    try {
      if(response == null) return;
      setState(() {
        reminders = (response as List)
            .map((item) => ReminderModel.fromJson(item))
            .toList();
      });
    } catch (e) {
      debugPrint('reminders was null, error: $e' );
    }
  }
  Future<void> logout() async{
    if(Supabase.instance.client.auth.currentUser != null)
    {
      await Supabase.instance.client.auth.signOut();
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal:8),
            // child:Text(Supabase.instance.client.auth.currentUser?.email ?? ''),
            child:Text(Supabase.instance.client.auth.currentUser != null? 'Logged in' : ''),
          ),
          if(Supabase.instance.client.auth.currentUser == null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal:8),
            child: ElevatedButton(
                onPressed: ()=>
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                ),
              child: Text('Login')
              ),
            ),
            if(Supabase.instance.client.auth.currentUser == null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal:8),
              child:ElevatedButton(
                  onPressed: ()=>
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                  ),
                child: Text('Register')
                ),
            ),
            if(Supabase.instance.client.auth.currentUser != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal:8),
              child:ElevatedButton(
                  onPressed: () async 
                  {
                    await logout();
                    setState(() {
                       reminders = [];
                    });
                  },
                  child: Text('Log out')
                ),
            ),
          ],
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: reminders.isEmpty
              ? Supabase.instance.client.auth.currentUser == null? const Text('Log in to view and add reminders.'): const Text('No reminders yet.')
              : Expanded(
                  child: ListView.builder(
                    itemCount: reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = reminders[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reminder.content,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, size: 16),
                                        const SizedBox(width: 4),
                                        Text(reminder.alarm.format(context)),
                                        const SizedBox(width: 16),
                                        Icon(
                                          reminder.enabled ? Icons.check_circle : Icons.cancel,
                                          color: reminder.enabled ? Colors.green : Colors.red,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(reminder.enabled ? 'Enabled' : 'Disabled'),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Created: ${reminder.createdAt.toLocal().toString().split('.')[0]}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  _textController.text = reminder.content;
                                  _selectedTime = reminder.alarm;
                                  bool enabled = reminder.enabled;
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) => StatefulBuilder(
                                      builder: (context, setState) => AlertDialog(
                                        title: const Text('Edit reminder'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            TextField(
                                              controller: _textController,
                                              decoration: const InputDecoration(
                                                labelText: 'Reminder',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            GestureDetector(
                                              onTap: () => _pickTime(context),
                                              child: AbsorbPointer(
                                                child: TextField(
                                                  readOnly: true,
                                                  decoration: InputDecoration(
                                                    labelText: 'Time',
                                                    border: const OutlineInputBorder(),
                                                    suffixIcon: const Icon(Icons.access_time),
                                                    hintText: _selectedTime == null
                                                        ? 'Pick time'
                                                        : _selectedTime!.format(context),
                                                  ),
                                                  controller: TextEditingController(
                                                    text: _selectedTime == null
                                                        ? ''
                                                        : _selectedTime!.format(context),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            CheckboxListTile(
                                              value: enabled,
                                              onChanged: (val) {
                                                setState(() {
                                                  enabled = val ?? true;
                                                });
                                              },
                                              title: const Text('Enabled'),
                                              controlAffinity: ListTileControlAffinity.leading,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                final content = _textController.text;
                                                if (content.isNotEmpty && _selectedTime != null) {
                                                  await editReminders(reminder.id, content, _selectedTime!, enabled);
                                                  await fetchReminders();
                                                  Navigator.of(context).pop();
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(const SnackBar(content: Text('Reminder edited!')));
                                                }
                                              },
                                              child: const Text('Save Changes'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () async {
                                  final result = await showDialog<bool>(
                                    context: context,
                                    builder: (context)=> AlertDialog(
                                    title: Text('Confirm delete'),
                                    content: Text('Are you sure you want to delete this reminder?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel')),
                                      ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Delete')),
                                    ],
                                    ),
                                  );
                                  if(result == true)
                                  {
                                    await deleteReminder(reminder.id);
                                    await fetchReminders();
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(const SnackBar(content: Text('Reminder deleted!')));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
       floatingActionButton: Supabase.instance.client.auth.currentUser != null
      ?FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (BuildContext context) {
            TimeOfDay? dialogTime = TimeOfDay.now(); // Set to now by default
            bool enabled = true;
            final timeController = TextEditingController(
              text: dialogTime.format(context),
            );
            return StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: const Text('New reminder'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        labelText: 'Reminder',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: dialogTime!,
                        );
                        if (picked != null) {
                          setState(() {
                            dialogTime = picked;
                            timeController.text = picked.format(context);
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Time',
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.access_time),
                            hintText: dialogTime?.format(context),
                          ),
                          controller: timeController,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: enabled,
                      onChanged: (val) {
                        setState(() {
                          enabled = val ?? true;
                        });
                      },
                      title: const Text('Enabled'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    ElevatedButton(
                        onPressed: () async {
                          final content = _textController.text;
                          final userId = Supabase.instance.client.auth.currentUser?.id;
                          if (content.isNotEmpty && dialogTime != null && userId != null) {
                            setState(() {
                              _selectedTime = dialogTime;
                            });
                            await addReminder(content, dialogTime!, userId, enabled: enabled);
                            await fetchReminders();

                            Navigator.of(context).pop(); // Close the dialog
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(const SnackBar(content: Text('Reminder added!')));
                            // Clear after dialog closes
                            _textController.clear();
                            setState(() {
                              _selectedTime = null;
                            });
                          }
                        },
                        child: const Text('Add reminder'),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        tooltip: 'Add',
        child: const Icon(Icons.add),
      )  : SizedBox.shrink(), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
