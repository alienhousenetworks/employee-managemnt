import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.api, required this.username});
  final ApiClient api;
  final String username;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  bool busy = false;
  String error = '';
  List<dynamic> posts = [], reports = [], tasks = [], attendance = [], leaves = [], documents = [], employees = [], inbox = [];
  final post = TextEditingController(), accomp = TextEditingController(), blockers = TextEditingController(),
      plan = TextEditingController(), hours = TextEditingController(text: '8'), taskTitle = TextEditingController(),
      taskDescription = TextEditingController(), leaveReason = TextEditingController(), leaveType = TextEditingController(text: 'Casual Leave'),
      leaveFrom = TextEditingController(), leaveTo = TextEditingController(), docType = TextEditingController(text: 'Employment letter'),
      docPurpose = TextEditingController(), aiPrompt = TextEditingController(text: 'Help me summarise my workday and suggest three priorities for tomorrow.'),
      aiContext = TextEditingController(), waTo = TextEditingController(), waMessage = TextEditingController();
  String type = 'Update', priority = 'Medium', aiResult = '';
  @override
  void initState() { super.initState(); refresh(); }
  @override
  void dispose() {
    for (final c in [post, accomp, blockers, plan, hours, taskTitle, taskDescription, leaveReason, leaveType,
      leaveFrom, leaveTo, docType, docPurpose, aiPrompt, aiContext, waTo, waMessage]) { c.dispose(); }
    super.dispose();
  }
  Future<dynamic> call(String method, [Map<String, String> args = const {}]) => widget.api.call(method, args);
  Future<void> refresh() async {
    setState(() { busy = true; error = ''; });
    try {
      final results = await Future.wait([
        call('get_feed'), call('get_my_eod_reports'), call('get_my_tasks'),
        call('get_attendance_history'), call('get_my_leave_applications'), call('get_document_requests'), call('get_employee_directory')
      ]);
      final inboxData = tab == 9 ? await call('get_whatsapp_inbox') as List<dynamic> : inbox;
      if (mounted) setState(() {
        posts = results[0] as List<dynamic>; reports = results[1] as List<dynamic>;
        tasks = results[2] as List<dynamic>; attendance = results[3] as List<dynamic>;
        leaves = results[4] as List<dynamic>; documents = results[5] as List<dynamic>;
        employees = results[6] as List<dynamic>; inbox = inboxData;
      });
    } catch (e) { if (mounted) setState(() { error = e.toString(); }); }
    finally { if (mounted) setState(() { busy = false; }); }
  }
  Future<void> act(String method, Map<String, String> args, {String success = 'Saved.'}) async {
    try { await call(method, args); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success))); await refresh(); }
    catch (e) { if (mounted) setState(() { error = e.toString(); }); }
  }
  Widget panel(Widget child) => Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(15), child: child));
  Widget field(String label, TextEditingController c, {int lines = 1, TextInputType? keyboard}) =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: TextField(controller: c, maxLines: lines, keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())));
  Widget rows(List<dynamic> items, List<String> keys) {
    if (items.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No records returned.'));
    return Column(children: items.map((raw) {
      final r = Map<String, dynamic>.from(raw as Map);
      return panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text((r[keys.first] ?? 'Record').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        for (final k in keys.skip(1)) if (r[k] != null && r[k].toString().isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 5), child: Text('$k: ${r[k]}', style: const TextStyle(fontSize: 12))),
      ]));
    }).toList());
  }
  @override
  Widget build(BuildContext context) {
    final titles = ['Team feed', 'Daily EOD', 'Tasks', 'Attendance', 'Leave', 'Documents', 'Dashboard', 'AI assistant', 'Employees', 'WhatsApp'];
    return Scaffold(
      appBar: AppBar(title: Text(titles[tab]), actions: [IconButton(onPressed: refresh, icon: const Icon(Icons.refresh)), IconButton(onPressed: () async { await widget.api.logout(); if (!mounted) return; Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false); }, icon: const Icon(Icons.logout), tooltip: 'Sign out')]),
      body: RefreshIndicator(onRefresh: refresh, child: ListView(padding: const EdgeInsets.all(14), children: [
        if (error.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(error, style: const TextStyle(color: Colors.red))),
        if (tab == 0) ...[
          panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Share with your team', style: TextStyle(fontWeight: FontWeight.bold)),
            field('Update', post, lines: 3),
            DropdownButton<String>(value: type, items: ['Update','Question','Recognition','Announcement'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(), onChanged:(v)=>setState(()=>type=v??'Update')),
            FilledButton.icon(onPressed:()=>act('create_feed_post', {'content':post.text,'post_type':type}, success:'Update published.'), icon:const Icon(Icons.send), label:const Text('Publish'))
          ])),
          rows(posts, ['author_name','post_type','content','creation'])
        ],
        if (tab == 1) ...[
          panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('End-of-day report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            field('Accomplishments *', accomp, lines: 3), field('Blockers', blockers, lines: 2),
            field('Plan for tomorrow', plan, lines: 2), field('Hours worked', hours, keyboard: TextInputType.number),
            FilledButton.icon(onPressed:()=>act('submit_eod_report', {'accomplishments':accomp.text,'blockers':blockers.text,'next_day_plan':plan.text,'hours_worked':hours.text}, success:'EOD report submitted.'), icon:const Icon(Icons.check), label:const Text('Submit report'))
          ])),
          rows(reports, ['report_date','status','accomplishments','hours_worked','reviewer_notes'])
        ],
        if (tab == 2) ...[
          panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Create task', style: TextStyle(fontWeight: FontWeight.bold)),
            field('Task title', taskTitle), field('Description', taskDescription, lines: 3),
            DropdownButton<String>(value:priority,items:['Low','Medium','High','Urgent'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setState(()=>priority=v??'Medium')),
            FilledButton(onPressed:()=>act('create_task', {'subject':taskTitle.text,'description':taskDescription.text,'priority':priority}, success:'Task created.'), child:const Text('Create task'))
          ])),
          rows(tasks, ['subject','status','priority','exp_end_date','name'])
        ],
        if (tab == 3) ...[
          panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Attendance clock', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Records events against your linked ERPNext Employee.'),
            Wrap(spacing: 10, children: [
              FilledButton(onPressed:()=>act('record_checkin', {'log_type':'IN'}, success:'Clock-in recorded.'), child:const Text('Clock in')),
              OutlinedButton(onPressed:()=>act('record_checkin', {'log_type':'OUT'}, success:'Clock-out recorded.'), child:const Text('Clock out'))
            ])
          ])),
          rows(attendance, ['record_type','attendance_date','time','status','log_type','in_time','out_time','working_hours'])
        ],
        if (tab == 4) ...[
          panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Request leave', style: TextStyle(fontWeight: FontWeight.bold)),
            field('Leave type (must exist in ERPNext)', leaveType), field('From date (YYYY-MM-DD)', leaveFrom), field('To date (YYYY-MM-DD)', leaveTo),
            field('Reason', leaveReason, lines: 3),
            FilledButton(onPressed:()=>act('apply_leave', {'leave_type':leaveType.text,'from_date':leaveFrom.text,'to_date':leaveTo.text,'description':leaveReason.text}, success:'Leave request submitted.'), child:const Text('Submit leave'))
          ])),
          rows(leaves, ['name','leave_type','from_date','to_date','status'])
        ],
        if (tab == 5) ...[
          panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Request an employee document', style: TextStyle(fontWeight: FontWeight.bold)),
            field('Document type', docType), field('Purpose', docPurpose, lines: 3),
            FilledButton(onPressed:()=>act('request_document', {'document_type':docType.text,'purpose':docPurpose.text}, success:'Document request submitted.'), child:const Text('Request document'))
          ])),
          rows(documents, ['name','document_type','status','reviewer_notes','attachment'])
        ],
        if (tab == 6) panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Your activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          metric('Feed posts loaded', posts.length), metric('EOD reports', reports.length), metric('Tasks returned', tasks.length),
          metric('Attendance records', attendance.length), metric('Leave requests', leaves.length), metric('Document requests', documents.length),
          const Text('These are returned-record counts, not company-wide totals.', style: TextStyle(fontSize: 11))
        ])),
        if (tab == 8) ...[panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Employee directory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),const Text('Directory fields depend on your ERPNext role.'),const SizedBox(height: 8),rows(employees, ['employee_name','department','designation','status'])]))],
        if (tab == 9) ...[panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Send WhatsApp to an employee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),field('Employee record ID',waTo),field('Message',waMessage,lines:3),FilledButton(onPressed:()=>act('send_whatsapp_to_employee',{'employee':waTo.text,'message':waMessage.text},success:'WhatsApp provider request processed.'),child:const Text('Send message')),const Text('HR/System Manager only. Provider configuration is required.',style:TextStyle(fontSize:11))])),rows(inbox, ['employee_name','sender_phone','message','status','creation'])],
        if (tab == 7) ...[
          panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Human-in-the-loop work assistant', style: TextStyle(fontWeight: FontWeight.bold)),
            field('Request', aiPrompt, lines: 3), field('Context (avoid unnecessary sensitive data)', aiContext, lines: 4),
            FilledButton(onPressed:() async {
              try { final r = await call('ai_work_assistant', {'task':aiPrompt.text,'context':aiContext.text}); setState(()=>aiResult=r['answer'] != null ? 'DRAFT\n${r['answer']}\n\nINDEPENDENT SAFETY REVIEW\n${r['review'] ?? 'Not provided'}\n\nHuman review is required before use.' : (r['message']??'AI status: ${r['status']}').toString()); }
              catch(e) { setState(()=>error=e.toString()); }
            }, child:const Text('Generate draft')),
            if (aiResult.isNotEmpty) Padding(padding:const EdgeInsets.only(top:14),child:Text(aiResult))
          ])),
          const Text('AI must be configured on the server. Output is a draft, not an automated HR decision.')
        ],
        if (busy) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
      ])),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v)=>setState(()=>tab=v),
        destinations: const [
          NavigationDestination(icon:Icon(Icons.groups),label:'Feed'),
          NavigationDestination(icon:Icon(Icons.today),label:'EOD'),
          NavigationDestination(icon:Icon(Icons.task_alt),label:'Tasks'),
          NavigationDestination(icon:Icon(Icons.schedule),label:'Attendance'),
          NavigationDestination(icon:Icon(Icons.event_available),label:'Leave'),
          NavigationDestination(icon:Icon(Icons.folder),label:'Docs'),
          NavigationDestination(icon:Icon(Icons.insights),label:'Dashboard'),
          NavigationDestination(icon:Icon(Icons.auto_awesome),label:'AI'),
          NavigationDestination(icon:Icon(Icons.badge),label:'People'),
          NavigationDestination(icon:Icon(Icons.chat),label:'WhatsApp'),
        ]),
    );
  }
  Widget metric(String label, int value) => Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Row(children:[Expanded(child:Text(label)),Text('$value',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18))]));
}
