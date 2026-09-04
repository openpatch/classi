// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SchoolYearsTableTable extends SchoolYearsTable
    with TableInfo<$SchoolYearsTableTable, SchoolYearsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchoolYearsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    startDate,
    endDate,
    archivedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'school_years_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SchoolYearsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SchoolYearsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SchoolYearsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SchoolYearsTableTable createAlias(String alias) {
    return $SchoolYearsTableTable(attachedDatabase, alias);
  }
}

class SchoolYearsTableData extends DataClass
    implements Insertable<SchoolYearsTableData> {
  final int id;
  final String label;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? archivedAt;
  final DateTime createdAt;

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  final DateTime updatedAt;
  const SchoolYearsTableData({
    required this.id,
    required this.label,
    required this.startDate,
    required this.endDate,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['label'] = Variable<String>(label);
    map['start_date'] = Variable<DateTime>(startDate);
    map['end_date'] = Variable<DateTime>(endDate);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SchoolYearsTableCompanion toCompanion(bool nullToAbsent) {
    return SchoolYearsTableCompanion(
      id: Value(id),
      label: Value(label),
      startDate: Value(startDate),
      endDate: Value(endDate),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SchoolYearsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SchoolYearsTableData(
      id: serializer.fromJson<int>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'label': serializer.toJson<String>(label),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SchoolYearsTableData copyWith({
    int? id,
    String? label,
    DateTime? startDate,
    DateTime? endDate,
    Value<DateTime?> archivedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SchoolYearsTableData(
    id: id ?? this.id,
    label: label ?? this.label,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SchoolYearsTableData copyWithCompanion(SchoolYearsTableCompanion data) {
    return SchoolYearsTableData(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SchoolYearsTableData(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    label,
    startDate,
    endDate,
    archivedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SchoolYearsTableData &&
          other.id == this.id &&
          other.label == this.label &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.archivedAt == this.archivedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SchoolYearsTableCompanion extends UpdateCompanion<SchoolYearsTableData> {
  final Value<int> id;
  final Value<String> label;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<DateTime?> archivedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SchoolYearsTableCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SchoolYearsTableCompanion.insert({
    this.id = const Value.absent(),
    required String label,
    required DateTime startDate,
    required DateTime endDate,
    this.archivedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : label = Value(label),
       startDate = Value(startDate),
       endDate = Value(endDate);
  static Insertable<SchoolYearsTableData> custom({
    Expression<int>? id,
    Expression<String>? label,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<DateTime>? archivedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SchoolYearsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? label,
    Value<DateTime>? startDate,
    Value<DateTime>? endDate,
    Value<DateTime?>? archivedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SchoolYearsTableCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchoolYearsTableCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $GroupsTableTable extends GroupsTable
    with TableInfo<$GroupsTableTable, GroupsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#FF1E88E5'),
  );
  static const VerificationMeta _gradeScaleJsonMeta = const VerificationMeta(
    'gradeScaleJson',
  );
  @override
  late final GeneratedColumn<String> gradeScaleJson = GeneratedColumn<String>(
    'grade_scale_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('["1","2","3","4","5","6"]'),
  );
  static const VerificationMeta _gradeCategoriesJsonMeta =
      const VerificationMeta('gradeCategoriesJson');
  @override
  late final GeneratedColumn<String>
  gradeCategoriesJson = GeneratedColumn<String>(
    'grade_categories_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(
      '[{"id":"sonstige-mitarbeit","name":"Sonstige Mitarbeit","weight":1.0,"color":"#FF1E88E5"},{"id":"klassenarbeit","name":"Klassenarbeit","weight":3.0,"color":"#FF8E24AA"},{"id":"praesentation","name":"Präsentation","weight":2.0,"color":"#FF00897B"}]',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _schoolYearIdMeta = const VerificationMeta(
    'schoolYearId',
  );
  @override
  late final GeneratedColumn<int> schoolYearId = GeneratedColumn<int>(
    'school_year_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES school_years_table (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    colorHex,
    gradeScaleJson,
    gradeCategoriesJson,
    createdAt,
    archivedAt,
    schoolYearId,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('grade_scale_json')) {
      context.handle(
        _gradeScaleJsonMeta,
        gradeScaleJson.isAcceptableOrUnknown(
          data['grade_scale_json']!,
          _gradeScaleJsonMeta,
        ),
      );
    }
    if (data.containsKey('grade_categories_json')) {
      context.handle(
        _gradeCategoriesJsonMeta,
        gradeCategoriesJson.isAcceptableOrUnknown(
          data['grade_categories_json']!,
          _gradeCategoriesJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('school_year_id')) {
      context.handle(
        _schoolYearIdMeta,
        schoolYearId.isAcceptableOrUnknown(
          data['school_year_id']!,
          _schoolYearIdMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      gradeScaleJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grade_scale_json'],
      )!,
      gradeCategoriesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grade_categories_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      schoolYearId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}school_year_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $GroupsTableTable createAlias(String alias) {
    return $GroupsTableTable(attachedDatabase, alias);
  }
}

class GroupsTableData extends DataClass implements Insertable<GroupsTableData> {
  final int id;
  final String name;
  final String colorHex;
  final String gradeScaleJson;
  final String gradeCategoriesJson;
  final DateTime createdAt;
  final DateTime? archivedAt;
  final int? schoolYearId;

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  final DateTime updatedAt;
  const GroupsTableData({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.gradeScaleJson,
    required this.gradeCategoriesJson,
    required this.createdAt,
    this.archivedAt,
    this.schoolYearId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color_hex'] = Variable<String>(colorHex);
    map['grade_scale_json'] = Variable<String>(gradeScaleJson);
    map['grade_categories_json'] = Variable<String>(gradeCategoriesJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    if (!nullToAbsent || schoolYearId != null) {
      map['school_year_id'] = Variable<int>(schoolYearId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GroupsTableCompanion toCompanion(bool nullToAbsent) {
    return GroupsTableCompanion(
      id: Value(id),
      name: Value(name),
      colorHex: Value(colorHex),
      gradeScaleJson: Value(gradeScaleJson),
      gradeCategoriesJson: Value(gradeCategoriesJson),
      createdAt: Value(createdAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      schoolYearId: schoolYearId == null && nullToAbsent
          ? const Value.absent()
          : Value(schoolYearId),
      updatedAt: Value(updatedAt),
    );
  }

  factory GroupsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupsTableData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      gradeScaleJson: serializer.fromJson<String>(json['gradeScaleJson']),
      gradeCategoriesJson: serializer.fromJson<String>(
        json['gradeCategoriesJson'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      schoolYearId: serializer.fromJson<int?>(json['schoolYearId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'colorHex': serializer.toJson<String>(colorHex),
      'gradeScaleJson': serializer.toJson<String>(gradeScaleJson),
      'gradeCategoriesJson': serializer.toJson<String>(gradeCategoriesJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'schoolYearId': serializer.toJson<int?>(schoolYearId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  GroupsTableData copyWith({
    int? id,
    String? name,
    String? colorHex,
    String? gradeScaleJson,
    String? gradeCategoriesJson,
    DateTime? createdAt,
    Value<DateTime?> archivedAt = const Value.absent(),
    Value<int?> schoolYearId = const Value.absent(),
    DateTime? updatedAt,
  }) => GroupsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    colorHex: colorHex ?? this.colorHex,
    gradeScaleJson: gradeScaleJson ?? this.gradeScaleJson,
    gradeCategoriesJson: gradeCategoriesJson ?? this.gradeCategoriesJson,
    createdAt: createdAt ?? this.createdAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    schoolYearId: schoolYearId.present ? schoolYearId.value : this.schoolYearId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  GroupsTableData copyWithCompanion(GroupsTableCompanion data) {
    return GroupsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      gradeScaleJson: data.gradeScaleJson.present
          ? data.gradeScaleJson.value
          : this.gradeScaleJson,
      gradeCategoriesJson: data.gradeCategoriesJson.present
          ? data.gradeCategoriesJson.value
          : this.gradeCategoriesJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      schoolYearId: data.schoolYearId.present
          ? data.schoolYearId.value
          : this.schoolYearId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('gradeScaleJson: $gradeScaleJson, ')
          ..write('gradeCategoriesJson: $gradeCategoriesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('schoolYearId: $schoolYearId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    colorHex,
    gradeScaleJson,
    gradeCategoriesJson,
    createdAt,
    archivedAt,
    schoolYearId,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorHex == this.colorHex &&
          other.gradeScaleJson == this.gradeScaleJson &&
          other.gradeCategoriesJson == this.gradeCategoriesJson &&
          other.createdAt == this.createdAt &&
          other.archivedAt == this.archivedAt &&
          other.schoolYearId == this.schoolYearId &&
          other.updatedAt == this.updatedAt);
}

class GroupsTableCompanion extends UpdateCompanion<GroupsTableData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> colorHex;
  final Value<String> gradeScaleJson;
  final Value<String> gradeCategoriesJson;
  final Value<DateTime> createdAt;
  final Value<DateTime?> archivedAt;
  final Value<int?> schoolYearId;
  final Value<DateTime> updatedAt;
  const GroupsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.gradeScaleJson = const Value.absent(),
    this.gradeCategoriesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.schoolYearId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  GroupsTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.colorHex = const Value.absent(),
    this.gradeScaleJson = const Value.absent(),
    this.gradeCategoriesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.schoolYearId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<GroupsTableData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? colorHex,
    Expression<String>? gradeScaleJson,
    Expression<String>? gradeCategoriesJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? archivedAt,
    Expression<int>? schoolYearId,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorHex != null) 'color_hex': colorHex,
      if (gradeScaleJson != null) 'grade_scale_json': gradeScaleJson,
      if (gradeCategoriesJson != null)
        'grade_categories_json': gradeCategoriesJson,
      if (createdAt != null) 'created_at': createdAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (schoolYearId != null) 'school_year_id': schoolYearId,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  GroupsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? colorHex,
    Value<String>? gradeScaleJson,
    Value<String>? gradeCategoriesJson,
    Value<DateTime>? createdAt,
    Value<DateTime?>? archivedAt,
    Value<int?>? schoolYearId,
    Value<DateTime>? updatedAt,
  }) {
    return GroupsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      gradeScaleJson: gradeScaleJson ?? this.gradeScaleJson,
      gradeCategoriesJson: gradeCategoriesJson ?? this.gradeCategoriesJson,
      createdAt: createdAt ?? this.createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
      schoolYearId: schoolYearId ?? this.schoolYearId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (gradeScaleJson.present) {
      map['grade_scale_json'] = Variable<String>(gradeScaleJson.value);
    }
    if (gradeCategoriesJson.present) {
      map['grade_categories_json'] = Variable<String>(
        gradeCategoriesJson.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (schoolYearId.present) {
      map['school_year_id'] = Variable<int>(schoolYearId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('gradeScaleJson: $gradeScaleJson, ')
          ..write('gradeCategoriesJson: $gradeCategoriesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('schoolYearId: $schoolYearId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $StudentsTableTable extends StudentsTable
    with TableInfo<$StudentsTableTable, StudentsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudentsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _callNameMeta = const VerificationMeta(
    'callName',
  );
  @override
  late final GeneratedColumn<String> callName = GeneratedColumn<String>(
    'call_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES groups_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _originNoteMeta = const VerificationMeta(
    'originNote',
  );
  @override
  late final GeneratedColumn<String> originNote = GeneratedColumn<String>(
    'origin_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _avatarJsonMeta = const VerificationMeta(
    'avatarJson',
  );
  @override
  late final GeneratedColumn<String> avatarJson = GeneratedColumn<String>(
    'avatar_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seatIndexMeta = const VerificationMeta(
    'seatIndex',
  );
  @override
  late final GeneratedColumn<int> seatIndex = GeneratedColumn<int>(
    'seat_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    firstName,
    lastName,
    callName,
    groupId,
    originNote,
    createdAt,
    avatarJson,
    seatIndex,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'students_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudentsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    if (data.containsKey('call_name')) {
      context.handle(
        _callNameMeta,
        callName.isAcceptableOrUnknown(data['call_name']!, _callNameMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('origin_note')) {
      context.handle(
        _originNoteMeta,
        originNote.isAcceptableOrUnknown(data['origin_note']!, _originNoteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('avatar_json')) {
      context.handle(
        _avatarJsonMeta,
        avatarJson.isAcceptableOrUnknown(data['avatar_json']!, _avatarJsonMeta),
      );
    }
    if (data.containsKey('seat_index')) {
      context.handle(
        _seatIndexMeta,
        seatIndex.isAcceptableOrUnknown(data['seat_index']!, _seatIndexMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudentsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudentsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      )!,
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      )!,
      callName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}call_name'],
      ),
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      )!,
      originNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      avatarJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_json'],
      ),
      seatIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seat_index'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StudentsTableTable createAlias(String alias) {
    return $StudentsTableTable(attachedDatabase, alias);
  }
}

class StudentsTableData extends DataClass
    implements Insertable<StudentsTableData> {
  final int id;
  final String firstName;
  final String lastName;

  /// Informal name a teacher actually calls the student by (German
  /// "Rufname"), shown instead of [firstName] wherever the surname is
  /// still displayed alongside it. `null` means "same as firstName".
  final String? callName;
  final int groupId;
  final String? originNote;
  final DateTime createdAt;
  final String? avatarJson;
  final int? seatIndex;

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  final DateTime updatedAt;
  const StudentsTableData({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.callName,
    required this.groupId,
    this.originNote,
    required this.createdAt,
    this.avatarJson,
    this.seatIndex,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
    if (!nullToAbsent || callName != null) {
      map['call_name'] = Variable<String>(callName);
    }
    map['group_id'] = Variable<int>(groupId);
    if (!nullToAbsent || originNote != null) {
      map['origin_note'] = Variable<String>(originNote);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || avatarJson != null) {
      map['avatar_json'] = Variable<String>(avatarJson);
    }
    if (!nullToAbsent || seatIndex != null) {
      map['seat_index'] = Variable<int>(seatIndex);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StudentsTableCompanion toCompanion(bool nullToAbsent) {
    return StudentsTableCompanion(
      id: Value(id),
      firstName: Value(firstName),
      lastName: Value(lastName),
      callName: callName == null && nullToAbsent
          ? const Value.absent()
          : Value(callName),
      groupId: Value(groupId),
      originNote: originNote == null && nullToAbsent
          ? const Value.absent()
          : Value(originNote),
      createdAt: Value(createdAt),
      avatarJson: avatarJson == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarJson),
      seatIndex: seatIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(seatIndex),
      updatedAt: Value(updatedAt),
    );
  }

  factory StudentsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudentsTableData(
      id: serializer.fromJson<int>(json['id']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      callName: serializer.fromJson<String?>(json['callName']),
      groupId: serializer.fromJson<int>(json['groupId']),
      originNote: serializer.fromJson<String?>(json['originNote']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      avatarJson: serializer.fromJson<String?>(json['avatarJson']),
      seatIndex: serializer.fromJson<int?>(json['seatIndex']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'callName': serializer.toJson<String?>(callName),
      'groupId': serializer.toJson<int>(groupId),
      'originNote': serializer.toJson<String?>(originNote),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'avatarJson': serializer.toJson<String?>(avatarJson),
      'seatIndex': serializer.toJson<int?>(seatIndex),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StudentsTableData copyWith({
    int? id,
    String? firstName,
    String? lastName,
    Value<String?> callName = const Value.absent(),
    int? groupId,
    Value<String?> originNote = const Value.absent(),
    DateTime? createdAt,
    Value<String?> avatarJson = const Value.absent(),
    Value<int?> seatIndex = const Value.absent(),
    DateTime? updatedAt,
  }) => StudentsTableData(
    id: id ?? this.id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    callName: callName.present ? callName.value : this.callName,
    groupId: groupId ?? this.groupId,
    originNote: originNote.present ? originNote.value : this.originNote,
    createdAt: createdAt ?? this.createdAt,
    avatarJson: avatarJson.present ? avatarJson.value : this.avatarJson,
    seatIndex: seatIndex.present ? seatIndex.value : this.seatIndex,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StudentsTableData copyWithCompanion(StudentsTableCompanion data) {
    return StudentsTableData(
      id: data.id.present ? data.id.value : this.id,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      callName: data.callName.present ? data.callName.value : this.callName,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      originNote: data.originNote.present
          ? data.originNote.value
          : this.originNote,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      avatarJson: data.avatarJson.present
          ? data.avatarJson.value
          : this.avatarJson,
      seatIndex: data.seatIndex.present ? data.seatIndex.value : this.seatIndex,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudentsTableData(')
          ..write('id: $id, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('callName: $callName, ')
          ..write('groupId: $groupId, ')
          ..write('originNote: $originNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('avatarJson: $avatarJson, ')
          ..write('seatIndex: $seatIndex, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    firstName,
    lastName,
    callName,
    groupId,
    originNote,
    createdAt,
    avatarJson,
    seatIndex,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudentsTableData &&
          other.id == this.id &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.callName == this.callName &&
          other.groupId == this.groupId &&
          other.originNote == this.originNote &&
          other.createdAt == this.createdAt &&
          other.avatarJson == this.avatarJson &&
          other.seatIndex == this.seatIndex &&
          other.updatedAt == this.updatedAt);
}

class StudentsTableCompanion extends UpdateCompanion<StudentsTableData> {
  final Value<int> id;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<String?> callName;
  final Value<int> groupId;
  final Value<String?> originNote;
  final Value<DateTime> createdAt;
  final Value<String?> avatarJson;
  final Value<int?> seatIndex;
  final Value<DateTime> updatedAt;
  const StudentsTableCompanion({
    this.id = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.callName = const Value.absent(),
    this.groupId = const Value.absent(),
    this.originNote = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.avatarJson = const Value.absent(),
    this.seatIndex = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  StudentsTableCompanion.insert({
    this.id = const Value.absent(),
    required String firstName,
    required String lastName,
    this.callName = const Value.absent(),
    required int groupId,
    this.originNote = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.avatarJson = const Value.absent(),
    this.seatIndex = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : firstName = Value(firstName),
       lastName = Value(lastName),
       groupId = Value(groupId);
  static Insertable<StudentsTableData> custom({
    Expression<int>? id,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? callName,
    Expression<int>? groupId,
    Expression<String>? originNote,
    Expression<DateTime>? createdAt,
    Expression<String>? avatarJson,
    Expression<int>? seatIndex,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (callName != null) 'call_name': callName,
      if (groupId != null) 'group_id': groupId,
      if (originNote != null) 'origin_note': originNote,
      if (createdAt != null) 'created_at': createdAt,
      if (avatarJson != null) 'avatar_json': avatarJson,
      if (seatIndex != null) 'seat_index': seatIndex,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  StudentsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? firstName,
    Value<String>? lastName,
    Value<String?>? callName,
    Value<int>? groupId,
    Value<String?>? originNote,
    Value<DateTime>? createdAt,
    Value<String?>? avatarJson,
    Value<int?>? seatIndex,
    Value<DateTime>? updatedAt,
  }) {
    return StudentsTableCompanion(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      callName: callName ?? this.callName,
      groupId: groupId ?? this.groupId,
      originNote: originNote ?? this.originNote,
      createdAt: createdAt ?? this.createdAt,
      avatarJson: avatarJson ?? this.avatarJson,
      seatIndex: seatIndex ?? this.seatIndex,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (callName.present) {
      map['call_name'] = Variable<String>(callName.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (originNote.present) {
      map['origin_note'] = Variable<String>(originNote.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (avatarJson.present) {
      map['avatar_json'] = Variable<String>(avatarJson.value);
    }
    if (seatIndex.present) {
      map['seat_index'] = Variable<int>(seatIndex.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentsTableCompanion(')
          ..write('id: $id, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('callName: $callName, ')
          ..write('groupId: $groupId, ')
          ..write('originNote: $originNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('avatarJson: $avatarJson, ')
          ..write('seatIndex: $seatIndex, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AttendanceLogsTableTable extends AttendanceLogsTable
    with TableInfo<$AttendanceLogsTableTable, AttendanceLogsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceLogsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<int> studentId = GeneratedColumn<int>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES students_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAbsentMeta = const VerificationMeta(
    'isAbsent',
  );
  @override
  late final GeneratedColumn<bool> isAbsent = GeneratedColumn<bool>(
    'is_absent',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_absent" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isExcusedMeta = const VerificationMeta(
    'isExcused',
  );
  @override
  late final GeneratedColumn<bool> isExcused = GeneratedColumn<bool>(
    'is_excused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_excused" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    studentId,
    date,
    isAbsent,
    isExcused,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_logs_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttendanceLogsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('is_absent')) {
      context.handle(
        _isAbsentMeta,
        isAbsent.isAcceptableOrUnknown(data['is_absent']!, _isAbsentMeta),
      );
    }
    if (data.containsKey('is_excused')) {
      context.handle(
        _isExcusedMeta,
        isExcused.isAcceptableOrUnknown(data['is_excused']!, _isExcusedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendanceLogsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceLogsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}student_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      isAbsent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_absent'],
      )!,
      isExcused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_excused'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AttendanceLogsTableTable createAlias(String alias) {
    return $AttendanceLogsTableTable(attachedDatabase, alias);
  }
}

class AttendanceLogsTableData extends DataClass
    implements Insertable<AttendanceLogsTableData> {
  final int id;
  final int studentId;
  final DateTime date;
  final bool isAbsent;
  final bool isExcused;
  final DateTime createdAt;

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  final DateTime updatedAt;
  const AttendanceLogsTableData({
    required this.id,
    required this.studentId,
    required this.date,
    required this.isAbsent,
    required this.isExcused,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['student_id'] = Variable<int>(studentId);
    map['date'] = Variable<DateTime>(date);
    map['is_absent'] = Variable<bool>(isAbsent);
    map['is_excused'] = Variable<bool>(isExcused);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AttendanceLogsTableCompanion toCompanion(bool nullToAbsent) {
    return AttendanceLogsTableCompanion(
      id: Value(id),
      studentId: Value(studentId),
      date: Value(date),
      isAbsent: Value(isAbsent),
      isExcused: Value(isExcused),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AttendanceLogsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceLogsTableData(
      id: serializer.fromJson<int>(json['id']),
      studentId: serializer.fromJson<int>(json['studentId']),
      date: serializer.fromJson<DateTime>(json['date']),
      isAbsent: serializer.fromJson<bool>(json['isAbsent']),
      isExcused: serializer.fromJson<bool>(json['isExcused']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'studentId': serializer.toJson<int>(studentId),
      'date': serializer.toJson<DateTime>(date),
      'isAbsent': serializer.toJson<bool>(isAbsent),
      'isExcused': serializer.toJson<bool>(isExcused),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AttendanceLogsTableData copyWith({
    int? id,
    int? studentId,
    DateTime? date,
    bool? isAbsent,
    bool? isExcused,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AttendanceLogsTableData(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    date: date ?? this.date,
    isAbsent: isAbsent ?? this.isAbsent,
    isExcused: isExcused ?? this.isExcused,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AttendanceLogsTableData copyWithCompanion(AttendanceLogsTableCompanion data) {
    return AttendanceLogsTableData(
      id: data.id.present ? data.id.value : this.id,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      date: data.date.present ? data.date.value : this.date,
      isAbsent: data.isAbsent.present ? data.isAbsent.value : this.isAbsent,
      isExcused: data.isExcused.present ? data.isExcused.value : this.isExcused,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceLogsTableData(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('date: $date, ')
          ..write('isAbsent: $isAbsent, ')
          ..write('isExcused: $isExcused, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    studentId,
    date,
    isAbsent,
    isExcused,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceLogsTableData &&
          other.id == this.id &&
          other.studentId == this.studentId &&
          other.date == this.date &&
          other.isAbsent == this.isAbsent &&
          other.isExcused == this.isExcused &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AttendanceLogsTableCompanion
    extends UpdateCompanion<AttendanceLogsTableData> {
  final Value<int> id;
  final Value<int> studentId;
  final Value<DateTime> date;
  final Value<bool> isAbsent;
  final Value<bool> isExcused;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AttendanceLogsTableCompanion({
    this.id = const Value.absent(),
    this.studentId = const Value.absent(),
    this.date = const Value.absent(),
    this.isAbsent = const Value.absent(),
    this.isExcused = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AttendanceLogsTableCompanion.insert({
    this.id = const Value.absent(),
    required int studentId,
    required DateTime date,
    this.isAbsent = const Value.absent(),
    this.isExcused = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : studentId = Value(studentId),
       date = Value(date);
  static Insertable<AttendanceLogsTableData> custom({
    Expression<int>? id,
    Expression<int>? studentId,
    Expression<DateTime>? date,
    Expression<bool>? isAbsent,
    Expression<bool>? isExcused,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentId != null) 'student_id': studentId,
      if (date != null) 'date': date,
      if (isAbsent != null) 'is_absent': isAbsent,
      if (isExcused != null) 'is_excused': isExcused,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AttendanceLogsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? studentId,
    Value<DateTime>? date,
    Value<bool>? isAbsent,
    Value<bool>? isExcused,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return AttendanceLogsTableCompanion(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      isAbsent: isAbsent ?? this.isAbsent,
      isExcused: isExcused ?? this.isExcused,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<int>(studentId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (isAbsent.present) {
      map['is_absent'] = Variable<bool>(isAbsent.value);
    }
    if (isExcused.present) {
      map['is_excused'] = Variable<bool>(isExcused.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceLogsTableCompanion(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('date: $date, ')
          ..write('isAbsent: $isAbsent, ')
          ..write('isExcused: $isExcused, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $StudentRelationsTableTable extends StudentRelationsTable
    with TableInfo<$StudentRelationsTableTable, StudentRelation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudentRelationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _studentAIdMeta = const VerificationMeta(
    'studentAId',
  );
  @override
  late final GeneratedColumn<int> studentAId = GeneratedColumn<int>(
    'student_a_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES students_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _studentBIdMeta = const VerificationMeta(
    'studentBId',
  );
  @override
  late final GeneratedColumn<int> studentBId = GeneratedColumn<int>(
    'student_b_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES students_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _isPositiveMeta = const VerificationMeta(
    'isPositive',
  );
  @override
  late final GeneratedColumn<bool> isPositive = GeneratedColumn<bool>(
    'is_positive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_positive" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    studentAId,
    studentBId,
    isPositive,
    comment,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'student_relations_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudentRelation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('student_a_id')) {
      context.handle(
        _studentAIdMeta,
        studentAId.isAcceptableOrUnknown(
          data['student_a_id']!,
          _studentAIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_studentAIdMeta);
    }
    if (data.containsKey('student_b_id')) {
      context.handle(
        _studentBIdMeta,
        studentBId.isAcceptableOrUnknown(
          data['student_b_id']!,
          _studentBIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_studentBIdMeta);
    }
    if (data.containsKey('is_positive')) {
      context.handle(
        _isPositiveMeta,
        isPositive.isAcceptableOrUnknown(data['is_positive']!, _isPositiveMeta),
      );
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {studentAId, studentBId},
  ];
  @override
  StudentRelation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudentRelation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      studentAId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}student_a_id'],
      )!,
      studentBId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}student_b_id'],
      )!,
      isPositive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_positive'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StudentRelationsTableTable createAlias(String alias) {
    return $StudentRelationsTableTable(attachedDatabase, alias);
  }
}

class StudentRelation extends DataClass implements Insertable<StudentRelation> {
  final int id;
  final int studentAId;
  final int studentBId;

  /// `true` when the two should sit together, `false` when they should not.
  final bool isPositive;

  /// Why the rule exists, e.g. "talks too much with him".
  final String? comment;
  final DateTime createdAt;

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  final DateTime updatedAt;
  const StudentRelation({
    required this.id,
    required this.studentAId,
    required this.studentBId,
    required this.isPositive,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['student_a_id'] = Variable<int>(studentAId);
    map['student_b_id'] = Variable<int>(studentBId);
    map['is_positive'] = Variable<bool>(isPositive);
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StudentRelationsTableCompanion toCompanion(bool nullToAbsent) {
    return StudentRelationsTableCompanion(
      id: Value(id),
      studentAId: Value(studentAId),
      studentBId: Value(studentBId),
      isPositive: Value(isPositive),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StudentRelation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudentRelation(
      id: serializer.fromJson<int>(json['id']),
      studentAId: serializer.fromJson<int>(json['studentAId']),
      studentBId: serializer.fromJson<int>(json['studentBId']),
      isPositive: serializer.fromJson<bool>(json['isPositive']),
      comment: serializer.fromJson<String?>(json['comment']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'studentAId': serializer.toJson<int>(studentAId),
      'studentBId': serializer.toJson<int>(studentBId),
      'isPositive': serializer.toJson<bool>(isPositive),
      'comment': serializer.toJson<String?>(comment),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StudentRelation copyWith({
    int? id,
    int? studentAId,
    int? studentBId,
    bool? isPositive,
    Value<String?> comment = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StudentRelation(
    id: id ?? this.id,
    studentAId: studentAId ?? this.studentAId,
    studentBId: studentBId ?? this.studentBId,
    isPositive: isPositive ?? this.isPositive,
    comment: comment.present ? comment.value : this.comment,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StudentRelation copyWithCompanion(StudentRelationsTableCompanion data) {
    return StudentRelation(
      id: data.id.present ? data.id.value : this.id,
      studentAId: data.studentAId.present
          ? data.studentAId.value
          : this.studentAId,
      studentBId: data.studentBId.present
          ? data.studentBId.value
          : this.studentBId,
      isPositive: data.isPositive.present
          ? data.isPositive.value
          : this.isPositive,
      comment: data.comment.present ? data.comment.value : this.comment,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudentRelation(')
          ..write('id: $id, ')
          ..write('studentAId: $studentAId, ')
          ..write('studentBId: $studentBId, ')
          ..write('isPositive: $isPositive, ')
          ..write('comment: $comment, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    studentAId,
    studentBId,
    isPositive,
    comment,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudentRelation &&
          other.id == this.id &&
          other.studentAId == this.studentAId &&
          other.studentBId == this.studentBId &&
          other.isPositive == this.isPositive &&
          other.comment == this.comment &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StudentRelationsTableCompanion extends UpdateCompanion<StudentRelation> {
  final Value<int> id;
  final Value<int> studentAId;
  final Value<int> studentBId;
  final Value<bool> isPositive;
  final Value<String?> comment;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const StudentRelationsTableCompanion({
    this.id = const Value.absent(),
    this.studentAId = const Value.absent(),
    this.studentBId = const Value.absent(),
    this.isPositive = const Value.absent(),
    this.comment = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  StudentRelationsTableCompanion.insert({
    this.id = const Value.absent(),
    required int studentAId,
    required int studentBId,
    this.isPositive = const Value.absent(),
    this.comment = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : studentAId = Value(studentAId),
       studentBId = Value(studentBId);
  static Insertable<StudentRelation> custom({
    Expression<int>? id,
    Expression<int>? studentAId,
    Expression<int>? studentBId,
    Expression<bool>? isPositive,
    Expression<String>? comment,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentAId != null) 'student_a_id': studentAId,
      if (studentBId != null) 'student_b_id': studentBId,
      if (isPositive != null) 'is_positive': isPositive,
      if (comment != null) 'comment': comment,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  StudentRelationsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? studentAId,
    Value<int>? studentBId,
    Value<bool>? isPositive,
    Value<String?>? comment,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return StudentRelationsTableCompanion(
      id: id ?? this.id,
      studentAId: studentAId ?? this.studentAId,
      studentBId: studentBId ?? this.studentBId,
      isPositive: isPositive ?? this.isPositive,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (studentAId.present) {
      map['student_a_id'] = Variable<int>(studentAId.value);
    }
    if (studentBId.present) {
      map['student_b_id'] = Variable<int>(studentBId.value);
    }
    if (isPositive.present) {
      map['is_positive'] = Variable<bool>(isPositive.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentRelationsTableCompanion(')
          ..write('id: $id, ')
          ..write('studentAId: $studentAId, ')
          ..write('studentBId: $studentBId, ')
          ..write('isPositive: $isPositive, ')
          ..write('comment: $comment, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $GradeEntriesTableTable extends GradeEntriesTable
    with TableInfo<$GradeEntriesTableTable, GradeEntriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GradeEntriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<int> studentId = GeneratedColumn<int>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES students_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionLabelMeta = const VerificationMeta(
    'sessionLabel',
  );
  @override
  late final GeneratedColumn<String> sessionLabel = GeneratedColumn<String>(
    'session_label',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 24,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sonstige-mitarbeit'),
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Sonstige Mitarbeit'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    studentId,
    date,
    sessionLabel,
    value,
    categoryId,
    categoryName,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grade_entries_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<GradeEntriesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('session_label')) {
      context.handle(
        _sessionLabelMeta,
        sessionLabel.isAcceptableOrUnknown(
          data['session_label']!,
          _sessionLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionLabelMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GradeEntriesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GradeEntriesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}student_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      sessionLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_label'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $GradeEntriesTableTable createAlias(String alias) {
    return $GradeEntriesTableTable(attachedDatabase, alias);
  }
}

class GradeEntriesTableData extends DataClass
    implements Insertable<GradeEntriesTableData> {
  final int id;
  final int studentId;
  final DateTime date;
  final String sessionLabel;
  final String value;
  final String categoryId;
  final String categoryName;
  final DateTime createdAt;

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  final DateTime updatedAt;
  const GradeEntriesTableData({
    required this.id,
    required this.studentId,
    required this.date,
    required this.sessionLabel,
    required this.value,
    required this.categoryId,
    required this.categoryName,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['student_id'] = Variable<int>(studentId);
    map['date'] = Variable<DateTime>(date);
    map['session_label'] = Variable<String>(sessionLabel);
    map['value'] = Variable<String>(value);
    map['category_id'] = Variable<String>(categoryId);
    map['category_name'] = Variable<String>(categoryName);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GradeEntriesTableCompanion toCompanion(bool nullToAbsent) {
    return GradeEntriesTableCompanion(
      id: Value(id),
      studentId: Value(studentId),
      date: Value(date),
      sessionLabel: Value(sessionLabel),
      value: Value(value),
      categoryId: Value(categoryId),
      categoryName: Value(categoryName),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory GradeEntriesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GradeEntriesTableData(
      id: serializer.fromJson<int>(json['id']),
      studentId: serializer.fromJson<int>(json['studentId']),
      date: serializer.fromJson<DateTime>(json['date']),
      sessionLabel: serializer.fromJson<String>(json['sessionLabel']),
      value: serializer.fromJson<String>(json['value']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'studentId': serializer.toJson<int>(studentId),
      'date': serializer.toJson<DateTime>(date),
      'sessionLabel': serializer.toJson<String>(sessionLabel),
      'value': serializer.toJson<String>(value),
      'categoryId': serializer.toJson<String>(categoryId),
      'categoryName': serializer.toJson<String>(categoryName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  GradeEntriesTableData copyWith({
    int? id,
    int? studentId,
    DateTime? date,
    String? sessionLabel,
    String? value,
    String? categoryId,
    String? categoryName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => GradeEntriesTableData(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    date: date ?? this.date,
    sessionLabel: sessionLabel ?? this.sessionLabel,
    value: value ?? this.value,
    categoryId: categoryId ?? this.categoryId,
    categoryName: categoryName ?? this.categoryName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  GradeEntriesTableData copyWithCompanion(GradeEntriesTableCompanion data) {
    return GradeEntriesTableData(
      id: data.id.present ? data.id.value : this.id,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      date: data.date.present ? data.date.value : this.date,
      sessionLabel: data.sessionLabel.present
          ? data.sessionLabel.value
          : this.sessionLabel,
      value: data.value.present ? data.value.value : this.value,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GradeEntriesTableData(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('date: $date, ')
          ..write('sessionLabel: $sessionLabel, ')
          ..write('value: $value, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    studentId,
    date,
    sessionLabel,
    value,
    categoryId,
    categoryName,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GradeEntriesTableData &&
          other.id == this.id &&
          other.studentId == this.studentId &&
          other.date == this.date &&
          other.sessionLabel == this.sessionLabel &&
          other.value == this.value &&
          other.categoryId == this.categoryId &&
          other.categoryName == this.categoryName &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GradeEntriesTableCompanion
    extends UpdateCompanion<GradeEntriesTableData> {
  final Value<int> id;
  final Value<int> studentId;
  final Value<DateTime> date;
  final Value<String> sessionLabel;
  final Value<String> value;
  final Value<String> categoryId;
  final Value<String> categoryName;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const GradeEntriesTableCompanion({
    this.id = const Value.absent(),
    this.studentId = const Value.absent(),
    this.date = const Value.absent(),
    this.sessionLabel = const Value.absent(),
    this.value = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  GradeEntriesTableCompanion.insert({
    this.id = const Value.absent(),
    required int studentId,
    required DateTime date,
    required String sessionLabel,
    required String value,
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : studentId = Value(studentId),
       date = Value(date),
       sessionLabel = Value(sessionLabel),
       value = Value(value);
  static Insertable<GradeEntriesTableData> custom({
    Expression<int>? id,
    Expression<int>? studentId,
    Expression<DateTime>? date,
    Expression<String>? sessionLabel,
    Expression<String>? value,
    Expression<String>? categoryId,
    Expression<String>? categoryName,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentId != null) 'student_id': studentId,
      if (date != null) 'date': date,
      if (sessionLabel != null) 'session_label': sessionLabel,
      if (value != null) 'value': value,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  GradeEntriesTableCompanion copyWith({
    Value<int>? id,
    Value<int>? studentId,
    Value<DateTime>? date,
    Value<String>? sessionLabel,
    Value<String>? value,
    Value<String>? categoryId,
    Value<String>? categoryName,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return GradeEntriesTableCompanion(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      sessionLabel: sessionLabel ?? this.sessionLabel,
      value: value ?? this.value,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<int>(studentId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (sessionLabel.present) {
      map['session_label'] = Variable<String>(sessionLabel.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GradeEntriesTableCompanion(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('date: $date, ')
          ..write('sessionLabel: $sessionLabel, ')
          ..write('value: $value, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MaterialLogsTableTable extends MaterialLogsTable
    with TableInfo<$MaterialLogsTableTable, MaterialLogsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaterialLogsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<int> studentId = GeneratedColumn<int>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES students_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hadMaterialMeta = const VerificationMeta(
    'hadMaterial',
  );
  @override
  late final GeneratedColumn<bool> hadMaterial = GeneratedColumn<bool>(
    'had_material',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("had_material" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    studentId,
    date,
    hadMaterial,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'material_logs_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<MaterialLogsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('had_material')) {
      context.handle(
        _hadMaterialMeta,
        hadMaterial.isAcceptableOrUnknown(
          data['had_material']!,
          _hadMaterialMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MaterialLogsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaterialLogsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}student_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      hadMaterial: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}had_material'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MaterialLogsTableTable createAlias(String alias) {
    return $MaterialLogsTableTable(attachedDatabase, alias);
  }
}

class MaterialLogsTableData extends DataClass
    implements Insertable<MaterialLogsTableData> {
  final int id;
  final int studentId;
  final DateTime date;
  final bool hadMaterial;
  final DateTime createdAt;

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  final DateTime updatedAt;
  const MaterialLogsTableData({
    required this.id,
    required this.studentId,
    required this.date,
    required this.hadMaterial,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['student_id'] = Variable<int>(studentId);
    map['date'] = Variable<DateTime>(date);
    map['had_material'] = Variable<bool>(hadMaterial);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MaterialLogsTableCompanion toCompanion(bool nullToAbsent) {
    return MaterialLogsTableCompanion(
      id: Value(id),
      studentId: Value(studentId),
      date: Value(date),
      hadMaterial: Value(hadMaterial),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MaterialLogsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaterialLogsTableData(
      id: serializer.fromJson<int>(json['id']),
      studentId: serializer.fromJson<int>(json['studentId']),
      date: serializer.fromJson<DateTime>(json['date']),
      hadMaterial: serializer.fromJson<bool>(json['hadMaterial']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'studentId': serializer.toJson<int>(studentId),
      'date': serializer.toJson<DateTime>(date),
      'hadMaterial': serializer.toJson<bool>(hadMaterial),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MaterialLogsTableData copyWith({
    int? id,
    int? studentId,
    DateTime? date,
    bool? hadMaterial,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MaterialLogsTableData(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    date: date ?? this.date,
    hadMaterial: hadMaterial ?? this.hadMaterial,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MaterialLogsTableData copyWithCompanion(MaterialLogsTableCompanion data) {
    return MaterialLogsTableData(
      id: data.id.present ? data.id.value : this.id,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      date: data.date.present ? data.date.value : this.date,
      hadMaterial: data.hadMaterial.present
          ? data.hadMaterial.value
          : this.hadMaterial,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaterialLogsTableData(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('date: $date, ')
          ..write('hadMaterial: $hadMaterial, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, studentId, date, hadMaterial, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaterialLogsTableData &&
          other.id == this.id &&
          other.studentId == this.studentId &&
          other.date == this.date &&
          other.hadMaterial == this.hadMaterial &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MaterialLogsTableCompanion
    extends UpdateCompanion<MaterialLogsTableData> {
  final Value<int> id;
  final Value<int> studentId;
  final Value<DateTime> date;
  final Value<bool> hadMaterial;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const MaterialLogsTableCompanion({
    this.id = const Value.absent(),
    this.studentId = const Value.absent(),
    this.date = const Value.absent(),
    this.hadMaterial = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MaterialLogsTableCompanion.insert({
    this.id = const Value.absent(),
    required int studentId,
    required DateTime date,
    this.hadMaterial = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : studentId = Value(studentId),
       date = Value(date);
  static Insertable<MaterialLogsTableData> custom({
    Expression<int>? id,
    Expression<int>? studentId,
    Expression<DateTime>? date,
    Expression<bool>? hadMaterial,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentId != null) 'student_id': studentId,
      if (date != null) 'date': date,
      if (hadMaterial != null) 'had_material': hadMaterial,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MaterialLogsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? studentId,
    Value<DateTime>? date,
    Value<bool>? hadMaterial,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return MaterialLogsTableCompanion(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      hadMaterial: hadMaterial ?? this.hadMaterial,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<int>(studentId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (hadMaterial.present) {
      map['had_material'] = Variable<bool>(hadMaterial.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaterialLogsTableCompanion(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('date: $date, ')
          ..write('hadMaterial: $hadMaterial, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $HomeworkLogsTableTable extends HomeworkLogsTable
    with TableInfo<$HomeworkLogsTableTable, HomeworkLogsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HomeworkLogsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<int> studentId = GeneratedColumn<int>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES students_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hadHomeworkMeta = const VerificationMeta(
    'hadHomework',
  );
  @override
  late final GeneratedColumn<bool> hadHomework = GeneratedColumn<bool>(
    'had_homework',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("had_homework" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    studentId,
    date,
    hadHomework,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'homework_logs_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<HomeworkLogsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('had_homework')) {
      context.handle(
        _hadHomeworkMeta,
        hadHomework.isAcceptableOrUnknown(
          data['had_homework']!,
          _hadHomeworkMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HomeworkLogsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HomeworkLogsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}student_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      hadHomework: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}had_homework'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HomeworkLogsTableTable createAlias(String alias) {
    return $HomeworkLogsTableTable(attachedDatabase, alias);
  }
}

class HomeworkLogsTableData extends DataClass
    implements Insertable<HomeworkLogsTableData> {
  final int id;
  final int studentId;
  final DateTime date;
  final bool hadHomework;
  final DateTime createdAt;

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  final DateTime updatedAt;
  const HomeworkLogsTableData({
    required this.id,
    required this.studentId,
    required this.date,
    required this.hadHomework,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['student_id'] = Variable<int>(studentId);
    map['date'] = Variable<DateTime>(date);
    map['had_homework'] = Variable<bool>(hadHomework);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HomeworkLogsTableCompanion toCompanion(bool nullToAbsent) {
    return HomeworkLogsTableCompanion(
      id: Value(id),
      studentId: Value(studentId),
      date: Value(date),
      hadHomework: Value(hadHomework),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HomeworkLogsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HomeworkLogsTableData(
      id: serializer.fromJson<int>(json['id']),
      studentId: serializer.fromJson<int>(json['studentId']),
      date: serializer.fromJson<DateTime>(json['date']),
      hadHomework: serializer.fromJson<bool>(json['hadHomework']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'studentId': serializer.toJson<int>(studentId),
      'date': serializer.toJson<DateTime>(date),
      'hadHomework': serializer.toJson<bool>(hadHomework),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HomeworkLogsTableData copyWith({
    int? id,
    int? studentId,
    DateTime? date,
    bool? hadHomework,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => HomeworkLogsTableData(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    date: date ?? this.date,
    hadHomework: hadHomework ?? this.hadHomework,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HomeworkLogsTableData copyWithCompanion(HomeworkLogsTableCompanion data) {
    return HomeworkLogsTableData(
      id: data.id.present ? data.id.value : this.id,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      date: data.date.present ? data.date.value : this.date,
      hadHomework: data.hadHomework.present
          ? data.hadHomework.value
          : this.hadHomework,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HomeworkLogsTableData(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('date: $date, ')
          ..write('hadHomework: $hadHomework, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, studentId, date, hadHomework, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HomeworkLogsTableData &&
          other.id == this.id &&
          other.studentId == this.studentId &&
          other.date == this.date &&
          other.hadHomework == this.hadHomework &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HomeworkLogsTableCompanion
    extends UpdateCompanion<HomeworkLogsTableData> {
  final Value<int> id;
  final Value<int> studentId;
  final Value<DateTime> date;
  final Value<bool> hadHomework;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const HomeworkLogsTableCompanion({
    this.id = const Value.absent(),
    this.studentId = const Value.absent(),
    this.date = const Value.absent(),
    this.hadHomework = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  HomeworkLogsTableCompanion.insert({
    this.id = const Value.absent(),
    required int studentId,
    required DateTime date,
    this.hadHomework = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : studentId = Value(studentId),
       date = Value(date);
  static Insertable<HomeworkLogsTableData> custom({
    Expression<int>? id,
    Expression<int>? studentId,
    Expression<DateTime>? date,
    Expression<bool>? hadHomework,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentId != null) 'student_id': studentId,
      if (date != null) 'date': date,
      if (hadHomework != null) 'had_homework': hadHomework,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  HomeworkLogsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? studentId,
    Value<DateTime>? date,
    Value<bool>? hadHomework,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return HomeworkLogsTableCompanion(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      hadHomework: hadHomework ?? this.hadHomework,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<int>(studentId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (hadHomework.present) {
      map['had_homework'] = Variable<bool>(hadHomework.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HomeworkLogsTableCompanion(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('date: $date, ')
          ..write('hadHomework: $hadHomework, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LessonSlotsTableTable extends LessonSlotsTable
    with TableInfo<$LessonSlotsTableTable, LessonSlotsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonSlotsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES groups_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodStartMeta = const VerificationMeta(
    'periodStart',
  );
  @override
  late final GeneratedColumn<int> periodStart = GeneratedColumn<int>(
    'period_start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodEndMeta = const VerificationMeta(
    'periodEnd',
  );
  @override
  late final GeneratedColumn<int> periodEnd = GeneratedColumn<int>(
    'period_end',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sonstige-mitarbeit'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    weekday,
    periodStart,
    periodEnd,
    categoryId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_slots_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LessonSlotsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    } else if (isInserting) {
      context.missing(_weekdayMeta);
    }
    if (data.containsKey('period_start')) {
      context.handle(
        _periodStartMeta,
        periodStart.isAcceptableOrUnknown(
          data['period_start']!,
          _periodStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_periodStartMeta);
    }
    if (data.containsKey('period_end')) {
      context.handle(
        _periodEndMeta,
        periodEnd.isAcceptableOrUnknown(data['period_end']!, _periodEndMeta),
      );
    } else if (isInserting) {
      context.missing(_periodEndMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {groupId, weekday, periodStart},
  ];
  @override
  LessonSlotsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonSlotsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      )!,
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      )!,
      periodStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}period_start'],
      )!,
      periodEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}period_end'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LessonSlotsTableTable createAlias(String alias) {
    return $LessonSlotsTableTable(attachedDatabase, alias);
  }
}

class LessonSlotsTableData extends DataClass
    implements Insertable<LessonSlotsTableData> {
  final int id;
  final int groupId;

  /// ISO weekday, [DateTime.monday] (1) through [DateTime.sunday] (7).
  final int weekday;

  /// First school period of the slot, 1-based.
  final int periodStart;

  /// Last school period of the slot, inclusive. Equals [periodStart] for a
  /// slot that is a single period long.
  final int periodEnd;

  /// Grade category that lessons planned from this slot default to.
  final String categoryId;
  final DateTime createdAt;

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  final DateTime updatedAt;
  const LessonSlotsTableData({
    required this.id,
    required this.groupId,
    required this.weekday,
    required this.periodStart,
    required this.periodEnd,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['group_id'] = Variable<int>(groupId);
    map['weekday'] = Variable<int>(weekday);
    map['period_start'] = Variable<int>(periodStart);
    map['period_end'] = Variable<int>(periodEnd);
    map['category_id'] = Variable<String>(categoryId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LessonSlotsTableCompanion toCompanion(bool nullToAbsent) {
    return LessonSlotsTableCompanion(
      id: Value(id),
      groupId: Value(groupId),
      weekday: Value(weekday),
      periodStart: Value(periodStart),
      periodEnd: Value(periodEnd),
      categoryId: Value(categoryId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LessonSlotsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonSlotsTableData(
      id: serializer.fromJson<int>(json['id']),
      groupId: serializer.fromJson<int>(json['groupId']),
      weekday: serializer.fromJson<int>(json['weekday']),
      periodStart: serializer.fromJson<int>(json['periodStart']),
      periodEnd: serializer.fromJson<int>(json['periodEnd']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'groupId': serializer.toJson<int>(groupId),
      'weekday': serializer.toJson<int>(weekday),
      'periodStart': serializer.toJson<int>(periodStart),
      'periodEnd': serializer.toJson<int>(periodEnd),
      'categoryId': serializer.toJson<String>(categoryId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LessonSlotsTableData copyWith({
    int? id,
    int? groupId,
    int? weekday,
    int? periodStart,
    int? periodEnd,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LessonSlotsTableData(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    weekday: weekday ?? this.weekday,
    periodStart: periodStart ?? this.periodStart,
    periodEnd: periodEnd ?? this.periodEnd,
    categoryId: categoryId ?? this.categoryId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LessonSlotsTableData copyWithCompanion(LessonSlotsTableCompanion data) {
    return LessonSlotsTableData(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      periodStart: data.periodStart.present
          ? data.periodStart.value
          : this.periodStart,
      periodEnd: data.periodEnd.present ? data.periodEnd.value : this.periodEnd,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonSlotsTableData(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('weekday: $weekday, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('categoryId: $categoryId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    weekday,
    periodStart,
    periodEnd,
    categoryId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonSlotsTableData &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.weekday == this.weekday &&
          other.periodStart == this.periodStart &&
          other.periodEnd == this.periodEnd &&
          other.categoryId == this.categoryId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LessonSlotsTableCompanion extends UpdateCompanion<LessonSlotsTableData> {
  final Value<int> id;
  final Value<int> groupId;
  final Value<int> weekday;
  final Value<int> periodStart;
  final Value<int> periodEnd;
  final Value<String> categoryId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const LessonSlotsTableCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.weekday = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.periodEnd = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LessonSlotsTableCompanion.insert({
    this.id = const Value.absent(),
    required int groupId,
    required int weekday,
    required int periodStart,
    required int periodEnd,
    this.categoryId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : groupId = Value(groupId),
       weekday = Value(weekday),
       periodStart = Value(periodStart),
       periodEnd = Value(periodEnd);
  static Insertable<LessonSlotsTableData> custom({
    Expression<int>? id,
    Expression<int>? groupId,
    Expression<int>? weekday,
    Expression<int>? periodStart,
    Expression<int>? periodEnd,
    Expression<String>? categoryId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (weekday != null) 'weekday': weekday,
      if (periodStart != null) 'period_start': periodStart,
      if (periodEnd != null) 'period_end': periodEnd,
      if (categoryId != null) 'category_id': categoryId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LessonSlotsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? groupId,
    Value<int>? weekday,
    Value<int>? periodStart,
    Value<int>? periodEnd,
    Value<String>? categoryId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return LessonSlotsTableCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      weekday: weekday ?? this.weekday,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (periodStart.present) {
      map['period_start'] = Variable<int>(periodStart.value);
    }
    if (periodEnd.present) {
      map['period_end'] = Variable<int>(periodEnd.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonSlotsTableCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('weekday: $weekday, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('categoryId: $categoryId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ListsTableTable extends ListsTable
    with TableInfo<$ListsTableTable, Checklist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES groups_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _touchedAtMeta = const VerificationMeta(
    'touchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> touchedAt = GeneratedColumn<DateTime>(
    'touched_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    name,
    createdAt,
    archivedAt,
    touchedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lists_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<Checklist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('touched_at')) {
      context.handle(
        _touchedAtMeta,
        touchedAt.isAcceptableOrUnknown(data['touched_at']!, _touchedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Checklist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Checklist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      touchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}touched_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ListsTableTable createAlias(String alias) {
    return $ListsTableTable(attachedDatabase, alias);
  }
}

class Checklist extends DataClass implements Insertable<Checklist> {
  final int id;
  final int? groupId;
  final String name;
  final DateTime createdAt;
  final DateTime? archivedAt;

  /// When the list was last worked on: an item added, ticked off, renamed or
  /// removed. `null` for lists nobody has touched since the column existed,
  /// which sort as if they were last used when they were made.
  final DateTime? touchedAt;

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  final DateTime updatedAt;
  const Checklist({
    required this.id,
    this.groupId,
    required this.name,
    required this.createdAt,
    this.archivedAt,
    this.touchedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<int>(groupId);
    }
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    if (!nullToAbsent || touchedAt != null) {
      map['touched_at'] = Variable<DateTime>(touchedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ListsTableCompanion toCompanion(bool nullToAbsent) {
    return ListsTableCompanion(
      id: Value(id),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      name: Value(name),
      createdAt: Value(createdAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      touchedAt: touchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(touchedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Checklist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Checklist(
      id: serializer.fromJson<int>(json['id']),
      groupId: serializer.fromJson<int?>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      touchedAt: serializer.fromJson<DateTime?>(json['touchedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'groupId': serializer.toJson<int?>(groupId),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'touchedAt': serializer.toJson<DateTime?>(touchedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Checklist copyWith({
    int? id,
    Value<int?> groupId = const Value.absent(),
    String? name,
    DateTime? createdAt,
    Value<DateTime?> archivedAt = const Value.absent(),
    Value<DateTime?> touchedAt = const Value.absent(),
    DateTime? updatedAt,
  }) => Checklist(
    id: id ?? this.id,
    groupId: groupId.present ? groupId.value : this.groupId,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    touchedAt: touchedAt.present ? touchedAt.value : this.touchedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Checklist copyWithCompanion(ListsTableCompanion data) {
    return Checklist(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      touchedAt: data.touchedAt.present ? data.touchedAt.value : this.touchedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Checklist(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('touchedAt: $touchedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    name,
    createdAt,
    archivedAt,
    touchedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Checklist &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.archivedAt == this.archivedAt &&
          other.touchedAt == this.touchedAt &&
          other.updatedAt == this.updatedAt);
}

class ListsTableCompanion extends UpdateCompanion<Checklist> {
  final Value<int> id;
  final Value<int?> groupId;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<DateTime?> archivedAt;
  final Value<DateTime?> touchedAt;
  final Value<DateTime> updatedAt;
  const ListsTableCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.touchedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ListsTableCompanion.insert({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    required String name,
    this.createdAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.touchedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Checklist> custom({
    Expression<int>? id,
    Expression<int>? groupId,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? archivedAt,
    Expression<DateTime>? touchedAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (touchedAt != null) 'touched_at': touchedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ListsTableCompanion copyWith({
    Value<int>? id,
    Value<int?>? groupId,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<DateTime?>? archivedAt,
    Value<DateTime?>? touchedAt,
    Value<DateTime>? updatedAt,
  }) {
    return ListsTableCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
      touchedAt: touchedAt ?? this.touchedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (touchedAt.present) {
      map['touched_at'] = Variable<DateTime>(touchedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListsTableCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('touchedAt: $touchedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ListItemsTableTable extends ListItemsTable
    with TableInfo<$ListItemsTableTable, ChecklistItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<int> listId = GeneratedColumn<int>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lists_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<int> studentId = GeneratedColumn<int>(
    'student_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES students_table (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _studentIdsJsonMeta = const VerificationMeta(
    'studentIdsJson',
  );
  @override
  late final GeneratedColumn<String> studentIdsJson = GeneratedColumn<String>(
    'student_ids_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 150,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checkedAtMeta = const VerificationMeta(
    'checkedAt',
  );
  @override
  late final GeneratedColumn<DateTime> checkedAt = GeneratedColumn<DateTime>(
    'checked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    listId,
    studentId,
    studentIdsJson,
    label,
    checkedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'list_items_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChecklistItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    }
    if (data.containsKey('student_ids_json')) {
      context.handle(
        _studentIdsJsonMeta,
        studentIdsJson.isAcceptableOrUnknown(
          data['student_ids_json']!,
          _studentIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('checked_at')) {
      context.handle(
        _checkedAtMeta,
        checkedAt.isAcceptableOrUnknown(data['checked_at']!, _checkedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChecklistItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChecklistItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}list_id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}student_id'],
      ),
      studentIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_ids_json'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      checkedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}checked_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ListItemsTableTable createAlias(String alias) {
    return $ListItemsTableTable(attachedDatabase, alias);
  }
}

class ChecklistItem extends DataClass implements Insertable<ChecklistItem> {
  final int id;
  final int listId;
  final int? studentId;
  final String? studentIdsJson;
  final String label;
  final DateTime? checkedAt;
  final DateTime createdAt;

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  final DateTime updatedAt;
  const ChecklistItem({
    required this.id,
    required this.listId,
    this.studentId,
    this.studentIdsJson,
    required this.label,
    this.checkedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['list_id'] = Variable<int>(listId);
    if (!nullToAbsent || studentId != null) {
      map['student_id'] = Variable<int>(studentId);
    }
    if (!nullToAbsent || studentIdsJson != null) {
      map['student_ids_json'] = Variable<String>(studentIdsJson);
    }
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || checkedAt != null) {
      map['checked_at'] = Variable<DateTime>(checkedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ListItemsTableCompanion toCompanion(bool nullToAbsent) {
    return ListItemsTableCompanion(
      id: Value(id),
      listId: Value(listId),
      studentId: studentId == null && nullToAbsent
          ? const Value.absent()
          : Value(studentId),
      studentIdsJson: studentIdsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(studentIdsJson),
      label: Value(label),
      checkedAt: checkedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(checkedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChecklistItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChecklistItem(
      id: serializer.fromJson<int>(json['id']),
      listId: serializer.fromJson<int>(json['listId']),
      studentId: serializer.fromJson<int?>(json['studentId']),
      studentIdsJson: serializer.fromJson<String?>(json['studentIdsJson']),
      label: serializer.fromJson<String>(json['label']),
      checkedAt: serializer.fromJson<DateTime?>(json['checkedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'listId': serializer.toJson<int>(listId),
      'studentId': serializer.toJson<int?>(studentId),
      'studentIdsJson': serializer.toJson<String?>(studentIdsJson),
      'label': serializer.toJson<String>(label),
      'checkedAt': serializer.toJson<DateTime?>(checkedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ChecklistItem copyWith({
    int? id,
    int? listId,
    Value<int?> studentId = const Value.absent(),
    Value<String?> studentIdsJson = const Value.absent(),
    String? label,
    Value<DateTime?> checkedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ChecklistItem(
    id: id ?? this.id,
    listId: listId ?? this.listId,
    studentId: studentId.present ? studentId.value : this.studentId,
    studentIdsJson: studentIdsJson.present
        ? studentIdsJson.value
        : this.studentIdsJson,
    label: label ?? this.label,
    checkedAt: checkedAt.present ? checkedAt.value : this.checkedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ChecklistItem copyWithCompanion(ListItemsTableCompanion data) {
    return ChecklistItem(
      id: data.id.present ? data.id.value : this.id,
      listId: data.listId.present ? data.listId.value : this.listId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      studentIdsJson: data.studentIdsJson.present
          ? data.studentIdsJson.value
          : this.studentIdsJson,
      label: data.label.present ? data.label.value : this.label,
      checkedAt: data.checkedAt.present ? data.checkedAt.value : this.checkedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistItem(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('studentId: $studentId, ')
          ..write('studentIdsJson: $studentIdsJson, ')
          ..write('label: $label, ')
          ..write('checkedAt: $checkedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    listId,
    studentId,
    studentIdsJson,
    label,
    checkedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistItem &&
          other.id == this.id &&
          other.listId == this.listId &&
          other.studentId == this.studentId &&
          other.studentIdsJson == this.studentIdsJson &&
          other.label == this.label &&
          other.checkedAt == this.checkedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ListItemsTableCompanion extends UpdateCompanion<ChecklistItem> {
  final Value<int> id;
  final Value<int> listId;
  final Value<int?> studentId;
  final Value<String?> studentIdsJson;
  final Value<String> label;
  final Value<DateTime?> checkedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ListItemsTableCompanion({
    this.id = const Value.absent(),
    this.listId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.studentIdsJson = const Value.absent(),
    this.label = const Value.absent(),
    this.checkedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ListItemsTableCompanion.insert({
    this.id = const Value.absent(),
    required int listId,
    this.studentId = const Value.absent(),
    this.studentIdsJson = const Value.absent(),
    required String label,
    this.checkedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : listId = Value(listId),
       label = Value(label);
  static Insertable<ChecklistItem> custom({
    Expression<int>? id,
    Expression<int>? listId,
    Expression<int>? studentId,
    Expression<String>? studentIdsJson,
    Expression<String>? label,
    Expression<DateTime>? checkedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listId != null) 'list_id': listId,
      if (studentId != null) 'student_id': studentId,
      if (studentIdsJson != null) 'student_ids_json': studentIdsJson,
      if (label != null) 'label': label,
      if (checkedAt != null) 'checked_at': checkedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ListItemsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? listId,
    Value<int?>? studentId,
    Value<String?>? studentIdsJson,
    Value<String>? label,
    Value<DateTime?>? checkedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ListItemsTableCompanion(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      studentId: studentId ?? this.studentId,
      studentIdsJson: studentIdsJson ?? this.studentIdsJson,
      label: label ?? this.label,
      checkedAt: checkedAt ?? this.checkedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<int>(listId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<int>(studentId.value);
    }
    if (studentIdsJson.present) {
      map['student_ids_json'] = Variable<String>(studentIdsJson.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (checkedAt.present) {
      map['checked_at'] = Variable<DateTime>(checkedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('studentId: $studentId, ')
          ..write('studentIdsJson: $studentIdsJson, ')
          ..write('label: $label, ')
          ..write('checkedAt: $checkedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $NotesTableTable extends NotesTable
    with TableInfo<$NotesTableTable, TeacherNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 5000,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES groups_table (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<int> studentId = GeneratedColumn<int>(
    'student_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES students_table (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _studentIdsJsonMeta = const VerificationMeta(
    'studentIdsJson',
  );
  @override
  late final GeneratedColumn<String> studentIdsJson = GeneratedColumn<String>(
    'student_ids_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isTodoMeta = const VerificationMeta('isTodo');
  @override
  late final GeneratedColumn<bool> isTodo = GeneratedColumn<bool>(
    'is_todo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_todo" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _todoDoneMeta = const VerificationMeta(
    'todoDone',
  );
  @override
  late final GeneratedColumn<bool> todoDone = GeneratedColumn<bool>(
    'todo_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("todo_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _todoDoneAtMeta = const VerificationMeta(
    'todoDoneAt',
  );
  @override
  late final GeneratedColumn<DateTime> todoDoneAt = GeneratedColumn<DateTime>(
    'todo_done_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    body,
    groupId,
    studentId,
    studentIdsJson,
    isTodo,
    todoDone,
    todoDoneAt,
    createdAt,
    archivedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TeacherNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    }
    if (data.containsKey('student_ids_json')) {
      context.handle(
        _studentIdsJsonMeta,
        studentIdsJson.isAcceptableOrUnknown(
          data['student_ids_json']!,
          _studentIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_todo')) {
      context.handle(
        _isTodoMeta,
        isTodo.isAcceptableOrUnknown(data['is_todo']!, _isTodoMeta),
      );
    }
    if (data.containsKey('todo_done')) {
      context.handle(
        _todoDoneMeta,
        todoDone.isAcceptableOrUnknown(data['todo_done']!, _todoDoneMeta),
      );
    }
    if (data.containsKey('todo_done_at')) {
      context.handle(
        _todoDoneAtMeta,
        todoDoneAt.isAcceptableOrUnknown(
          data['todo_done_at']!,
          _todoDoneAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TeacherNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeacherNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      ),
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}student_id'],
      ),
      studentIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_ids_json'],
      ),
      isTodo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_todo'],
      )!,
      todoDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}todo_done'],
      )!,
      todoDoneAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}todo_done_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NotesTableTable createAlias(String alias) {
    return $NotesTableTable(attachedDatabase, alias);
  }
}

class TeacherNote extends DataClass implements Insertable<TeacherNote> {
  final int id;
  final String body;
  final int? groupId;
  final int? studentId;
  final String? studentIdsJson;
  final bool isTodo;
  final bool todoDone;
  final DateTime? todoDoneAt;
  final DateTime createdAt;
  final DateTime? archivedAt;

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  final DateTime updatedAt;
  const TeacherNote({
    required this.id,
    required this.body,
    this.groupId,
    this.studentId,
    this.studentIdsJson,
    required this.isTodo,
    required this.todoDone,
    this.todoDoneAt,
    required this.createdAt,
    this.archivedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<int>(groupId);
    }
    if (!nullToAbsent || studentId != null) {
      map['student_id'] = Variable<int>(studentId);
    }
    if (!nullToAbsent || studentIdsJson != null) {
      map['student_ids_json'] = Variable<String>(studentIdsJson);
    }
    map['is_todo'] = Variable<bool>(isTodo);
    map['todo_done'] = Variable<bool>(todoDone);
    if (!nullToAbsent || todoDoneAt != null) {
      map['todo_done_at'] = Variable<DateTime>(todoDoneAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NotesTableCompanion toCompanion(bool nullToAbsent) {
    return NotesTableCompanion(
      id: Value(id),
      body: Value(body),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      studentId: studentId == null && nullToAbsent
          ? const Value.absent()
          : Value(studentId),
      studentIdsJson: studentIdsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(studentIdsJson),
      isTodo: Value(isTodo),
      todoDone: Value(todoDone),
      todoDoneAt: todoDoneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(todoDoneAt),
      createdAt: Value(createdAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TeacherNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeacherNote(
      id: serializer.fromJson<int>(json['id']),
      body: serializer.fromJson<String>(json['body']),
      groupId: serializer.fromJson<int?>(json['groupId']),
      studentId: serializer.fromJson<int?>(json['studentId']),
      studentIdsJson: serializer.fromJson<String?>(json['studentIdsJson']),
      isTodo: serializer.fromJson<bool>(json['isTodo']),
      todoDone: serializer.fromJson<bool>(json['todoDone']),
      todoDoneAt: serializer.fromJson<DateTime?>(json['todoDoneAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'body': serializer.toJson<String>(body),
      'groupId': serializer.toJson<int?>(groupId),
      'studentId': serializer.toJson<int?>(studentId),
      'studentIdsJson': serializer.toJson<String?>(studentIdsJson),
      'isTodo': serializer.toJson<bool>(isTodo),
      'todoDone': serializer.toJson<bool>(todoDone),
      'todoDoneAt': serializer.toJson<DateTime?>(todoDoneAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TeacherNote copyWith({
    int? id,
    String? body,
    Value<int?> groupId = const Value.absent(),
    Value<int?> studentId = const Value.absent(),
    Value<String?> studentIdsJson = const Value.absent(),
    bool? isTodo,
    bool? todoDone,
    Value<DateTime?> todoDoneAt = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> archivedAt = const Value.absent(),
    DateTime? updatedAt,
  }) => TeacherNote(
    id: id ?? this.id,
    body: body ?? this.body,
    groupId: groupId.present ? groupId.value : this.groupId,
    studentId: studentId.present ? studentId.value : this.studentId,
    studentIdsJson: studentIdsJson.present
        ? studentIdsJson.value
        : this.studentIdsJson,
    isTodo: isTodo ?? this.isTodo,
    todoDone: todoDone ?? this.todoDone,
    todoDoneAt: todoDoneAt.present ? todoDoneAt.value : this.todoDoneAt,
    createdAt: createdAt ?? this.createdAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TeacherNote copyWithCompanion(NotesTableCompanion data) {
    return TeacherNote(
      id: data.id.present ? data.id.value : this.id,
      body: data.body.present ? data.body.value : this.body,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      studentIdsJson: data.studentIdsJson.present
          ? data.studentIdsJson.value
          : this.studentIdsJson,
      isTodo: data.isTodo.present ? data.isTodo.value : this.isTodo,
      todoDone: data.todoDone.present ? data.todoDone.value : this.todoDone,
      todoDoneAt: data.todoDoneAt.present
          ? data.todoDoneAt.value
          : this.todoDoneAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeacherNote(')
          ..write('id: $id, ')
          ..write('body: $body, ')
          ..write('groupId: $groupId, ')
          ..write('studentId: $studentId, ')
          ..write('studentIdsJson: $studentIdsJson, ')
          ..write('isTodo: $isTodo, ')
          ..write('todoDone: $todoDone, ')
          ..write('todoDoneAt: $todoDoneAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    body,
    groupId,
    studentId,
    studentIdsJson,
    isTodo,
    todoDone,
    todoDoneAt,
    createdAt,
    archivedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeacherNote &&
          other.id == this.id &&
          other.body == this.body &&
          other.groupId == this.groupId &&
          other.studentId == this.studentId &&
          other.studentIdsJson == this.studentIdsJson &&
          other.isTodo == this.isTodo &&
          other.todoDone == this.todoDone &&
          other.todoDoneAt == this.todoDoneAt &&
          other.createdAt == this.createdAt &&
          other.archivedAt == this.archivedAt &&
          other.updatedAt == this.updatedAt);
}

class NotesTableCompanion extends UpdateCompanion<TeacherNote> {
  final Value<int> id;
  final Value<String> body;
  final Value<int?> groupId;
  final Value<int?> studentId;
  final Value<String?> studentIdsJson;
  final Value<bool> isTodo;
  final Value<bool> todoDone;
  final Value<DateTime?> todoDoneAt;
  final Value<DateTime> createdAt;
  final Value<DateTime?> archivedAt;
  final Value<DateTime> updatedAt;
  const NotesTableCompanion({
    this.id = const Value.absent(),
    this.body = const Value.absent(),
    this.groupId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.studentIdsJson = const Value.absent(),
    this.isTodo = const Value.absent(),
    this.todoDone = const Value.absent(),
    this.todoDoneAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NotesTableCompanion.insert({
    this.id = const Value.absent(),
    required String body,
    this.groupId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.studentIdsJson = const Value.absent(),
    this.isTodo = const Value.absent(),
    this.todoDone = const Value.absent(),
    this.todoDoneAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : body = Value(body);
  static Insertable<TeacherNote> custom({
    Expression<int>? id,
    Expression<String>? body,
    Expression<int>? groupId,
    Expression<int>? studentId,
    Expression<String>? studentIdsJson,
    Expression<bool>? isTodo,
    Expression<bool>? todoDone,
    Expression<DateTime>? todoDoneAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? archivedAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (body != null) 'body': body,
      if (groupId != null) 'group_id': groupId,
      if (studentId != null) 'student_id': studentId,
      if (studentIdsJson != null) 'student_ids_json': studentIdsJson,
      if (isTodo != null) 'is_todo': isTodo,
      if (todoDone != null) 'todo_done': todoDone,
      if (todoDoneAt != null) 'todo_done_at': todoDoneAt,
      if (createdAt != null) 'created_at': createdAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NotesTableCompanion copyWith({
    Value<int>? id,
    Value<String>? body,
    Value<int?>? groupId,
    Value<int?>? studentId,
    Value<String?>? studentIdsJson,
    Value<bool>? isTodo,
    Value<bool>? todoDone,
    Value<DateTime?>? todoDoneAt,
    Value<DateTime>? createdAt,
    Value<DateTime?>? archivedAt,
    Value<DateTime>? updatedAt,
  }) {
    return NotesTableCompanion(
      id: id ?? this.id,
      body: body ?? this.body,
      groupId: groupId ?? this.groupId,
      studentId: studentId ?? this.studentId,
      studentIdsJson: studentIdsJson ?? this.studentIdsJson,
      isTodo: isTodo ?? this.isTodo,
      todoDone: todoDone ?? this.todoDone,
      todoDoneAt: todoDoneAt ?? this.todoDoneAt,
      createdAt: createdAt ?? this.createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<int>(studentId.value);
    }
    if (studentIdsJson.present) {
      map['student_ids_json'] = Variable<String>(studentIdsJson.value);
    }
    if (isTodo.present) {
      map['is_todo'] = Variable<bool>(isTodo.value);
    }
    if (todoDone.present) {
      map['todo_done'] = Variable<bool>(todoDone.value);
    }
    if (todoDoneAt.present) {
      map['todo_done_at'] = Variable<DateTime>(todoDoneAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesTableCompanion(')
          ..write('id: $id, ')
          ..write('body: $body, ')
          ..write('groupId: $groupId, ')
          ..write('studentId: $studentId, ')
          ..write('studentIdsJson: $studentIdsJson, ')
          ..write('isTodo: $isTodo, ')
          ..write('todoDone: $todoDone, ')
          ..write('todoDoneAt: $todoDoneAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SeatingPlansTableTable extends SeatingPlansTable
    with TableInfo<$SeatingPlansTableTable, SeatingPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeatingPlansTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES groups_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _columnsMeta = const VerificationMeta(
    'columns',
  );
  @override
  late final GeneratedColumn<int> columns = GeneratedColumn<int>(
    'columns',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(6),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    name,
    columns,
    isDefault,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seating_plans_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeatingPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('columns')) {
      context.handle(
        _columnsMeta,
        columns.isAcceptableOrUnknown(data['columns']!, _columnsMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SeatingPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeatingPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      columns: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}columns'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SeatingPlansTableTable createAlias(String alias) {
    return $SeatingPlansTableTable(attachedDatabase, alias);
  }
}

class SeatingPlan extends DataClass implements Insertable<SeatingPlan> {
  final int id;
  final int groupId;
  final String name;

  /// Number of columns in the seating grid.
  final int columns;

  /// Whether this plan is the default for its group.
  ///
  /// At most one plan per group should have this set to `true`.
  final bool isDefault;
  final DateTime createdAt;

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  final DateTime updatedAt;
  const SeatingPlan({
    required this.id,
    required this.groupId,
    required this.name,
    required this.columns,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['group_id'] = Variable<int>(groupId);
    map['name'] = Variable<String>(name);
    map['columns'] = Variable<int>(columns);
    map['is_default'] = Variable<bool>(isDefault);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SeatingPlansTableCompanion toCompanion(bool nullToAbsent) {
    return SeatingPlansTableCompanion(
      id: Value(id),
      groupId: Value(groupId),
      name: Value(name),
      columns: Value(columns),
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SeatingPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeatingPlan(
      id: serializer.fromJson<int>(json['id']),
      groupId: serializer.fromJson<int>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
      columns: serializer.fromJson<int>(json['columns']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'groupId': serializer.toJson<int>(groupId),
      'name': serializer.toJson<String>(name),
      'columns': serializer.toJson<int>(columns),
      'isDefault': serializer.toJson<bool>(isDefault),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SeatingPlan copyWith({
    int? id,
    int? groupId,
    String? name,
    int? columns,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SeatingPlan(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    name: name ?? this.name,
    columns: columns ?? this.columns,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SeatingPlan copyWithCompanion(SeatingPlansTableCompanion data) {
    return SeatingPlan(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      name: data.name.present ? data.name.value : this.name,
      columns: data.columns.present ? data.columns.value : this.columns,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeatingPlan(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('columns: $columns, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, groupId, name, columns, isDefault, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeatingPlan &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.name == this.name &&
          other.columns == this.columns &&
          other.isDefault == this.isDefault &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SeatingPlansTableCompanion extends UpdateCompanion<SeatingPlan> {
  final Value<int> id;
  final Value<int> groupId;
  final Value<String> name;
  final Value<int> columns;
  final Value<bool> isDefault;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SeatingPlansTableCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
    this.columns = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SeatingPlansTableCompanion.insert({
    this.id = const Value.absent(),
    required int groupId,
    required String name,
    this.columns = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : groupId = Value(groupId),
       name = Value(name);
  static Insertable<SeatingPlan> custom({
    Expression<int>? id,
    Expression<int>? groupId,
    Expression<String>? name,
    Expression<int>? columns,
    Expression<bool>? isDefault,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (name != null) 'name': name,
      if (columns != null) 'columns': columns,
      if (isDefault != null) 'is_default': isDefault,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SeatingPlansTableCompanion copyWith({
    Value<int>? id,
    Value<int>? groupId,
    Value<String>? name,
    Value<int>? columns,
    Value<bool>? isDefault,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SeatingPlansTableCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      columns: columns ?? this.columns,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (columns.present) {
      map['columns'] = Variable<int>(columns.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeatingPlansTableCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('columns: $columns, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SeatingPlanPositionsTableTable extends SeatingPlanPositionsTable
    with TableInfo<$SeatingPlanPositionsTableTable, SeatingPlanPosition> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeatingPlanPositionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _seatingPlanIdMeta = const VerificationMeta(
    'seatingPlanId',
  );
  @override
  late final GeneratedColumn<int> seatingPlanId = GeneratedColumn<int>(
    'seating_plan_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES seating_plans_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<int> studentId = GeneratedColumn<int>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES students_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _colIndexMeta = const VerificationMeta(
    'colIndex',
  );
  @override
  late final GeneratedColumn<int> colIndex = GeneratedColumn<int>(
    'col_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _rowIndexMeta = const VerificationMeta(
    'rowIndex',
  );
  @override
  late final GeneratedColumn<int> rowIndex = GeneratedColumn<int>(
    'row_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    seatingPlanId,
    studentId,
    colIndex,
    rowIndex,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seating_plan_positions_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeatingPlanPosition> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('seating_plan_id')) {
      context.handle(
        _seatingPlanIdMeta,
        seatingPlanId.isAcceptableOrUnknown(
          data['seating_plan_id']!,
          _seatingPlanIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seatingPlanIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('col_index')) {
      context.handle(
        _colIndexMeta,
        colIndex.isAcceptableOrUnknown(data['col_index']!, _colIndexMeta),
      );
    }
    if (data.containsKey('row_index')) {
      context.handle(
        _rowIndexMeta,
        rowIndex.isAcceptableOrUnknown(data['row_index']!, _rowIndexMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {seatingPlanId, studentId},
  ];
  @override
  SeatingPlanPosition map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeatingPlanPosition(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      seatingPlanId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seating_plan_id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}student_id'],
      )!,
      colIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}col_index'],
      )!,
      rowIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_index'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SeatingPlanPositionsTableTable createAlias(String alias) {
    return $SeatingPlanPositionsTableTable(attachedDatabase, alias);
  }
}

class SeatingPlanPosition extends DataClass
    implements Insertable<SeatingPlanPosition> {
  final int id;
  final int seatingPlanId;
  final int studentId;

  /// Zero-based column index within the seating grid.
  final int colIndex;

  /// Zero-based row index within the seating grid.
  final int rowIndex;

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  final DateTime updatedAt;
  const SeatingPlanPosition({
    required this.id,
    required this.seatingPlanId,
    required this.studentId,
    required this.colIndex,
    required this.rowIndex,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['seating_plan_id'] = Variable<int>(seatingPlanId);
    map['student_id'] = Variable<int>(studentId);
    map['col_index'] = Variable<int>(colIndex);
    map['row_index'] = Variable<int>(rowIndex);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SeatingPlanPositionsTableCompanion toCompanion(bool nullToAbsent) {
    return SeatingPlanPositionsTableCompanion(
      id: Value(id),
      seatingPlanId: Value(seatingPlanId),
      studentId: Value(studentId),
      colIndex: Value(colIndex),
      rowIndex: Value(rowIndex),
      updatedAt: Value(updatedAt),
    );
  }

  factory SeatingPlanPosition.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeatingPlanPosition(
      id: serializer.fromJson<int>(json['id']),
      seatingPlanId: serializer.fromJson<int>(json['seatingPlanId']),
      studentId: serializer.fromJson<int>(json['studentId']),
      colIndex: serializer.fromJson<int>(json['colIndex']),
      rowIndex: serializer.fromJson<int>(json['rowIndex']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'seatingPlanId': serializer.toJson<int>(seatingPlanId),
      'studentId': serializer.toJson<int>(studentId),
      'colIndex': serializer.toJson<int>(colIndex),
      'rowIndex': serializer.toJson<int>(rowIndex),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SeatingPlanPosition copyWith({
    int? id,
    int? seatingPlanId,
    int? studentId,
    int? colIndex,
    int? rowIndex,
    DateTime? updatedAt,
  }) => SeatingPlanPosition(
    id: id ?? this.id,
    seatingPlanId: seatingPlanId ?? this.seatingPlanId,
    studentId: studentId ?? this.studentId,
    colIndex: colIndex ?? this.colIndex,
    rowIndex: rowIndex ?? this.rowIndex,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SeatingPlanPosition copyWithCompanion(
    SeatingPlanPositionsTableCompanion data,
  ) {
    return SeatingPlanPosition(
      id: data.id.present ? data.id.value : this.id,
      seatingPlanId: data.seatingPlanId.present
          ? data.seatingPlanId.value
          : this.seatingPlanId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      colIndex: data.colIndex.present ? data.colIndex.value : this.colIndex,
      rowIndex: data.rowIndex.present ? data.rowIndex.value : this.rowIndex,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeatingPlanPosition(')
          ..write('id: $id, ')
          ..write('seatingPlanId: $seatingPlanId, ')
          ..write('studentId: $studentId, ')
          ..write('colIndex: $colIndex, ')
          ..write('rowIndex: $rowIndex, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, seatingPlanId, studentId, colIndex, rowIndex, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeatingPlanPosition &&
          other.id == this.id &&
          other.seatingPlanId == this.seatingPlanId &&
          other.studentId == this.studentId &&
          other.colIndex == this.colIndex &&
          other.rowIndex == this.rowIndex &&
          other.updatedAt == this.updatedAt);
}

class SeatingPlanPositionsTableCompanion
    extends UpdateCompanion<SeatingPlanPosition> {
  final Value<int> id;
  final Value<int> seatingPlanId;
  final Value<int> studentId;
  final Value<int> colIndex;
  final Value<int> rowIndex;
  final Value<DateTime> updatedAt;
  const SeatingPlanPositionsTableCompanion({
    this.id = const Value.absent(),
    this.seatingPlanId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.colIndex = const Value.absent(),
    this.rowIndex = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SeatingPlanPositionsTableCompanion.insert({
    this.id = const Value.absent(),
    required int seatingPlanId,
    required int studentId,
    this.colIndex = const Value.absent(),
    this.rowIndex = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : seatingPlanId = Value(seatingPlanId),
       studentId = Value(studentId);
  static Insertable<SeatingPlanPosition> custom({
    Expression<int>? id,
    Expression<int>? seatingPlanId,
    Expression<int>? studentId,
    Expression<int>? colIndex,
    Expression<int>? rowIndex,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seatingPlanId != null) 'seating_plan_id': seatingPlanId,
      if (studentId != null) 'student_id': studentId,
      if (colIndex != null) 'col_index': colIndex,
      if (rowIndex != null) 'row_index': rowIndex,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SeatingPlanPositionsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? seatingPlanId,
    Value<int>? studentId,
    Value<int>? colIndex,
    Value<int>? rowIndex,
    Value<DateTime>? updatedAt,
  }) {
    return SeatingPlanPositionsTableCompanion(
      id: id ?? this.id,
      seatingPlanId: seatingPlanId ?? this.seatingPlanId,
      studentId: studentId ?? this.studentId,
      colIndex: colIndex ?? this.colIndex,
      rowIndex: rowIndex ?? this.rowIndex,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (seatingPlanId.present) {
      map['seating_plan_id'] = Variable<int>(seatingPlanId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<int>(studentId.value);
    }
    if (colIndex.present) {
      map['col_index'] = Variable<int>(colIndex.value);
    }
    if (rowIndex.present) {
      map['row_index'] = Variable<int>(rowIndex.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeatingPlanPositionsTableCompanion(')
          ..write('id: $id, ')
          ..write('seatingPlanId: $seatingPlanId, ')
          ..write('studentId: $studentId, ')
          ..write('colIndex: $colIndex, ')
          ..write('rowIndex: $rowIndex, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SessionsTableTable extends SessionsTable
    with TableInfo<$SessionsTableTable, SessionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES groups_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sonstige-mitarbeit'),
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Sonstige Mitarbeit'),
  );
  static const VerificationMeta _periodStartMeta = const VerificationMeta(
    'periodStart',
  );
  @override
  late final GeneratedColumn<int> periodStart = GeneratedColumn<int>(
    'period_start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _periodEndMeta = const VerificationMeta(
    'periodEnd',
  );
  @override
  late final GeneratedColumn<int> periodEnd = GeneratedColumn<int>(
    'period_end',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    date,
    label,
    description,
    categoryId,
    categoryName,
    periodStart,
    periodEnd,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    }
    if (data.containsKey('period_start')) {
      context.handle(
        _periodStartMeta,
        periodStart.isAcceptableOrUnknown(
          data['period_start']!,
          _periodStartMeta,
        ),
      );
    }
    if (data.containsKey('period_end')) {
      context.handle(
        _periodEndMeta,
        periodEnd.isAcceptableOrUnknown(data['period_end']!, _periodEndMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {groupId, date, categoryId, periodStart},
  ];
  @override
  SessionsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      )!,
      periodStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}period_start'],
      )!,
      periodEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}period_end'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SessionsTableTable createAlias(String alias) {
    return $SessionsTableTable(attachedDatabase, alias);
  }
}

class SessionsTableData extends DataClass
    implements Insertable<SessionsTableData> {
  final int id;
  final int groupId;
  final DateTime date;
  final String label;
  final String? description;
  final String categoryId;
  final String categoryName;

  /// First school period of the lesson, 1-based, or 0 when the lesson is not
  /// tied to a period. Lessons planned from a group's weekly schedule carry
  /// the periods of the slot they came from.
  final int periodStart;

  /// Last school period of the lesson, inclusive. Equals [periodStart] for a
  /// single-period lesson, 0 when [periodStart] is 0.
  final int periodEnd;
  final DateTime createdAt;

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  final DateTime updatedAt;
  const SessionsTableData({
    required this.id,
    required this.groupId,
    required this.date,
    required this.label,
    this.description,
    required this.categoryId,
    required this.categoryName,
    required this.periodStart,
    required this.periodEnd,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['group_id'] = Variable<int>(groupId);
    map['date'] = Variable<DateTime>(date);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['category_id'] = Variable<String>(categoryId);
    map['category_name'] = Variable<String>(categoryName);
    map['period_start'] = Variable<int>(periodStart);
    map['period_end'] = Variable<int>(periodEnd);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SessionsTableCompanion toCompanion(bool nullToAbsent) {
    return SessionsTableCompanion(
      id: Value(id),
      groupId: Value(groupId),
      date: Value(date),
      label: Value(label),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      categoryId: Value(categoryId),
      categoryName: Value(categoryName),
      periodStart: Value(periodStart),
      periodEnd: Value(periodEnd),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SessionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionsTableData(
      id: serializer.fromJson<int>(json['id']),
      groupId: serializer.fromJson<int>(json['groupId']),
      date: serializer.fromJson<DateTime>(json['date']),
      label: serializer.fromJson<String>(json['label']),
      description: serializer.fromJson<String?>(json['description']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      periodStart: serializer.fromJson<int>(json['periodStart']),
      periodEnd: serializer.fromJson<int>(json['periodEnd']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'groupId': serializer.toJson<int>(groupId),
      'date': serializer.toJson<DateTime>(date),
      'label': serializer.toJson<String>(label),
      'description': serializer.toJson<String?>(description),
      'categoryId': serializer.toJson<String>(categoryId),
      'categoryName': serializer.toJson<String>(categoryName),
      'periodStart': serializer.toJson<int>(periodStart),
      'periodEnd': serializer.toJson<int>(periodEnd),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SessionsTableData copyWith({
    int? id,
    int? groupId,
    DateTime? date,
    String? label,
    Value<String?> description = const Value.absent(),
    String? categoryId,
    String? categoryName,
    int? periodStart,
    int? periodEnd,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SessionsTableData(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    date: date ?? this.date,
    label: label ?? this.label,
    description: description.present ? description.value : this.description,
    categoryId: categoryId ?? this.categoryId,
    categoryName: categoryName ?? this.categoryName,
    periodStart: periodStart ?? this.periodStart,
    periodEnd: periodEnd ?? this.periodEnd,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SessionsTableData copyWithCompanion(SessionsTableCompanion data) {
    return SessionsTableData(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      date: data.date.present ? data.date.value : this.date,
      label: data.label.present ? data.label.value : this.label,
      description: data.description.present
          ? data.description.value
          : this.description,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      periodStart: data.periodStart.present
          ? data.periodStart.value
          : this.periodStart,
      periodEnd: data.periodEnd.present ? data.periodEnd.value : this.periodEnd,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionsTableData(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('date: $date, ')
          ..write('label: $label, ')
          ..write('description: $description, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    date,
    label,
    description,
    categoryId,
    categoryName,
    periodStart,
    periodEnd,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionsTableData &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.date == this.date &&
          other.label == this.label &&
          other.description == this.description &&
          other.categoryId == this.categoryId &&
          other.categoryName == this.categoryName &&
          other.periodStart == this.periodStart &&
          other.periodEnd == this.periodEnd &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SessionsTableCompanion extends UpdateCompanion<SessionsTableData> {
  final Value<int> id;
  final Value<int> groupId;
  final Value<DateTime> date;
  final Value<String> label;
  final Value<String?> description;
  final Value<String> categoryId;
  final Value<String> categoryName;
  final Value<int> periodStart;
  final Value<int> periodEnd;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SessionsTableCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.date = const Value.absent(),
    this.label = const Value.absent(),
    this.description = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.periodEnd = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SessionsTableCompanion.insert({
    this.id = const Value.absent(),
    required int groupId,
    required DateTime date,
    required String label,
    this.description = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.periodEnd = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : groupId = Value(groupId),
       date = Value(date),
       label = Value(label);
  static Insertable<SessionsTableData> custom({
    Expression<int>? id,
    Expression<int>? groupId,
    Expression<DateTime>? date,
    Expression<String>? label,
    Expression<String>? description,
    Expression<String>? categoryId,
    Expression<String>? categoryName,
    Expression<int>? periodStart,
    Expression<int>? periodEnd,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (date != null) 'date': date,
      if (label != null) 'label': label,
      if (description != null) 'description': description,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (periodStart != null) 'period_start': periodStart,
      if (periodEnd != null) 'period_end': periodEnd,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SessionsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? groupId,
    Value<DateTime>? date,
    Value<String>? label,
    Value<String?>? description,
    Value<String>? categoryId,
    Value<String>? categoryName,
    Value<int>? periodStart,
    Value<int>? periodEnd,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SessionsTableCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      date: date ?? this.date,
      label: label ?? this.label,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (periodStart.present) {
      map['period_start'] = Variable<int>(periodStart.value);
    }
    if (periodEnd.present) {
      map['period_end'] = Variable<int>(periodEnd.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsTableCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('date: $date, ')
          ..write('label: $label, ')
          ..write('description: $description, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TimeframesTableTable extends TimeframesTable
    with TableInfo<$TimeframesTableTable, TimeframesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimeframesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _schoolYearIdMeta = const VerificationMeta(
    'schoolYearId',
  );
  @override
  late final GeneratedColumn<int> schoolYearId = GeneratedColumn<int>(
    'school_year_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES school_years_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    schoolYearId,
    label,
    startDate,
    endDate,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timeframes_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimeframesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('school_year_id')) {
      context.handle(
        _schoolYearIdMeta,
        schoolYearId.isAcceptableOrUnknown(
          data['school_year_id']!,
          _schoolYearIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_schoolYearIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimeframesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimeframesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      schoolYearId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}school_year_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TimeframesTableTable createAlias(String alias) {
    return $TimeframesTableTable(attachedDatabase, alias);
  }
}

class TimeframesTableData extends DataClass
    implements Insertable<TimeframesTableData> {
  final int id;
  final int schoolYearId;
  final String label;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  final DateTime updatedAt;
  const TimeframesTableData({
    required this.id,
    required this.schoolYearId,
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['school_year_id'] = Variable<int>(schoolYearId);
    map['label'] = Variable<String>(label);
    map['start_date'] = Variable<DateTime>(startDate);
    map['end_date'] = Variable<DateTime>(endDate);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TimeframesTableCompanion toCompanion(bool nullToAbsent) {
    return TimeframesTableCompanion(
      id: Value(id),
      schoolYearId: Value(schoolYearId),
      label: Value(label),
      startDate: Value(startDate),
      endDate: Value(endDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TimeframesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimeframesTableData(
      id: serializer.fromJson<int>(json['id']),
      schoolYearId: serializer.fromJson<int>(json['schoolYearId']),
      label: serializer.fromJson<String>(json['label']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'schoolYearId': serializer.toJson<int>(schoolYearId),
      'label': serializer.toJson<String>(label),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TimeframesTableData copyWith({
    int? id,
    int? schoolYearId,
    String? label,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TimeframesTableData(
    id: id ?? this.id,
    schoolYearId: schoolYearId ?? this.schoolYearId,
    label: label ?? this.label,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TimeframesTableData copyWithCompanion(TimeframesTableCompanion data) {
    return TimeframesTableData(
      id: data.id.present ? data.id.value : this.id,
      schoolYearId: data.schoolYearId.present
          ? data.schoolYearId.value
          : this.schoolYearId,
      label: data.label.present ? data.label.value : this.label,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimeframesTableData(')
          ..write('id: $id, ')
          ..write('schoolYearId: $schoolYearId, ')
          ..write('label: $label, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    schoolYearId,
    label,
    startDate,
    endDate,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimeframesTableData &&
          other.id == this.id &&
          other.schoolYearId == this.schoolYearId &&
          other.label == this.label &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TimeframesTableCompanion extends UpdateCompanion<TimeframesTableData> {
  final Value<int> id;
  final Value<int> schoolYearId;
  final Value<String> label;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const TimeframesTableCompanion({
    this.id = const Value.absent(),
    this.schoolYearId = const Value.absent(),
    this.label = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TimeframesTableCompanion.insert({
    this.id = const Value.absent(),
    required int schoolYearId,
    required String label,
    required DateTime startDate,
    required DateTime endDate,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : schoolYearId = Value(schoolYearId),
       label = Value(label),
       startDate = Value(startDate),
       endDate = Value(endDate);
  static Insertable<TimeframesTableData> custom({
    Expression<int>? id,
    Expression<int>? schoolYearId,
    Expression<String>? label,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (schoolYearId != null) 'school_year_id': schoolYearId,
      if (label != null) 'label': label,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TimeframesTableCompanion copyWith({
    Value<int>? id,
    Value<int>? schoolYearId,
    Value<String>? label,
    Value<DateTime>? startDate,
    Value<DateTime>? endDate,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return TimeframesTableCompanion(
      id: id ?? this.id,
      schoolYearId: schoolYearId ?? this.schoolYearId,
      label: label ?? this.label,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (schoolYearId.present) {
      map['school_year_id'] = Variable<int>(schoolYearId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimeframesTableCompanion(')
          ..write('id: $id, ')
          ..write('schoolYearId: $schoolYearId, ')
          ..write('label: $label, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TimeframeGradesTableTable extends TimeframeGradesTable
    with TableInfo<$TimeframeGradesTableTable, TimeframeGradesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimeframeGradesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timeframeIdMeta = const VerificationMeta(
    'timeframeId',
  );
  @override
  late final GeneratedColumn<int> timeframeId = GeneratedColumn<int>(
    'timeframe_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES timeframes_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<int> studentId = GeneratedColumn<int>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES students_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<String> grade = GeneratedColumn<String>(
    'grade',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timeframeId,
    studentId,
    grade,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timeframe_grades_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimeframeGradesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timeframe_id')) {
      context.handle(
        _timeframeIdMeta,
        timeframeId.isAcceptableOrUnknown(
          data['timeframe_id']!,
          _timeframeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeframeIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {timeframeId, studentId},
  ];
  @override
  TimeframeGradesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimeframeGradesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timeframeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timeframe_id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}student_id'],
      )!,
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grade'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TimeframeGradesTableTable createAlias(String alias) {
    return $TimeframeGradesTableTable(attachedDatabase, alias);
  }
}

class TimeframeGradesTableData extends DataClass
    implements Insertable<TimeframeGradesTableData> {
  final int id;
  final int timeframeId;
  final int studentId;
  final String grade;

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  final DateTime updatedAt;
  const TimeframeGradesTableData({
    required this.id,
    required this.timeframeId,
    required this.studentId,
    required this.grade,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timeframe_id'] = Variable<int>(timeframeId);
    map['student_id'] = Variable<int>(studentId);
    map['grade'] = Variable<String>(grade);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TimeframeGradesTableCompanion toCompanion(bool nullToAbsent) {
    return TimeframeGradesTableCompanion(
      id: Value(id),
      timeframeId: Value(timeframeId),
      studentId: Value(studentId),
      grade: Value(grade),
      updatedAt: Value(updatedAt),
    );
  }

  factory TimeframeGradesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimeframeGradesTableData(
      id: serializer.fromJson<int>(json['id']),
      timeframeId: serializer.fromJson<int>(json['timeframeId']),
      studentId: serializer.fromJson<int>(json['studentId']),
      grade: serializer.fromJson<String>(json['grade']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timeframeId': serializer.toJson<int>(timeframeId),
      'studentId': serializer.toJson<int>(studentId),
      'grade': serializer.toJson<String>(grade),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TimeframeGradesTableData copyWith({
    int? id,
    int? timeframeId,
    int? studentId,
    String? grade,
    DateTime? updatedAt,
  }) => TimeframeGradesTableData(
    id: id ?? this.id,
    timeframeId: timeframeId ?? this.timeframeId,
    studentId: studentId ?? this.studentId,
    grade: grade ?? this.grade,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TimeframeGradesTableData copyWithCompanion(
    TimeframeGradesTableCompanion data,
  ) {
    return TimeframeGradesTableData(
      id: data.id.present ? data.id.value : this.id,
      timeframeId: data.timeframeId.present
          ? data.timeframeId.value
          : this.timeframeId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      grade: data.grade.present ? data.grade.value : this.grade,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimeframeGradesTableData(')
          ..write('id: $id, ')
          ..write('timeframeId: $timeframeId, ')
          ..write('studentId: $studentId, ')
          ..write('grade: $grade, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, timeframeId, studentId, grade, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimeframeGradesTableData &&
          other.id == this.id &&
          other.timeframeId == this.timeframeId &&
          other.studentId == this.studentId &&
          other.grade == this.grade &&
          other.updatedAt == this.updatedAt);
}

class TimeframeGradesTableCompanion
    extends UpdateCompanion<TimeframeGradesTableData> {
  final Value<int> id;
  final Value<int> timeframeId;
  final Value<int> studentId;
  final Value<String> grade;
  final Value<DateTime> updatedAt;
  const TimeframeGradesTableCompanion({
    this.id = const Value.absent(),
    this.timeframeId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.grade = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TimeframeGradesTableCompanion.insert({
    this.id = const Value.absent(),
    required int timeframeId,
    required int studentId,
    required String grade,
    this.updatedAt = const Value.absent(),
  }) : timeframeId = Value(timeframeId),
       studentId = Value(studentId),
       grade = Value(grade);
  static Insertable<TimeframeGradesTableData> custom({
    Expression<int>? id,
    Expression<int>? timeframeId,
    Expression<int>? studentId,
    Expression<String>? grade,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timeframeId != null) 'timeframe_id': timeframeId,
      if (studentId != null) 'student_id': studentId,
      if (grade != null) 'grade': grade,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TimeframeGradesTableCompanion copyWith({
    Value<int>? id,
    Value<int>? timeframeId,
    Value<int>? studentId,
    Value<String>? grade,
    Value<DateTime>? updatedAt,
  }) {
    return TimeframeGradesTableCompanion(
      id: id ?? this.id,
      timeframeId: timeframeId ?? this.timeframeId,
      studentId: studentId ?? this.studentId,
      grade: grade ?? this.grade,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timeframeId.present) {
      map['timeframe_id'] = Variable<int>(timeframeId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<int>(studentId.value);
    }
    if (grade.present) {
      map['grade'] = Variable<String>(grade.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimeframeGradesTableCompanion(')
          ..write('id: $id, ')
          ..write('timeframeId: $timeframeId, ')
          ..write('studentId: $studentId, ')
          ..write('grade: $grade, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SchoolYearsTableTable schoolYearsTable = $SchoolYearsTableTable(
    this,
  );
  late final $GroupsTableTable groupsTable = $GroupsTableTable(this);
  late final $StudentsTableTable studentsTable = $StudentsTableTable(this);
  late final $AttendanceLogsTableTable attendanceLogsTable =
      $AttendanceLogsTableTable(this);
  late final $StudentRelationsTableTable studentRelationsTable =
      $StudentRelationsTableTable(this);
  late final $GradeEntriesTableTable gradeEntriesTable =
      $GradeEntriesTableTable(this);
  late final $MaterialLogsTableTable materialLogsTable =
      $MaterialLogsTableTable(this);
  late final $HomeworkLogsTableTable homeworkLogsTable =
      $HomeworkLogsTableTable(this);
  late final $LessonSlotsTableTable lessonSlotsTable = $LessonSlotsTableTable(
    this,
  );
  late final $ListsTableTable listsTable = $ListsTableTable(this);
  late final $ListItemsTableTable listItemsTable = $ListItemsTableTable(this);
  late final $NotesTableTable notesTable = $NotesTableTable(this);
  late final $SeatingPlansTableTable seatingPlansTable =
      $SeatingPlansTableTable(this);
  late final $SeatingPlanPositionsTableTable seatingPlanPositionsTable =
      $SeatingPlanPositionsTableTable(this);
  late final $SessionsTableTable sessionsTable = $SessionsTableTable(this);
  late final $TimeframesTableTable timeframesTable = $TimeframesTableTable(
    this,
  );
  late final $TimeframeGradesTableTable timeframeGradesTable =
      $TimeframeGradesTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    schoolYearsTable,
    groupsTable,
    studentsTable,
    attendanceLogsTable,
    studentRelationsTable,
    gradeEntriesTable,
    materialLogsTable,
    homeworkLogsTable,
    lessonSlotsTable,
    listsTable,
    listItemsTable,
    notesTable,
    seatingPlansTable,
    seatingPlanPositionsTable,
    sessionsTable,
    timeframesTable,
    timeframeGradesTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'school_years_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('groups_table', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'groups_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('students_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'students_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('attendance_logs_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'students_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('student_relations_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'students_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('student_relations_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'students_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('grade_entries_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'students_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('material_logs_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'students_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('homework_logs_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'groups_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lesson_slots_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'groups_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lists_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'lists_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('list_items_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'students_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('list_items_table', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'groups_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('notes_table', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'students_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('notes_table', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'groups_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('seating_plans_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'seating_plans_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('seating_plan_positions_table', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'students_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('seating_plan_positions_table', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'groups_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sessions_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'school_years_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('timeframes_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'timeframes_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('timeframe_grades_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'students_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('timeframe_grades_table', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SchoolYearsTableTableCreateCompanionBuilder =
    SchoolYearsTableCompanion Function({
      Value<int> id,
      required String label,
      required DateTime startDate,
      required DateTime endDate,
      Value<DateTime?> archivedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$SchoolYearsTableTableUpdateCompanionBuilder =
    SchoolYearsTableCompanion Function({
      Value<int> id,
      Value<String> label,
      Value<DateTime> startDate,
      Value<DateTime> endDate,
      Value<DateTime?> archivedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$SchoolYearsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SchoolYearsTableTable,
          SchoolYearsTableData
        > {
  $$SchoolYearsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$GroupsTableTable, List<GroupsTableData>>
  _groupsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.groupsTable,
    aliasName: $_aliasNameGenerator(
      db.schoolYearsTable.id,
      db.groupsTable.schoolYearId,
    ),
  );

  $$GroupsTableTableProcessedTableManager get groupsTableRefs {
    final manager = $$GroupsTableTableTableManager(
      $_db,
      $_db.groupsTable,
    ).filter((f) => f.schoolYearId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_groupsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TimeframesTableTable, List<TimeframesTableData>>
  _timeframesTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.timeframesTable,
    aliasName: $_aliasNameGenerator(
      db.schoolYearsTable.id,
      db.timeframesTable.schoolYearId,
    ),
  );

  $$TimeframesTableTableProcessedTableManager get timeframesTableRefs {
    final manager = $$TimeframesTableTableTableManager(
      $_db,
      $_db.timeframesTable,
    ).filter((f) => f.schoolYearId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _timeframesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SchoolYearsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SchoolYearsTableTable> {
  $$SchoolYearsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> groupsTableRefs(
    Expression<bool> Function($$GroupsTableTableFilterComposer f) f,
  ) {
    final $$GroupsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groupsTable,
      getReferencedColumn: (t) => t.schoolYearId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableTableFilterComposer(
            $db: $db,
            $table: $db.groupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> timeframesTableRefs(
    Expression<bool> Function($$TimeframesTableTableFilterComposer f) f,
  ) {
    final $$TimeframesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timeframesTable,
      getReferencedColumn: (t) => t.schoolYearId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimeframesTableTableFilterComposer(
            $db: $db,
            $table: $db.timeframesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SchoolYearsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SchoolYearsTableTable> {
  $$SchoolYearsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SchoolYearsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchoolYearsTableTable> {
  $$SchoolYearsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> groupsTableRefs<T extends Object>(
    Expression<T> Function($$GroupsTableTableAnnotationComposer a) f,
  ) {
    final $$GroupsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groupsTable,
      getReferencedColumn: (t) => t.schoolYearId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.groupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> timeframesTableRefs<T extends Object>(
    Expression<T> Function($$TimeframesTableTableAnnotationComposer a) f,
  ) {
    final $$TimeframesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timeframesTable,
      getReferencedColumn: (t) => t.schoolYearId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimeframesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.timeframesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SchoolYearsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchoolYearsTableTable,
          SchoolYearsTableData,
          $$SchoolYearsTableTableFilterComposer,
          $$SchoolYearsTableTableOrderingComposer,
          $$SchoolYearsTableTableAnnotationComposer,
          $$SchoolYearsTableTableCreateCompanionBuilder,
          $$SchoolYearsTableTableUpdateCompanionBuilder,
          (SchoolYearsTableData, $$SchoolYearsTableTableReferences),
          SchoolYearsTableData,
          PrefetchHooks Function({
            bool groupsTableRefs,
            bool timeframesTableRefs,
          })
        > {
  $$SchoolYearsTableTableTableManager(
    _$AppDatabase db,
    $SchoolYearsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchoolYearsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchoolYearsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchoolYearsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> endDate = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SchoolYearsTableCompanion(
                id: id,
                label: label,
                startDate: startDate,
                endDate: endDate,
                archivedAt: archivedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String label,
                required DateTime startDate,
                required DateTime endDate,
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SchoolYearsTableCompanion.insert(
                id: id,
                label: label,
                startDate: startDate,
                endDate: endDate,
                archivedAt: archivedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SchoolYearsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({groupsTableRefs = false, timeframesTableRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (groupsTableRefs) db.groupsTable,
                    if (timeframesTableRefs) db.timeframesTable,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (groupsTableRefs)
                        await $_getPrefetchedData<
                          SchoolYearsTableData,
                          $SchoolYearsTableTable,
                          GroupsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$SchoolYearsTableTableReferences
                              ._groupsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SchoolYearsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).groupsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.schoolYearId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (timeframesTableRefs)
                        await $_getPrefetchedData<
                          SchoolYearsTableData,
                          $SchoolYearsTableTable,
                          TimeframesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$SchoolYearsTableTableReferences
                              ._timeframesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SchoolYearsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).timeframesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.schoolYearId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SchoolYearsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchoolYearsTableTable,
      SchoolYearsTableData,
      $$SchoolYearsTableTableFilterComposer,
      $$SchoolYearsTableTableOrderingComposer,
      $$SchoolYearsTableTableAnnotationComposer,
      $$SchoolYearsTableTableCreateCompanionBuilder,
      $$SchoolYearsTableTableUpdateCompanionBuilder,
      (SchoolYearsTableData, $$SchoolYearsTableTableReferences),
      SchoolYearsTableData,
      PrefetchHooks Function({bool groupsTableRefs, bool timeframesTableRefs})
    >;
typedef $$GroupsTableTableCreateCompanionBuilder =
    GroupsTableCompanion Function({
      Value<int> id,
      required String name,
      Value<String> colorHex,
      Value<String> gradeScaleJson,
      Value<String> gradeCategoriesJson,
      Value<DateTime> createdAt,
      Value<DateTime?> archivedAt,
      Value<int?> schoolYearId,
      Value<DateTime> updatedAt,
    });
typedef $$GroupsTableTableUpdateCompanionBuilder =
    GroupsTableCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> colorHex,
      Value<String> gradeScaleJson,
      Value<String> gradeCategoriesJson,
      Value<DateTime> createdAt,
      Value<DateTime?> archivedAt,
      Value<int?> schoolYearId,
      Value<DateTime> updatedAt,
    });

final class $$GroupsTableTableReferences
    extends BaseReferences<_$AppDatabase, $GroupsTableTable, GroupsTableData> {
  $$GroupsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SchoolYearsTableTable _schoolYearIdTable(_$AppDatabase db) =>
      db.schoolYearsTable.createAlias(
        $_aliasNameGenerator(
          db.groupsTable.schoolYearId,
          db.schoolYearsTable.id,
        ),
      );

  $$SchoolYearsTableTableProcessedTableManager? get schoolYearId {
    final $_column = $_itemColumn<int>('school_year_id');
    if ($_column == null) return null;
    final manager = $$SchoolYearsTableTableTableManager(
      $_db,
      $_db.schoolYearsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_schoolYearIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$StudentsTableTable, List<StudentsTableData>>
  _studentsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.studentsTable,
    aliasName: $_aliasNameGenerator(
      db.groupsTable.id,
      db.studentsTable.groupId,
    ),
  );

  $$StudentsTableTableProcessedTableManager get studentsTableRefs {
    final manager = $$StudentsTableTableTableManager(
      $_db,
      $_db.studentsTable,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_studentsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LessonSlotsTableTable, List<LessonSlotsTableData>>
  _lessonSlotsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lessonSlotsTable,
    aliasName: $_aliasNameGenerator(
      db.groupsTable.id,
      db.lessonSlotsTable.groupId,
    ),
  );

  $$LessonSlotsTableTableProcessedTableManager get lessonSlotsTableRefs {
    final manager = $$LessonSlotsTableTableTableManager(
      $_db,
      $_db.lessonSlotsTable,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _lessonSlotsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ListsTableTable, List<Checklist>>
  _listsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.listsTable,
    aliasName: $_aliasNameGenerator(db.groupsTable.id, db.listsTable.groupId),
  );

  $$ListsTableTableProcessedTableManager get listsTableRefs {
    final manager = $$ListsTableTableTableManager(
      $_db,
      $_db.listsTable,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_listsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NotesTableTable, List<TeacherNote>>
  _notesTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.notesTable,
    aliasName: $_aliasNameGenerator(db.groupsTable.id, db.notesTable.groupId),
  );

  $$NotesTableTableProcessedTableManager get notesTableRefs {
    final manager = $$NotesTableTableTableManager(
      $_db,
      $_db.notesTable,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_notesTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SeatingPlansTableTable, List<SeatingPlan>>
  _seatingPlansTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.seatingPlansTable,
        aliasName: $_aliasNameGenerator(
          db.groupsTable.id,
          db.seatingPlansTable.groupId,
        ),
      );

  $$SeatingPlansTableTableProcessedTableManager get seatingPlansTableRefs {
    final manager = $$SeatingPlansTableTableTableManager(
      $_db,
      $_db.seatingPlansTable,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _seatingPlansTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SessionsTableTable, List<SessionsTableData>>
  _sessionsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionsTable,
    aliasName: $_aliasNameGenerator(
      db.groupsTable.id,
      db.sessionsTable.groupId,
    ),
  );

  $$SessionsTableTableProcessedTableManager get sessionsTableRefs {
    final manager = $$SessionsTableTableTableManager(
      $_db,
      $_db.sessionsTable,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GroupsTableTableFilterComposer
    extends Composer<_$AppDatabase, $GroupsTableTable> {
  $$GroupsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gradeScaleJson => $composableBuilder(
    column: $table.gradeScaleJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gradeCategoriesJson => $composableBuilder(
    column: $table.gradeCategoriesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SchoolYearsTableTableFilterComposer get schoolYearId {
    final $$SchoolYearsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.schoolYearId,
      referencedTable: $db.schoolYearsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchoolYearsTableTableFilterComposer(
            $db: $db,
            $table: $db.schoolYearsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> studentsTableRefs(
    Expression<bool> Function($$StudentsTableTableFilterComposer f) f,
  ) {
    final $$StudentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableFilterComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lessonSlotsTableRefs(
    Expression<bool> Function($$LessonSlotsTableTableFilterComposer f) f,
  ) {
    final $$LessonSlotsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lessonSlotsTable,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonSlotsTableTableFilterComposer(
            $db: $db,
            $table: $db.lessonSlotsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> listsTableRefs(
    Expression<bool> Function($$ListsTableTableFilterComposer f) f,
  ) {
    final $$ListsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.listsTable,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListsTableTableFilterComposer(
            $db: $db,
            $table: $db.listsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> notesTableRefs(
    Expression<bool> Function($$NotesTableTableFilterComposer f) f,
  ) {
    final $$NotesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notesTable,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableTableFilterComposer(
            $db: $db,
            $table: $db.notesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> seatingPlansTableRefs(
    Expression<bool> Function($$SeatingPlansTableTableFilterComposer f) f,
  ) {
    final $$SeatingPlansTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.seatingPlansTable,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeatingPlansTableTableFilterComposer(
            $db: $db,
            $table: $db.seatingPlansTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sessionsTableRefs(
    Expression<bool> Function($$SessionsTableTableFilterComposer f) f,
  ) {
    final $$SessionsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionsTable,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableTableFilterComposer(
            $db: $db,
            $table: $db.sessionsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GroupsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupsTableTable> {
  $$GroupsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gradeScaleJson => $composableBuilder(
    column: $table.gradeScaleJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gradeCategoriesJson => $composableBuilder(
    column: $table.gradeCategoriesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SchoolYearsTableTableOrderingComposer get schoolYearId {
    final $$SchoolYearsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.schoolYearId,
      referencedTable: $db.schoolYearsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchoolYearsTableTableOrderingComposer(
            $db: $db,
            $table: $db.schoolYearsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GroupsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupsTableTable> {
  $$GroupsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get gradeScaleJson => $composableBuilder(
    column: $table.gradeScaleJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gradeCategoriesJson => $composableBuilder(
    column: $table.gradeCategoriesJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SchoolYearsTableTableAnnotationComposer get schoolYearId {
    final $$SchoolYearsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.schoolYearId,
      referencedTable: $db.schoolYearsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchoolYearsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.schoolYearsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> studentsTableRefs<T extends Object>(
    Expression<T> Function($$StudentsTableTableAnnotationComposer a) f,
  ) {
    final $$StudentsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lessonSlotsTableRefs<T extends Object>(
    Expression<T> Function($$LessonSlotsTableTableAnnotationComposer a) f,
  ) {
    final $$LessonSlotsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lessonSlotsTable,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonSlotsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.lessonSlotsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> listsTableRefs<T extends Object>(
    Expression<T> Function($$ListsTableTableAnnotationComposer a) f,
  ) {
    final $$ListsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.listsTable,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.listsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> notesTableRefs<T extends Object>(
    Expression<T> Function($$NotesTableTableAnnotationComposer a) f,
  ) {
    final $$NotesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notesTable,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.notesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> seatingPlansTableRefs<T extends Object>(
    Expression<T> Function($$SeatingPlansTableTableAnnotationComposer a) f,
  ) {
    final $$SeatingPlansTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.seatingPlansTable,
          getReferencedColumn: (t) => t.groupId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SeatingPlansTableTableAnnotationComposer(
                $db: $db,
                $table: $db.seatingPlansTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> sessionsTableRefs<T extends Object>(
    Expression<T> Function($$SessionsTableTableAnnotationComposer a) f,
  ) {
    final $$SessionsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionsTable,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GroupsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupsTableTable,
          GroupsTableData,
          $$GroupsTableTableFilterComposer,
          $$GroupsTableTableOrderingComposer,
          $$GroupsTableTableAnnotationComposer,
          $$GroupsTableTableCreateCompanionBuilder,
          $$GroupsTableTableUpdateCompanionBuilder,
          (GroupsTableData, $$GroupsTableTableReferences),
          GroupsTableData,
          PrefetchHooks Function({
            bool schoolYearId,
            bool studentsTableRefs,
            bool lessonSlotsTableRefs,
            bool listsTableRefs,
            bool notesTableRefs,
            bool seatingPlansTableRefs,
            bool sessionsTableRefs,
          })
        > {
  $$GroupsTableTableTableManager(_$AppDatabase db, $GroupsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<String> gradeScaleJson = const Value.absent(),
                Value<String> gradeCategoriesJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int?> schoolYearId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GroupsTableCompanion(
                id: id,
                name: name,
                colorHex: colorHex,
                gradeScaleJson: gradeScaleJson,
                gradeCategoriesJson: gradeCategoriesJson,
                createdAt: createdAt,
                archivedAt: archivedAt,
                schoolYearId: schoolYearId,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> colorHex = const Value.absent(),
                Value<String> gradeScaleJson = const Value.absent(),
                Value<String> gradeCategoriesJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int?> schoolYearId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GroupsTableCompanion.insert(
                id: id,
                name: name,
                colorHex: colorHex,
                gradeScaleJson: gradeScaleJson,
                gradeCategoriesJson: gradeCategoriesJson,
                createdAt: createdAt,
                archivedAt: archivedAt,
                schoolYearId: schoolYearId,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GroupsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                schoolYearId = false,
                studentsTableRefs = false,
                lessonSlotsTableRefs = false,
                listsTableRefs = false,
                notesTableRefs = false,
                seatingPlansTableRefs = false,
                sessionsTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (studentsTableRefs) db.studentsTable,
                    if (lessonSlotsTableRefs) db.lessonSlotsTable,
                    if (listsTableRefs) db.listsTable,
                    if (notesTableRefs) db.notesTable,
                    if (seatingPlansTableRefs) db.seatingPlansTable,
                    if (sessionsTableRefs) db.sessionsTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (schoolYearId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.schoolYearId,
                                    referencedTable:
                                        $$GroupsTableTableReferences
                                            ._schoolYearIdTable(db),
                                    referencedColumn:
                                        $$GroupsTableTableReferences
                                            ._schoolYearIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (studentsTableRefs)
                        await $_getPrefetchedData<
                          GroupsTableData,
                          $GroupsTableTable,
                          StudentsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableTableReferences
                              ._studentsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).studentsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (lessonSlotsTableRefs)
                        await $_getPrefetchedData<
                          GroupsTableData,
                          $GroupsTableTable,
                          LessonSlotsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableTableReferences
                              ._lessonSlotsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).lessonSlotsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (listsTableRefs)
                        await $_getPrefetchedData<
                          GroupsTableData,
                          $GroupsTableTable,
                          Checklist
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableTableReferences
                              ._listsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).listsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (notesTableRefs)
                        await $_getPrefetchedData<
                          GroupsTableData,
                          $GroupsTableTable,
                          TeacherNote
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableTableReferences
                              ._notesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).notesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (seatingPlansTableRefs)
                        await $_getPrefetchedData<
                          GroupsTableData,
                          $GroupsTableTable,
                          SeatingPlan
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableTableReferences
                              ._seatingPlansTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).seatingPlansTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (sessionsTableRefs)
                        await $_getPrefetchedData<
                          GroupsTableData,
                          $GroupsTableTable,
                          SessionsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableTableReferences
                              ._sessionsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$GroupsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupsTableTable,
      GroupsTableData,
      $$GroupsTableTableFilterComposer,
      $$GroupsTableTableOrderingComposer,
      $$GroupsTableTableAnnotationComposer,
      $$GroupsTableTableCreateCompanionBuilder,
      $$GroupsTableTableUpdateCompanionBuilder,
      (GroupsTableData, $$GroupsTableTableReferences),
      GroupsTableData,
      PrefetchHooks Function({
        bool schoolYearId,
        bool studentsTableRefs,
        bool lessonSlotsTableRefs,
        bool listsTableRefs,
        bool notesTableRefs,
        bool seatingPlansTableRefs,
        bool sessionsTableRefs,
      })
    >;
typedef $$StudentsTableTableCreateCompanionBuilder =
    StudentsTableCompanion Function({
      Value<int> id,
      required String firstName,
      required String lastName,
      Value<String?> callName,
      required int groupId,
      Value<String?> originNote,
      Value<DateTime> createdAt,
      Value<String?> avatarJson,
      Value<int?> seatIndex,
      Value<DateTime> updatedAt,
    });
typedef $$StudentsTableTableUpdateCompanionBuilder =
    StudentsTableCompanion Function({
      Value<int> id,
      Value<String> firstName,
      Value<String> lastName,
      Value<String?> callName,
      Value<int> groupId,
      Value<String?> originNote,
      Value<DateTime> createdAt,
      Value<String?> avatarJson,
      Value<int?> seatIndex,
      Value<DateTime> updatedAt,
    });

final class $$StudentsTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $StudentsTableTable, StudentsTableData> {
  $$StudentsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GroupsTableTable _groupIdTable(_$AppDatabase db) =>
      db.groupsTable.createAlias(
        $_aliasNameGenerator(db.studentsTable.groupId, db.groupsTable.id),
      );

  $$GroupsTableTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<int>('group_id')!;

    final manager = $$GroupsTableTableTableManager(
      $_db,
      $_db.groupsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $AttendanceLogsTableTable,
    List<AttendanceLogsTableData>
  >
  _attendanceLogsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.attendanceLogsTable,
        aliasName: $_aliasNameGenerator(
          db.studentsTable.id,
          db.attendanceLogsTable.studentId,
        ),
      );

  $$AttendanceLogsTableTableProcessedTableManager get attendanceLogsTableRefs {
    final manager = $$AttendanceLogsTableTableTableManager(
      $_db,
      $_db.attendanceLogsTable,
    ).filter((f) => f.studentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _attendanceLogsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StudentRelationsTableTable, List<StudentRelation>>
  _relationsAsStudentATable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.studentRelationsTable,
    aliasName: $_aliasNameGenerator(
      db.studentsTable.id,
      db.studentRelationsTable.studentAId,
    ),
  );

  $$StudentRelationsTableTableProcessedTableManager get relationsAsStudentA {
    final manager = $$StudentRelationsTableTableTableManager(
      $_db,
      $_db.studentRelationsTable,
    ).filter((f) => f.studentAId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _relationsAsStudentATable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StudentRelationsTableTable, List<StudentRelation>>
  _relationsAsStudentBTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.studentRelationsTable,
    aliasName: $_aliasNameGenerator(
      db.studentsTable.id,
      db.studentRelationsTable.studentBId,
    ),
  );

  $$StudentRelationsTableTableProcessedTableManager get relationsAsStudentB {
    final manager = $$StudentRelationsTableTableTableManager(
      $_db,
      $_db.studentRelationsTable,
    ).filter((f) => f.studentBId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _relationsAsStudentBTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $GradeEntriesTableTable,
    List<GradeEntriesTableData>
  >
  _gradeEntriesTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.gradeEntriesTable,
        aliasName: $_aliasNameGenerator(
          db.studentsTable.id,
          db.gradeEntriesTable.studentId,
        ),
      );

  $$GradeEntriesTableTableProcessedTableManager get gradeEntriesTableRefs {
    final manager = $$GradeEntriesTableTableTableManager(
      $_db,
      $_db.gradeEntriesTable,
    ).filter((f) => f.studentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _gradeEntriesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $MaterialLogsTableTable,
    List<MaterialLogsTableData>
  >
  _materialLogsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.materialLogsTable,
        aliasName: $_aliasNameGenerator(
          db.studentsTable.id,
          db.materialLogsTable.studentId,
        ),
      );

  $$MaterialLogsTableTableProcessedTableManager get materialLogsTableRefs {
    final manager = $$MaterialLogsTableTableTableManager(
      $_db,
      $_db.materialLogsTable,
    ).filter((f) => f.studentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _materialLogsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $HomeworkLogsTableTable,
    List<HomeworkLogsTableData>
  >
  _homeworkLogsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.homeworkLogsTable,
        aliasName: $_aliasNameGenerator(
          db.studentsTable.id,
          db.homeworkLogsTable.studentId,
        ),
      );

  $$HomeworkLogsTableTableProcessedTableManager get homeworkLogsTableRefs {
    final manager = $$HomeworkLogsTableTableTableManager(
      $_db,
      $_db.homeworkLogsTable,
    ).filter((f) => f.studentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _homeworkLogsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ListItemsTableTable, List<ChecklistItem>>
  _listItemsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.listItemsTable,
    aliasName: $_aliasNameGenerator(
      db.studentsTable.id,
      db.listItemsTable.studentId,
    ),
  );

  $$ListItemsTableTableProcessedTableManager get listItemsTableRefs {
    final manager = $$ListItemsTableTableTableManager(
      $_db,
      $_db.listItemsTable,
    ).filter((f) => f.studentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_listItemsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NotesTableTable, List<TeacherNote>>
  _notesTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.notesTable,
    aliasName: $_aliasNameGenerator(
      db.studentsTable.id,
      db.notesTable.studentId,
    ),
  );

  $$NotesTableTableProcessedTableManager get notesTableRefs {
    final manager = $$NotesTableTableTableManager(
      $_db,
      $_db.notesTable,
    ).filter((f) => f.studentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_notesTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $SeatingPlanPositionsTableTable,
    List<SeatingPlanPosition>
  >
  _seatingPlanPositionsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.seatingPlanPositionsTable,
        aliasName: $_aliasNameGenerator(
          db.studentsTable.id,
          db.seatingPlanPositionsTable.studentId,
        ),
      );

  $$SeatingPlanPositionsTableTableProcessedTableManager
  get seatingPlanPositionsTableRefs {
    final manager = $$SeatingPlanPositionsTableTableTableManager(
      $_db,
      $_db.seatingPlanPositionsTable,
    ).filter((f) => f.studentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _seatingPlanPositionsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $TimeframeGradesTableTable,
    List<TimeframeGradesTableData>
  >
  _timeframeGradesTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.timeframeGradesTable,
        aliasName: $_aliasNameGenerator(
          db.studentsTable.id,
          db.timeframeGradesTable.studentId,
        ),
      );

  $$TimeframeGradesTableTableProcessedTableManager
  get timeframeGradesTableRefs {
    final manager = $$TimeframeGradesTableTableTableManager(
      $_db,
      $_db.timeframeGradesTable,
    ).filter((f) => f.studentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _timeframeGradesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StudentsTableTableFilterComposer
    extends Composer<_$AppDatabase, $StudentsTableTable> {
  $$StudentsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get callName => $composableBuilder(
    column: $table.callName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originNote => $composableBuilder(
    column: $table.originNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarJson => $composableBuilder(
    column: $table.avatarJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seatIndex => $composableBuilder(
    column: $table.seatIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableTableFilterComposer get groupId {
    final $$GroupsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableTableFilterComposer(
            $db: $db,
            $table: $db.groupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> attendanceLogsTableRefs(
    Expression<bool> Function($$AttendanceLogsTableTableFilterComposer f) f,
  ) {
    final $$AttendanceLogsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attendanceLogsTable,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttendanceLogsTableTableFilterComposer(
            $db: $db,
            $table: $db.attendanceLogsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> relationsAsStudentA(
    Expression<bool> Function($$StudentRelationsTableTableFilterComposer f) f,
  ) {
    final $$StudentRelationsTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.studentRelationsTable,
          getReferencedColumn: (t) => t.studentAId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$StudentRelationsTableTableFilterComposer(
                $db: $db,
                $table: $db.studentRelationsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> relationsAsStudentB(
    Expression<bool> Function($$StudentRelationsTableTableFilterComposer f) f,
  ) {
    final $$StudentRelationsTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.studentRelationsTable,
          getReferencedColumn: (t) => t.studentBId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$StudentRelationsTableTableFilterComposer(
                $db: $db,
                $table: $db.studentRelationsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> gradeEntriesTableRefs(
    Expression<bool> Function($$GradeEntriesTableTableFilterComposer f) f,
  ) {
    final $$GradeEntriesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gradeEntriesTable,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GradeEntriesTableTableFilterComposer(
            $db: $db,
            $table: $db.gradeEntriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> materialLogsTableRefs(
    Expression<bool> Function($$MaterialLogsTableTableFilterComposer f) f,
  ) {
    final $$MaterialLogsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.materialLogsTable,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MaterialLogsTableTableFilterComposer(
            $db: $db,
            $table: $db.materialLogsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> homeworkLogsTableRefs(
    Expression<bool> Function($$HomeworkLogsTableTableFilterComposer f) f,
  ) {
    final $$HomeworkLogsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.homeworkLogsTable,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HomeworkLogsTableTableFilterComposer(
            $db: $db,
            $table: $db.homeworkLogsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> listItemsTableRefs(
    Expression<bool> Function($$ListItemsTableTableFilterComposer f) f,
  ) {
    final $$ListItemsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.listItemsTable,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListItemsTableTableFilterComposer(
            $db: $db,
            $table: $db.listItemsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> notesTableRefs(
    Expression<bool> Function($$NotesTableTableFilterComposer f) f,
  ) {
    final $$NotesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notesTable,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableTableFilterComposer(
            $db: $db,
            $table: $db.notesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> seatingPlanPositionsTableRefs(
    Expression<bool> Function($$SeatingPlanPositionsTableTableFilterComposer f)
    f,
  ) {
    final $$SeatingPlanPositionsTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.seatingPlanPositionsTable,
          getReferencedColumn: (t) => t.studentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SeatingPlanPositionsTableTableFilterComposer(
                $db: $db,
                $table: $db.seatingPlanPositionsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> timeframeGradesTableRefs(
    Expression<bool> Function($$TimeframeGradesTableTableFilterComposer f) f,
  ) {
    final $$TimeframeGradesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timeframeGradesTable,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimeframeGradesTableTableFilterComposer(
            $db: $db,
            $table: $db.timeframeGradesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StudentsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $StudentsTableTable> {
  $$StudentsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get callName => $composableBuilder(
    column: $table.callName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originNote => $composableBuilder(
    column: $table.originNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarJson => $composableBuilder(
    column: $table.avatarJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seatIndex => $composableBuilder(
    column: $table.seatIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableTableOrderingComposer get groupId {
    final $$GroupsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableTableOrderingComposer(
            $db: $db,
            $table: $db.groupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StudentsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudentsTableTable> {
  $$StudentsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get callName =>
      $composableBuilder(column: $table.callName, builder: (column) => column);

  GeneratedColumn<String> get originNote => $composableBuilder(
    column: $table.originNote,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get avatarJson => $composableBuilder(
    column: $table.avatarJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seatIndex =>
      $composableBuilder(column: $table.seatIndex, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$GroupsTableTableAnnotationComposer get groupId {
    final $$GroupsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.groupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> attendanceLogsTableRefs<T extends Object>(
    Expression<T> Function($$AttendanceLogsTableTableAnnotationComposer a) f,
  ) {
    final $$AttendanceLogsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.attendanceLogsTable,
          getReferencedColumn: (t) => t.studentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AttendanceLogsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.attendanceLogsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> relationsAsStudentA<T extends Object>(
    Expression<T> Function($$StudentRelationsTableTableAnnotationComposer a) f,
  ) {
    final $$StudentRelationsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.studentRelationsTable,
          getReferencedColumn: (t) => t.studentAId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$StudentRelationsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.studentRelationsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> relationsAsStudentB<T extends Object>(
    Expression<T> Function($$StudentRelationsTableTableAnnotationComposer a) f,
  ) {
    final $$StudentRelationsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.studentRelationsTable,
          getReferencedColumn: (t) => t.studentBId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$StudentRelationsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.studentRelationsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> gradeEntriesTableRefs<T extends Object>(
    Expression<T> Function($$GradeEntriesTableTableAnnotationComposer a) f,
  ) {
    final $$GradeEntriesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.gradeEntriesTable,
          getReferencedColumn: (t) => t.studentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GradeEntriesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.gradeEntriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> materialLogsTableRefs<T extends Object>(
    Expression<T> Function($$MaterialLogsTableTableAnnotationComposer a) f,
  ) {
    final $$MaterialLogsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.materialLogsTable,
          getReferencedColumn: (t) => t.studentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MaterialLogsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.materialLogsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> homeworkLogsTableRefs<T extends Object>(
    Expression<T> Function($$HomeworkLogsTableTableAnnotationComposer a) f,
  ) {
    final $$HomeworkLogsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.homeworkLogsTable,
          getReferencedColumn: (t) => t.studentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$HomeworkLogsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.homeworkLogsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> listItemsTableRefs<T extends Object>(
    Expression<T> Function($$ListItemsTableTableAnnotationComposer a) f,
  ) {
    final $$ListItemsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.listItemsTable,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListItemsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.listItemsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> notesTableRefs<T extends Object>(
    Expression<T> Function($$NotesTableTableAnnotationComposer a) f,
  ) {
    final $$NotesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notesTable,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.notesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> seatingPlanPositionsTableRefs<T extends Object>(
    Expression<T> Function($$SeatingPlanPositionsTableTableAnnotationComposer a)
    f,
  ) {
    final $$SeatingPlanPositionsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.seatingPlanPositionsTable,
          getReferencedColumn: (t) => t.studentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SeatingPlanPositionsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.seatingPlanPositionsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> timeframeGradesTableRefs<T extends Object>(
    Expression<T> Function($$TimeframeGradesTableTableAnnotationComposer a) f,
  ) {
    final $$TimeframeGradesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.timeframeGradesTable,
          getReferencedColumn: (t) => t.studentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TimeframeGradesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.timeframeGradesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$StudentsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudentsTableTable,
          StudentsTableData,
          $$StudentsTableTableFilterComposer,
          $$StudentsTableTableOrderingComposer,
          $$StudentsTableTableAnnotationComposer,
          $$StudentsTableTableCreateCompanionBuilder,
          $$StudentsTableTableUpdateCompanionBuilder,
          (StudentsTableData, $$StudentsTableTableReferences),
          StudentsTableData,
          PrefetchHooks Function({
            bool groupId,
            bool attendanceLogsTableRefs,
            bool relationsAsStudentA,
            bool relationsAsStudentB,
            bool gradeEntriesTableRefs,
            bool materialLogsTableRefs,
            bool homeworkLogsTableRefs,
            bool listItemsTableRefs,
            bool notesTableRefs,
            bool seatingPlanPositionsTableRefs,
            bool timeframeGradesTableRefs,
          })
        > {
  $$StudentsTableTableTableManager(_$AppDatabase db, $StudentsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudentsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudentsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudentsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> firstName = const Value.absent(),
                Value<String> lastName = const Value.absent(),
                Value<String?> callName = const Value.absent(),
                Value<int> groupId = const Value.absent(),
                Value<String?> originNote = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> avatarJson = const Value.absent(),
                Value<int?> seatIndex = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => StudentsTableCompanion(
                id: id,
                firstName: firstName,
                lastName: lastName,
                callName: callName,
                groupId: groupId,
                originNote: originNote,
                createdAt: createdAt,
                avatarJson: avatarJson,
                seatIndex: seatIndex,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String firstName,
                required String lastName,
                Value<String?> callName = const Value.absent(),
                required int groupId,
                Value<String?> originNote = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> avatarJson = const Value.absent(),
                Value<int?> seatIndex = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => StudentsTableCompanion.insert(
                id: id,
                firstName: firstName,
                lastName: lastName,
                callName: callName,
                groupId: groupId,
                originNote: originNote,
                createdAt: createdAt,
                avatarJson: avatarJson,
                seatIndex: seatIndex,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StudentsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                groupId = false,
                attendanceLogsTableRefs = false,
                relationsAsStudentA = false,
                relationsAsStudentB = false,
                gradeEntriesTableRefs = false,
                materialLogsTableRefs = false,
                homeworkLogsTableRefs = false,
                listItemsTableRefs = false,
                notesTableRefs = false,
                seatingPlanPositionsTableRefs = false,
                timeframeGradesTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (attendanceLogsTableRefs) db.attendanceLogsTable,
                    if (relationsAsStudentA) db.studentRelationsTable,
                    if (relationsAsStudentB) db.studentRelationsTable,
                    if (gradeEntriesTableRefs) db.gradeEntriesTable,
                    if (materialLogsTableRefs) db.materialLogsTable,
                    if (homeworkLogsTableRefs) db.homeworkLogsTable,
                    if (listItemsTableRefs) db.listItemsTable,
                    if (notesTableRefs) db.notesTable,
                    if (seatingPlanPositionsTableRefs)
                      db.seatingPlanPositionsTable,
                    if (timeframeGradesTableRefs) db.timeframeGradesTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.groupId,
                                    referencedTable:
                                        $$StudentsTableTableReferences
                                            ._groupIdTable(db),
                                    referencedColumn:
                                        $$StudentsTableTableReferences
                                            ._groupIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (attendanceLogsTableRefs)
                        await $_getPrefetchedData<
                          StudentsTableData,
                          $StudentsTableTable,
                          AttendanceLogsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$StudentsTableTableReferences
                              ._attendanceLogsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudentsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).attendanceLogsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (relationsAsStudentA)
                        await $_getPrefetchedData<
                          StudentsTableData,
                          $StudentsTableTable,
                          StudentRelation
                        >(
                          currentTable: table,
                          referencedTable: $$StudentsTableTableReferences
                              ._relationsAsStudentATable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudentsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).relationsAsStudentA,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studentAId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (relationsAsStudentB)
                        await $_getPrefetchedData<
                          StudentsTableData,
                          $StudentsTableTable,
                          StudentRelation
                        >(
                          currentTable: table,
                          referencedTable: $$StudentsTableTableReferences
                              ._relationsAsStudentBTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudentsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).relationsAsStudentB,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studentBId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (gradeEntriesTableRefs)
                        await $_getPrefetchedData<
                          StudentsTableData,
                          $StudentsTableTable,
                          GradeEntriesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$StudentsTableTableReferences
                              ._gradeEntriesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudentsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).gradeEntriesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (materialLogsTableRefs)
                        await $_getPrefetchedData<
                          StudentsTableData,
                          $StudentsTableTable,
                          MaterialLogsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$StudentsTableTableReferences
                              ._materialLogsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudentsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).materialLogsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (homeworkLogsTableRefs)
                        await $_getPrefetchedData<
                          StudentsTableData,
                          $StudentsTableTable,
                          HomeworkLogsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$StudentsTableTableReferences
                              ._homeworkLogsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudentsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).homeworkLogsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (listItemsTableRefs)
                        await $_getPrefetchedData<
                          StudentsTableData,
                          $StudentsTableTable,
                          ChecklistItem
                        >(
                          currentTable: table,
                          referencedTable: $$StudentsTableTableReferences
                              ._listItemsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudentsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).listItemsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (notesTableRefs)
                        await $_getPrefetchedData<
                          StudentsTableData,
                          $StudentsTableTable,
                          TeacherNote
                        >(
                          currentTable: table,
                          referencedTable: $$StudentsTableTableReferences
                              ._notesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudentsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).notesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (seatingPlanPositionsTableRefs)
                        await $_getPrefetchedData<
                          StudentsTableData,
                          $StudentsTableTable,
                          SeatingPlanPosition
                        >(
                          currentTable: table,
                          referencedTable: $$StudentsTableTableReferences
                              ._seatingPlanPositionsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudentsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).seatingPlanPositionsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (timeframeGradesTableRefs)
                        await $_getPrefetchedData<
                          StudentsTableData,
                          $StudentsTableTable,
                          TimeframeGradesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$StudentsTableTableReferences
                              ._timeframeGradesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudentsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).timeframeGradesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studentId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StudentsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudentsTableTable,
      StudentsTableData,
      $$StudentsTableTableFilterComposer,
      $$StudentsTableTableOrderingComposer,
      $$StudentsTableTableAnnotationComposer,
      $$StudentsTableTableCreateCompanionBuilder,
      $$StudentsTableTableUpdateCompanionBuilder,
      (StudentsTableData, $$StudentsTableTableReferences),
      StudentsTableData,
      PrefetchHooks Function({
        bool groupId,
        bool attendanceLogsTableRefs,
        bool relationsAsStudentA,
        bool relationsAsStudentB,
        bool gradeEntriesTableRefs,
        bool materialLogsTableRefs,
        bool homeworkLogsTableRefs,
        bool listItemsTableRefs,
        bool notesTableRefs,
        bool seatingPlanPositionsTableRefs,
        bool timeframeGradesTableRefs,
      })
    >;
typedef $$AttendanceLogsTableTableCreateCompanionBuilder =
    AttendanceLogsTableCompanion Function({
      Value<int> id,
      required int studentId,
      required DateTime date,
      Value<bool> isAbsent,
      Value<bool> isExcused,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$AttendanceLogsTableTableUpdateCompanionBuilder =
    AttendanceLogsTableCompanion Function({
      Value<int> id,
      Value<int> studentId,
      Value<DateTime> date,
      Value<bool> isAbsent,
      Value<bool> isExcused,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$AttendanceLogsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AttendanceLogsTableTable,
          AttendanceLogsTableData
        > {
  $$AttendanceLogsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StudentsTableTable _studentIdTable(_$AppDatabase db) =>
      db.studentsTable.createAlias(
        $_aliasNameGenerator(
          db.attendanceLogsTable.studentId,
          db.studentsTable.id,
        ),
      );

  $$StudentsTableTableProcessedTableManager get studentId {
    final $_column = $_itemColumn<int>('student_id')!;

    final manager = $$StudentsTableTableTableManager(
      $_db,
      $_db.studentsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttendanceLogsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceLogsTableTable> {
  $$AttendanceLogsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAbsent => $composableBuilder(
    column: $table.isAbsent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isExcused => $composableBuilder(
    column: $table.isExcused,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StudentsTableTableFilterComposer get studentId {
    final $$StudentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableFilterComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceLogsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceLogsTableTable> {
  $$AttendanceLogsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAbsent => $composableBuilder(
    column: $table.isAbsent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isExcused => $composableBuilder(
    column: $table.isExcused,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StudentsTableTableOrderingComposer get studentId {
    final $$StudentsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableOrderingComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceLogsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceLogsTableTable> {
  $$AttendanceLogsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get isAbsent =>
      $composableBuilder(column: $table.isAbsent, builder: (column) => column);

  GeneratedColumn<bool> get isExcused =>
      $composableBuilder(column: $table.isExcused, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$StudentsTableTableAnnotationComposer get studentId {
    final $$StudentsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceLogsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttendanceLogsTableTable,
          AttendanceLogsTableData,
          $$AttendanceLogsTableTableFilterComposer,
          $$AttendanceLogsTableTableOrderingComposer,
          $$AttendanceLogsTableTableAnnotationComposer,
          $$AttendanceLogsTableTableCreateCompanionBuilder,
          $$AttendanceLogsTableTableUpdateCompanionBuilder,
          (AttendanceLogsTableData, $$AttendanceLogsTableTableReferences),
          AttendanceLogsTableData,
          PrefetchHooks Function({bool studentId})
        > {
  $$AttendanceLogsTableTableTableManager(
    _$AppDatabase db,
    $AttendanceLogsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceLogsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendanceLogsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AttendanceLogsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> studentId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<bool> isAbsent = const Value.absent(),
                Value<bool> isExcused = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AttendanceLogsTableCompanion(
                id: id,
                studentId: studentId,
                date: date,
                isAbsent: isAbsent,
                isExcused: isExcused,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int studentId,
                required DateTime date,
                Value<bool> isAbsent = const Value.absent(),
                Value<bool> isExcused = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AttendanceLogsTableCompanion.insert(
                id: id,
                studentId: studentId,
                date: date,
                isAbsent: isAbsent,
                isExcused: isExcused,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AttendanceLogsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({studentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (studentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.studentId,
                                referencedTable:
                                    $$AttendanceLogsTableTableReferences
                                        ._studentIdTable(db),
                                referencedColumn:
                                    $$AttendanceLogsTableTableReferences
                                        ._studentIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AttendanceLogsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttendanceLogsTableTable,
      AttendanceLogsTableData,
      $$AttendanceLogsTableTableFilterComposer,
      $$AttendanceLogsTableTableOrderingComposer,
      $$AttendanceLogsTableTableAnnotationComposer,
      $$AttendanceLogsTableTableCreateCompanionBuilder,
      $$AttendanceLogsTableTableUpdateCompanionBuilder,
      (AttendanceLogsTableData, $$AttendanceLogsTableTableReferences),
      AttendanceLogsTableData,
      PrefetchHooks Function({bool studentId})
    >;
typedef $$StudentRelationsTableTableCreateCompanionBuilder =
    StudentRelationsTableCompanion Function({
      Value<int> id,
      required int studentAId,
      required int studentBId,
      Value<bool> isPositive,
      Value<String?> comment,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$StudentRelationsTableTableUpdateCompanionBuilder =
    StudentRelationsTableCompanion Function({
      Value<int> id,
      Value<int> studentAId,
      Value<int> studentBId,
      Value<bool> isPositive,
      Value<String?> comment,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$StudentRelationsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $StudentRelationsTableTable,
          StudentRelation
        > {
  $$StudentRelationsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StudentsTableTable _studentAIdTable(_$AppDatabase db) =>
      db.studentsTable.createAlias(
        $_aliasNameGenerator(
          db.studentRelationsTable.studentAId,
          db.studentsTable.id,
        ),
      );

  $$StudentsTableTableProcessedTableManager get studentAId {
    final $_column = $_itemColumn<int>('student_a_id')!;

    final manager = $$StudentsTableTableTableManager(
      $_db,
      $_db.studentsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studentAIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StudentsTableTable _studentBIdTable(_$AppDatabase db) =>
      db.studentsTable.createAlias(
        $_aliasNameGenerator(
          db.studentRelationsTable.studentBId,
          db.studentsTable.id,
        ),
      );

  $$StudentsTableTableProcessedTableManager get studentBId {
    final $_column = $_itemColumn<int>('student_b_id')!;

    final manager = $$StudentsTableTableTableManager(
      $_db,
      $_db.studentsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studentBIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StudentRelationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $StudentRelationsTableTable> {
  $$StudentRelationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPositive => $composableBuilder(
    column: $table.isPositive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StudentsTableTableFilterComposer get studentAId {
    final $$StudentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentAId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableFilterComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableTableFilterComposer get studentBId {
    final $$StudentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentBId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableFilterComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StudentRelationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $StudentRelationsTableTable> {
  $$StudentRelationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPositive => $composableBuilder(
    column: $table.isPositive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StudentsTableTableOrderingComposer get studentAId {
    final $$StudentsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentAId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableOrderingComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableTableOrderingComposer get studentBId {
    final $$StudentsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentBId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableOrderingComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StudentRelationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudentRelationsTableTable> {
  $$StudentRelationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isPositive => $composableBuilder(
    column: $table.isPositive,
    builder: (column) => column,
  );

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$StudentsTableTableAnnotationComposer get studentAId {
    final $$StudentsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentAId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableTableAnnotationComposer get studentBId {
    final $$StudentsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentBId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StudentRelationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudentRelationsTableTable,
          StudentRelation,
          $$StudentRelationsTableTableFilterComposer,
          $$StudentRelationsTableTableOrderingComposer,
          $$StudentRelationsTableTableAnnotationComposer,
          $$StudentRelationsTableTableCreateCompanionBuilder,
          $$StudentRelationsTableTableUpdateCompanionBuilder,
          (StudentRelation, $$StudentRelationsTableTableReferences),
          StudentRelation,
          PrefetchHooks Function({bool studentAId, bool studentBId})
        > {
  $$StudentRelationsTableTableTableManager(
    _$AppDatabase db,
    $StudentRelationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudentRelationsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$StudentRelationsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$StudentRelationsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> studentAId = const Value.absent(),
                Value<int> studentBId = const Value.absent(),
                Value<bool> isPositive = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => StudentRelationsTableCompanion(
                id: id,
                studentAId: studentAId,
                studentBId: studentBId,
                isPositive: isPositive,
                comment: comment,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int studentAId,
                required int studentBId,
                Value<bool> isPositive = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => StudentRelationsTableCompanion.insert(
                id: id,
                studentAId: studentAId,
                studentBId: studentBId,
                isPositive: isPositive,
                comment: comment,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StudentRelationsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({studentAId = false, studentBId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (studentAId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.studentAId,
                                referencedTable:
                                    $$StudentRelationsTableTableReferences
                                        ._studentAIdTable(db),
                                referencedColumn:
                                    $$StudentRelationsTableTableReferences
                                        ._studentAIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (studentBId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.studentBId,
                                referencedTable:
                                    $$StudentRelationsTableTableReferences
                                        ._studentBIdTable(db),
                                referencedColumn:
                                    $$StudentRelationsTableTableReferences
                                        ._studentBIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StudentRelationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudentRelationsTableTable,
      StudentRelation,
      $$StudentRelationsTableTableFilterComposer,
      $$StudentRelationsTableTableOrderingComposer,
      $$StudentRelationsTableTableAnnotationComposer,
      $$StudentRelationsTableTableCreateCompanionBuilder,
      $$StudentRelationsTableTableUpdateCompanionBuilder,
      (StudentRelation, $$StudentRelationsTableTableReferences),
      StudentRelation,
      PrefetchHooks Function({bool studentAId, bool studentBId})
    >;
typedef $$GradeEntriesTableTableCreateCompanionBuilder =
    GradeEntriesTableCompanion Function({
      Value<int> id,
      required int studentId,
      required DateTime date,
      required String sessionLabel,
      required String value,
      Value<String> categoryId,
      Value<String> categoryName,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$GradeEntriesTableTableUpdateCompanionBuilder =
    GradeEntriesTableCompanion Function({
      Value<int> id,
      Value<int> studentId,
      Value<DateTime> date,
      Value<String> sessionLabel,
      Value<String> value,
      Value<String> categoryId,
      Value<String> categoryName,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$GradeEntriesTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $GradeEntriesTableTable,
          GradeEntriesTableData
        > {
  $$GradeEntriesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StudentsTableTable _studentIdTable(_$AppDatabase db) =>
      db.studentsTable.createAlias(
        $_aliasNameGenerator(
          db.gradeEntriesTable.studentId,
          db.studentsTable.id,
        ),
      );

  $$StudentsTableTableProcessedTableManager get studentId {
    final $_column = $_itemColumn<int>('student_id')!;

    final manager = $$StudentsTableTableTableManager(
      $_db,
      $_db.studentsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GradeEntriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $GradeEntriesTableTable> {
  $$GradeEntriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionLabel => $composableBuilder(
    column: $table.sessionLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StudentsTableTableFilterComposer get studentId {
    final $$StudentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableFilterComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GradeEntriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GradeEntriesTableTable> {
  $$GradeEntriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionLabel => $composableBuilder(
    column: $table.sessionLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StudentsTableTableOrderingComposer get studentId {
    final $$StudentsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableOrderingComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GradeEntriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GradeEntriesTableTable> {
  $$GradeEntriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get sessionLabel => $composableBuilder(
    column: $table.sessionLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$StudentsTableTableAnnotationComposer get studentId {
    final $$StudentsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GradeEntriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GradeEntriesTableTable,
          GradeEntriesTableData,
          $$GradeEntriesTableTableFilterComposer,
          $$GradeEntriesTableTableOrderingComposer,
          $$GradeEntriesTableTableAnnotationComposer,
          $$GradeEntriesTableTableCreateCompanionBuilder,
          $$GradeEntriesTableTableUpdateCompanionBuilder,
          (GradeEntriesTableData, $$GradeEntriesTableTableReferences),
          GradeEntriesTableData,
          PrefetchHooks Function({bool studentId})
        > {
  $$GradeEntriesTableTableTableManager(
    _$AppDatabase db,
    $GradeEntriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GradeEntriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GradeEntriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GradeEntriesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> studentId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> sessionLabel = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GradeEntriesTableCompanion(
                id: id,
                studentId: studentId,
                date: date,
                sessionLabel: sessionLabel,
                value: value,
                categoryId: categoryId,
                categoryName: categoryName,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int studentId,
                required DateTime date,
                required String sessionLabel,
                required String value,
                Value<String> categoryId = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GradeEntriesTableCompanion.insert(
                id: id,
                studentId: studentId,
                date: date,
                sessionLabel: sessionLabel,
                value: value,
                categoryId: categoryId,
                categoryName: categoryName,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GradeEntriesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({studentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (studentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.studentId,
                                referencedTable:
                                    $$GradeEntriesTableTableReferences
                                        ._studentIdTable(db),
                                referencedColumn:
                                    $$GradeEntriesTableTableReferences
                                        ._studentIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GradeEntriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GradeEntriesTableTable,
      GradeEntriesTableData,
      $$GradeEntriesTableTableFilterComposer,
      $$GradeEntriesTableTableOrderingComposer,
      $$GradeEntriesTableTableAnnotationComposer,
      $$GradeEntriesTableTableCreateCompanionBuilder,
      $$GradeEntriesTableTableUpdateCompanionBuilder,
      (GradeEntriesTableData, $$GradeEntriesTableTableReferences),
      GradeEntriesTableData,
      PrefetchHooks Function({bool studentId})
    >;
typedef $$MaterialLogsTableTableCreateCompanionBuilder =
    MaterialLogsTableCompanion Function({
      Value<int> id,
      required int studentId,
      required DateTime date,
      Value<bool> hadMaterial,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$MaterialLogsTableTableUpdateCompanionBuilder =
    MaterialLogsTableCompanion Function({
      Value<int> id,
      Value<int> studentId,
      Value<DateTime> date,
      Value<bool> hadMaterial,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$MaterialLogsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MaterialLogsTableTable,
          MaterialLogsTableData
        > {
  $$MaterialLogsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StudentsTableTable _studentIdTable(_$AppDatabase db) =>
      db.studentsTable.createAlias(
        $_aliasNameGenerator(
          db.materialLogsTable.studentId,
          db.studentsTable.id,
        ),
      );

  $$StudentsTableTableProcessedTableManager get studentId {
    final $_column = $_itemColumn<int>('student_id')!;

    final manager = $$StudentsTableTableTableManager(
      $_db,
      $_db.studentsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MaterialLogsTableTableFilterComposer
    extends Composer<_$AppDatabase, $MaterialLogsTableTable> {
  $$MaterialLogsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hadMaterial => $composableBuilder(
    column: $table.hadMaterial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StudentsTableTableFilterComposer get studentId {
    final $$StudentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableFilterComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MaterialLogsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MaterialLogsTableTable> {
  $$MaterialLogsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hadMaterial => $composableBuilder(
    column: $table.hadMaterial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StudentsTableTableOrderingComposer get studentId {
    final $$StudentsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableOrderingComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MaterialLogsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MaterialLogsTableTable> {
  $$MaterialLogsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get hadMaterial => $composableBuilder(
    column: $table.hadMaterial,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$StudentsTableTableAnnotationComposer get studentId {
    final $$StudentsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MaterialLogsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MaterialLogsTableTable,
          MaterialLogsTableData,
          $$MaterialLogsTableTableFilterComposer,
          $$MaterialLogsTableTableOrderingComposer,
          $$MaterialLogsTableTableAnnotationComposer,
          $$MaterialLogsTableTableCreateCompanionBuilder,
          $$MaterialLogsTableTableUpdateCompanionBuilder,
          (MaterialLogsTableData, $$MaterialLogsTableTableReferences),
          MaterialLogsTableData,
          PrefetchHooks Function({bool studentId})
        > {
  $$MaterialLogsTableTableTableManager(
    _$AppDatabase db,
    $MaterialLogsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaterialLogsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MaterialLogsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MaterialLogsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> studentId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<bool> hadMaterial = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => MaterialLogsTableCompanion(
                id: id,
                studentId: studentId,
                date: date,
                hadMaterial: hadMaterial,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int studentId,
                required DateTime date,
                Value<bool> hadMaterial = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => MaterialLogsTableCompanion.insert(
                id: id,
                studentId: studentId,
                date: date,
                hadMaterial: hadMaterial,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MaterialLogsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({studentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (studentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.studentId,
                                referencedTable:
                                    $$MaterialLogsTableTableReferences
                                        ._studentIdTable(db),
                                referencedColumn:
                                    $$MaterialLogsTableTableReferences
                                        ._studentIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MaterialLogsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MaterialLogsTableTable,
      MaterialLogsTableData,
      $$MaterialLogsTableTableFilterComposer,
      $$MaterialLogsTableTableOrderingComposer,
      $$MaterialLogsTableTableAnnotationComposer,
      $$MaterialLogsTableTableCreateCompanionBuilder,
      $$MaterialLogsTableTableUpdateCompanionBuilder,
      (MaterialLogsTableData, $$MaterialLogsTableTableReferences),
      MaterialLogsTableData,
      PrefetchHooks Function({bool studentId})
    >;
typedef $$HomeworkLogsTableTableCreateCompanionBuilder =
    HomeworkLogsTableCompanion Function({
      Value<int> id,
      required int studentId,
      required DateTime date,
      Value<bool> hadHomework,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$HomeworkLogsTableTableUpdateCompanionBuilder =
    HomeworkLogsTableCompanion Function({
      Value<int> id,
      Value<int> studentId,
      Value<DateTime> date,
      Value<bool> hadHomework,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$HomeworkLogsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $HomeworkLogsTableTable,
          HomeworkLogsTableData
        > {
  $$HomeworkLogsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StudentsTableTable _studentIdTable(_$AppDatabase db) =>
      db.studentsTable.createAlias(
        $_aliasNameGenerator(
          db.homeworkLogsTable.studentId,
          db.studentsTable.id,
        ),
      );

  $$StudentsTableTableProcessedTableManager get studentId {
    final $_column = $_itemColumn<int>('student_id')!;

    final manager = $$StudentsTableTableTableManager(
      $_db,
      $_db.studentsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HomeworkLogsTableTableFilterComposer
    extends Composer<_$AppDatabase, $HomeworkLogsTableTable> {
  $$HomeworkLogsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hadHomework => $composableBuilder(
    column: $table.hadHomework,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StudentsTableTableFilterComposer get studentId {
    final $$StudentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableFilterComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HomeworkLogsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $HomeworkLogsTableTable> {
  $$HomeworkLogsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hadHomework => $composableBuilder(
    column: $table.hadHomework,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StudentsTableTableOrderingComposer get studentId {
    final $$StudentsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableOrderingComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HomeworkLogsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $HomeworkLogsTableTable> {
  $$HomeworkLogsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get hadHomework => $composableBuilder(
    column: $table.hadHomework,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$StudentsTableTableAnnotationComposer get studentId {
    final $$StudentsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HomeworkLogsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HomeworkLogsTableTable,
          HomeworkLogsTableData,
          $$HomeworkLogsTableTableFilterComposer,
          $$HomeworkLogsTableTableOrderingComposer,
          $$HomeworkLogsTableTableAnnotationComposer,
          $$HomeworkLogsTableTableCreateCompanionBuilder,
          $$HomeworkLogsTableTableUpdateCompanionBuilder,
          (HomeworkLogsTableData, $$HomeworkLogsTableTableReferences),
          HomeworkLogsTableData,
          PrefetchHooks Function({bool studentId})
        > {
  $$HomeworkLogsTableTableTableManager(
    _$AppDatabase db,
    $HomeworkLogsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HomeworkLogsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HomeworkLogsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HomeworkLogsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> studentId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<bool> hadHomework = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => HomeworkLogsTableCompanion(
                id: id,
                studentId: studentId,
                date: date,
                hadHomework: hadHomework,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int studentId,
                required DateTime date,
                Value<bool> hadHomework = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => HomeworkLogsTableCompanion.insert(
                id: id,
                studentId: studentId,
                date: date,
                hadHomework: hadHomework,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HomeworkLogsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({studentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (studentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.studentId,
                                referencedTable:
                                    $$HomeworkLogsTableTableReferences
                                        ._studentIdTable(db),
                                referencedColumn:
                                    $$HomeworkLogsTableTableReferences
                                        ._studentIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HomeworkLogsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HomeworkLogsTableTable,
      HomeworkLogsTableData,
      $$HomeworkLogsTableTableFilterComposer,
      $$HomeworkLogsTableTableOrderingComposer,
      $$HomeworkLogsTableTableAnnotationComposer,
      $$HomeworkLogsTableTableCreateCompanionBuilder,
      $$HomeworkLogsTableTableUpdateCompanionBuilder,
      (HomeworkLogsTableData, $$HomeworkLogsTableTableReferences),
      HomeworkLogsTableData,
      PrefetchHooks Function({bool studentId})
    >;
typedef $$LessonSlotsTableTableCreateCompanionBuilder =
    LessonSlotsTableCompanion Function({
      Value<int> id,
      required int groupId,
      required int weekday,
      required int periodStart,
      required int periodEnd,
      Value<String> categoryId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$LessonSlotsTableTableUpdateCompanionBuilder =
    LessonSlotsTableCompanion Function({
      Value<int> id,
      Value<int> groupId,
      Value<int> weekday,
      Value<int> periodStart,
      Value<int> periodEnd,
      Value<String> categoryId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$LessonSlotsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LessonSlotsTableTable,
          LessonSlotsTableData
        > {
  $$LessonSlotsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GroupsTableTable _groupIdTable(_$AppDatabase db) =>
      db.groupsTable.createAlias(
        $_aliasNameGenerator(db.lessonSlotsTable.groupId, db.groupsTable.id),
      );

  $$GroupsTableTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<int>('group_id')!;

    final manager = $$GroupsTableTableTableManager(
      $_db,
      $_db.groupsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LessonSlotsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LessonSlotsTableTable> {
  $$LessonSlotsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get periodEnd => $composableBuilder(
    column: $table.periodEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableTableFilterComposer get groupId {
    final $$GroupsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableTableFilterComposer(
            $db: $db,
            $table: $db.groupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LessonSlotsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonSlotsTableTable> {
  $$LessonSlotsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get periodEnd => $composableBuilder(
    column: $table.periodEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableTableOrderingComposer get groupId {
    final $$GroupsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableTableOrderingComposer(
            $db: $db,
            $table: $db.groupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LessonSlotsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonSlotsTableTable> {
  $$LessonSlotsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<int> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get periodEnd =>
      $composableBuilder(column: $table.periodEnd, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$GroupsTableTableAnnotationComposer get groupId {
    final $$GroupsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.groupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LessonSlotsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LessonSlotsTableTable,
          LessonSlotsTableData,
          $$LessonSlotsTableTableFilterComposer,
          $$LessonSlotsTableTableOrderingComposer,
          $$LessonSlotsTableTableAnnotationComposer,
          $$LessonSlotsTableTableCreateCompanionBuilder,
          $$LessonSlotsTableTableUpdateCompanionBuilder,
          (LessonSlotsTableData, $$LessonSlotsTableTableReferences),
          LessonSlotsTableData,
          PrefetchHooks Function({bool groupId})
        > {
  $$LessonSlotsTableTableTableManager(
    _$AppDatabase db,
    $LessonSlotsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonSlotsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonSlotsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonSlotsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> groupId = const Value.absent(),
                Value<int> weekday = const Value.absent(),
                Value<int> periodStart = const Value.absent(),
                Value<int> periodEnd = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LessonSlotsTableCompanion(
                id: id,
                groupId: groupId,
                weekday: weekday,
                periodStart: periodStart,
                periodEnd: periodEnd,
                categoryId: categoryId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int groupId,
                required int weekday,
                required int periodStart,
                required int periodEnd,
                Value<String> categoryId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LessonSlotsTableCompanion.insert(
                id: id,
                groupId: groupId,
                weekday: weekday,
                periodStart: periodStart,
                periodEnd: periodEnd,
                categoryId: categoryId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LessonSlotsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (groupId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.groupId,
                                referencedTable:
                                    $$LessonSlotsTableTableReferences
                                        ._groupIdTable(db),
                                referencedColumn:
                                    $$LessonSlotsTableTableReferences
                                        ._groupIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LessonSlotsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LessonSlotsTableTable,
      LessonSlotsTableData,
      $$LessonSlotsTableTableFilterComposer,
      $$LessonSlotsTableTableOrderingComposer,
      $$LessonSlotsTableTableAnnotationComposer,
      $$LessonSlotsTableTableCreateCompanionBuilder,
      $$LessonSlotsTableTableUpdateCompanionBuilder,
      (LessonSlotsTableData, $$LessonSlotsTableTableReferences),
      LessonSlotsTableData,
      PrefetchHooks Function({bool groupId})
    >;
typedef $$ListsTableTableCreateCompanionBuilder =
    ListsTableCompanion Function({
      Value<int> id,
      Value<int?> groupId,
      required String name,
      Value<DateTime> createdAt,
      Value<DateTime?> archivedAt,
      Value<DateTime?> touchedAt,
      Value<DateTime> updatedAt,
    });
typedef $$ListsTableTableUpdateCompanionBuilder =
    ListsTableCompanion Function({
      Value<int> id,
      Value<int?> groupId,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<DateTime?> archivedAt,
      Value<DateTime?> touchedAt,
      Value<DateTime> updatedAt,
    });

final class $$ListsTableTableReferences
    extends BaseReferences<_$AppDatabase, $ListsTableTable, Checklist> {
  $$ListsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTableTable _groupIdTable(_$AppDatabase db) =>
      db.groupsTable.createAlias(
        $_aliasNameGenerator(db.listsTable.groupId, db.groupsTable.id),
      );

  $$GroupsTableTableProcessedTableManager? get groupId {
    final $_column = $_itemColumn<int>('group_id');
    if ($_column == null) return null;
    final manager = $$GroupsTableTableTableManager(
      $_db,
      $_db.groupsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ListItemsTableTable, List<ChecklistItem>>
  _listItemsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.listItemsTable,
    aliasName: $_aliasNameGenerator(db.listsTable.id, db.listItemsTable.listId),
  );

  $$ListItemsTableTableProcessedTableManager get listItemsTableRefs {
    final manager = $$ListItemsTableTableTableManager(
      $_db,
      $_db.listItemsTable,
    ).filter((f) => f.listId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_listItemsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ListsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ListsTableTable> {
  $$ListsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get touchedAt => $composableBuilder(
    column: $table.touchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableTableFilterComposer get groupId {
    final $$GroupsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableTableFilterComposer(
            $db: $db,
            $table: $db.groupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> listItemsTableRefs(
    Expression<bool> Function($$ListItemsTableTableFilterComposer f) f,
  ) {
    final $$ListItemsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.listItemsTable,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListItemsTableTableFilterComposer(
            $db: $db,
            $table: $db.listItemsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ListsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ListsTableTable> {
  $$ListsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get touchedAt => $composableBuilder(
    column: $table.touchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableTableOrderingComposer get groupId {
    final $$GroupsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableTableOrderingComposer(
            $db: $db,
            $table: $db.groupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ListsTableTable> {
  $$ListsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get touchedAt =>
      $composableBuilder(column: $table.touchedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$GroupsTableTableAnnotationComposer get groupId {
    final $$GroupsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.groupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> listItemsTableRefs<T extends Object>(
    Expression<T> Function($$ListItemsTableTableAnnotationComposer a) f,
  ) {
    final $$ListItemsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.listItemsTable,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListItemsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.listItemsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ListsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ListsTableTable,
          Checklist,
          $$ListsTableTableFilterComposer,
          $$ListsTableTableOrderingComposer,
          $$ListsTableTableAnnotationComposer,
          $$ListsTableTableCreateCompanionBuilder,
          $$ListsTableTableUpdateCompanionBuilder,
          (Checklist, $$ListsTableTableReferences),
          Checklist,
          PrefetchHooks Function({bool groupId, bool listItemsTableRefs})
        > {
  $$ListsTableTableTableManager(_$AppDatabase db, $ListsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> groupId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime?> touchedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ListsTableCompanion(
                id: id,
                groupId: groupId,
                name: name,
                createdAt: createdAt,
                archivedAt: archivedAt,
                touchedAt: touchedAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> groupId = const Value.absent(),
                required String name,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime?> touchedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ListsTableCompanion.insert(
                id: id,
                groupId: groupId,
                name: name,
                createdAt: createdAt,
                archivedAt: archivedAt,
                touchedAt: touchedAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ListsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({groupId = false, listItemsTableRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (listItemsTableRefs) db.listItemsTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.groupId,
                                    referencedTable: $$ListsTableTableReferences
                                        ._groupIdTable(db),
                                    referencedColumn:
                                        $$ListsTableTableReferences
                                            ._groupIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (listItemsTableRefs)
                        await $_getPrefetchedData<
                          Checklist,
                          $ListsTableTable,
                          ChecklistItem
                        >(
                          currentTable: table,
                          referencedTable: $$ListsTableTableReferences
                              ._listItemsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ListsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).listItemsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.listId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ListsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ListsTableTable,
      Checklist,
      $$ListsTableTableFilterComposer,
      $$ListsTableTableOrderingComposer,
      $$ListsTableTableAnnotationComposer,
      $$ListsTableTableCreateCompanionBuilder,
      $$ListsTableTableUpdateCompanionBuilder,
      (Checklist, $$ListsTableTableReferences),
      Checklist,
      PrefetchHooks Function({bool groupId, bool listItemsTableRefs})
    >;
typedef $$ListItemsTableTableCreateCompanionBuilder =
    ListItemsTableCompanion Function({
      Value<int> id,
      required int listId,
      Value<int?> studentId,
      Value<String?> studentIdsJson,
      required String label,
      Value<DateTime?> checkedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$ListItemsTableTableUpdateCompanionBuilder =
    ListItemsTableCompanion Function({
      Value<int> id,
      Value<int> listId,
      Value<int?> studentId,
      Value<String?> studentIdsJson,
      Value<String> label,
      Value<DateTime?> checkedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$ListItemsTableTableReferences
    extends BaseReferences<_$AppDatabase, $ListItemsTableTable, ChecklistItem> {
  $$ListItemsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ListsTableTable _listIdTable(_$AppDatabase db) =>
      db.listsTable.createAlias(
        $_aliasNameGenerator(db.listItemsTable.listId, db.listsTable.id),
      );

  $$ListsTableTableProcessedTableManager get listId {
    final $_column = $_itemColumn<int>('list_id')!;

    final manager = $$ListsTableTableTableManager(
      $_db,
      $_db.listsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StudentsTableTable _studentIdTable(_$AppDatabase db) =>
      db.studentsTable.createAlias(
        $_aliasNameGenerator(db.listItemsTable.studentId, db.studentsTable.id),
      );

  $$StudentsTableTableProcessedTableManager? get studentId {
    final $_column = $_itemColumn<int>('student_id');
    if ($_column == null) return null;
    final manager = $$StudentsTableTableTableManager(
      $_db,
      $_db.studentsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ListItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ListItemsTableTable> {
  $$ListItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentIdsJson => $composableBuilder(
    column: $table.studentIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get checkedAt => $composableBuilder(
    column: $table.checkedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ListsTableTableFilterComposer get listId {
    final $$ListsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.listsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListsTableTableFilterComposer(
            $db: $db,
            $table: $db.listsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableTableFilterComposer get studentId {
    final $$StudentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableFilterComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ListItemsTableTable> {
  $$ListItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentIdsJson => $composableBuilder(
    column: $table.studentIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get checkedAt => $composableBuilder(
    column: $table.checkedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ListsTableTableOrderingComposer get listId {
    final $$ListsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.listsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListsTableTableOrderingComposer(
            $db: $db,
            $table: $db.listsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableTableOrderingComposer get studentId {
    final $$StudentsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableOrderingComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ListItemsTableTable> {
  $$ListItemsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get studentIdsJson => $composableBuilder(
    column: $table.studentIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<DateTime> get checkedAt =>
      $composableBuilder(column: $table.checkedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ListsTableTableAnnotationComposer get listId {
    final $$ListsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.listsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.listsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableTableAnnotationComposer get studentId {
    final $$StudentsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListItemsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ListItemsTableTable,
          ChecklistItem,
          $$ListItemsTableTableFilterComposer,
          $$ListItemsTableTableOrderingComposer,
          $$ListItemsTableTableAnnotationComposer,
          $$ListItemsTableTableCreateCompanionBuilder,
          $$ListItemsTableTableUpdateCompanionBuilder,
          (ChecklistItem, $$ListItemsTableTableReferences),
          ChecklistItem,
          PrefetchHooks Function({bool listId, bool studentId})
        > {
  $$ListItemsTableTableTableManager(
    _$AppDatabase db,
    $ListItemsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListItemsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListItemsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListItemsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> listId = const Value.absent(),
                Value<int?> studentId = const Value.absent(),
                Value<String?> studentIdsJson = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<DateTime?> checkedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ListItemsTableCompanion(
                id: id,
                listId: listId,
                studentId: studentId,
                studentIdsJson: studentIdsJson,
                label: label,
                checkedAt: checkedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int listId,
                Value<int?> studentId = const Value.absent(),
                Value<String?> studentIdsJson = const Value.absent(),
                required String label,
                Value<DateTime?> checkedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ListItemsTableCompanion.insert(
                id: id,
                listId: listId,
                studentId: studentId,
                studentIdsJson: studentIdsJson,
                label: label,
                checkedAt: checkedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ListItemsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({listId = false, studentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (listId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.listId,
                                referencedTable: $$ListItemsTableTableReferences
                                    ._listIdTable(db),
                                referencedColumn:
                                    $$ListItemsTableTableReferences
                                        ._listIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (studentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.studentId,
                                referencedTable: $$ListItemsTableTableReferences
                                    ._studentIdTable(db),
                                referencedColumn:
                                    $$ListItemsTableTableReferences
                                        ._studentIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ListItemsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ListItemsTableTable,
      ChecklistItem,
      $$ListItemsTableTableFilterComposer,
      $$ListItemsTableTableOrderingComposer,
      $$ListItemsTableTableAnnotationComposer,
      $$ListItemsTableTableCreateCompanionBuilder,
      $$ListItemsTableTableUpdateCompanionBuilder,
      (ChecklistItem, $$ListItemsTableTableReferences),
      ChecklistItem,
      PrefetchHooks Function({bool listId, bool studentId})
    >;
typedef $$NotesTableTableCreateCompanionBuilder =
    NotesTableCompanion Function({
      Value<int> id,
      required String body,
      Value<int?> groupId,
      Value<int?> studentId,
      Value<String?> studentIdsJson,
      Value<bool> isTodo,
      Value<bool> todoDone,
      Value<DateTime?> todoDoneAt,
      Value<DateTime> createdAt,
      Value<DateTime?> archivedAt,
      Value<DateTime> updatedAt,
    });
typedef $$NotesTableTableUpdateCompanionBuilder =
    NotesTableCompanion Function({
      Value<int> id,
      Value<String> body,
      Value<int?> groupId,
      Value<int?> studentId,
      Value<String?> studentIdsJson,
      Value<bool> isTodo,
      Value<bool> todoDone,
      Value<DateTime?> todoDoneAt,
      Value<DateTime> createdAt,
      Value<DateTime?> archivedAt,
      Value<DateTime> updatedAt,
    });

final class $$NotesTableTableReferences
    extends BaseReferences<_$AppDatabase, $NotesTableTable, TeacherNote> {
  $$NotesTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTableTable _groupIdTable(_$AppDatabase db) =>
      db.groupsTable.createAlias(
        $_aliasNameGenerator(db.notesTable.groupId, db.groupsTable.id),
      );

  $$GroupsTableTableProcessedTableManager? get groupId {
    final $_column = $_itemColumn<int>('group_id');
    if ($_column == null) return null;
    final manager = $$GroupsTableTableTableManager(
      $_db,
      $_db.groupsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StudentsTableTable _studentIdTable(_$AppDatabase db) =>
      db.studentsTable.createAlias(
        $_aliasNameGenerator(db.notesTable.studentId, db.studentsTable.id),
      );

  $$StudentsTableTableProcessedTableManager? get studentId {
    final $_column = $_itemColumn<int>('student_id');
    if ($_column == null) return null;
    final manager = $$StudentsTableTableTableManager(
      $_db,
      $_db.studentsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NotesTableTableFilterComposer
    extends Composer<_$AppDatabase, $NotesTableTable> {
  $$NotesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentIdsJson => $composableBuilder(
    column: $table.studentIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTodo => $composableBuilder(
    column: $table.isTodo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get todoDone => $composableBuilder(
    column: $table.todoDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get todoDoneAt => $composableBuilder(
    column: $table.todoDoneAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableTableFilterComposer get groupId {
    final $$GroupsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableTableFilterComposer(
            $db: $db,
            $table: $db.groupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableTableFilterComposer get studentId {
    final $$StudentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableFilterComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTableTable> {
  $$NotesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentIdsJson => $composableBuilder(
    column: $table.studentIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTodo => $composableBuilder(
    column: $table.isTodo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get todoDone => $composableBuilder(
    column: $table.todoDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get todoDoneAt => $composableBuilder(
    column: $table.todoDoneAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableTableOrderingComposer get groupId {
    final $$GroupsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableTableOrderingComposer(
            $db: $db,
            $table: $db.groupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableTableOrderingComposer get studentId {
    final $$StudentsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableOrderingComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTableTable> {
  $$NotesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get studentIdsJson => $composableBuilder(
    column: $table.studentIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTodo =>
      $composableBuilder(column: $table.isTodo, builder: (column) => column);

  GeneratedColumn<bool> get todoDone =>
      $composableBuilder(column: $table.todoDone, builder: (column) => column);

  GeneratedColumn<DateTime> get todoDoneAt => $composableBuilder(
    column: $table.todoDoneAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$GroupsTableTableAnnotationComposer get groupId {
    final $$GroupsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.groupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableTableAnnotationComposer get studentId {
    final $$StudentsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTableTable,
          TeacherNote,
          $$NotesTableTableFilterComposer,
          $$NotesTableTableOrderingComposer,
          $$NotesTableTableAnnotationComposer,
          $$NotesTableTableCreateCompanionBuilder,
          $$NotesTableTableUpdateCompanionBuilder,
          (TeacherNote, $$NotesTableTableReferences),
          TeacherNote,
          PrefetchHooks Function({bool groupId, bool studentId})
        > {
  $$NotesTableTableTableManager(_$AppDatabase db, $NotesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int?> groupId = const Value.absent(),
                Value<int?> studentId = const Value.absent(),
                Value<String?> studentIdsJson = const Value.absent(),
                Value<bool> isTodo = const Value.absent(),
                Value<bool> todoDone = const Value.absent(),
                Value<DateTime?> todoDoneAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => NotesTableCompanion(
                id: id,
                body: body,
                groupId: groupId,
                studentId: studentId,
                studentIdsJson: studentIdsJson,
                isTodo: isTodo,
                todoDone: todoDone,
                todoDoneAt: todoDoneAt,
                createdAt: createdAt,
                archivedAt: archivedAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String body,
                Value<int?> groupId = const Value.absent(),
                Value<int?> studentId = const Value.absent(),
                Value<String?> studentIdsJson = const Value.absent(),
                Value<bool> isTodo = const Value.absent(),
                Value<bool> todoDone = const Value.absent(),
                Value<DateTime?> todoDoneAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => NotesTableCompanion.insert(
                id: id,
                body: body,
                groupId: groupId,
                studentId: studentId,
                studentIdsJson: studentIdsJson,
                isTodo: isTodo,
                todoDone: todoDone,
                todoDoneAt: todoDoneAt,
                createdAt: createdAt,
                archivedAt: archivedAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NotesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupId = false, studentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (groupId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.groupId,
                                referencedTable: $$NotesTableTableReferences
                                    ._groupIdTable(db),
                                referencedColumn: $$NotesTableTableReferences
                                    ._groupIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (studentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.studentId,
                                referencedTable: $$NotesTableTableReferences
                                    ._studentIdTable(db),
                                referencedColumn: $$NotesTableTableReferences
                                    ._studentIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NotesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTableTable,
      TeacherNote,
      $$NotesTableTableFilterComposer,
      $$NotesTableTableOrderingComposer,
      $$NotesTableTableAnnotationComposer,
      $$NotesTableTableCreateCompanionBuilder,
      $$NotesTableTableUpdateCompanionBuilder,
      (TeacherNote, $$NotesTableTableReferences),
      TeacherNote,
      PrefetchHooks Function({bool groupId, bool studentId})
    >;
typedef $$SeatingPlansTableTableCreateCompanionBuilder =
    SeatingPlansTableCompanion Function({
      Value<int> id,
      required int groupId,
      required String name,
      Value<int> columns,
      Value<bool> isDefault,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$SeatingPlansTableTableUpdateCompanionBuilder =
    SeatingPlansTableCompanion Function({
      Value<int> id,
      Value<int> groupId,
      Value<String> name,
      Value<int> columns,
      Value<bool> isDefault,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$SeatingPlansTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $SeatingPlansTableTable, SeatingPlan> {
  $$SeatingPlansTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GroupsTableTable _groupIdTable(_$AppDatabase db) =>
      db.groupsTable.createAlias(
        $_aliasNameGenerator(db.seatingPlansTable.groupId, db.groupsTable.id),
      );

  $$GroupsTableTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<int>('group_id')!;

    final manager = $$GroupsTableTableTableManager(
      $_db,
      $_db.groupsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $SeatingPlanPositionsTableTable,
    List<SeatingPlanPosition>
  >
  _seatingPlanPositionsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.seatingPlanPositionsTable,
        aliasName: $_aliasNameGenerator(
          db.seatingPlansTable.id,
          db.seatingPlanPositionsTable.seatingPlanId,
        ),
      );

  $$SeatingPlanPositionsTableTableProcessedTableManager
  get seatingPlanPositionsTableRefs {
    final manager = $$SeatingPlanPositionsTableTableTableManager(
      $_db,
      $_db.seatingPlanPositionsTable,
    ).filter((f) => f.seatingPlanId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _seatingPlanPositionsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SeatingPlansTableTableFilterComposer
    extends Composer<_$AppDatabase, $SeatingPlansTableTable> {
  $$SeatingPlansTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get columns => $composableBuilder(
    column: $table.columns,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableTableFilterComposer get groupId {
    final $$GroupsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableTableFilterComposer(
            $db: $db,
            $table: $db.groupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> seatingPlanPositionsTableRefs(
    Expression<bool> Function($$SeatingPlanPositionsTableTableFilterComposer f)
    f,
  ) {
    final $$SeatingPlanPositionsTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.seatingPlanPositionsTable,
          getReferencedColumn: (t) => t.seatingPlanId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SeatingPlanPositionsTableTableFilterComposer(
                $db: $db,
                $table: $db.seatingPlanPositionsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SeatingPlansTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SeatingPlansTableTable> {
  $$SeatingPlansTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get columns => $composableBuilder(
    column: $table.columns,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableTableOrderingComposer get groupId {
    final $$GroupsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableTableOrderingComposer(
            $db: $db,
            $table: $db.groupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeatingPlansTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeatingPlansTableTable> {
  $$SeatingPlansTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get columns =>
      $composableBuilder(column: $table.columns, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$GroupsTableTableAnnotationComposer get groupId {
    final $$GroupsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.groupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> seatingPlanPositionsTableRefs<T extends Object>(
    Expression<T> Function($$SeatingPlanPositionsTableTableAnnotationComposer a)
    f,
  ) {
    final $$SeatingPlanPositionsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.seatingPlanPositionsTable,
          getReferencedColumn: (t) => t.seatingPlanId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SeatingPlanPositionsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.seatingPlanPositionsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SeatingPlansTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeatingPlansTableTable,
          SeatingPlan,
          $$SeatingPlansTableTableFilterComposer,
          $$SeatingPlansTableTableOrderingComposer,
          $$SeatingPlansTableTableAnnotationComposer,
          $$SeatingPlansTableTableCreateCompanionBuilder,
          $$SeatingPlansTableTableUpdateCompanionBuilder,
          (SeatingPlan, $$SeatingPlansTableTableReferences),
          SeatingPlan,
          PrefetchHooks Function({
            bool groupId,
            bool seatingPlanPositionsTableRefs,
          })
        > {
  $$SeatingPlansTableTableTableManager(
    _$AppDatabase db,
    $SeatingPlansTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeatingPlansTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeatingPlansTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeatingPlansTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> groupId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> columns = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SeatingPlansTableCompanion(
                id: id,
                groupId: groupId,
                name: name,
                columns: columns,
                isDefault: isDefault,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int groupId,
                required String name,
                Value<int> columns = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SeatingPlansTableCompanion.insert(
                id: id,
                groupId: groupId,
                name: name,
                columns: columns,
                isDefault: isDefault,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SeatingPlansTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({groupId = false, seatingPlanPositionsTableRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (seatingPlanPositionsTableRefs)
                      db.seatingPlanPositionsTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.groupId,
                                    referencedTable:
                                        $$SeatingPlansTableTableReferences
                                            ._groupIdTable(db),
                                    referencedColumn:
                                        $$SeatingPlansTableTableReferences
                                            ._groupIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (seatingPlanPositionsTableRefs)
                        await $_getPrefetchedData<
                          SeatingPlan,
                          $SeatingPlansTableTable,
                          SeatingPlanPosition
                        >(
                          currentTable: table,
                          referencedTable: $$SeatingPlansTableTableReferences
                              ._seatingPlanPositionsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SeatingPlansTableTableReferences(
                                db,
                                table,
                                p0,
                              ).seatingPlanPositionsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.seatingPlanId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SeatingPlansTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeatingPlansTableTable,
      SeatingPlan,
      $$SeatingPlansTableTableFilterComposer,
      $$SeatingPlansTableTableOrderingComposer,
      $$SeatingPlansTableTableAnnotationComposer,
      $$SeatingPlansTableTableCreateCompanionBuilder,
      $$SeatingPlansTableTableUpdateCompanionBuilder,
      (SeatingPlan, $$SeatingPlansTableTableReferences),
      SeatingPlan,
      PrefetchHooks Function({bool groupId, bool seatingPlanPositionsTableRefs})
    >;
typedef $$SeatingPlanPositionsTableTableCreateCompanionBuilder =
    SeatingPlanPositionsTableCompanion Function({
      Value<int> id,
      required int seatingPlanId,
      required int studentId,
      Value<int> colIndex,
      Value<int> rowIndex,
      Value<DateTime> updatedAt,
    });
typedef $$SeatingPlanPositionsTableTableUpdateCompanionBuilder =
    SeatingPlanPositionsTableCompanion Function({
      Value<int> id,
      Value<int> seatingPlanId,
      Value<int> studentId,
      Value<int> colIndex,
      Value<int> rowIndex,
      Value<DateTime> updatedAt,
    });

final class $$SeatingPlanPositionsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SeatingPlanPositionsTableTable,
          SeatingPlanPosition
        > {
  $$SeatingPlanPositionsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SeatingPlansTableTable _seatingPlanIdTable(_$AppDatabase db) =>
      db.seatingPlansTable.createAlias(
        $_aliasNameGenerator(
          db.seatingPlanPositionsTable.seatingPlanId,
          db.seatingPlansTable.id,
        ),
      );

  $$SeatingPlansTableTableProcessedTableManager get seatingPlanId {
    final $_column = $_itemColumn<int>('seating_plan_id')!;

    final manager = $$SeatingPlansTableTableTableManager(
      $_db,
      $_db.seatingPlansTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seatingPlanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StudentsTableTable _studentIdTable(_$AppDatabase db) =>
      db.studentsTable.createAlias(
        $_aliasNameGenerator(
          db.seatingPlanPositionsTable.studentId,
          db.studentsTable.id,
        ),
      );

  $$StudentsTableTableProcessedTableManager get studentId {
    final $_column = $_itemColumn<int>('student_id')!;

    final manager = $$StudentsTableTableTableManager(
      $_db,
      $_db.studentsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SeatingPlanPositionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SeatingPlanPositionsTableTable> {
  $$SeatingPlanPositionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colIndex => $composableBuilder(
    column: $table.colIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowIndex => $composableBuilder(
    column: $table.rowIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SeatingPlansTableTableFilterComposer get seatingPlanId {
    final $$SeatingPlansTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seatingPlanId,
      referencedTable: $db.seatingPlansTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeatingPlansTableTableFilterComposer(
            $db: $db,
            $table: $db.seatingPlansTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableTableFilterComposer get studentId {
    final $$StudentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableFilterComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeatingPlanPositionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SeatingPlanPositionsTableTable> {
  $$SeatingPlanPositionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colIndex => $composableBuilder(
    column: $table.colIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowIndex => $composableBuilder(
    column: $table.rowIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SeatingPlansTableTableOrderingComposer get seatingPlanId {
    final $$SeatingPlansTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seatingPlanId,
      referencedTable: $db.seatingPlansTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeatingPlansTableTableOrderingComposer(
            $db: $db,
            $table: $db.seatingPlansTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableTableOrderingComposer get studentId {
    final $$StudentsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableOrderingComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeatingPlanPositionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeatingPlanPositionsTableTable> {
  $$SeatingPlanPositionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get colIndex =>
      $composableBuilder(column: $table.colIndex, builder: (column) => column);

  GeneratedColumn<int> get rowIndex =>
      $composableBuilder(column: $table.rowIndex, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SeatingPlansTableTableAnnotationComposer get seatingPlanId {
    final $$SeatingPlansTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.seatingPlanId,
          referencedTable: $db.seatingPlansTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SeatingPlansTableTableAnnotationComposer(
                $db: $db,
                $table: $db.seatingPlansTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$StudentsTableTableAnnotationComposer get studentId {
    final $$StudentsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeatingPlanPositionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeatingPlanPositionsTableTable,
          SeatingPlanPosition,
          $$SeatingPlanPositionsTableTableFilterComposer,
          $$SeatingPlanPositionsTableTableOrderingComposer,
          $$SeatingPlanPositionsTableTableAnnotationComposer,
          $$SeatingPlanPositionsTableTableCreateCompanionBuilder,
          $$SeatingPlanPositionsTableTableUpdateCompanionBuilder,
          (SeatingPlanPosition, $$SeatingPlanPositionsTableTableReferences),
          SeatingPlanPosition,
          PrefetchHooks Function({bool seatingPlanId, bool studentId})
        > {
  $$SeatingPlanPositionsTableTableTableManager(
    _$AppDatabase db,
    $SeatingPlanPositionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeatingPlanPositionsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SeatingPlanPositionsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SeatingPlanPositionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> seatingPlanId = const Value.absent(),
                Value<int> studentId = const Value.absent(),
                Value<int> colIndex = const Value.absent(),
                Value<int> rowIndex = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SeatingPlanPositionsTableCompanion(
                id: id,
                seatingPlanId: seatingPlanId,
                studentId: studentId,
                colIndex: colIndex,
                rowIndex: rowIndex,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int seatingPlanId,
                required int studentId,
                Value<int> colIndex = const Value.absent(),
                Value<int> rowIndex = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SeatingPlanPositionsTableCompanion.insert(
                id: id,
                seatingPlanId: seatingPlanId,
                studentId: studentId,
                colIndex: colIndex,
                rowIndex: rowIndex,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SeatingPlanPositionsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({seatingPlanId = false, studentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (seatingPlanId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.seatingPlanId,
                                referencedTable:
                                    $$SeatingPlanPositionsTableTableReferences
                                        ._seatingPlanIdTable(db),
                                referencedColumn:
                                    $$SeatingPlanPositionsTableTableReferences
                                        ._seatingPlanIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (studentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.studentId,
                                referencedTable:
                                    $$SeatingPlanPositionsTableTableReferences
                                        ._studentIdTable(db),
                                referencedColumn:
                                    $$SeatingPlanPositionsTableTableReferences
                                        ._studentIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SeatingPlanPositionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeatingPlanPositionsTableTable,
      SeatingPlanPosition,
      $$SeatingPlanPositionsTableTableFilterComposer,
      $$SeatingPlanPositionsTableTableOrderingComposer,
      $$SeatingPlanPositionsTableTableAnnotationComposer,
      $$SeatingPlanPositionsTableTableCreateCompanionBuilder,
      $$SeatingPlanPositionsTableTableUpdateCompanionBuilder,
      (SeatingPlanPosition, $$SeatingPlanPositionsTableTableReferences),
      SeatingPlanPosition,
      PrefetchHooks Function({bool seatingPlanId, bool studentId})
    >;
typedef $$SessionsTableTableCreateCompanionBuilder =
    SessionsTableCompanion Function({
      Value<int> id,
      required int groupId,
      required DateTime date,
      required String label,
      Value<String?> description,
      Value<String> categoryId,
      Value<String> categoryName,
      Value<int> periodStart,
      Value<int> periodEnd,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$SessionsTableTableUpdateCompanionBuilder =
    SessionsTableCompanion Function({
      Value<int> id,
      Value<int> groupId,
      Value<DateTime> date,
      Value<String> label,
      Value<String?> description,
      Value<String> categoryId,
      Value<String> categoryName,
      Value<int> periodStart,
      Value<int> periodEnd,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$SessionsTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $SessionsTableTable, SessionsTableData> {
  $$SessionsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GroupsTableTable _groupIdTable(_$AppDatabase db) =>
      db.groupsTable.createAlias(
        $_aliasNameGenerator(db.sessionsTable.groupId, db.groupsTable.id),
      );

  $$GroupsTableTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<int>('group_id')!;

    final manager = $$GroupsTableTableTableManager(
      $_db,
      $_db.groupsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SessionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTableTable> {
  $$SessionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get periodEnd => $composableBuilder(
    column: $table.periodEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableTableFilterComposer get groupId {
    final $$GroupsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableTableFilterComposer(
            $db: $db,
            $table: $db.groupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTableTable> {
  $$SessionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get periodEnd => $composableBuilder(
    column: $table.periodEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableTableOrderingComposer get groupId {
    final $$GroupsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableTableOrderingComposer(
            $db: $db,
            $table: $db.groupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTableTable> {
  $$SessionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get periodEnd =>
      $composableBuilder(column: $table.periodEnd, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$GroupsTableTableAnnotationComposer get groupId {
    final $$GroupsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.groupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTableTable,
          SessionsTableData,
          $$SessionsTableTableFilterComposer,
          $$SessionsTableTableOrderingComposer,
          $$SessionsTableTableAnnotationComposer,
          $$SessionsTableTableCreateCompanionBuilder,
          $$SessionsTableTableUpdateCompanionBuilder,
          (SessionsTableData, $$SessionsTableTableReferences),
          SessionsTableData,
          PrefetchHooks Function({bool groupId})
        > {
  $$SessionsTableTableTableManager(_$AppDatabase db, $SessionsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> groupId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<int> periodStart = const Value.absent(),
                Value<int> periodEnd = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SessionsTableCompanion(
                id: id,
                groupId: groupId,
                date: date,
                label: label,
                description: description,
                categoryId: categoryId,
                categoryName: categoryName,
                periodStart: periodStart,
                periodEnd: periodEnd,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int groupId,
                required DateTime date,
                required String label,
                Value<String?> description = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<int> periodStart = const Value.absent(),
                Value<int> periodEnd = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SessionsTableCompanion.insert(
                id: id,
                groupId: groupId,
                date: date,
                label: label,
                description: description,
                categoryId: categoryId,
                categoryName: categoryName,
                periodStart: periodStart,
                periodEnd: periodEnd,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (groupId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.groupId,
                                referencedTable: $$SessionsTableTableReferences
                                    ._groupIdTable(db),
                                referencedColumn: $$SessionsTableTableReferences
                                    ._groupIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SessionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTableTable,
      SessionsTableData,
      $$SessionsTableTableFilterComposer,
      $$SessionsTableTableOrderingComposer,
      $$SessionsTableTableAnnotationComposer,
      $$SessionsTableTableCreateCompanionBuilder,
      $$SessionsTableTableUpdateCompanionBuilder,
      (SessionsTableData, $$SessionsTableTableReferences),
      SessionsTableData,
      PrefetchHooks Function({bool groupId})
    >;
typedef $$TimeframesTableTableCreateCompanionBuilder =
    TimeframesTableCompanion Function({
      Value<int> id,
      required int schoolYearId,
      required String label,
      required DateTime startDate,
      required DateTime endDate,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$TimeframesTableTableUpdateCompanionBuilder =
    TimeframesTableCompanion Function({
      Value<int> id,
      Value<int> schoolYearId,
      Value<String> label,
      Value<DateTime> startDate,
      Value<DateTime> endDate,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$TimeframesTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TimeframesTableTable,
          TimeframesTableData
        > {
  $$TimeframesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SchoolYearsTableTable _schoolYearIdTable(_$AppDatabase db) =>
      db.schoolYearsTable.createAlias(
        $_aliasNameGenerator(
          db.timeframesTable.schoolYearId,
          db.schoolYearsTable.id,
        ),
      );

  $$SchoolYearsTableTableProcessedTableManager get schoolYearId {
    final $_column = $_itemColumn<int>('school_year_id')!;

    final manager = $$SchoolYearsTableTableTableManager(
      $_db,
      $_db.schoolYearsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_schoolYearIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $TimeframeGradesTableTable,
    List<TimeframeGradesTableData>
  >
  _timeframeGradesTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.timeframeGradesTable,
        aliasName: $_aliasNameGenerator(
          db.timeframesTable.id,
          db.timeframeGradesTable.timeframeId,
        ),
      );

  $$TimeframeGradesTableTableProcessedTableManager
  get timeframeGradesTableRefs {
    final manager = $$TimeframeGradesTableTableTableManager(
      $_db,
      $_db.timeframeGradesTable,
    ).filter((f) => f.timeframeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _timeframeGradesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TimeframesTableTableFilterComposer
    extends Composer<_$AppDatabase, $TimeframesTableTable> {
  $$TimeframesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SchoolYearsTableTableFilterComposer get schoolYearId {
    final $$SchoolYearsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.schoolYearId,
      referencedTable: $db.schoolYearsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchoolYearsTableTableFilterComposer(
            $db: $db,
            $table: $db.schoolYearsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> timeframeGradesTableRefs(
    Expression<bool> Function($$TimeframeGradesTableTableFilterComposer f) f,
  ) {
    final $$TimeframeGradesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timeframeGradesTable,
      getReferencedColumn: (t) => t.timeframeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimeframeGradesTableTableFilterComposer(
            $db: $db,
            $table: $db.timeframeGradesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TimeframesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TimeframesTableTable> {
  $$TimeframesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SchoolYearsTableTableOrderingComposer get schoolYearId {
    final $$SchoolYearsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.schoolYearId,
      referencedTable: $db.schoolYearsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchoolYearsTableTableOrderingComposer(
            $db: $db,
            $table: $db.schoolYearsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimeframesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimeframesTableTable> {
  $$TimeframesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SchoolYearsTableTableAnnotationComposer get schoolYearId {
    final $$SchoolYearsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.schoolYearId,
      referencedTable: $db.schoolYearsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchoolYearsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.schoolYearsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> timeframeGradesTableRefs<T extends Object>(
    Expression<T> Function($$TimeframeGradesTableTableAnnotationComposer a) f,
  ) {
    final $$TimeframeGradesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.timeframeGradesTable,
          getReferencedColumn: (t) => t.timeframeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TimeframeGradesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.timeframeGradesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TimeframesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimeframesTableTable,
          TimeframesTableData,
          $$TimeframesTableTableFilterComposer,
          $$TimeframesTableTableOrderingComposer,
          $$TimeframesTableTableAnnotationComposer,
          $$TimeframesTableTableCreateCompanionBuilder,
          $$TimeframesTableTableUpdateCompanionBuilder,
          (TimeframesTableData, $$TimeframesTableTableReferences),
          TimeframesTableData,
          PrefetchHooks Function({
            bool schoolYearId,
            bool timeframeGradesTableRefs,
          })
        > {
  $$TimeframesTableTableTableManager(
    _$AppDatabase db,
    $TimeframesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimeframesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimeframesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimeframesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> schoolYearId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> endDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TimeframesTableCompanion(
                id: id,
                schoolYearId: schoolYearId,
                label: label,
                startDate: startDate,
                endDate: endDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int schoolYearId,
                required String label,
                required DateTime startDate,
                required DateTime endDate,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TimeframesTableCompanion.insert(
                id: id,
                schoolYearId: schoolYearId,
                label: label,
                startDate: startDate,
                endDate: endDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TimeframesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({schoolYearId = false, timeframeGradesTableRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (timeframeGradesTableRefs) db.timeframeGradesTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (schoolYearId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.schoolYearId,
                                    referencedTable:
                                        $$TimeframesTableTableReferences
                                            ._schoolYearIdTable(db),
                                    referencedColumn:
                                        $$TimeframesTableTableReferences
                                            ._schoolYearIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (timeframeGradesTableRefs)
                        await $_getPrefetchedData<
                          TimeframesTableData,
                          $TimeframesTableTable,
                          TimeframeGradesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$TimeframesTableTableReferences
                              ._timeframeGradesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TimeframesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).timeframeGradesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.timeframeId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TimeframesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimeframesTableTable,
      TimeframesTableData,
      $$TimeframesTableTableFilterComposer,
      $$TimeframesTableTableOrderingComposer,
      $$TimeframesTableTableAnnotationComposer,
      $$TimeframesTableTableCreateCompanionBuilder,
      $$TimeframesTableTableUpdateCompanionBuilder,
      (TimeframesTableData, $$TimeframesTableTableReferences),
      TimeframesTableData,
      PrefetchHooks Function({bool schoolYearId, bool timeframeGradesTableRefs})
    >;
typedef $$TimeframeGradesTableTableCreateCompanionBuilder =
    TimeframeGradesTableCompanion Function({
      Value<int> id,
      required int timeframeId,
      required int studentId,
      required String grade,
      Value<DateTime> updatedAt,
    });
typedef $$TimeframeGradesTableTableUpdateCompanionBuilder =
    TimeframeGradesTableCompanion Function({
      Value<int> id,
      Value<int> timeframeId,
      Value<int> studentId,
      Value<String> grade,
      Value<DateTime> updatedAt,
    });

final class $$TimeframeGradesTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TimeframeGradesTableTable,
          TimeframeGradesTableData
        > {
  $$TimeframeGradesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TimeframesTableTable _timeframeIdTable(_$AppDatabase db) =>
      db.timeframesTable.createAlias(
        $_aliasNameGenerator(
          db.timeframeGradesTable.timeframeId,
          db.timeframesTable.id,
        ),
      );

  $$TimeframesTableTableProcessedTableManager get timeframeId {
    final $_column = $_itemColumn<int>('timeframe_id')!;

    final manager = $$TimeframesTableTableTableManager(
      $_db,
      $_db.timeframesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_timeframeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StudentsTableTable _studentIdTable(_$AppDatabase db) =>
      db.studentsTable.createAlias(
        $_aliasNameGenerator(
          db.timeframeGradesTable.studentId,
          db.studentsTable.id,
        ),
      );

  $$StudentsTableTableProcessedTableManager get studentId {
    final $_column = $_itemColumn<int>('student_id')!;

    final manager = $$StudentsTableTableTableManager(
      $_db,
      $_db.studentsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TimeframeGradesTableTableFilterComposer
    extends Composer<_$AppDatabase, $TimeframeGradesTableTable> {
  $$TimeframeGradesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TimeframesTableTableFilterComposer get timeframeId {
    final $$TimeframesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timeframeId,
      referencedTable: $db.timeframesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimeframesTableTableFilterComposer(
            $db: $db,
            $table: $db.timeframesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableTableFilterComposer get studentId {
    final $$StudentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableFilterComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimeframeGradesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TimeframeGradesTableTable> {
  $$TimeframeGradesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TimeframesTableTableOrderingComposer get timeframeId {
    final $$TimeframesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timeframeId,
      referencedTable: $db.timeframesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimeframesTableTableOrderingComposer(
            $db: $db,
            $table: $db.timeframesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableTableOrderingComposer get studentId {
    final $$StudentsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableOrderingComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimeframeGradesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimeframeGradesTableTable> {
  $$TimeframeGradesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TimeframesTableTableAnnotationComposer get timeframeId {
    final $$TimeframesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timeframeId,
      referencedTable: $db.timeframesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimeframesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.timeframesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableTableAnnotationComposer get studentId {
    final $$StudentsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.studentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.studentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimeframeGradesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimeframeGradesTableTable,
          TimeframeGradesTableData,
          $$TimeframeGradesTableTableFilterComposer,
          $$TimeframeGradesTableTableOrderingComposer,
          $$TimeframeGradesTableTableAnnotationComposer,
          $$TimeframeGradesTableTableCreateCompanionBuilder,
          $$TimeframeGradesTableTableUpdateCompanionBuilder,
          (TimeframeGradesTableData, $$TimeframeGradesTableTableReferences),
          TimeframeGradesTableData,
          PrefetchHooks Function({bool timeframeId, bool studentId})
        > {
  $$TimeframeGradesTableTableTableManager(
    _$AppDatabase db,
    $TimeframeGradesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimeframeGradesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimeframeGradesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TimeframeGradesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> timeframeId = const Value.absent(),
                Value<int> studentId = const Value.absent(),
                Value<String> grade = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TimeframeGradesTableCompanion(
                id: id,
                timeframeId: timeframeId,
                studentId: studentId,
                grade: grade,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int timeframeId,
                required int studentId,
                required String grade,
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TimeframeGradesTableCompanion.insert(
                id: id,
                timeframeId: timeframeId,
                studentId: studentId,
                grade: grade,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TimeframeGradesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({timeframeId = false, studentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (timeframeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.timeframeId,
                                referencedTable:
                                    $$TimeframeGradesTableTableReferences
                                        ._timeframeIdTable(db),
                                referencedColumn:
                                    $$TimeframeGradesTableTableReferences
                                        ._timeframeIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (studentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.studentId,
                                referencedTable:
                                    $$TimeframeGradesTableTableReferences
                                        ._studentIdTable(db),
                                referencedColumn:
                                    $$TimeframeGradesTableTableReferences
                                        ._studentIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TimeframeGradesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimeframeGradesTableTable,
      TimeframeGradesTableData,
      $$TimeframeGradesTableTableFilterComposer,
      $$TimeframeGradesTableTableOrderingComposer,
      $$TimeframeGradesTableTableAnnotationComposer,
      $$TimeframeGradesTableTableCreateCompanionBuilder,
      $$TimeframeGradesTableTableUpdateCompanionBuilder,
      (TimeframeGradesTableData, $$TimeframeGradesTableTableReferences),
      TimeframeGradesTableData,
      PrefetchHooks Function({bool timeframeId, bool studentId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SchoolYearsTableTableTableManager get schoolYearsTable =>
      $$SchoolYearsTableTableTableManager(_db, _db.schoolYearsTable);
  $$GroupsTableTableTableManager get groupsTable =>
      $$GroupsTableTableTableManager(_db, _db.groupsTable);
  $$StudentsTableTableTableManager get studentsTable =>
      $$StudentsTableTableTableManager(_db, _db.studentsTable);
  $$AttendanceLogsTableTableTableManager get attendanceLogsTable =>
      $$AttendanceLogsTableTableTableManager(_db, _db.attendanceLogsTable);
  $$StudentRelationsTableTableTableManager get studentRelationsTable =>
      $$StudentRelationsTableTableTableManager(_db, _db.studentRelationsTable);
  $$GradeEntriesTableTableTableManager get gradeEntriesTable =>
      $$GradeEntriesTableTableTableManager(_db, _db.gradeEntriesTable);
  $$MaterialLogsTableTableTableManager get materialLogsTable =>
      $$MaterialLogsTableTableTableManager(_db, _db.materialLogsTable);
  $$HomeworkLogsTableTableTableManager get homeworkLogsTable =>
      $$HomeworkLogsTableTableTableManager(_db, _db.homeworkLogsTable);
  $$LessonSlotsTableTableTableManager get lessonSlotsTable =>
      $$LessonSlotsTableTableTableManager(_db, _db.lessonSlotsTable);
  $$ListsTableTableTableManager get listsTable =>
      $$ListsTableTableTableManager(_db, _db.listsTable);
  $$ListItemsTableTableTableManager get listItemsTable =>
      $$ListItemsTableTableTableManager(_db, _db.listItemsTable);
  $$NotesTableTableTableManager get notesTable =>
      $$NotesTableTableTableManager(_db, _db.notesTable);
  $$SeatingPlansTableTableTableManager get seatingPlansTable =>
      $$SeatingPlansTableTableTableManager(_db, _db.seatingPlansTable);
  $$SeatingPlanPositionsTableTableTableManager get seatingPlanPositionsTable =>
      $$SeatingPlanPositionsTableTableTableManager(
        _db,
        _db.seatingPlanPositionsTable,
      );
  $$SessionsTableTableTableManager get sessionsTable =>
      $$SessionsTableTableTableManager(_db, _db.sessionsTable);
  $$TimeframesTableTableTableManager get timeframesTable =>
      $$TimeframesTableTableTableManager(_db, _db.timeframesTable);
  $$TimeframeGradesTableTableTableManager get timeframeGradesTable =>
      $$TimeframeGradesTableTableTableManager(_db, _db.timeframeGradesTable);
}
