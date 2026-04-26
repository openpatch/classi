enum StudentSortField { firstName, lastName }

extension StudentSortFieldPersistence on StudentSortField {
  String get storageValue => switch (this) {
    StudentSortField.firstName => 'first_name',
    StudentSortField.lastName => 'last_name',
  };

  static StudentSortField fromStorage(String? value) {
    return switch (value) {
      'first_name' => StudentSortField.firstName,
      _ => StudentSortField.lastName,
    };
  }
}
