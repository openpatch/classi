// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    colorHex,
    gradeScaleJson,
    gradeCategoriesJson,
    createdAt,
    archivedAt,
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
  const GroupsTableData({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.gradeScaleJson,
    required this.gradeCategoriesJson,
    required this.createdAt,
    this.archivedAt,
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
  }) => GroupsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    colorHex: colorHex ?? this.colorHex,
    gradeScaleJson: gradeScaleJson ?? this.gradeScaleJson,
    gradeCategoriesJson: gradeCategoriesJson ?? this.gradeCategoriesJson,
    createdAt: createdAt ?? this.createdAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
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
          ..write('archivedAt: $archivedAt')
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
          other.archivedAt == this.archivedAt);
}

class GroupsTableCompanion extends UpdateCompanion<GroupsTableData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> colorHex;
  final Value<String> gradeScaleJson;
  final Value<String> gradeCategoriesJson;
  final Value<DateTime> createdAt;
  final Value<DateTime?> archivedAt;
  const GroupsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.gradeScaleJson = const Value.absent(),
    this.gradeCategoriesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
  });
  GroupsTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.colorHex = const Value.absent(),
    this.gradeScaleJson = const Value.absent(),
    this.gradeCategoriesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<GroupsTableData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? colorHex,
    Expression<String>? gradeScaleJson,
    Expression<String>? gradeCategoriesJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? archivedAt,
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
  }) {
    return GroupsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      gradeScaleJson: gradeScaleJson ?? this.gradeScaleJson,
      gradeCategoriesJson: gradeCategoriesJson ?? this.gradeCategoriesJson,
      createdAt: createdAt ?? this.createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
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
          ..write('archivedAt: $archivedAt')
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    firstName,
    lastName,
    groupId,
    originNote,
    createdAt,
    avatarJson,
    seatIndex,
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
  final int groupId;
  final String? originNote;
  final DateTime createdAt;
  final String? avatarJson;
  final int? seatIndex;
  const StudentsTableData({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.groupId,
    this.originNote,
    required this.createdAt,
    this.avatarJson,
    this.seatIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
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
    return map;
  }

  StudentsTableCompanion toCompanion(bool nullToAbsent) {
    return StudentsTableCompanion(
      id: Value(id),
      firstName: Value(firstName),
      lastName: Value(lastName),
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
      groupId: serializer.fromJson<int>(json['groupId']),
      originNote: serializer.fromJson<String?>(json['originNote']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      avatarJson: serializer.fromJson<String?>(json['avatarJson']),
      seatIndex: serializer.fromJson<int?>(json['seatIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'groupId': serializer.toJson<int>(groupId),
      'originNote': serializer.toJson<String?>(originNote),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'avatarJson': serializer.toJson<String?>(avatarJson),
      'seatIndex': serializer.toJson<int?>(seatIndex),
    };
  }

  StudentsTableData copyWith({
    int? id,
    String? firstName,
    String? lastName,
    int? groupId,
    Value<String?> originNote = const Value.absent(),
    DateTime? createdAt,
    Value<String?> avatarJson = const Value.absent(),
    Value<int?> seatIndex = const Value.absent(),
  }) => StudentsTableData(
    id: id ?? this.id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    groupId: groupId ?? this.groupId,
    originNote: originNote.present ? originNote.value : this.originNote,
    createdAt: createdAt ?? this.createdAt,
    avatarJson: avatarJson.present ? avatarJson.value : this.avatarJson,
    seatIndex: seatIndex.present ? seatIndex.value : this.seatIndex,
  );
  StudentsTableData copyWithCompanion(StudentsTableCompanion data) {
    return StudentsTableData(
      id: data.id.present ? data.id.value : this.id,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      originNote: data.originNote.present
          ? data.originNote.value
          : this.originNote,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      avatarJson: data.avatarJson.present
          ? data.avatarJson.value
          : this.avatarJson,
      seatIndex: data.seatIndex.present ? data.seatIndex.value : this.seatIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudentsTableData(')
          ..write('id: $id, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('groupId: $groupId, ')
          ..write('originNote: $originNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('avatarJson: $avatarJson, ')
          ..write('seatIndex: $seatIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    firstName,
    lastName,
    groupId,
    originNote,
    createdAt,
    avatarJson,
    seatIndex,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudentsTableData &&
          other.id == this.id &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.groupId == this.groupId &&
          other.originNote == this.originNote &&
          other.createdAt == this.createdAt &&
          other.avatarJson == this.avatarJson &&
          other.seatIndex == this.seatIndex);
}

class StudentsTableCompanion extends UpdateCompanion<StudentsTableData> {
  final Value<int> id;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<int> groupId;
  final Value<String?> originNote;
  final Value<DateTime> createdAt;
  final Value<String?> avatarJson;
  final Value<int?> seatIndex;
  const StudentsTableCompanion({
    this.id = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.groupId = const Value.absent(),
    this.originNote = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.avatarJson = const Value.absent(),
    this.seatIndex = const Value.absent(),
  });
  StudentsTableCompanion.insert({
    this.id = const Value.absent(),
    required String firstName,
    required String lastName,
    required int groupId,
    this.originNote = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.avatarJson = const Value.absent(),
    this.seatIndex = const Value.absent(),
  }) : firstName = Value(firstName),
       lastName = Value(lastName),
       groupId = Value(groupId);
  static Insertable<StudentsTableData> custom({
    Expression<int>? id,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<int>? groupId,
    Expression<String>? originNote,
    Expression<DateTime>? createdAt,
    Expression<String>? avatarJson,
    Expression<int>? seatIndex,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (groupId != null) 'group_id': groupId,
      if (originNote != null) 'origin_note': originNote,
      if (createdAt != null) 'created_at': createdAt,
      if (avatarJson != null) 'avatar_json': avatarJson,
      if (seatIndex != null) 'seat_index': seatIndex,
    });
  }

  StudentsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? firstName,
    Value<String>? lastName,
    Value<int>? groupId,
    Value<String?>? originNote,
    Value<DateTime>? createdAt,
    Value<String?>? avatarJson,
    Value<int?>? seatIndex,
  }) {
    return StudentsTableCompanion(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      groupId: groupId ?? this.groupId,
      originNote: originNote ?? this.originNote,
      createdAt: createdAt ?? this.createdAt,
      avatarJson: avatarJson ?? this.avatarJson,
      seatIndex: seatIndex ?? this.seatIndex,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentsTableCompanion(')
          ..write('id: $id, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('groupId: $groupId, ')
          ..write('originNote: $originNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('avatarJson: $avatarJson, ')
          ..write('seatIndex: $seatIndex')
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
  @override
  List<GeneratedColumn> get $columns => [id, studentId, date, createdAt];
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
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
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
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
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
  final DateTime createdAt;
  const AttendanceLogsTableData({
    required this.id,
    required this.studentId,
    required this.date,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['student_id'] = Variable<int>(studentId);
    map['date'] = Variable<DateTime>(date);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AttendanceLogsTableCompanion toCompanion(bool nullToAbsent) {
    return AttendanceLogsTableCompanion(
      id: Value(id),
      studentId: Value(studentId),
      date: Value(date),
      createdAt: Value(createdAt),
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
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'studentId': serializer.toJson<int>(studentId),
      'date': serializer.toJson<DateTime>(date),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AttendanceLogsTableData copyWith({
    int? id,
    int? studentId,
    DateTime? date,
    DateTime? createdAt,
  }) => AttendanceLogsTableData(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    date: date ?? this.date,
    createdAt: createdAt ?? this.createdAt,
  );
  AttendanceLogsTableData copyWithCompanion(AttendanceLogsTableCompanion data) {
    return AttendanceLogsTableData(
      id: data.id.present ? data.id.value : this.id,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      date: data.date.present ? data.date.value : this.date,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceLogsTableData(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, studentId, date, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceLogsTableData &&
          other.id == this.id &&
          other.studentId == this.studentId &&
          other.date == this.date &&
          other.createdAt == this.createdAt);
}

class AttendanceLogsTableCompanion
    extends UpdateCompanion<AttendanceLogsTableData> {
  final Value<int> id;
  final Value<int> studentId;
  final Value<DateTime> date;
  final Value<DateTime> createdAt;
  const AttendanceLogsTableCompanion({
    this.id = const Value.absent(),
    this.studentId = const Value.absent(),
    this.date = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AttendanceLogsTableCompanion.insert({
    this.id = const Value.absent(),
    required int studentId,
    required DateTime date,
    this.createdAt = const Value.absent(),
  }) : studentId = Value(studentId),
       date = Value(date);
  static Insertable<AttendanceLogsTableData> custom({
    Expression<int>? id,
    Expression<int>? studentId,
    Expression<DateTime>? date,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentId != null) 'student_id': studentId,
      if (date != null) 'date': date,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AttendanceLogsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? studentId,
    Value<DateTime>? date,
    Value<DateTime>? createdAt,
  }) {
    return AttendanceLogsTableCompanion(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
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
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceLogsTableCompanion(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt')
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
  const GradeEntriesTableData({
    required this.id,
    required this.studentId,
    required this.date,
    required this.sessionLabel,
    required this.value,
    required this.categoryId,
    required this.categoryName,
    required this.createdAt,
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
  }) => GradeEntriesTableData(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    date: date ?? this.date,
    sessionLabel: sessionLabel ?? this.sessionLabel,
    value: value ?? this.value,
    categoryId: categoryId ?? this.categoryId,
    categoryName: categoryName ?? this.categoryName,
    createdAt: createdAt ?? this.createdAt,
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
          ..write('createdAt: $createdAt')
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
          other.createdAt == this.createdAt);
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
  const GradeEntriesTableCompanion({
    this.id = const Value.absent(),
    this.studentId = const Value.absent(),
    this.date = const Value.absent(),
    this.sessionLabel = const Value.absent(),
    this.value = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.createdAt = const Value.absent(),
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
          ..write('createdAt: $createdAt')
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    studentId,
    date,
    hadMaterial,
    createdAt,
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
  const MaterialLogsTableData({
    required this.id,
    required this.studentId,
    required this.date,
    required this.hadMaterial,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['student_id'] = Variable<int>(studentId);
    map['date'] = Variable<DateTime>(date);
    map['had_material'] = Variable<bool>(hadMaterial);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MaterialLogsTableCompanion toCompanion(bool nullToAbsent) {
    return MaterialLogsTableCompanion(
      id: Value(id),
      studentId: Value(studentId),
      date: Value(date),
      hadMaterial: Value(hadMaterial),
      createdAt: Value(createdAt),
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
    };
  }

  MaterialLogsTableData copyWith({
    int? id,
    int? studentId,
    DateTime? date,
    bool? hadMaterial,
    DateTime? createdAt,
  }) => MaterialLogsTableData(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    date: date ?? this.date,
    hadMaterial: hadMaterial ?? this.hadMaterial,
    createdAt: createdAt ?? this.createdAt,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaterialLogsTableData(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('date: $date, ')
          ..write('hadMaterial: $hadMaterial, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, studentId, date, hadMaterial, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaterialLogsTableData &&
          other.id == this.id &&
          other.studentId == this.studentId &&
          other.date == this.date &&
          other.hadMaterial == this.hadMaterial &&
          other.createdAt == this.createdAt);
}

class MaterialLogsTableCompanion
    extends UpdateCompanion<MaterialLogsTableData> {
  final Value<int> id;
  final Value<int> studentId;
  final Value<DateTime> date;
  final Value<bool> hadMaterial;
  final Value<DateTime> createdAt;
  const MaterialLogsTableCompanion({
    this.id = const Value.absent(),
    this.studentId = const Value.absent(),
    this.date = const Value.absent(),
    this.hadMaterial = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MaterialLogsTableCompanion.insert({
    this.id = const Value.absent(),
    required int studentId,
    required DateTime date,
    this.hadMaterial = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : studentId = Value(studentId),
       date = Value(date);
  static Insertable<MaterialLogsTableData> custom({
    Expression<int>? id,
    Expression<int>? studentId,
    Expression<DateTime>? date,
    Expression<bool>? hadMaterial,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentId != null) 'student_id': studentId,
      if (date != null) 'date': date,
      if (hadMaterial != null) 'had_material': hadMaterial,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MaterialLogsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? studentId,
    Value<DateTime>? date,
    Value<bool>? hadMaterial,
    Value<DateTime>? createdAt,
  }) {
    return MaterialLogsTableCompanion(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      hadMaterial: hadMaterial ?? this.hadMaterial,
      createdAt: createdAt ?? this.createdAt,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaterialLogsTableCompanion(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('date: $date, ')
          ..write('hadMaterial: $hadMaterial, ')
          ..write('createdAt: $createdAt')
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    studentId,
    date,
    hadHomework,
    createdAt,
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
  const HomeworkLogsTableData({
    required this.id,
    required this.studentId,
    required this.date,
    required this.hadHomework,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['student_id'] = Variable<int>(studentId);
    map['date'] = Variable<DateTime>(date);
    map['had_homework'] = Variable<bool>(hadHomework);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HomeworkLogsTableCompanion toCompanion(bool nullToAbsent) {
    return HomeworkLogsTableCompanion(
      id: Value(id),
      studentId: Value(studentId),
      date: Value(date),
      hadHomework: Value(hadHomework),
      createdAt: Value(createdAt),
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
    };
  }

  HomeworkLogsTableData copyWith({
    int? id,
    int? studentId,
    DateTime? date,
    bool? hadHomework,
    DateTime? createdAt,
  }) => HomeworkLogsTableData(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    date: date ?? this.date,
    hadHomework: hadHomework ?? this.hadHomework,
    createdAt: createdAt ?? this.createdAt,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('HomeworkLogsTableData(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('date: $date, ')
          ..write('hadHomework: $hadHomework, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, studentId, date, hadHomework, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HomeworkLogsTableData &&
          other.id == this.id &&
          other.studentId == this.studentId &&
          other.date == this.date &&
          other.hadHomework == this.hadHomework &&
          other.createdAt == this.createdAt);
}

class HomeworkLogsTableCompanion
    extends UpdateCompanion<HomeworkLogsTableData> {
  final Value<int> id;
  final Value<int> studentId;
  final Value<DateTime> date;
  final Value<bool> hadHomework;
  final Value<DateTime> createdAt;
  const HomeworkLogsTableCompanion({
    this.id = const Value.absent(),
    this.studentId = const Value.absent(),
    this.date = const Value.absent(),
    this.hadHomework = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  HomeworkLogsTableCompanion.insert({
    this.id = const Value.absent(),
    required int studentId,
    required DateTime date,
    this.hadHomework = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : studentId = Value(studentId),
       date = Value(date);
  static Insertable<HomeworkLogsTableData> custom({
    Expression<int>? id,
    Expression<int>? studentId,
    Expression<DateTime>? date,
    Expression<bool>? hadHomework,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentId != null) 'student_id': studentId,
      if (date != null) 'date': date,
      if (hadHomework != null) 'had_homework': hadHomework,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  HomeworkLogsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? studentId,
    Value<DateTime>? date,
    Value<bool>? hadHomework,
    Value<DateTime>? createdAt,
  }) {
    return HomeworkLogsTableCompanion(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      hadHomework: hadHomework ?? this.hadHomework,
      createdAt: createdAt ?? this.createdAt,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HomeworkLogsTableCompanion(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('date: $date, ')
          ..write('hadHomework: $hadHomework, ')
          ..write('createdAt: $createdAt')
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    name,
    createdAt,
    archivedAt,
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
      )!,
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
    );
  }

  @override
  $ListsTableTable createAlias(String alias) {
    return $ListsTableTable(attachedDatabase, alias);
  }
}

class Checklist extends DataClass implements Insertable<Checklist> {
  final int id;
  final int groupId;
  final String name;
  final DateTime createdAt;
  final DateTime? archivedAt;
  const Checklist({
    required this.id,
    required this.groupId,
    required this.name,
    required this.createdAt,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['group_id'] = Variable<int>(groupId);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  ListsTableCompanion toCompanion(bool nullToAbsent) {
    return ListsTableCompanion(
      id: Value(id),
      groupId: Value(groupId),
      name: Value(name),
      createdAt: Value(createdAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory Checklist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Checklist(
      id: serializer.fromJson<int>(json['id']),
      groupId: serializer.fromJson<int>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'groupId': serializer.toJson<int>(groupId),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  Checklist copyWith({
    int? id,
    int? groupId,
    String? name,
    DateTime? createdAt,
    Value<DateTime?> archivedAt = const Value.absent(),
  }) => Checklist(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('Checklist(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, groupId, name, createdAt, archivedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Checklist &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.archivedAt == this.archivedAt);
}

class ListsTableCompanion extends UpdateCompanion<Checklist> {
  final Value<int> id;
  final Value<int> groupId;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<DateTime?> archivedAt;
  const ListsTableCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
  });
  ListsTableCompanion.insert({
    this.id = const Value.absent(),
    required int groupId,
    required String name,
    this.createdAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
  }) : groupId = Value(groupId),
       name = Value(name);
  static Insertable<Checklist> custom({
    Expression<int>? id,
    Expression<int>? groupId,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? archivedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (archivedAt != null) 'archived_at': archivedAt,
    });
  }

  ListsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? groupId,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<DateTime?>? archivedAt,
  }) {
    return ListsTableCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListsTableCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt')
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    listId,
    studentId,
    label,
    checkedAt,
    createdAt,
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
  final String label;
  final DateTime? checkedAt;
  final DateTime createdAt;
  const ChecklistItem({
    required this.id,
    required this.listId,
    this.studentId,
    required this.label,
    this.checkedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['list_id'] = Variable<int>(listId);
    if (!nullToAbsent || studentId != null) {
      map['student_id'] = Variable<int>(studentId);
    }
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || checkedAt != null) {
      map['checked_at'] = Variable<DateTime>(checkedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ListItemsTableCompanion toCompanion(bool nullToAbsent) {
    return ListItemsTableCompanion(
      id: Value(id),
      listId: Value(listId),
      studentId: studentId == null && nullToAbsent
          ? const Value.absent()
          : Value(studentId),
      label: Value(label),
      checkedAt: checkedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(checkedAt),
      createdAt: Value(createdAt),
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
      label: serializer.fromJson<String>(json['label']),
      checkedAt: serializer.fromJson<DateTime?>(json['checkedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'listId': serializer.toJson<int>(listId),
      'studentId': serializer.toJson<int?>(studentId),
      'label': serializer.toJson<String>(label),
      'checkedAt': serializer.toJson<DateTime?>(checkedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChecklistItem copyWith({
    int? id,
    int? listId,
    Value<int?> studentId = const Value.absent(),
    String? label,
    Value<DateTime?> checkedAt = const Value.absent(),
    DateTime? createdAt,
  }) => ChecklistItem(
    id: id ?? this.id,
    listId: listId ?? this.listId,
    studentId: studentId.present ? studentId.value : this.studentId,
    label: label ?? this.label,
    checkedAt: checkedAt.present ? checkedAt.value : this.checkedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  ChecklistItem copyWithCompanion(ListItemsTableCompanion data) {
    return ChecklistItem(
      id: data.id.present ? data.id.value : this.id,
      listId: data.listId.present ? data.listId.value : this.listId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      label: data.label.present ? data.label.value : this.label,
      checkedAt: data.checkedAt.present ? data.checkedAt.value : this.checkedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistItem(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('studentId: $studentId, ')
          ..write('label: $label, ')
          ..write('checkedAt: $checkedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, listId, studentId, label, checkedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistItem &&
          other.id == this.id &&
          other.listId == this.listId &&
          other.studentId == this.studentId &&
          other.label == this.label &&
          other.checkedAt == this.checkedAt &&
          other.createdAt == this.createdAt);
}

class ListItemsTableCompanion extends UpdateCompanion<ChecklistItem> {
  final Value<int> id;
  final Value<int> listId;
  final Value<int?> studentId;
  final Value<String> label;
  final Value<DateTime?> checkedAt;
  final Value<DateTime> createdAt;
  const ListItemsTableCompanion({
    this.id = const Value.absent(),
    this.listId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.label = const Value.absent(),
    this.checkedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ListItemsTableCompanion.insert({
    this.id = const Value.absent(),
    required int listId,
    this.studentId = const Value.absent(),
    required String label,
    this.checkedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : listId = Value(listId),
       label = Value(label);
  static Insertable<ChecklistItem> custom({
    Expression<int>? id,
    Expression<int>? listId,
    Expression<int>? studentId,
    Expression<String>? label,
    Expression<DateTime>? checkedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listId != null) 'list_id': listId,
      if (studentId != null) 'student_id': studentId,
      if (label != null) 'label': label,
      if (checkedAt != null) 'checked_at': checkedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ListItemsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? listId,
    Value<int?>? studentId,
    Value<String>? label,
    Value<DateTime?>? checkedAt,
    Value<DateTime>? createdAt,
  }) {
    return ListItemsTableCompanion(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      studentId: studentId ?? this.studentId,
      label: label ?? this.label,
      checkedAt: checkedAt ?? this.checkedAt,
      createdAt: createdAt ?? this.createdAt,
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
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (checkedAt.present) {
      map['checked_at'] = Variable<DateTime>(checkedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('studentId: $studentId, ')
          ..write('label: $label, ')
          ..write('checkedAt: $checkedAt, ')
          ..write('createdAt: $createdAt')
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
          ..write('archivedAt: $archivedAt')
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
          other.archivedAt == this.archivedAt);
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
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GroupsTableTable groupsTable = $GroupsTableTable(this);
  late final $StudentsTableTable studentsTable = $StudentsTableTable(this);
  late final $AttendanceLogsTableTable attendanceLogsTable =
      $AttendanceLogsTableTable(this);
  late final $GradeEntriesTableTable gradeEntriesTable =
      $GradeEntriesTableTable(this);
  late final $MaterialLogsTableTable materialLogsTable =
      $MaterialLogsTableTable(this);
  late final $HomeworkLogsTableTable homeworkLogsTable =
      $HomeworkLogsTableTable(this);
  late final $ListsTableTable listsTable = $ListsTableTable(this);
  late final $ListItemsTableTable listItemsTable = $ListItemsTableTable(this);
  late final $NotesTableTable notesTable = $NotesTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    groupsTable,
    studentsTable,
    attendanceLogsTable,
    gradeEntriesTable,
    materialLogsTable,
    homeworkLogsTable,
    listsTable,
    listItemsTable,
    notesTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
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
  ]);
}

typedef $$GroupsTableTableCreateCompanionBuilder =
    GroupsTableCompanion Function({
      Value<int> id,
      required String name,
      Value<String> colorHex,
      Value<String> gradeScaleJson,
      Value<String> gradeCategoriesJson,
      Value<DateTime> createdAt,
      Value<DateTime?> archivedAt,
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
    });

final class $$GroupsTableTableReferences
    extends BaseReferences<_$AppDatabase, $GroupsTableTable, GroupsTableData> {
  $$GroupsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

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
            bool studentsTableRefs,
            bool listsTableRefs,
            bool notesTableRefs,
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
              }) => GroupsTableCompanion(
                id: id,
                name: name,
                colorHex: colorHex,
                gradeScaleJson: gradeScaleJson,
                gradeCategoriesJson: gradeCategoriesJson,
                createdAt: createdAt,
                archivedAt: archivedAt,
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
              }) => GroupsTableCompanion.insert(
                id: id,
                name: name,
                colorHex: colorHex,
                gradeScaleJson: gradeScaleJson,
                gradeCategoriesJson: gradeCategoriesJson,
                createdAt: createdAt,
                archivedAt: archivedAt,
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
                studentsTableRefs = false,
                listsTableRefs = false,
                notesTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (studentsTableRefs) db.studentsTable,
                    if (listsTableRefs) db.listsTable,
                    if (notesTableRefs) db.notesTable,
                  ],
                  addJoins: null,
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
        bool studentsTableRefs,
        bool listsTableRefs,
        bool notesTableRefs,
      })
    >;
typedef $$StudentsTableTableCreateCompanionBuilder =
    StudentsTableCompanion Function({
      Value<int> id,
      required String firstName,
      required String lastName,
      required int groupId,
      Value<String?> originNote,
      Value<DateTime> createdAt,
      Value<String?> avatarJson,
      Value<int?> seatIndex,
    });
typedef $$StudentsTableTableUpdateCompanionBuilder =
    StudentsTableCompanion Function({
      Value<int> id,
      Value<String> firstName,
      Value<String> lastName,
      Value<int> groupId,
      Value<String?> originNote,
      Value<DateTime> createdAt,
      Value<String?> avatarJson,
      Value<int?> seatIndex,
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
            bool gradeEntriesTableRefs,
            bool materialLogsTableRefs,
            bool homeworkLogsTableRefs,
            bool listItemsTableRefs,
            bool notesTableRefs,
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
                Value<int> groupId = const Value.absent(),
                Value<String?> originNote = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> avatarJson = const Value.absent(),
                Value<int?> seatIndex = const Value.absent(),
              }) => StudentsTableCompanion(
                id: id,
                firstName: firstName,
                lastName: lastName,
                groupId: groupId,
                originNote: originNote,
                createdAt: createdAt,
                avatarJson: avatarJson,
                seatIndex: seatIndex,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String firstName,
                required String lastName,
                required int groupId,
                Value<String?> originNote = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> avatarJson = const Value.absent(),
                Value<int?> seatIndex = const Value.absent(),
              }) => StudentsTableCompanion.insert(
                id: id,
                firstName: firstName,
                lastName: lastName,
                groupId: groupId,
                originNote: originNote,
                createdAt: createdAt,
                avatarJson: avatarJson,
                seatIndex: seatIndex,
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
                gradeEntriesTableRefs = false,
                materialLogsTableRefs = false,
                homeworkLogsTableRefs = false,
                listItemsTableRefs = false,
                notesTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (attendanceLogsTableRefs) db.attendanceLogsTable,
                    if (gradeEntriesTableRefs) db.gradeEntriesTable,
                    if (materialLogsTableRefs) db.materialLogsTable,
                    if (homeworkLogsTableRefs) db.homeworkLogsTable,
                    if (listItemsTableRefs) db.listItemsTable,
                    if (notesTableRefs) db.notesTable,
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
        bool gradeEntriesTableRefs,
        bool materialLogsTableRefs,
        bool homeworkLogsTableRefs,
        bool listItemsTableRefs,
        bool notesTableRefs,
      })
    >;
typedef $$AttendanceLogsTableTableCreateCompanionBuilder =
    AttendanceLogsTableCompanion Function({
      Value<int> id,
      required int studentId,
      required DateTime date,
      Value<DateTime> createdAt,
    });
typedef $$AttendanceLogsTableTableUpdateCompanionBuilder =
    AttendanceLogsTableCompanion Function({
      Value<int> id,
      Value<int> studentId,
      Value<DateTime> date,
      Value<DateTime> createdAt,
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

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
                Value<DateTime> createdAt = const Value.absent(),
              }) => AttendanceLogsTableCompanion(
                id: id,
                studentId: studentId,
                date: date,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int studentId,
                required DateTime date,
                Value<DateTime> createdAt = const Value.absent(),
              }) => AttendanceLogsTableCompanion.insert(
                id: id,
                studentId: studentId,
                date: date,
                createdAt: createdAt,
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
              }) => GradeEntriesTableCompanion(
                id: id,
                studentId: studentId,
                date: date,
                sessionLabel: sessionLabel,
                value: value,
                categoryId: categoryId,
                categoryName: categoryName,
                createdAt: createdAt,
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
              }) => GradeEntriesTableCompanion.insert(
                id: id,
                studentId: studentId,
                date: date,
                sessionLabel: sessionLabel,
                value: value,
                categoryId: categoryId,
                categoryName: categoryName,
                createdAt: createdAt,
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
    });
typedef $$MaterialLogsTableTableUpdateCompanionBuilder =
    MaterialLogsTableCompanion Function({
      Value<int> id,
      Value<int> studentId,
      Value<DateTime> date,
      Value<bool> hadMaterial,
      Value<DateTime> createdAt,
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
              }) => MaterialLogsTableCompanion(
                id: id,
                studentId: studentId,
                date: date,
                hadMaterial: hadMaterial,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int studentId,
                required DateTime date,
                Value<bool> hadMaterial = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MaterialLogsTableCompanion.insert(
                id: id,
                studentId: studentId,
                date: date,
                hadMaterial: hadMaterial,
                createdAt: createdAt,
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
    });
typedef $$HomeworkLogsTableTableUpdateCompanionBuilder =
    HomeworkLogsTableCompanion Function({
      Value<int> id,
      Value<int> studentId,
      Value<DateTime> date,
      Value<bool> hadHomework,
      Value<DateTime> createdAt,
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
              }) => HomeworkLogsTableCompanion(
                id: id,
                studentId: studentId,
                date: date,
                hadHomework: hadHomework,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int studentId,
                required DateTime date,
                Value<bool> hadHomework = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => HomeworkLogsTableCompanion.insert(
                id: id,
                studentId: studentId,
                date: date,
                hadHomework: hadHomework,
                createdAt: createdAt,
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
typedef $$ListsTableTableCreateCompanionBuilder =
    ListsTableCompanion Function({
      Value<int> id,
      required int groupId,
      required String name,
      Value<DateTime> createdAt,
      Value<DateTime?> archivedAt,
    });
typedef $$ListsTableTableUpdateCompanionBuilder =
    ListsTableCompanion Function({
      Value<int> id,
      Value<int> groupId,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<DateTime?> archivedAt,
    });

final class $$ListsTableTableReferences
    extends BaseReferences<_$AppDatabase, $ListsTableTable, Checklist> {
  $$ListsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTableTable _groupIdTable(_$AppDatabase db) =>
      db.groupsTable.createAlias(
        $_aliasNameGenerator(db.listsTable.groupId, db.groupsTable.id),
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
                Value<int> groupId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
              }) => ListsTableCompanion(
                id: id,
                groupId: groupId,
                name: name,
                createdAt: createdAt,
                archivedAt: archivedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int groupId,
                required String name,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
              }) => ListsTableCompanion.insert(
                id: id,
                groupId: groupId,
                name: name,
                createdAt: createdAt,
                archivedAt: archivedAt,
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
      required String label,
      Value<DateTime?> checkedAt,
      Value<DateTime> createdAt,
    });
typedef $$ListItemsTableTableUpdateCompanionBuilder =
    ListItemsTableCompanion Function({
      Value<int> id,
      Value<int> listId,
      Value<int?> studentId,
      Value<String> label,
      Value<DateTime?> checkedAt,
      Value<DateTime> createdAt,
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

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<DateTime> get checkedAt =>
      $composableBuilder(column: $table.checkedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

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
                Value<String> label = const Value.absent(),
                Value<DateTime?> checkedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ListItemsTableCompanion(
                id: id,
                listId: listId,
                studentId: studentId,
                label: label,
                checkedAt: checkedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int listId,
                Value<int?> studentId = const Value.absent(),
                required String label,
                Value<DateTime?> checkedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ListItemsTableCompanion.insert(
                id: id,
                listId: listId,
                studentId: studentId,
                label: label,
                checkedAt: checkedAt,
                createdAt: createdAt,
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GroupsTableTableTableManager get groupsTable =>
      $$GroupsTableTableTableManager(_db, _db.groupsTable);
  $$StudentsTableTableTableManager get studentsTable =>
      $$StudentsTableTableTableManager(_db, _db.studentsTable);
  $$AttendanceLogsTableTableTableManager get attendanceLogsTable =>
      $$AttendanceLogsTableTableTableManager(_db, _db.attendanceLogsTable);
  $$GradeEntriesTableTableTableManager get gradeEntriesTable =>
      $$GradeEntriesTableTableTableManager(_db, _db.gradeEntriesTable);
  $$MaterialLogsTableTableTableManager get materialLogsTable =>
      $$MaterialLogsTableTableTableManager(_db, _db.materialLogsTable);
  $$HomeworkLogsTableTableTableManager get homeworkLogsTable =>
      $$HomeworkLogsTableTableTableManager(_db, _db.homeworkLogsTable);
  $$ListsTableTableTableManager get listsTable =>
      $$ListsTableTableTableManager(_db, _db.listsTable);
  $$ListItemsTableTableTableManager get listItemsTable =>
      $$ListItemsTableTableTableManager(_db, _db.listItemsTable);
  $$NotesTableTableTableManager get notesTable =>
      $$NotesTableTableTableManager(_db, _db.notesTable);
}
