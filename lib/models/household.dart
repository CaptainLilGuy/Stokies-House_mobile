class Household {
  final int id;
  final String name;
  final String code;
  final double? budget;
  final String myRole;
  final List<HouseholdMember> members;
  bool get isOwner => myRole == 'owner';

  Household({
    required this.id,
    required this.name,
    required this.code,
    required this.members,
    this.budget,
    this.myRole = 'member',
  });

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'], 
      name: json['name'], 
      code: json['invite_code'], 
      budget: double.tryParse("&{json['monthly_budget'] ?? ''}"),
      myRole: json['my_role'] ?? 'member',
      members: (json['members'] as List<dynamic>? ?? [])
      .map((m) => HouseholdMember.fromJson(m))
      .toList(),
    );
  }
}

class HouseholdMember {
  final int id;
  final String name;
  final String email;
  final String role;

  HouseholdMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory HouseholdMember.fromJson(Map<String, dynamic> json) {
    return HouseholdMember(
      id: json['id'], 
      name: json['name'], 
      email: json['email'], 
      role: json['role'] ?? 'member',
    );
  }
}