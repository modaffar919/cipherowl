/// Role of a member inside an organisation vault.
enum OrgRole {
  admin,
  manager,
  member;

  /// Arabic label.
  String get labelAr {
    switch (this) {
      case admin:
        return 'مدير النظام';
      case manager:
        return 'مدير';
      case member:
        return 'عضو';
    }
  }

  /// Whether this role can invite or remove members.
  bool get canManageMembers => this == admin;

  /// Whether this role can create / delete shared vaults.
  bool get canManageVaults => this == admin || this == manager;

  /// Whether this role can read vault items.
  bool get canRead => true;

  /// Whether this role can add or update vault items.
  bool get canWrite => this == admin || this == manager;

  static OrgRole fromString(String value) {
    switch (value) {
      case 'admin':
        return OrgRole.admin;
      case 'manager':
        return OrgRole.manager;
      default:
        return OrgRole.member;
    }
  }
}
