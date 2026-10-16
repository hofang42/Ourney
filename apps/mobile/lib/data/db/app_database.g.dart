// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles
    with TableInfo<$ProfilesTable, ProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarPathMeta = const VerificationMeta(
    'avatarPath',
  );
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
    'avatar_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    username,
    displayName,
    avatarPath,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('avatar_path')) {
      context.handle(
        _avatarPathMeta,
        avatarPath.isAcceptableOrUnknown(data['avatar_path']!, _avatarPathMeta),
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
  ProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      avatarPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_path'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class ProfileRow extends DataClass implements Insertable<ProfileRow> {
  final String id;
  final String username;
  final String displayName;
  final String? avatarPath;

  /// Server `updated_at` (null while only local).
  final String? updatedAt;
  const ProfileRow({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarPath,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['username'] = Variable<String>(username);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      username: Value(username),
      displayName: Value(displayName),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory ProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRow(
      id: serializer.fromJson<String>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      displayName: serializer.fromJson<String>(json['displayName']),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'username': serializer.toJson<String>(username),
      'displayName': serializer.toJson<String>(displayName),
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  ProfileRow copyWith({
    String? id,
    String? username,
    String? displayName,
    Value<String?> avatarPath = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => ProfileRow(
    id: id ?? this.id,
    username: username ?? this.username,
    displayName: displayName ?? this.displayName,
    avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  ProfileRow copyWithCompanion(ProfilesCompanion data) {
    return ProfileRow(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      avatarPath: data.avatarPath.present
          ? data.avatarPath.value
          : this.avatarPath,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRow(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, username, displayName, avatarPath, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRow &&
          other.id == this.id &&
          other.username == this.username &&
          other.displayName == this.displayName &&
          other.avatarPath == this.avatarPath &&
          other.updatedAt == this.updatedAt);
}

class ProfilesCompanion extends UpdateCompanion<ProfileRow> {
  final Value<String> id;
  final Value<String> username;
  final Value<String> displayName;
  final Value<String?> avatarPath;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.displayName = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    required String username,
    required String displayName,
    this.avatarPath = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       username = Value(username),
       displayName = Value(displayName);
  static Insertable<ProfileRow> custom({
    Expression<String>? id,
    Expression<String>? username,
    Expression<String>? displayName,
    Expression<String>? avatarPath,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? username,
    Value<String>? displayName,
    Value<String?>? avatarPath,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarPath: avatarPath ?? this.avatarPath,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JourneysTable extends Journeys
    with TableInfo<$JourneysTable, JourneyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JourneysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metricNameMeta = const VerificationMeta(
    'metricName',
  );
  @override
  late final GeneratedColumn<String> metricName = GeneratedColumn<String>(
    'metric_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metricUnitMeta = const VerificationMeta(
    'metricUnit',
  );
  @override
  late final GeneratedColumn<String> metricUnit = GeneratedColumn<String>(
    'metric_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hideMetricDefaultMeta = const VerificationMeta(
    'hideMetricDefault',
  );
  @override
  late final GeneratedColumn<bool> hideMetricDefault = GeneratedColumn<bool>(
    'hide_metric_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hide_metric_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> startDate =
      GeneratedColumn<String>(
        'start_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($JourneysTable.$converterstartDate);
  static const VerificationMeta _durationDaysMeta = const VerificationMeta(
    'durationDays',
  );
  @override
  late final GeneratedColumn<int> durationDays = GeneratedColumn<int>(
    'duration_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visibilityMeta = const VerificationMeta(
    'visibility',
  );
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
    'visibility',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inviteCodeMeta = const VerificationMeta(
    'inviteCode',
  );
  @override
  late final GeneratedColumn<String> inviteCode = GeneratedColumn<String>(
    'invite_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxMembersMeta = const VerificationMeta(
    'maxMembers',
  );
  @override
  late final GeneratedColumn<int> maxMembers = GeneratedColumn<int>(
    'max_members',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  static const VerificationMeta _publicTokenMeta = const VerificationMeta(
    'publicToken',
  );
  @override
  late final GeneratedColumn<String> publicToken = GeneratedColumn<String>(
    'public_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localArchivedMeta = const VerificationMeta(
    'localArchived',
  );
  @override
  late final GeneratedColumn<bool> localArchived = GeneratedColumn<bool>(
    'local_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("local_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    kind,
    templateId,
    title,
    emoji,
    metricName,
    metricUnit,
    hideMetricDefault,
    startDate,
    durationDays,
    timezone,
    visibility,
    status,
    inviteCode,
    maxMembers,
    publicToken,
    localArchived,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journeys';
  @override
  VerificationContext validateIntegrity(
    Insertable<JourneyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    } else if (isInserting) {
      context.missing(_emojiMeta);
    }
    if (data.containsKey('metric_name')) {
      context.handle(
        _metricNameMeta,
        metricName.isAcceptableOrUnknown(data['metric_name']!, _metricNameMeta),
      );
    }
    if (data.containsKey('metric_unit')) {
      context.handle(
        _metricUnitMeta,
        metricUnit.isAcceptableOrUnknown(data['metric_unit']!, _metricUnitMeta),
      );
    }
    if (data.containsKey('hide_metric_default')) {
      context.handle(
        _hideMetricDefaultMeta,
        hideMetricDefault.isAcceptableOrUnknown(
          data['hide_metric_default']!,
          _hideMetricDefaultMeta,
        ),
      );
    }
    if (data.containsKey('duration_days')) {
      context.handle(
        _durationDaysMeta,
        durationDays.isAcceptableOrUnknown(
          data['duration_days']!,
          _durationDaysMeta,
        ),
      );
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    } else if (isInserting) {
      context.missing(_timezoneMeta);
    }
    if (data.containsKey('visibility')) {
      context.handle(
        _visibilityMeta,
        visibility.isAcceptableOrUnknown(data['visibility']!, _visibilityMeta),
      );
    } else if (isInserting) {
      context.missing(_visibilityMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('invite_code')) {
      context.handle(
        _inviteCodeMeta,
        inviteCode.isAcceptableOrUnknown(data['invite_code']!, _inviteCodeMeta),
      );
    }
    if (data.containsKey('max_members')) {
      context.handle(
        _maxMembersMeta,
        maxMembers.isAcceptableOrUnknown(data['max_members']!, _maxMembersMeta),
      );
    }
    if (data.containsKey('public_token')) {
      context.handle(
        _publicTokenMeta,
        publicToken.isAcceptableOrUnknown(
          data['public_token']!,
          _publicTokenMeta,
        ),
      );
    }
    if (data.containsKey('local_archived')) {
      context.handle(
        _localArchivedMeta,
        localArchived.isAcceptableOrUnknown(
          data['local_archived']!,
          _localArchivedMeta,
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
  JourneyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JourneyRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
      metricName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metric_name'],
      ),
      metricUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metric_unit'],
      ),
      hideMetricDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hide_metric_default'],
      )!,
      startDate: $JourneysTable.$converterstartDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}start_date'],
        )!,
      ),
      durationDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_days'],
      ),
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      visibility: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visibility'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      inviteCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invite_code'],
      ),
      maxMembers: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_members'],
      )!,
      publicToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_token'],
      ),
      localArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}local_archived'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $JourneysTable createAlias(String alias) {
    return $JourneysTable(attachedDatabase, alias);
  }

  static TypeConverter<LocalDate, String> $converterstartDate =
      const LocalDateConverter();
}

class JourneyRow extends DataClass implements Insertable<JourneyRow> {
  final String id;
  final String ownerId;
  final String kind;
  final String templateId;
  final String title;
  final String emoji;
  final String? metricName;
  final String? metricUnit;
  final bool hideMetricDefault;
  final LocalDate startDate;
  final int? durationDays;
  final String timezone;
  final String visibility;
  final String status;
  final String? inviteCode;
  final int maxMembers;
  final String? publicToken;

  /// Client-only "archive" (JourneyRepository.archive): hidden from the list.
  final bool localArchived;
  final String? updatedAt;
  const JourneyRow({
    required this.id,
    required this.ownerId,
    required this.kind,
    required this.templateId,
    required this.title,
    required this.emoji,
    this.metricName,
    this.metricUnit,
    required this.hideMetricDefault,
    required this.startDate,
    this.durationDays,
    required this.timezone,
    required this.visibility,
    required this.status,
    this.inviteCode,
    required this.maxMembers,
    this.publicToken,
    required this.localArchived,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['kind'] = Variable<String>(kind);
    map['template_id'] = Variable<String>(templateId);
    map['title'] = Variable<String>(title);
    map['emoji'] = Variable<String>(emoji);
    if (!nullToAbsent || metricName != null) {
      map['metric_name'] = Variable<String>(metricName);
    }
    if (!nullToAbsent || metricUnit != null) {
      map['metric_unit'] = Variable<String>(metricUnit);
    }
    map['hide_metric_default'] = Variable<bool>(hideMetricDefault);
    {
      map['start_date'] = Variable<String>(
        $JourneysTable.$converterstartDate.toSql(startDate),
      );
    }
    if (!nullToAbsent || durationDays != null) {
      map['duration_days'] = Variable<int>(durationDays);
    }
    map['timezone'] = Variable<String>(timezone);
    map['visibility'] = Variable<String>(visibility);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || inviteCode != null) {
      map['invite_code'] = Variable<String>(inviteCode);
    }
    map['max_members'] = Variable<int>(maxMembers);
    if (!nullToAbsent || publicToken != null) {
      map['public_token'] = Variable<String>(publicToken);
    }
    map['local_archived'] = Variable<bool>(localArchived);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  JourneysCompanion toCompanion(bool nullToAbsent) {
    return JourneysCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      kind: Value(kind),
      templateId: Value(templateId),
      title: Value(title),
      emoji: Value(emoji),
      metricName: metricName == null && nullToAbsent
          ? const Value.absent()
          : Value(metricName),
      metricUnit: metricUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(metricUnit),
      hideMetricDefault: Value(hideMetricDefault),
      startDate: Value(startDate),
      durationDays: durationDays == null && nullToAbsent
          ? const Value.absent()
          : Value(durationDays),
      timezone: Value(timezone),
      visibility: Value(visibility),
      status: Value(status),
      inviteCode: inviteCode == null && nullToAbsent
          ? const Value.absent()
          : Value(inviteCode),
      maxMembers: Value(maxMembers),
      publicToken: publicToken == null && nullToAbsent
          ? const Value.absent()
          : Value(publicToken),
      localArchived: Value(localArchived),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory JourneyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JourneyRow(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      kind: serializer.fromJson<String>(json['kind']),
      templateId: serializer.fromJson<String>(json['templateId']),
      title: serializer.fromJson<String>(json['title']),
      emoji: serializer.fromJson<String>(json['emoji']),
      metricName: serializer.fromJson<String?>(json['metricName']),
      metricUnit: serializer.fromJson<String?>(json['metricUnit']),
      hideMetricDefault: serializer.fromJson<bool>(json['hideMetricDefault']),
      startDate: serializer.fromJson<LocalDate>(json['startDate']),
      durationDays: serializer.fromJson<int?>(json['durationDays']),
      timezone: serializer.fromJson<String>(json['timezone']),
      visibility: serializer.fromJson<String>(json['visibility']),
      status: serializer.fromJson<String>(json['status']),
      inviteCode: serializer.fromJson<String?>(json['inviteCode']),
      maxMembers: serializer.fromJson<int>(json['maxMembers']),
      publicToken: serializer.fromJson<String?>(json['publicToken']),
      localArchived: serializer.fromJson<bool>(json['localArchived']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'kind': serializer.toJson<String>(kind),
      'templateId': serializer.toJson<String>(templateId),
      'title': serializer.toJson<String>(title),
      'emoji': serializer.toJson<String>(emoji),
      'metricName': serializer.toJson<String?>(metricName),
      'metricUnit': serializer.toJson<String?>(metricUnit),
      'hideMetricDefault': serializer.toJson<bool>(hideMetricDefault),
      'startDate': serializer.toJson<LocalDate>(startDate),
      'durationDays': serializer.toJson<int?>(durationDays),
      'timezone': serializer.toJson<String>(timezone),
      'visibility': serializer.toJson<String>(visibility),
      'status': serializer.toJson<String>(status),
      'inviteCode': serializer.toJson<String?>(inviteCode),
      'maxMembers': serializer.toJson<int>(maxMembers),
      'publicToken': serializer.toJson<String?>(publicToken),
      'localArchived': serializer.toJson<bool>(localArchived),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  JourneyRow copyWith({
    String? id,
    String? ownerId,
    String? kind,
    String? templateId,
    String? title,
    String? emoji,
    Value<String?> metricName = const Value.absent(),
    Value<String?> metricUnit = const Value.absent(),
    bool? hideMetricDefault,
    LocalDate? startDate,
    Value<int?> durationDays = const Value.absent(),
    String? timezone,
    String? visibility,
    String? status,
    Value<String?> inviteCode = const Value.absent(),
    int? maxMembers,
    Value<String?> publicToken = const Value.absent(),
    bool? localArchived,
    Value<String?> updatedAt = const Value.absent(),
  }) => JourneyRow(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    kind: kind ?? this.kind,
    templateId: templateId ?? this.templateId,
    title: title ?? this.title,
    emoji: emoji ?? this.emoji,
    metricName: metricName.present ? metricName.value : this.metricName,
    metricUnit: metricUnit.present ? metricUnit.value : this.metricUnit,
    hideMetricDefault: hideMetricDefault ?? this.hideMetricDefault,
    startDate: startDate ?? this.startDate,
    durationDays: durationDays.present ? durationDays.value : this.durationDays,
    timezone: timezone ?? this.timezone,
    visibility: visibility ?? this.visibility,
    status: status ?? this.status,
    inviteCode: inviteCode.present ? inviteCode.value : this.inviteCode,
    maxMembers: maxMembers ?? this.maxMembers,
    publicToken: publicToken.present ? publicToken.value : this.publicToken,
    localArchived: localArchived ?? this.localArchived,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  JourneyRow copyWithCompanion(JourneysCompanion data) {
    return JourneyRow(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      kind: data.kind.present ? data.kind.value : this.kind,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      title: data.title.present ? data.title.value : this.title,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      metricName: data.metricName.present
          ? data.metricName.value
          : this.metricName,
      metricUnit: data.metricUnit.present
          ? data.metricUnit.value
          : this.metricUnit,
      hideMetricDefault: data.hideMetricDefault.present
          ? data.hideMetricDefault.value
          : this.hideMetricDefault,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      durationDays: data.durationDays.present
          ? data.durationDays.value
          : this.durationDays,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      visibility: data.visibility.present
          ? data.visibility.value
          : this.visibility,
      status: data.status.present ? data.status.value : this.status,
      inviteCode: data.inviteCode.present
          ? data.inviteCode.value
          : this.inviteCode,
      maxMembers: data.maxMembers.present
          ? data.maxMembers.value
          : this.maxMembers,
      publicToken: data.publicToken.present
          ? data.publicToken.value
          : this.publicToken,
      localArchived: data.localArchived.present
          ? data.localArchived.value
          : this.localArchived,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JourneyRow(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('kind: $kind, ')
          ..write('templateId: $templateId, ')
          ..write('title: $title, ')
          ..write('emoji: $emoji, ')
          ..write('metricName: $metricName, ')
          ..write('metricUnit: $metricUnit, ')
          ..write('hideMetricDefault: $hideMetricDefault, ')
          ..write('startDate: $startDate, ')
          ..write('durationDays: $durationDays, ')
          ..write('timezone: $timezone, ')
          ..write('visibility: $visibility, ')
          ..write('status: $status, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('maxMembers: $maxMembers, ')
          ..write('publicToken: $publicToken, ')
          ..write('localArchived: $localArchived, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerId,
    kind,
    templateId,
    title,
    emoji,
    metricName,
    metricUnit,
    hideMetricDefault,
    startDate,
    durationDays,
    timezone,
    visibility,
    status,
    inviteCode,
    maxMembers,
    publicToken,
    localArchived,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JourneyRow &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.kind == this.kind &&
          other.templateId == this.templateId &&
          other.title == this.title &&
          other.emoji == this.emoji &&
          other.metricName == this.metricName &&
          other.metricUnit == this.metricUnit &&
          other.hideMetricDefault == this.hideMetricDefault &&
          other.startDate == this.startDate &&
          other.durationDays == this.durationDays &&
          other.timezone == this.timezone &&
          other.visibility == this.visibility &&
          other.status == this.status &&
          other.inviteCode == this.inviteCode &&
          other.maxMembers == this.maxMembers &&
          other.publicToken == this.publicToken &&
          other.localArchived == this.localArchived &&
          other.updatedAt == this.updatedAt);
}

class JourneysCompanion extends UpdateCompanion<JourneyRow> {
  final Value<String> id;
  final Value<String> ownerId;
  final Value<String> kind;
  final Value<String> templateId;
  final Value<String> title;
  final Value<String> emoji;
  final Value<String?> metricName;
  final Value<String?> metricUnit;
  final Value<bool> hideMetricDefault;
  final Value<LocalDate> startDate;
  final Value<int?> durationDays;
  final Value<String> timezone;
  final Value<String> visibility;
  final Value<String> status;
  final Value<String?> inviteCode;
  final Value<int> maxMembers;
  final Value<String?> publicToken;
  final Value<bool> localArchived;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const JourneysCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.kind = const Value.absent(),
    this.templateId = const Value.absent(),
    this.title = const Value.absent(),
    this.emoji = const Value.absent(),
    this.metricName = const Value.absent(),
    this.metricUnit = const Value.absent(),
    this.hideMetricDefault = const Value.absent(),
    this.startDate = const Value.absent(),
    this.durationDays = const Value.absent(),
    this.timezone = const Value.absent(),
    this.visibility = const Value.absent(),
    this.status = const Value.absent(),
    this.inviteCode = const Value.absent(),
    this.maxMembers = const Value.absent(),
    this.publicToken = const Value.absent(),
    this.localArchived = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JourneysCompanion.insert({
    required String id,
    required String ownerId,
    required String kind,
    required String templateId,
    required String title,
    required String emoji,
    this.metricName = const Value.absent(),
    this.metricUnit = const Value.absent(),
    this.hideMetricDefault = const Value.absent(),
    required LocalDate startDate,
    this.durationDays = const Value.absent(),
    required String timezone,
    required String visibility,
    required String status,
    this.inviteCode = const Value.absent(),
    this.maxMembers = const Value.absent(),
    this.publicToken = const Value.absent(),
    this.localArchived = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerId = Value(ownerId),
       kind = Value(kind),
       templateId = Value(templateId),
       title = Value(title),
       emoji = Value(emoji),
       startDate = Value(startDate),
       timezone = Value(timezone),
       visibility = Value(visibility),
       status = Value(status);
  static Insertable<JourneyRow> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? kind,
    Expression<String>? templateId,
    Expression<String>? title,
    Expression<String>? emoji,
    Expression<String>? metricName,
    Expression<String>? metricUnit,
    Expression<bool>? hideMetricDefault,
    Expression<String>? startDate,
    Expression<int>? durationDays,
    Expression<String>? timezone,
    Expression<String>? visibility,
    Expression<String>? status,
    Expression<String>? inviteCode,
    Expression<int>? maxMembers,
    Expression<String>? publicToken,
    Expression<bool>? localArchived,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (kind != null) 'kind': kind,
      if (templateId != null) 'template_id': templateId,
      if (title != null) 'title': title,
      if (emoji != null) 'emoji': emoji,
      if (metricName != null) 'metric_name': metricName,
      if (metricUnit != null) 'metric_unit': metricUnit,
      if (hideMetricDefault != null) 'hide_metric_default': hideMetricDefault,
      if (startDate != null) 'start_date': startDate,
      if (durationDays != null) 'duration_days': durationDays,
      if (timezone != null) 'timezone': timezone,
      if (visibility != null) 'visibility': visibility,
      if (status != null) 'status': status,
      if (inviteCode != null) 'invite_code': inviteCode,
      if (maxMembers != null) 'max_members': maxMembers,
      if (publicToken != null) 'public_token': publicToken,
      if (localArchived != null) 'local_archived': localArchived,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JourneysCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerId,
    Value<String>? kind,
    Value<String>? templateId,
    Value<String>? title,
    Value<String>? emoji,
    Value<String?>? metricName,
    Value<String?>? metricUnit,
    Value<bool>? hideMetricDefault,
    Value<LocalDate>? startDate,
    Value<int?>? durationDays,
    Value<String>? timezone,
    Value<String>? visibility,
    Value<String>? status,
    Value<String?>? inviteCode,
    Value<int>? maxMembers,
    Value<String?>? publicToken,
    Value<bool>? localArchived,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return JourneysCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      kind: kind ?? this.kind,
      templateId: templateId ?? this.templateId,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      metricName: metricName ?? this.metricName,
      metricUnit: metricUnit ?? this.metricUnit,
      hideMetricDefault: hideMetricDefault ?? this.hideMetricDefault,
      startDate: startDate ?? this.startDate,
      durationDays: durationDays ?? this.durationDays,
      timezone: timezone ?? this.timezone,
      visibility: visibility ?? this.visibility,
      status: status ?? this.status,
      inviteCode: inviteCode ?? this.inviteCode,
      maxMembers: maxMembers ?? this.maxMembers,
      publicToken: publicToken ?? this.publicToken,
      localArchived: localArchived ?? this.localArchived,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (metricName.present) {
      map['metric_name'] = Variable<String>(metricName.value);
    }
    if (metricUnit.present) {
      map['metric_unit'] = Variable<String>(metricUnit.value);
    }
    if (hideMetricDefault.present) {
      map['hide_metric_default'] = Variable<bool>(hideMetricDefault.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(
        $JourneysTable.$converterstartDate.toSql(startDate.value),
      );
    }
    if (durationDays.present) {
      map['duration_days'] = Variable<int>(durationDays.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (inviteCode.present) {
      map['invite_code'] = Variable<String>(inviteCode.value);
    }
    if (maxMembers.present) {
      map['max_members'] = Variable<int>(maxMembers.value);
    }
    if (publicToken.present) {
      map['public_token'] = Variable<String>(publicToken.value);
    }
    if (localArchived.present) {
      map['local_archived'] = Variable<bool>(localArchived.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JourneysCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('kind: $kind, ')
          ..write('templateId: $templateId, ')
          ..write('title: $title, ')
          ..write('emoji: $emoji, ')
          ..write('metricName: $metricName, ')
          ..write('metricUnit: $metricUnit, ')
          ..write('hideMetricDefault: $hideMetricDefault, ')
          ..write('startDate: $startDate, ')
          ..write('durationDays: $durationDays, ')
          ..write('timezone: $timezone, ')
          ..write('visibility: $visibility, ')
          ..write('status: $status, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('maxMembers: $maxMembers, ')
          ..write('publicToken: $publicToken, ')
          ..write('localArchived: $localArchived, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MembershipsTable extends Memberships
    with TableInfo<$MembershipsTable, MembershipRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembershipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _journeyIdMeta = const VerificationMeta(
    'journeyId',
  );
  @override
  late final GeneratedColumn<String> journeyId = GeneratedColumn<String>(
    'journey_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> joinedAt =
      GeneratedColumn<int>(
        'joined_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($MembershipsTable.$converterjoinedAt);
  static const VerificationMeta _hideMetricMeta = const VerificationMeta(
    'hideMetric',
  );
  @override
  late final GeneratedColumn<bool> hideMetric = GeneratedColumn<bool>(
    'hide_metric',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hide_metric" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _blurMediaMeta = const VerificationMeta(
    'blurMedia',
  );
  @override
  late final GeneratedColumn<bool> blurMedia = GeneratedColumn<bool>(
    'blur_media',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("blur_media" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    journeyId,
    userId,
    role,
    status,
    joinedAt,
    hideMetric,
    blurMedia,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memberships';
  @override
  VerificationContext validateIntegrity(
    Insertable<MembershipRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('journey_id')) {
      context.handle(
        _journeyIdMeta,
        journeyId.isAcceptableOrUnknown(data['journey_id']!, _journeyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_journeyIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('hide_metric')) {
      context.handle(
        _hideMetricMeta,
        hideMetric.isAcceptableOrUnknown(data['hide_metric']!, _hideMetricMeta),
      );
    }
    if (data.containsKey('blur_media')) {
      context.handle(
        _blurMediaMeta,
        blurMedia.isAcceptableOrUnknown(data['blur_media']!, _blurMediaMeta),
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
  Set<GeneratedColumn> get $primaryKey => {journeyId, userId};
  @override
  MembershipRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MembershipRow(
      journeyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}journey_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      joinedAt: $MembershipsTable.$converterjoinedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}joined_at'],
        )!,
      ),
      hideMetric: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hide_metric'],
      )!,
      blurMedia: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}blur_media'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $MembershipsTable createAlias(String alias) {
    return $MembershipsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterjoinedAt =
      const UtcMicrosConverter();
}

class MembershipRow extends DataClass implements Insertable<MembershipRow> {
  final String journeyId;
  final String userId;
  final String role;
  final String status;
  final DateTime joinedAt;
  final bool hideMetric;
  final bool blurMedia;
  final String? updatedAt;
  const MembershipRow({
    required this.journeyId,
    required this.userId,
    required this.role,
    required this.status,
    required this.joinedAt,
    required this.hideMetric,
    required this.blurMedia,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['journey_id'] = Variable<String>(journeyId);
    map['user_id'] = Variable<String>(userId);
    map['role'] = Variable<String>(role);
    map['status'] = Variable<String>(status);
    {
      map['joined_at'] = Variable<int>(
        $MembershipsTable.$converterjoinedAt.toSql(joinedAt),
      );
    }
    map['hide_metric'] = Variable<bool>(hideMetric);
    map['blur_media'] = Variable<bool>(blurMedia);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  MembershipsCompanion toCompanion(bool nullToAbsent) {
    return MembershipsCompanion(
      journeyId: Value(journeyId),
      userId: Value(userId),
      role: Value(role),
      status: Value(status),
      joinedAt: Value(joinedAt),
      hideMetric: Value(hideMetric),
      blurMedia: Value(blurMedia),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory MembershipRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MembershipRow(
      journeyId: serializer.fromJson<String>(json['journeyId']),
      userId: serializer.fromJson<String>(json['userId']),
      role: serializer.fromJson<String>(json['role']),
      status: serializer.fromJson<String>(json['status']),
      joinedAt: serializer.fromJson<DateTime>(json['joinedAt']),
      hideMetric: serializer.fromJson<bool>(json['hideMetric']),
      blurMedia: serializer.fromJson<bool>(json['blurMedia']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'journeyId': serializer.toJson<String>(journeyId),
      'userId': serializer.toJson<String>(userId),
      'role': serializer.toJson<String>(role),
      'status': serializer.toJson<String>(status),
      'joinedAt': serializer.toJson<DateTime>(joinedAt),
      'hideMetric': serializer.toJson<bool>(hideMetric),
      'blurMedia': serializer.toJson<bool>(blurMedia),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  MembershipRow copyWith({
    String? journeyId,
    String? userId,
    String? role,
    String? status,
    DateTime? joinedAt,
    bool? hideMetric,
    bool? blurMedia,
    Value<String?> updatedAt = const Value.absent(),
  }) => MembershipRow(
    journeyId: journeyId ?? this.journeyId,
    userId: userId ?? this.userId,
    role: role ?? this.role,
    status: status ?? this.status,
    joinedAt: joinedAt ?? this.joinedAt,
    hideMetric: hideMetric ?? this.hideMetric,
    blurMedia: blurMedia ?? this.blurMedia,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  MembershipRow copyWithCompanion(MembershipsCompanion data) {
    return MembershipRow(
      journeyId: data.journeyId.present ? data.journeyId.value : this.journeyId,
      userId: data.userId.present ? data.userId.value : this.userId,
      role: data.role.present ? data.role.value : this.role,
      status: data.status.present ? data.status.value : this.status,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
      hideMetric: data.hideMetric.present
          ? data.hideMetric.value
          : this.hideMetric,
      blurMedia: data.blurMedia.present ? data.blurMedia.value : this.blurMedia,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MembershipRow(')
          ..write('journeyId: $journeyId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('status: $status, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('hideMetric: $hideMetric, ')
          ..write('blurMedia: $blurMedia, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    journeyId,
    userId,
    role,
    status,
    joinedAt,
    hideMetric,
    blurMedia,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MembershipRow &&
          other.journeyId == this.journeyId &&
          other.userId == this.userId &&
          other.role == this.role &&
          other.status == this.status &&
          other.joinedAt == this.joinedAt &&
          other.hideMetric == this.hideMetric &&
          other.blurMedia == this.blurMedia &&
          other.updatedAt == this.updatedAt);
}

class MembershipsCompanion extends UpdateCompanion<MembershipRow> {
  final Value<String> journeyId;
  final Value<String> userId;
  final Value<String> role;
  final Value<String> status;
  final Value<DateTime> joinedAt;
  final Value<bool> hideMetric;
  final Value<bool> blurMedia;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const MembershipsCompanion({
    this.journeyId = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.status = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.hideMetric = const Value.absent(),
    this.blurMedia = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembershipsCompanion.insert({
    required String journeyId,
    required String userId,
    required String role,
    required String status,
    required DateTime joinedAt,
    this.hideMetric = const Value.absent(),
    this.blurMedia = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : journeyId = Value(journeyId),
       userId = Value(userId),
       role = Value(role),
       status = Value(status),
       joinedAt = Value(joinedAt);
  static Insertable<MembershipRow> custom({
    Expression<String>? journeyId,
    Expression<String>? userId,
    Expression<String>? role,
    Expression<String>? status,
    Expression<int>? joinedAt,
    Expression<bool>? hideMetric,
    Expression<bool>? blurMedia,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (journeyId != null) 'journey_id': journeyId,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (status != null) 'status': status,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (hideMetric != null) 'hide_metric': hideMetric,
      if (blurMedia != null) 'blur_media': blurMedia,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembershipsCompanion copyWith({
    Value<String>? journeyId,
    Value<String>? userId,
    Value<String>? role,
    Value<String>? status,
    Value<DateTime>? joinedAt,
    Value<bool>? hideMetric,
    Value<bool>? blurMedia,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return MembershipsCompanion(
      journeyId: journeyId ?? this.journeyId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      hideMetric: hideMetric ?? this.hideMetric,
      blurMedia: blurMedia ?? this.blurMedia,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (journeyId.present) {
      map['journey_id'] = Variable<String>(journeyId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<int>(
        $MembershipsTable.$converterjoinedAt.toSql(joinedAt.value),
      );
    }
    if (hideMetric.present) {
      map['hide_metric'] = Variable<bool>(hideMetric.value);
    }
    if (blurMedia.present) {
      map['blur_media'] = Variable<bool>(blurMedia.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembershipsCompanion(')
          ..write('journeyId: $journeyId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('status: $status, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('hideMetric: $hideMetric, ')
          ..write('blurMedia: $blurMedia, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CheckInsTable extends CheckIns
    with TableInfo<$CheckInsTable, CheckInRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckInsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _journeyIdMeta = const VerificationMeta(
    'journeyId',
  );
  @override
  late final GeneratedColumn<String> journeyId = GeneratedColumn<String>(
    'journey_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> localDate =
      GeneratedColumn<String>(
        'local_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($CheckInsTable.$converterlocalDate);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> capturedAt =
      GeneratedColumn<int>(
        'captured_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CheckInsTable.$convertercapturedAt);
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbPathMeta = const VerificationMeta(
    'thumbPath',
  );
  @override
  late final GeneratedColumn<String> thumbPath = GeneratedColumn<String>(
    'thumb_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromLibraryMeta = const VerificationMeta(
    'fromLibrary',
  );
  @override
  late final GeneratedColumn<bool> fromLibrary = GeneratedColumn<bool>(
    'from_library',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("from_library" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metricValueMeta = const VerificationMeta(
    'metricValue',
  );
  @override
  late final GeneratedColumn<double> metricValue = GeneratedColumn<double>(
    'metric_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadedMeta = const VerificationMeta(
    'uploaded',
  );
  @override
  late final GeneratedColumn<bool> uploaded = GeneratedColumn<bool>(
    'uploaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("uploaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    journeyId,
    userId,
    localDate,
    capturedAt,
    photoPath,
    thumbPath,
    fromLibrary,
    caption,
    metricValue,
    uploaded,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'check_ins';
  @override
  VerificationContext validateIntegrity(
    Insertable<CheckInRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('journey_id')) {
      context.handle(
        _journeyIdMeta,
        journeyId.isAcceptableOrUnknown(data['journey_id']!, _journeyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_journeyIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    } else if (isInserting) {
      context.missing(_photoPathMeta);
    }
    if (data.containsKey('thumb_path')) {
      context.handle(
        _thumbPathMeta,
        thumbPath.isAcceptableOrUnknown(data['thumb_path']!, _thumbPathMeta),
      );
    } else if (isInserting) {
      context.missing(_thumbPathMeta);
    }
    if (data.containsKey('from_library')) {
      context.handle(
        _fromLibraryMeta,
        fromLibrary.isAcceptableOrUnknown(
          data['from_library']!,
          _fromLibraryMeta,
        ),
      );
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    }
    if (data.containsKey('metric_value')) {
      context.handle(
        _metricValueMeta,
        metricValue.isAcceptableOrUnknown(
          data['metric_value']!,
          _metricValueMeta,
        ),
      );
    }
    if (data.containsKey('uploaded')) {
      context.handle(
        _uploadedMeta,
        uploaded.isAcceptableOrUnknown(data['uploaded']!, _uploadedMeta),
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
    {journeyId, userId, localDate},
  ];
  @override
  CheckInRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheckInRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      journeyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}journey_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      localDate: $CheckInsTable.$converterlocalDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}local_date'],
        )!,
      ),
      capturedAt: $CheckInsTable.$convertercapturedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}captured_at'],
        )!,
      ),
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      )!,
      thumbPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb_path'],
      )!,
      fromLibrary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}from_library'],
      )!,
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      ),
      metricValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}metric_value'],
      ),
      uploaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}uploaded'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $CheckInsTable createAlias(String alias) {
    return $CheckInsTable(attachedDatabase, alias);
  }

  static TypeConverter<LocalDate, String> $converterlocalDate =
      const LocalDateConverter();
  static TypeConverter<DateTime, int> $convertercapturedAt =
      const UtcMicrosConverter();
}

class CheckInRow extends DataClass implements Insertable<CheckInRow> {
  final String id;
  final String journeyId;
  final String userId;
  final LocalDate localDate;
  final DateTime capturedAt;
  final String photoPath;
  final String thumbPath;
  final bool fromLibrary;
  final String? caption;
  final double? metricValue;

  /// True once the server confirmed the row (and its media).
  final bool uploaded;
  final String? updatedAt;
  const CheckInRow({
    required this.id,
    required this.journeyId,
    required this.userId,
    required this.localDate,
    required this.capturedAt,
    required this.photoPath,
    required this.thumbPath,
    required this.fromLibrary,
    this.caption,
    this.metricValue,
    required this.uploaded,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['journey_id'] = Variable<String>(journeyId);
    map['user_id'] = Variable<String>(userId);
    {
      map['local_date'] = Variable<String>(
        $CheckInsTable.$converterlocalDate.toSql(localDate),
      );
    }
    {
      map['captured_at'] = Variable<int>(
        $CheckInsTable.$convertercapturedAt.toSql(capturedAt),
      );
    }
    map['photo_path'] = Variable<String>(photoPath);
    map['thumb_path'] = Variable<String>(thumbPath);
    map['from_library'] = Variable<bool>(fromLibrary);
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    if (!nullToAbsent || metricValue != null) {
      map['metric_value'] = Variable<double>(metricValue);
    }
    map['uploaded'] = Variable<bool>(uploaded);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  CheckInsCompanion toCompanion(bool nullToAbsent) {
    return CheckInsCompanion(
      id: Value(id),
      journeyId: Value(journeyId),
      userId: Value(userId),
      localDate: Value(localDate),
      capturedAt: Value(capturedAt),
      photoPath: Value(photoPath),
      thumbPath: Value(thumbPath),
      fromLibrary: Value(fromLibrary),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
      metricValue: metricValue == null && nullToAbsent
          ? const Value.absent()
          : Value(metricValue),
      uploaded: Value(uploaded),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory CheckInRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheckInRow(
      id: serializer.fromJson<String>(json['id']),
      journeyId: serializer.fromJson<String>(json['journeyId']),
      userId: serializer.fromJson<String>(json['userId']),
      localDate: serializer.fromJson<LocalDate>(json['localDate']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      photoPath: serializer.fromJson<String>(json['photoPath']),
      thumbPath: serializer.fromJson<String>(json['thumbPath']),
      fromLibrary: serializer.fromJson<bool>(json['fromLibrary']),
      caption: serializer.fromJson<String?>(json['caption']),
      metricValue: serializer.fromJson<double?>(json['metricValue']),
      uploaded: serializer.fromJson<bool>(json['uploaded']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'journeyId': serializer.toJson<String>(journeyId),
      'userId': serializer.toJson<String>(userId),
      'localDate': serializer.toJson<LocalDate>(localDate),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'photoPath': serializer.toJson<String>(photoPath),
      'thumbPath': serializer.toJson<String>(thumbPath),
      'fromLibrary': serializer.toJson<bool>(fromLibrary),
      'caption': serializer.toJson<String?>(caption),
      'metricValue': serializer.toJson<double?>(metricValue),
      'uploaded': serializer.toJson<bool>(uploaded),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  CheckInRow copyWith({
    String? id,
    String? journeyId,
    String? userId,
    LocalDate? localDate,
    DateTime? capturedAt,
    String? photoPath,
    String? thumbPath,
    bool? fromLibrary,
    Value<String?> caption = const Value.absent(),
    Value<double?> metricValue = const Value.absent(),
    bool? uploaded,
    Value<String?> updatedAt = const Value.absent(),
  }) => CheckInRow(
    id: id ?? this.id,
    journeyId: journeyId ?? this.journeyId,
    userId: userId ?? this.userId,
    localDate: localDate ?? this.localDate,
    capturedAt: capturedAt ?? this.capturedAt,
    photoPath: photoPath ?? this.photoPath,
    thumbPath: thumbPath ?? this.thumbPath,
    fromLibrary: fromLibrary ?? this.fromLibrary,
    caption: caption.present ? caption.value : this.caption,
    metricValue: metricValue.present ? metricValue.value : this.metricValue,
    uploaded: uploaded ?? this.uploaded,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  CheckInRow copyWithCompanion(CheckInsCompanion data) {
    return CheckInRow(
      id: data.id.present ? data.id.value : this.id,
      journeyId: data.journeyId.present ? data.journeyId.value : this.journeyId,
      userId: data.userId.present ? data.userId.value : this.userId,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      thumbPath: data.thumbPath.present ? data.thumbPath.value : this.thumbPath,
      fromLibrary: data.fromLibrary.present
          ? data.fromLibrary.value
          : this.fromLibrary,
      caption: data.caption.present ? data.caption.value : this.caption,
      metricValue: data.metricValue.present
          ? data.metricValue.value
          : this.metricValue,
      uploaded: data.uploaded.present ? data.uploaded.value : this.uploaded,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CheckInRow(')
          ..write('id: $id, ')
          ..write('journeyId: $journeyId, ')
          ..write('userId: $userId, ')
          ..write('localDate: $localDate, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('photoPath: $photoPath, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('fromLibrary: $fromLibrary, ')
          ..write('caption: $caption, ')
          ..write('metricValue: $metricValue, ')
          ..write('uploaded: $uploaded, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    journeyId,
    userId,
    localDate,
    capturedAt,
    photoPath,
    thumbPath,
    fromLibrary,
    caption,
    metricValue,
    uploaded,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CheckInRow &&
          other.id == this.id &&
          other.journeyId == this.journeyId &&
          other.userId == this.userId &&
          other.localDate == this.localDate &&
          other.capturedAt == this.capturedAt &&
          other.photoPath == this.photoPath &&
          other.thumbPath == this.thumbPath &&
          other.fromLibrary == this.fromLibrary &&
          other.caption == this.caption &&
          other.metricValue == this.metricValue &&
          other.uploaded == this.uploaded &&
          other.updatedAt == this.updatedAt);
}

class CheckInsCompanion extends UpdateCompanion<CheckInRow> {
  final Value<String> id;
  final Value<String> journeyId;
  final Value<String> userId;
  final Value<LocalDate> localDate;
  final Value<DateTime> capturedAt;
  final Value<String> photoPath;
  final Value<String> thumbPath;
  final Value<bool> fromLibrary;
  final Value<String?> caption;
  final Value<double?> metricValue;
  final Value<bool> uploaded;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const CheckInsCompanion({
    this.id = const Value.absent(),
    this.journeyId = const Value.absent(),
    this.userId = const Value.absent(),
    this.localDate = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.thumbPath = const Value.absent(),
    this.fromLibrary = const Value.absent(),
    this.caption = const Value.absent(),
    this.metricValue = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CheckInsCompanion.insert({
    required String id,
    required String journeyId,
    required String userId,
    required LocalDate localDate,
    required DateTime capturedAt,
    required String photoPath,
    required String thumbPath,
    this.fromLibrary = const Value.absent(),
    this.caption = const Value.absent(),
    this.metricValue = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       journeyId = Value(journeyId),
       userId = Value(userId),
       localDate = Value(localDate),
       capturedAt = Value(capturedAt),
       photoPath = Value(photoPath),
       thumbPath = Value(thumbPath);
  static Insertable<CheckInRow> custom({
    Expression<String>? id,
    Expression<String>? journeyId,
    Expression<String>? userId,
    Expression<String>? localDate,
    Expression<int>? capturedAt,
    Expression<String>? photoPath,
    Expression<String>? thumbPath,
    Expression<bool>? fromLibrary,
    Expression<String>? caption,
    Expression<double>? metricValue,
    Expression<bool>? uploaded,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (journeyId != null) 'journey_id': journeyId,
      if (userId != null) 'user_id': userId,
      if (localDate != null) 'local_date': localDate,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (photoPath != null) 'photo_path': photoPath,
      if (thumbPath != null) 'thumb_path': thumbPath,
      if (fromLibrary != null) 'from_library': fromLibrary,
      if (caption != null) 'caption': caption,
      if (metricValue != null) 'metric_value': metricValue,
      if (uploaded != null) 'uploaded': uploaded,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CheckInsCompanion copyWith({
    Value<String>? id,
    Value<String>? journeyId,
    Value<String>? userId,
    Value<LocalDate>? localDate,
    Value<DateTime>? capturedAt,
    Value<String>? photoPath,
    Value<String>? thumbPath,
    Value<bool>? fromLibrary,
    Value<String?>? caption,
    Value<double?>? metricValue,
    Value<bool>? uploaded,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return CheckInsCompanion(
      id: id ?? this.id,
      journeyId: journeyId ?? this.journeyId,
      userId: userId ?? this.userId,
      localDate: localDate ?? this.localDate,
      capturedAt: capturedAt ?? this.capturedAt,
      photoPath: photoPath ?? this.photoPath,
      thumbPath: thumbPath ?? this.thumbPath,
      fromLibrary: fromLibrary ?? this.fromLibrary,
      caption: caption ?? this.caption,
      metricValue: metricValue ?? this.metricValue,
      uploaded: uploaded ?? this.uploaded,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (journeyId.present) {
      map['journey_id'] = Variable<String>(journeyId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(
        $CheckInsTable.$converterlocalDate.toSql(localDate.value),
      );
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<int>(
        $CheckInsTable.$convertercapturedAt.toSql(capturedAt.value),
      );
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (thumbPath.present) {
      map['thumb_path'] = Variable<String>(thumbPath.value);
    }
    if (fromLibrary.present) {
      map['from_library'] = Variable<bool>(fromLibrary.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (metricValue.present) {
      map['metric_value'] = Variable<double>(metricValue.value);
    }
    if (uploaded.present) {
      map['uploaded'] = Variable<bool>(uploaded.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckInsCompanion(')
          ..write('id: $id, ')
          ..write('journeyId: $journeyId, ')
          ..write('userId: $userId, ')
          ..write('localDate: $localDate, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('photoPath: $photoPath, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('fromLibrary: $fromLibrary, ')
          ..write('caption: $caption, ')
          ..write('metricValue: $metricValue, ')
          ..write('uploaded: $uploaded, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReactionsTable extends Reactions
    with TableInfo<$ReactionsTable, ReactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _checkInIdMeta = const VerificationMeta(
    'checkInId',
  );
  @override
  late final GeneratedColumn<String> checkInId = GeneratedColumn<String>(
    'check_in_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ReactionsTable.$convertercreatedAt);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    checkInId,
    userId,
    emoji,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('check_in_id')) {
      context.handle(
        _checkInIdMeta,
        checkInId.isAcceptableOrUnknown(data['check_in_id']!, _checkInIdMeta),
      );
    } else if (isInserting) {
      context.missing(_checkInIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    } else if (isInserting) {
      context.missing(_emojiMeta);
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
  Set<GeneratedColumn> get $primaryKey => {checkInId, userId};
  @override
  ReactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReactionRow(
      checkInId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}check_in_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
      createdAt: $ReactionsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $ReactionsTable createAlias(String alias) {
    return $ReactionsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcMicrosConverter();
}

class ReactionRow extends DataClass implements Insertable<ReactionRow> {
  final String checkInId;
  final String userId;
  final String emoji;
  final DateTime createdAt;
  final String? updatedAt;
  const ReactionRow({
    required this.checkInId,
    required this.userId,
    required this.emoji,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['check_in_id'] = Variable<String>(checkInId);
    map['user_id'] = Variable<String>(userId);
    map['emoji'] = Variable<String>(emoji);
    {
      map['created_at'] = Variable<int>(
        $ReactionsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  ReactionsCompanion toCompanion(bool nullToAbsent) {
    return ReactionsCompanion(
      checkInId: Value(checkInId),
      userId: Value(userId),
      emoji: Value(emoji),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory ReactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReactionRow(
      checkInId: serializer.fromJson<String>(json['checkInId']),
      userId: serializer.fromJson<String>(json['userId']),
      emoji: serializer.fromJson<String>(json['emoji']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'checkInId': serializer.toJson<String>(checkInId),
      'userId': serializer.toJson<String>(userId),
      'emoji': serializer.toJson<String>(emoji),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  ReactionRow copyWith({
    String? checkInId,
    String? userId,
    String? emoji,
    DateTime? createdAt,
    Value<String?> updatedAt = const Value.absent(),
  }) => ReactionRow(
    checkInId: checkInId ?? this.checkInId,
    userId: userId ?? this.userId,
    emoji: emoji ?? this.emoji,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  ReactionRow copyWithCompanion(ReactionsCompanion data) {
    return ReactionRow(
      checkInId: data.checkInId.present ? data.checkInId.value : this.checkInId,
      userId: data.userId.present ? data.userId.value : this.userId,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReactionRow(')
          ..write('checkInId: $checkInId, ')
          ..write('userId: $userId, ')
          ..write('emoji: $emoji, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(checkInId, userId, emoji, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReactionRow &&
          other.checkInId == this.checkInId &&
          other.userId == this.userId &&
          other.emoji == this.emoji &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ReactionsCompanion extends UpdateCompanion<ReactionRow> {
  final Value<String> checkInId;
  final Value<String> userId;
  final Value<String> emoji;
  final Value<DateTime> createdAt;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const ReactionsCompanion({
    this.checkInId = const Value.absent(),
    this.userId = const Value.absent(),
    this.emoji = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReactionsCompanion.insert({
    required String checkInId,
    required String userId,
    required String emoji,
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : checkInId = Value(checkInId),
       userId = Value(userId),
       emoji = Value(emoji),
       createdAt = Value(createdAt);
  static Insertable<ReactionRow> custom({
    Expression<String>? checkInId,
    Expression<String>? userId,
    Expression<String>? emoji,
    Expression<int>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (checkInId != null) 'check_in_id': checkInId,
      if (userId != null) 'user_id': userId,
      if (emoji != null) 'emoji': emoji,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReactionsCompanion copyWith({
    Value<String>? checkInId,
    Value<String>? userId,
    Value<String>? emoji,
    Value<DateTime>? createdAt,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReactionsCompanion(
      checkInId: checkInId ?? this.checkInId,
      userId: userId ?? this.userId,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (checkInId.present) {
      map['check_in_id'] = Variable<String>(checkInId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $ReactionsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReactionsCompanion(')
          ..write('checkInId: $checkInId, ')
          ..write('userId: $userId, ')
          ..write('emoji: $emoji, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BlocksTable extends Blocks with TableInfo<$BlocksTable, BlockRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _blockedIdMeta = const VerificationMeta(
    'blockedId',
  );
  @override
  late final GeneratedColumn<String> blockedId = GeneratedColumn<String>(
    'blocked_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [blockedId, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'blocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<BlockRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('blocked_id')) {
      context.handle(
        _blockedIdMeta,
        blockedId.isAcceptableOrUnknown(data['blocked_id']!, _blockedIdMeta),
      );
    } else if (isInserting) {
      context.missing(_blockedIdMeta);
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
  Set<GeneratedColumn> get $primaryKey => {blockedId};
  @override
  BlockRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BlockRow(
      blockedId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blocked_id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $BlocksTable createAlias(String alias) {
    return $BlocksTable(attachedDatabase, alias);
  }
}

class BlockRow extends DataClass implements Insertable<BlockRow> {
  final String blockedId;
  final String? updatedAt;
  const BlockRow({required this.blockedId, this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['blocked_id'] = Variable<String>(blockedId);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  BlocksCompanion toCompanion(bool nullToAbsent) {
    return BlocksCompanion(
      blockedId: Value(blockedId),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory BlockRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BlockRow(
      blockedId: serializer.fromJson<String>(json['blockedId']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'blockedId': serializer.toJson<String>(blockedId),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  BlockRow copyWith({
    String? blockedId,
    Value<String?> updatedAt = const Value.absent(),
  }) => BlockRow(
    blockedId: blockedId ?? this.blockedId,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  BlockRow copyWithCompanion(BlocksCompanion data) {
    return BlockRow(
      blockedId: data.blockedId.present ? data.blockedId.value : this.blockedId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BlockRow(')
          ..write('blockedId: $blockedId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(blockedId, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlockRow &&
          other.blockedId == this.blockedId &&
          other.updatedAt == this.updatedAt);
}

class BlocksCompanion extends UpdateCompanion<BlockRow> {
  final Value<String> blockedId;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const BlocksCompanion({
    this.blockedId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BlocksCompanion.insert({
    required String blockedId,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : blockedId = Value(blockedId);
  static Insertable<BlockRow> custom({
    Expression<String>? blockedId,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (blockedId != null) 'blocked_id': blockedId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BlocksCompanion copyWith({
    Value<String>? blockedId,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return BlocksCompanion(
      blockedId: blockedId ?? this.blockedId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (blockedId.present) {
      map['blocked_id'] = Variable<String>(blockedId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlocksCompanion(')
          ..write('blockedId: $blockedId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UploadQueueTable extends UploadQueue
    with TableInfo<$UploadQueueTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UploadQueueTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityKeyMeta = const VerificationMeta(
    'entityKey',
  );
  @override
  late final GeneratedColumn<String> entityKey = GeneratedColumn<String>(
    'entity_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<int> nextAttemptAt = GeneratedColumn<int>(
    'next_attempt_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deadMeta = const VerificationMeta('dead');
  @override
  late final GeneratedColumn<bool> dead = GeneratedColumn<bool>(
    'dead',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dead" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($UploadQueueTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    entityKey,
    payload,
    attempts,
    nextAttemptAt,
    lastError,
    dead,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'upload_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('entity_key')) {
      context.handle(
        _entityKeyMeta,
        entityKey.isAcceptableOrUnknown(data['entity_key']!, _entityKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_entityKeyMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('dead')) {
      context.handle(
        _deadMeta,
        dead.isAcceptableOrUnknown(data['dead']!, _deadMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      entityKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_key'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      dead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dead'],
      )!,
      createdAt: $UploadQueueTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $UploadQueueTable createAlias(String alias) {
    return $UploadQueueTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcMicrosConverter();
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final int id;

  /// One of `OutboxKind.wire`.
  final String kind;

  /// Entity the item writes (e.g. `checkin:<journey>:<date>`); pull sync does
  /// not overwrite local rows while an item for the same key is pending.
  final String entityKey;
  final String payload;
  final int attempts;
  final int nextAttemptAt;
  final String? lastError;

  /// Permanently rejected by the server (kept for diagnostics, not retried).
  final bool dead;
  final DateTime createdAt;
  const OutboxRow({
    required this.id,
    required this.kind,
    required this.entityKey,
    required this.payload,
    required this.attempts,
    required this.nextAttemptAt,
    this.lastError,
    required this.dead,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['entity_key'] = Variable<String>(entityKey);
    map['payload'] = Variable<String>(payload);
    map['attempts'] = Variable<int>(attempts);
    map['next_attempt_at'] = Variable<int>(nextAttemptAt);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['dead'] = Variable<bool>(dead);
    {
      map['created_at'] = Variable<int>(
        $UploadQueueTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  UploadQueueCompanion toCompanion(bool nullToAbsent) {
    return UploadQueueCompanion(
      id: Value(id),
      kind: Value(kind),
      entityKey: Value(entityKey),
      payload: Value(payload),
      attempts: Value(attempts),
      nextAttemptAt: Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      dead: Value(dead),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      entityKey: serializer.fromJson<String>(json['entityKey']),
      payload: serializer.fromJson<String>(json['payload']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<int>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      dead: serializer.fromJson<bool>(json['dead']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'entityKey': serializer.toJson<String>(entityKey),
      'payload': serializer.toJson<String>(payload),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<int>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'dead': serializer.toJson<bool>(dead),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OutboxRow copyWith({
    int? id,
    String? kind,
    String? entityKey,
    String? payload,
    int? attempts,
    int? nextAttemptAt,
    Value<String?> lastError = const Value.absent(),
    bool? dead,
    DateTime? createdAt,
  }) => OutboxRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    entityKey: entityKey ?? this.entityKey,
    payload: payload ?? this.payload,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    dead: dead ?? this.dead,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxRow copyWithCompanion(UploadQueueCompanion data) {
    return OutboxRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      entityKey: data.entityKey.present ? data.entityKey.value : this.entityKey,
      payload: data.payload.present ? data.payload.value : this.payload,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      dead: data.dead.present ? data.dead.value : this.dead,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('entityKey: $entityKey, ')
          ..write('payload: $payload, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('dead: $dead, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    entityKey,
    payload,
    attempts,
    nextAttemptAt,
    lastError,
    dead,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.entityKey == this.entityKey &&
          other.payload == this.payload &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError &&
          other.dead == this.dead &&
          other.createdAt == this.createdAt);
}

class UploadQueueCompanion extends UpdateCompanion<OutboxRow> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String> entityKey;
  final Value<String> payload;
  final Value<int> attempts;
  final Value<int> nextAttemptAt;
  final Value<String?> lastError;
  final Value<bool> dead;
  final Value<DateTime> createdAt;
  const UploadQueueCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.entityKey = const Value.absent(),
    this.payload = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.dead = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UploadQueueCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required String entityKey,
    required String payload,
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.dead = const Value.absent(),
    required DateTime createdAt,
  }) : kind = Value(kind),
       entityKey = Value(entityKey),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<OutboxRow> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? entityKey,
    Expression<String>? payload,
    Expression<int>? attempts,
    Expression<int>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<bool>? dead,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (entityKey != null) 'entity_key': entityKey,
      if (payload != null) 'payload': payload,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (dead != null) 'dead': dead,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UploadQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<String>? entityKey,
    Value<String>? payload,
    Value<int>? attempts,
    Value<int>? nextAttemptAt,
    Value<String?>? lastError,
    Value<bool>? dead,
    Value<DateTime>? createdAt,
  }) {
    return UploadQueueCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      entityKey: entityKey ?? this.entityKey,
      payload: payload ?? this.payload,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      dead: dead ?? this.dead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (entityKey.present) {
      map['entity_key'] = Variable<String>(entityKey.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (dead.present) {
      map['dead'] = Variable<bool>(dead.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $UploadQueueTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UploadQueueCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('entityKey: $entityKey, ')
          ..write('payload: $payload, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('dead: $dead, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorTable extends SyncCursor
    with TableInfo<$SyncCursorTable, SyncCursorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tableKeyMeta = const VerificationMeta(
    'tableKey',
  );
  @override
  late final GeneratedColumn<String> tableKey = GeneratedColumn<String>(
    'table_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [tableKey, cursor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursor';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('table_key')) {
      context.handle(
        _tableKeyMeta,
        tableKey.isAcceptableOrUnknown(data['table_key']!, _tableKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_tableKeyMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    } else if (isInserting) {
      context.missing(_cursorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tableKey};
  @override
  SyncCursorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursorRow(
      tableKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_key'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor'],
      )!,
    );
  }

  @override
  $SyncCursorTable createAlias(String alias) {
    return $SyncCursorTable(attachedDatabase, alias);
  }
}

class SyncCursorRow extends DataClass implements Insertable<SyncCursorRow> {
  final String tableKey;
  final String cursor;
  const SyncCursorRow({required this.tableKey, required this.cursor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['table_key'] = Variable<String>(tableKey);
    map['cursor'] = Variable<String>(cursor);
    return map;
  }

  SyncCursorCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorCompanion(
      tableKey: Value(tableKey),
      cursor: Value(cursor),
    );
  }

  factory SyncCursorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursorRow(
      tableKey: serializer.fromJson<String>(json['tableKey']),
      cursor: serializer.fromJson<String>(json['cursor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tableKey': serializer.toJson<String>(tableKey),
      'cursor': serializer.toJson<String>(cursor),
    };
  }

  SyncCursorRow copyWith({String? tableKey, String? cursor}) => SyncCursorRow(
    tableKey: tableKey ?? this.tableKey,
    cursor: cursor ?? this.cursor,
  );
  SyncCursorRow copyWithCompanion(SyncCursorCompanion data) {
    return SyncCursorRow(
      tableKey: data.tableKey.present ? data.tableKey.value : this.tableKey,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorRow(')
          ..write('tableKey: $tableKey, ')
          ..write('cursor: $cursor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tableKey, cursor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursorRow &&
          other.tableKey == this.tableKey &&
          other.cursor == this.cursor);
}

class SyncCursorCompanion extends UpdateCompanion<SyncCursorRow> {
  final Value<String> tableKey;
  final Value<String> cursor;
  final Value<int> rowid;
  const SyncCursorCompanion({
    this.tableKey = const Value.absent(),
    this.cursor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorCompanion.insert({
    required String tableKey,
    required String cursor,
    this.rowid = const Value.absent(),
  }) : tableKey = Value(tableKey),
       cursor = Value(cursor);
  static Insertable<SyncCursorRow> custom({
    Expression<String>? tableKey,
    Expression<String>? cursor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tableKey != null) 'table_key': tableKey,
      if (cursor != null) 'cursor': cursor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorCompanion copyWith({
    Value<String>? tableKey,
    Value<String>? cursor,
    Value<int>? rowid,
  }) {
    return SyncCursorCompanion(
      tableKey: tableKey ?? this.tableKey,
      cursor: cursor ?? this.cursor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tableKey.present) {
      map['table_key'] = Variable<String>(tableKey.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorCompanion(')
          ..write('tableKey: $tableKey, ')
          ..write('cursor: $cursor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $JourneysTable journeys = $JourneysTable(this);
  late final $MembershipsTable memberships = $MembershipsTable(this);
  late final $CheckInsTable checkIns = $CheckInsTable(this);
  late final $ReactionsTable reactions = $ReactionsTable(this);
  late final $BlocksTable blocks = $BlocksTable(this);
  late final $UploadQueueTable uploadQueue = $UploadQueueTable(this);
  late final $SyncCursorTable syncCursor = $SyncCursorTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    journeys,
    memberships,
    checkIns,
    reactions,
    blocks,
    uploadQueue,
    syncCursor,
  ];
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  required String id,
  required String username,
  required String displayName,
  Value<String?> avatarPath,
  Value<String?> updatedAt,
  Value<int> rowid,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<String> id,
  Value<String> username,
  Value<String> displayName,
  Value<String?> avatarPath,
  Value<String?> updatedAt,
  Value<int> rowid,
});

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          ProfileRow,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (
            ProfileRow,
            BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>,
          ),
          ProfileRow,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> avatarPath = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                username: username,
                displayName: displayName,
                avatarPath: avatarPath,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String username,
                required String displayName,
                Value<String?> avatarPath = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                username: username,
                displayName: displayName,
                avatarPath: avatarPath,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfilesTable, ProfileRow>(table),
                  BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      ProfileRow,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (ProfileRow, BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>),
      ProfileRow,
      PrefetchHooks Function()
    >;
typedef $$JourneysTableCreateCompanionBuilder = JourneysCompanion Function({
  required String id,
  required String ownerId,
  required String kind,
  required String templateId,
  required String title,
  required String emoji,
  Value<String?> metricName,
  Value<String?> metricUnit,
  Value<bool> hideMetricDefault,
  required LocalDate startDate,
  Value<int?> durationDays,
  required String timezone,
  required String visibility,
  required String status,
  Value<String?> inviteCode,
  Value<int> maxMembers,
  Value<String?> publicToken,
  Value<bool> localArchived,
  Value<String?> updatedAt,
  Value<int> rowid,
});
typedef $$JourneysTableUpdateCompanionBuilder = JourneysCompanion Function({
  Value<String> id,
  Value<String> ownerId,
  Value<String> kind,
  Value<String> templateId,
  Value<String> title,
  Value<String> emoji,
  Value<String?> metricName,
  Value<String?> metricUnit,
  Value<bool> hideMetricDefault,
  Value<LocalDate> startDate,
  Value<int?> durationDays,
  Value<String> timezone,
  Value<String> visibility,
  Value<String> status,
  Value<String?> inviteCode,
  Value<int> maxMembers,
  Value<String?> publicToken,
  Value<bool> localArchived,
  Value<String?> updatedAt,
  Value<int> rowid,
});

class $$JourneysTableFilterComposer
    extends Composer<_$AppDatabase, $JourneysTable> {
  $$JourneysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metricName => $composableBuilder(
    column: $table.metricName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metricUnit => $composableBuilder(
    column: $table.metricUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hideMetricDefault => $composableBuilder(
    column: $table.hideMetricDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LocalDate, LocalDate, String> get startDate =>
      $composableBuilder(
        column: $table.startDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxMembers => $composableBuilder(
    column: $table.maxMembers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicToken => $composableBuilder(
    column: $table.publicToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get localArchived => $composableBuilder(
    column: $table.localArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JourneysTableOrderingComposer
    extends Composer<_$AppDatabase, $JourneysTable> {
  $$JourneysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metricName => $composableBuilder(
    column: $table.metricName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metricUnit => $composableBuilder(
    column: $table.metricUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hideMetricDefault => $composableBuilder(
    column: $table.hideMetricDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxMembers => $composableBuilder(
    column: $table.maxMembers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicToken => $composableBuilder(
    column: $table.publicToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get localArchived => $composableBuilder(
    column: $table.localArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JourneysTableAnnotationComposer
    extends Composer<_$AppDatabase, $JourneysTable> {
  $$JourneysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<String> get metricName => $composableBuilder(
    column: $table.metricName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metricUnit => $composableBuilder(
    column: $table.metricUnit,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hideMetricDefault => $composableBuilder(
    column: $table.hideMetricDefault,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<LocalDate, String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxMembers => $composableBuilder(
    column: $table.maxMembers,
    builder: (column) => column,
  );

  GeneratedColumn<String> get publicToken => $composableBuilder(
    column: $table.publicToken,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get localArchived => $composableBuilder(
    column: $table.localArchived,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$JourneysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JourneysTable,
          JourneyRow,
          $$JourneysTableFilterComposer,
          $$JourneysTableOrderingComposer,
          $$JourneysTableAnnotationComposer,
          $$JourneysTableCreateCompanionBuilder,
          $$JourneysTableUpdateCompanionBuilder,
          (
            JourneyRow,
            BaseReferences<_$AppDatabase, $JourneysTable, JourneyRow>,
          ),
          JourneyRow,
          PrefetchHooks Function()
        > {
  $$JourneysTableTableManager(_$AppDatabase db, $JourneysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JourneysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JourneysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JourneysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<String?> metricName = const Value.absent(),
                Value<String?> metricUnit = const Value.absent(),
                Value<bool> hideMetricDefault = const Value.absent(),
                Value<LocalDate> startDate = const Value.absent(),
                Value<int?> durationDays = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<String> visibility = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> inviteCode = const Value.absent(),
                Value<int> maxMembers = const Value.absent(),
                Value<String?> publicToken = const Value.absent(),
                Value<bool> localArchived = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneysCompanion(
                id: id,
                ownerId: ownerId,
                kind: kind,
                templateId: templateId,
                title: title,
                emoji: emoji,
                metricName: metricName,
                metricUnit: metricUnit,
                hideMetricDefault: hideMetricDefault,
                startDate: startDate,
                durationDays: durationDays,
                timezone: timezone,
                visibility: visibility,
                status: status,
                inviteCode: inviteCode,
                maxMembers: maxMembers,
                publicToken: publicToken,
                localArchived: localArchived,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ownerId,
                required String kind,
                required String templateId,
                required String title,
                required String emoji,
                Value<String?> metricName = const Value.absent(),
                Value<String?> metricUnit = const Value.absent(),
                Value<bool> hideMetricDefault = const Value.absent(),
                required LocalDate startDate,
                Value<int?> durationDays = const Value.absent(),
                required String timezone,
                required String visibility,
                required String status,
                Value<String?> inviteCode = const Value.absent(),
                Value<int> maxMembers = const Value.absent(),
                Value<String?> publicToken = const Value.absent(),
                Value<bool> localArchived = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneysCompanion.insert(
                id: id,
                ownerId: ownerId,
                kind: kind,
                templateId: templateId,
                title: title,
                emoji: emoji,
                metricName: metricName,
                metricUnit: metricUnit,
                hideMetricDefault: hideMetricDefault,
                startDate: startDate,
                durationDays: durationDays,
                timezone: timezone,
                visibility: visibility,
                status: status,
                inviteCode: inviteCode,
                maxMembers: maxMembers,
                publicToken: publicToken,
                localArchived: localArchived,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JourneysTable, JourneyRow>(table),
                  BaseReferences<_$AppDatabase, $JourneysTable, JourneyRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JourneysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JourneysTable,
      JourneyRow,
      $$JourneysTableFilterComposer,
      $$JourneysTableOrderingComposer,
      $$JourneysTableAnnotationComposer,
      $$JourneysTableCreateCompanionBuilder,
      $$JourneysTableUpdateCompanionBuilder,
      (JourneyRow, BaseReferences<_$AppDatabase, $JourneysTable, JourneyRow>),
      JourneyRow,
      PrefetchHooks Function()
    >;
typedef $$MembershipsTableCreateCompanionBuilder =
    MembershipsCompanion Function({
      required String journeyId,
      required String userId,
      required String role,
      required String status,
      required DateTime joinedAt,
      Value<bool> hideMetric,
      Value<bool> blurMedia,
      Value<String?> updatedAt,
      Value<int> rowid,
    });
typedef $$MembershipsTableUpdateCompanionBuilder =
    MembershipsCompanion Function({
      Value<String> journeyId,
      Value<String> userId,
      Value<String> role,
      Value<String> status,
      Value<DateTime> joinedAt,
      Value<bool> hideMetric,
      Value<bool> blurMedia,
      Value<String?> updatedAt,
      Value<int> rowid,
    });

class $$MembershipsTableFilterComposer
    extends Composer<_$AppDatabase, $MembershipsTable> {
  $$MembershipsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get journeyId => $composableBuilder(
    column: $table.journeyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get joinedAt =>
      $composableBuilder(
        column: $table.joinedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get hideMetric => $composableBuilder(
    column: $table.hideMetric,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get blurMedia => $composableBuilder(
    column: $table.blurMedia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MembershipsTableOrderingComposer
    extends Composer<_$AppDatabase, $MembershipsTable> {
  $$MembershipsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get journeyId => $composableBuilder(
    column: $table.journeyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hideMetric => $composableBuilder(
    column: $table.hideMetric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get blurMedia => $composableBuilder(
    column: $table.blurMedia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MembershipsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MembershipsTable> {
  $$MembershipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get journeyId =>
      $composableBuilder(column: $table.journeyId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  GeneratedColumn<bool> get hideMetric => $composableBuilder(
    column: $table.hideMetric,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get blurMedia =>
      $composableBuilder(column: $table.blurMedia, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MembershipsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MembershipsTable,
          MembershipRow,
          $$MembershipsTableFilterComposer,
          $$MembershipsTableOrderingComposer,
          $$MembershipsTableAnnotationComposer,
          $$MembershipsTableCreateCompanionBuilder,
          $$MembershipsTableUpdateCompanionBuilder,
          (
            MembershipRow,
            BaseReferences<_$AppDatabase, $MembershipsTable, MembershipRow>,
          ),
          MembershipRow,
          PrefetchHooks Function()
        > {
  $$MembershipsTableTableManager(_$AppDatabase db, $MembershipsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembershipsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembershipsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembershipsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> journeyId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> joinedAt = const Value.absent(),
                Value<bool> hideMetric = const Value.absent(),
                Value<bool> blurMedia = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembershipsCompanion(
                journeyId: journeyId,
                userId: userId,
                role: role,
                status: status,
                joinedAt: joinedAt,
                hideMetric: hideMetric,
                blurMedia: blurMedia,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String journeyId,
                required String userId,
                required String role,
                required String status,
                required DateTime joinedAt,
                Value<bool> hideMetric = const Value.absent(),
                Value<bool> blurMedia = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembershipsCompanion.insert(
                journeyId: journeyId,
                userId: userId,
                role: role,
                status: status,
                joinedAt: joinedAt,
                hideMetric: hideMetric,
                blurMedia: blurMedia,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MembershipsTable, MembershipRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MembershipsTable,
                    MembershipRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MembershipsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MembershipsTable,
      MembershipRow,
      $$MembershipsTableFilterComposer,
      $$MembershipsTableOrderingComposer,
      $$MembershipsTableAnnotationComposer,
      $$MembershipsTableCreateCompanionBuilder,
      $$MembershipsTableUpdateCompanionBuilder,
      (
        MembershipRow,
        BaseReferences<_$AppDatabase, $MembershipsTable, MembershipRow>,
      ),
      MembershipRow,
      PrefetchHooks Function()
    >;
typedef $$CheckInsTableCreateCompanionBuilder = CheckInsCompanion Function({
  required String id,
  required String journeyId,
  required String userId,
  required LocalDate localDate,
  required DateTime capturedAt,
  required String photoPath,
  required String thumbPath,
  Value<bool> fromLibrary,
  Value<String?> caption,
  Value<double?> metricValue,
  Value<bool> uploaded,
  Value<String?> updatedAt,
  Value<int> rowid,
});
typedef $$CheckInsTableUpdateCompanionBuilder = CheckInsCompanion Function({
  Value<String> id,
  Value<String> journeyId,
  Value<String> userId,
  Value<LocalDate> localDate,
  Value<DateTime> capturedAt,
  Value<String> photoPath,
  Value<String> thumbPath,
  Value<bool> fromLibrary,
  Value<String?> caption,
  Value<double?> metricValue,
  Value<bool> uploaded,
  Value<String?> updatedAt,
  Value<int> rowid,
});

class $$CheckInsTableFilterComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get journeyId => $composableBuilder(
    column: $table.journeyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LocalDate, LocalDate, String> get localDate =>
      $composableBuilder(
        column: $table.localDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get capturedAt =>
      $composableBuilder(
        column: $table.capturedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbPath => $composableBuilder(
    column: $table.thumbPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fromLibrary => $composableBuilder(
    column: $table.fromLibrary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get metricValue => $composableBuilder(
    column: $table.metricValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get uploaded => $composableBuilder(
    column: $table.uploaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CheckInsTableOrderingComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get journeyId => $composableBuilder(
    column: $table.journeyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbPath => $composableBuilder(
    column: $table.thumbPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fromLibrary => $composableBuilder(
    column: $table.fromLibrary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get metricValue => $composableBuilder(
    column: $table.metricValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get uploaded => $composableBuilder(
    column: $table.uploaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CheckInsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get journeyId =>
      $composableBuilder(column: $table.journeyId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocalDate, String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get capturedAt =>
      $composableBuilder(
        column: $table.capturedAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get thumbPath =>
      $composableBuilder(column: $table.thumbPath, builder: (column) => column);

  GeneratedColumn<bool> get fromLibrary => $composableBuilder(
    column: $table.fromLibrary,
    builder: (column) => column,
  );

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<double> get metricValue => $composableBuilder(
    column: $table.metricValue,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get uploaded =>
      $composableBuilder(column: $table.uploaded, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CheckInsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CheckInsTable,
          CheckInRow,
          $$CheckInsTableFilterComposer,
          $$CheckInsTableOrderingComposer,
          $$CheckInsTableAnnotationComposer,
          $$CheckInsTableCreateCompanionBuilder,
          $$CheckInsTableUpdateCompanionBuilder,
          (
            CheckInRow,
            BaseReferences<_$AppDatabase, $CheckInsTable, CheckInRow>,
          ),
          CheckInRow,
          PrefetchHooks Function()
        > {
  $$CheckInsTableTableManager(_$AppDatabase db, $CheckInsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CheckInsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CheckInsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CheckInsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> journeyId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<LocalDate> localDate = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<String> photoPath = const Value.absent(),
                Value<String> thumbPath = const Value.absent(),
                Value<bool> fromLibrary = const Value.absent(),
                Value<String?> caption = const Value.absent(),
                Value<double?> metricValue = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CheckInsCompanion(
                id: id,
                journeyId: journeyId,
                userId: userId,
                localDate: localDate,
                capturedAt: capturedAt,
                photoPath: photoPath,
                thumbPath: thumbPath,
                fromLibrary: fromLibrary,
                caption: caption,
                metricValue: metricValue,
                uploaded: uploaded,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String journeyId,
                required String userId,
                required LocalDate localDate,
                required DateTime capturedAt,
                required String photoPath,
                required String thumbPath,
                Value<bool> fromLibrary = const Value.absent(),
                Value<String?> caption = const Value.absent(),
                Value<double?> metricValue = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CheckInsCompanion.insert(
                id: id,
                journeyId: journeyId,
                userId: userId,
                localDate: localDate,
                capturedAt: capturedAt,
                photoPath: photoPath,
                thumbPath: thumbPath,
                fromLibrary: fromLibrary,
                caption: caption,
                metricValue: metricValue,
                uploaded: uploaded,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CheckInsTable, CheckInRow>(table),
                  BaseReferences<_$AppDatabase, $CheckInsTable, CheckInRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CheckInsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CheckInsTable,
      CheckInRow,
      $$CheckInsTableFilterComposer,
      $$CheckInsTableOrderingComposer,
      $$CheckInsTableAnnotationComposer,
      $$CheckInsTableCreateCompanionBuilder,
      $$CheckInsTableUpdateCompanionBuilder,
      (CheckInRow, BaseReferences<_$AppDatabase, $CheckInsTable, CheckInRow>),
      CheckInRow,
      PrefetchHooks Function()
    >;
typedef $$ReactionsTableCreateCompanionBuilder = ReactionsCompanion Function({
  required String checkInId,
  required String userId,
  required String emoji,
  required DateTime createdAt,
  Value<String?> updatedAt,
  Value<int> rowid,
});
typedef $$ReactionsTableUpdateCompanionBuilder = ReactionsCompanion Function({
  Value<String> checkInId,
  Value<String> userId,
  Value<String> emoji,
  Value<DateTime> createdAt,
  Value<String?> updatedAt,
  Value<int> rowid,
});

class $$ReactionsTableFilterComposer
    extends Composer<_$AppDatabase, $ReactionsTable> {
  $$ReactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get checkInId => $composableBuilder(
    column: $table.checkInId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReactionsTable> {
  $$ReactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get checkInId => $composableBuilder(
    column: $table.checkInId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReactionsTable> {
  $$ReactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get checkInId =>
      $composableBuilder(column: $table.checkInId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ReactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReactionsTable,
          ReactionRow,
          $$ReactionsTableFilterComposer,
          $$ReactionsTableOrderingComposer,
          $$ReactionsTableAnnotationComposer,
          $$ReactionsTableCreateCompanionBuilder,
          $$ReactionsTableUpdateCompanionBuilder,
          (
            ReactionRow,
            BaseReferences<_$AppDatabase, $ReactionsTable, ReactionRow>,
          ),
          ReactionRow,
          PrefetchHooks Function()
        > {
  $$ReactionsTableTableManager(_$AppDatabase db, $ReactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> checkInId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReactionsCompanion(
                checkInId: checkInId,
                userId: userId,
                emoji: emoji,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String checkInId,
                required String userId,
                required String emoji,
                required DateTime createdAt,
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReactionsCompanion.insert(
                checkInId: checkInId,
                userId: userId,
                emoji: emoji,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReactionsTable, ReactionRow>(table),
                  BaseReferences<_$AppDatabase, $ReactionsTable, ReactionRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReactionsTable,
      ReactionRow,
      $$ReactionsTableFilterComposer,
      $$ReactionsTableOrderingComposer,
      $$ReactionsTableAnnotationComposer,
      $$ReactionsTableCreateCompanionBuilder,
      $$ReactionsTableUpdateCompanionBuilder,
      (
        ReactionRow,
        BaseReferences<_$AppDatabase, $ReactionsTable, ReactionRow>,
      ),
      ReactionRow,
      PrefetchHooks Function()
    >;
typedef $$BlocksTableCreateCompanionBuilder = BlocksCompanion Function({
  required String blockedId,
  Value<String?> updatedAt,
  Value<int> rowid,
});
typedef $$BlocksTableUpdateCompanionBuilder = BlocksCompanion Function({
  Value<String> blockedId,
  Value<String?> updatedAt,
  Value<int> rowid,
});

class $$BlocksTableFilterComposer
    extends Composer<_$AppDatabase, $BlocksTable> {
  $$BlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get blockedId => $composableBuilder(
    column: $table.blockedId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BlocksTableOrderingComposer
    extends Composer<_$AppDatabase, $BlocksTable> {
  $$BlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get blockedId => $composableBuilder(
    column: $table.blockedId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BlocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BlocksTable> {
  $$BlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get blockedId =>
      $composableBuilder(column: $table.blockedId, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BlocksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BlocksTable,
          BlockRow,
          $$BlocksTableFilterComposer,
          $$BlocksTableOrderingComposer,
          $$BlocksTableAnnotationComposer,
          $$BlocksTableCreateCompanionBuilder,
          $$BlocksTableUpdateCompanionBuilder,
          (BlockRow, BaseReferences<_$AppDatabase, $BlocksTable, BlockRow>),
          BlockRow,
          PrefetchHooks Function()
        > {
  $$BlocksTableTableManager(_$AppDatabase db, $BlocksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> blockedId = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BlocksCompanion(
                blockedId: blockedId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String blockedId,
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BlocksCompanion.insert(
                blockedId: blockedId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BlocksTable, BlockRow>(table),
                  BaseReferences<_$AppDatabase, $BlocksTable, BlockRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BlocksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BlocksTable,
      BlockRow,
      $$BlocksTableFilterComposer,
      $$BlocksTableOrderingComposer,
      $$BlocksTableAnnotationComposer,
      $$BlocksTableCreateCompanionBuilder,
      $$BlocksTableUpdateCompanionBuilder,
      (BlockRow, BaseReferences<_$AppDatabase, $BlocksTable, BlockRow>),
      BlockRow,
      PrefetchHooks Function()
    >;
typedef $$UploadQueueTableCreateCompanionBuilder =
    UploadQueueCompanion Function({
      Value<int> id,
      required String kind,
      required String entityKey,
      required String payload,
      Value<int> attempts,
      Value<int> nextAttemptAt,
      Value<String?> lastError,
      Value<bool> dead,
      required DateTime createdAt,
    });
typedef $$UploadQueueTableUpdateCompanionBuilder =
    UploadQueueCompanion Function({
      Value<int> id,
      Value<String> kind,
      Value<String> entityKey,
      Value<String> payload,
      Value<int> attempts,
      Value<int> nextAttemptAt,
      Value<String?> lastError,
      Value<bool> dead,
      Value<DateTime> createdAt,
    });

class $$UploadQueueTableFilterComposer
    extends Composer<_$AppDatabase, $UploadQueueTable> {
  $$UploadQueueTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityKey => $composableBuilder(
    column: $table.entityKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dead => $composableBuilder(
    column: $table.dead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$UploadQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $UploadQueueTable> {
  $$UploadQueueTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityKey => $composableBuilder(
    column: $table.entityKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dead => $composableBuilder(
    column: $table.dead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UploadQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $UploadQueueTable> {
  $$UploadQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get entityKey =>
      $composableBuilder(column: $table.entityKey, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<bool> get dead =>
      $composableBuilder(column: $table.dead, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UploadQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UploadQueueTable,
          OutboxRow,
          $$UploadQueueTableFilterComposer,
          $$UploadQueueTableOrderingComposer,
          $$UploadQueueTableAnnotationComposer,
          $$UploadQueueTableCreateCompanionBuilder,
          $$UploadQueueTableUpdateCompanionBuilder,
          (
            OutboxRow,
            BaseReferences<_$AppDatabase, $UploadQueueTable, OutboxRow>,
          ),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$UploadQueueTableTableManager(_$AppDatabase db, $UploadQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UploadQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UploadQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UploadQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> entityKey = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<bool> dead = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UploadQueueCompanion(
                id: id,
                kind: kind,
                entityKey: entityKey,
                payload: payload,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                dead: dead,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                required String entityKey,
                required String payload,
                Value<int> attempts = const Value.absent(),
                Value<int> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<bool> dead = const Value.absent(),
                required DateTime createdAt,
              }) => UploadQueueCompanion.insert(
                id: id,
                kind: kind,
                entityKey: entityKey,
                payload: payload,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                dead: dead,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UploadQueueTable, OutboxRow>(table),
                  BaseReferences<_$AppDatabase, $UploadQueueTable, OutboxRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UploadQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UploadQueueTable,
      OutboxRow,
      $$UploadQueueTableFilterComposer,
      $$UploadQueueTableOrderingComposer,
      $$UploadQueueTableAnnotationComposer,
      $$UploadQueueTableCreateCompanionBuilder,
      $$UploadQueueTableUpdateCompanionBuilder,
      (OutboxRow, BaseReferences<_$AppDatabase, $UploadQueueTable, OutboxRow>),
      OutboxRow,
      PrefetchHooks Function()
    >;
typedef $$SyncCursorTableCreateCompanionBuilder = SyncCursorCompanion Function({
  required String tableKey,
  required String cursor,
  Value<int> rowid,
});
typedef $$SyncCursorTableUpdateCompanionBuilder = SyncCursorCompanion Function({
  Value<String> tableKey,
  Value<String> cursor,
  Value<int> rowid,
});

class $$SyncCursorTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCursorTable> {
  $$SyncCursorTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tableKey => $composableBuilder(
    column: $table.tableKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCursorTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCursorTable> {
  $$SyncCursorTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tableKey => $composableBuilder(
    column: $table.tableKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCursorTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCursorTable> {
  $$SyncCursorTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tableKey =>
      $composableBuilder(column: $table.tableKey, builder: (column) => column);

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);
}

class $$SyncCursorTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCursorTable,
          SyncCursorRow,
          $$SyncCursorTableFilterComposer,
          $$SyncCursorTableOrderingComposer,
          $$SyncCursorTableAnnotationComposer,
          $$SyncCursorTableCreateCompanionBuilder,
          $$SyncCursorTableUpdateCompanionBuilder,
          (
            SyncCursorRow,
            BaseReferences<_$AppDatabase, $SyncCursorTable, SyncCursorRow>,
          ),
          SyncCursorRow,
          PrefetchHooks Function()
        > {
  $$SyncCursorTableTableManager(_$AppDatabase db, $SyncCursorTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursorTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursorTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursorTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tableKey = const Value.absent(),
                Value<String> cursor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorCompanion(
                tableKey: tableKey,
                cursor: cursor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tableKey,
                required String cursor,
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorCompanion.insert(
                tableKey: tableKey,
                cursor: cursor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncCursorTable, SyncCursorRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncCursorTable,
                    SyncCursorRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCursorTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCursorTable,
      SyncCursorRow,
      $$SyncCursorTableFilterComposer,
      $$SyncCursorTableOrderingComposer,
      $$SyncCursorTableAnnotationComposer,
      $$SyncCursorTableCreateCompanionBuilder,
      $$SyncCursorTableUpdateCompanionBuilder,
      (
        SyncCursorRow,
        BaseReferences<_$AppDatabase, $SyncCursorTable, SyncCursorRow>,
      ),
      SyncCursorRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$JourneysTableTableManager get journeys =>
      $$JourneysTableTableManager(_db, _db.journeys);
  $$MembershipsTableTableManager get memberships =>
      $$MembershipsTableTableManager(_db, _db.memberships);
  $$CheckInsTableTableManager get checkIns =>
      $$CheckInsTableTableManager(_db, _db.checkIns);
  $$ReactionsTableTableManager get reactions =>
      $$ReactionsTableTableManager(_db, _db.reactions);
  $$BlocksTableTableManager get blocks =>
      $$BlocksTableTableManager(_db, _db.blocks);
  $$UploadQueueTableTableManager get uploadQueue =>
      $$UploadQueueTableTableManager(_db, _db.uploadQueue);
  $$SyncCursorTableTableManager get syncCursor =>
      $$SyncCursorTableTableManager(_db, _db.syncCursor);
}
