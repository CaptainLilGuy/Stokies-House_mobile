import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/household_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/household.dart';

class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({super.key});

  @override
  State<StatefulWidget> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends State<HouseholdScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HouseholdProvider>().fetchHousehold();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hp = context.watch<HouseholdProvider>();
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Household'),
        centerTitle: false,
        leading: IconButton( 
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/inventory'),
        ),
        actions: [
          IconButton(
          icon: Icon(Icons.logout),
          tooltip: 'Log out',
          onPressed: () async {
            await auth.logout();
            if (context.mounted) context .go('/login');
            },
          ),
        ],
      ),
      body: () {
        switch (hp.status) {
          case HouseholdStatus.loading:
          case HouseholdStatus.idle:
            return const Center(child: CircularProgressIndicator());

          case HouseholdStatus.error:
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(hp.errorMessage ?? 'Something went wrong',
                    style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: hp.fetchHousehold, 
                  child: const Text('Retry'),
                ),
              ],
            ),
          );

        case HouseholdStatus.loaded:
          return hp.hasHousehold 
              ? _HouseholdDetails(household: hp.household!)
              : const _NoHousehold();
        }
      }(),
    );
  }
}

// ─── No household yet ─────────────────────────────────────

class _NoHousehold extends StatefulWidget {
  const _NoHousehold();

  @override
  State<StatefulWidget> createState() => _NoHouseholdState();
}

class _NoHouseholdState extends State<_NoHousehold> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    await context.read<HouseholdProvider>().createHousehold(_nameCtrl.text.trim());
  }

  Future<void> _join() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    await context.read<HouseholdProvider>().joinHousehold(_codeCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final hp = context.watch<HouseholdProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Illustration / icon
          Center(child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.home_outlined, size: 40,
                color: Theme.of(context).colorScheme.primary,),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text("You're not in a household yet",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 36),

          // Create household
          Text('Create a household',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Household name',
              hintText: 'e.g. Keluarga Santoso',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.home_outlined),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: hp.status == HouseholdStatus.loading ? null : _create, 
              icon: const Icon(Icons.add_home_outlined),
              label: const Text('Create Household'),
            ),
          ),

          const SizedBox(height: 32),

          // Divider
          Row(children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: TextStyle(color: Colors.grey.shade500)),  
            ),
            const Expanded(child: Divider()),
          ]),

          const SizedBox(height: 32),


          //Join household
          Text('Join with invite code',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Invite code',
              hintText: 'e.g. AB12CD',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: hp.status == HouseholdStatus.loading ? null : _join,
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Join household'),
            ),
          ),

          if (hp.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(hp.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),  
            ),
        ],
      ),
    );
  }
}

// ─── Household details ────────────────────────────────────

class _HouseholdDetails extends StatelessWidget {
  final Household household;
  const _HouseholdDetails({required this.household});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<HouseholdProvider>().fetchHousehold(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [

          //Household name + invite code card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.home, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(household.name,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary)),
                ]),
                const SizedBox(height: 16),
                Text('Invite code',
                  style: TextStyle(
                    fontSize: 12,
                    // ignore: deprecated_member_use
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7))),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(household.code,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4)),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy code',  
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: household.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite code copied!')),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 8),
                Text('Share this code with family members to invite them.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            // ignore: deprecated_member_use
                            .withOpacity(0.7))),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Member list
          Text('Members (${household.members.length})',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),

          ...household.members.map((m) => _MemberTile(member: m)),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final HouseholdMember member;
  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final isOwner = member.role == 'owner';
    return Card(
      margin: const  EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOwner
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.shade200,
          child: Text(
            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
            style: TextStyle(
                color: isOwner 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(member.name,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(member.email),
        trailing: isOwner
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Owner',
                    style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600)),
              )
            : null,
      ),
    );
  }
}