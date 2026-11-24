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
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('live'),
  );
  static const VerificationMeta _coupleSelfNameMeta = const VerificationMeta(
    'coupleSelfName',
  );
  @override
  late final GeneratedColumn<String> coupleSelfName = GeneratedColumn<String>(
    'couple_self_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _couplePartnerNameMeta = const VerificationMeta(
    'couplePartnerName',
  );
  @override
  late final GeneratedColumn<String> couplePartnerName =
      GeneratedColumn<String>(
        'couple_partner_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _layoutMeta = const VerificationMeta('layout');
  @override
  late final GeneratedColumn<String> layout = GeneratedColumn<String>(
    'layout',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverMeta = const VerificationMeta('cover');
  @override
  late final GeneratedColumn<int> cover = GeneratedColumn<int>(
    'cover',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderTimeMeta = const VerificationMeta(
    'reminderTime',
  );
  @override
  late final GeneratedColumn<String> reminderTime = GeneratedColumn<String>(
    'reminder_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dnaMeta = const VerificationMeta('dna');
  @override
  late final GeneratedColumn<String> dna = GeneratedColumn<String>(
    'dna',
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
    origin,
    coupleSelfName,
    couplePartnerName,
    layout,
    cover,
    color,
    reminderTime,
    dna,
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
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('couple_self_name')) {
      context.handle(
        _coupleSelfNameMeta,
        coupleSelfName.isAcceptableOrUnknown(
          data['couple_self_name']!,
          _coupleSelfNameMeta,
        ),
      );
    }
    if (data.containsKey('couple_partner_name')) {
      context.handle(
        _couplePartnerNameMeta,
        couplePartnerName.isAcceptableOrUnknown(
          data['couple_partner_name']!,
          _couplePartnerNameMeta,
        ),
      );
    }
    if (data.containsKey('layout')) {
      context.handle(
        _layoutMeta,
        layout.isAcceptableOrUnknown(data['layout']!, _layoutMeta),
      );
    }
    if (data.containsKey('cover')) {
      context.handle(
        _coverMeta,
        cover.isAcceptableOrUnknown(data['cover']!, _coverMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('reminder_time')) {
      context.handle(
        _reminderTimeMeta,
        reminderTime.isAcceptableOrUnknown(
          data['reminder_time']!,
          _reminderTimeMeta,
        ),
      );
    }
    if (data.containsKey('dna')) {
      context.handle(
        _dnaMeta,
        dna.isAcceptableOrUnknown(data['dna']!, _dnaMeta),
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
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      coupleSelfName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}couple_self_name'],
      ),
      couplePartnerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}couple_partner_name'],
      ),
      layout: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layout'],
      ),
      cover: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cover'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      reminderTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_time'],
      ),
      dna: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dna'],
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

  /// `journeys.origin` wire value (v1.3, schema version 2).
  final String origin;

  /// Couple names (`journeys.couple_*_name`, 0007; schema version 3).
  final String? coupleSelfName;
  final String? couplePartnerName;

  /// Edit-journey fields (0012; schema version 5). `dna` is a JSON object.
  final String? layout;
  final int? cover;
  final int? color;
  final String? reminderTime;
  final String? dna;

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
    required this.origin,
    this.coupleSelfName,
    this.couplePartnerName,
    this.layout,
    this.cover,
    this.color,
    this.reminderTime,
    this.dna,
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
    map['origin'] = Variable<String>(origin);
    if (!nullToAbsent || coupleSelfName != null) {
      map['couple_self_name'] = Variable<String>(coupleSelfName);
    }
    if (!nullToAbsent || couplePartnerName != null) {
      map['couple_partner_name'] = Variable<String>(couplePartnerName);
    }
    if (!nullToAbsent || layout != null) {
      map['layout'] = Variable<String>(layout);
    }
    if (!nullToAbsent || cover != null) {
      map['cover'] = Variable<int>(cover);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    if (!nullToAbsent || reminderTime != null) {
      map['reminder_time'] = Variable<String>(reminderTime);
    }
    if (!nullToAbsent || dna != null) {
      map['dna'] = Variable<String>(dna);
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
      origin: Value(origin),
      coupleSelfName: coupleSelfName == null && nullToAbsent
          ? const Value.absent()
          : Value(coupleSelfName),
      couplePartnerName: couplePartnerName == null && nullToAbsent
          ? const Value.absent()
          : Value(couplePartnerName),
      layout: layout == null && nullToAbsent
          ? const Value.absent()
          : Value(layout),
      cover: cover == null && nullToAbsent
          ? const Value.absent()
          : Value(cover),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      reminderTime: reminderTime == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderTime),
      dna: dna == null && nullToAbsent ? const Value.absent() : Value(dna),
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
      origin: serializer.fromJson<String>(json['origin']),
      coupleSelfName: serializer.fromJson<String?>(json['coupleSelfName']),
      couplePartnerName: serializer.fromJson<String?>(
        json['couplePartnerName'],
      ),
      layout: serializer.fromJson<String?>(json['layout']),
      cover: serializer.fromJson<int?>(json['cover']),
      color: serializer.fromJson<int?>(json['color']),
      reminderTime: serializer.fromJson<String?>(json['reminderTime']),
      dna: serializer.fromJson<String?>(json['dna']),
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
      'origin': serializer.toJson<String>(origin),
      'coupleSelfName': serializer.toJson<String?>(coupleSelfName),
      'couplePartnerName': serializer.toJson<String?>(couplePartnerName),
      'layout': serializer.toJson<String?>(layout),
      'cover': serializer.toJson<int?>(cover),
      'color': serializer.toJson<int?>(color),
      'reminderTime': serializer.toJson<String?>(reminderTime),
      'dna': serializer.toJson<String?>(dna),
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
    String? origin,
    Value<String?> coupleSelfName = const Value.absent(),
    Value<String?> couplePartnerName = const Value.absent(),
    Value<String?> layout = const Value.absent(),
    Value<int?> cover = const Value.absent(),
    Value<int?> color = const Value.absent(),
    Value<String?> reminderTime = const Value.absent(),
    Value<String?> dna = const Value.absent(),
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
    origin: origin ?? this.origin,
    coupleSelfName: coupleSelfName.present
        ? coupleSelfName.value
        : this.coupleSelfName,
    couplePartnerName: couplePartnerName.present
        ? couplePartnerName.value
        : this.couplePartnerName,
    layout: layout.present ? layout.value : this.layout,
    cover: cover.present ? cover.value : this.cover,
    color: color.present ? color.value : this.color,
    reminderTime: reminderTime.present ? reminderTime.value : this.reminderTime,
    dna: dna.present ? dna.value : this.dna,
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
      origin: data.origin.present ? data.origin.value : this.origin,
      coupleSelfName: data.coupleSelfName.present
          ? data.coupleSelfName.value
          : this.coupleSelfName,
      couplePartnerName: data.couplePartnerName.present
          ? data.couplePartnerName.value
          : this.couplePartnerName,
      layout: data.layout.present ? data.layout.value : this.layout,
      cover: data.cover.present ? data.cover.value : this.cover,
      color: data.color.present ? data.color.value : this.color,
      reminderTime: data.reminderTime.present
          ? data.reminderTime.value
          : this.reminderTime,
      dna: data.dna.present ? data.dna.value : this.dna,
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
          ..write('origin: $origin, ')
          ..write('coupleSelfName: $coupleSelfName, ')
          ..write('couplePartnerName: $couplePartnerName, ')
          ..write('layout: $layout, ')
          ..write('cover: $cover, ')
          ..write('color: $color, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('dna: $dna, ')
          ..write('localArchived: $localArchived, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
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
    origin,
    coupleSelfName,
    couplePartnerName,
    layout,
    cover,
    color,
    reminderTime,
    dna,
    localArchived,
    updatedAt,
  ]);
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
          other.origin == this.origin &&
          other.coupleSelfName == this.coupleSelfName &&
          other.couplePartnerName == this.couplePartnerName &&
          other.layout == this.layout &&
          other.cover == this.cover &&
          other.color == this.color &&
          other.reminderTime == this.reminderTime &&
          other.dna == this.dna &&
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
  final Value<String> origin;
  final Value<String?> coupleSelfName;
  final Value<String?> couplePartnerName;
  final Value<String?> layout;
  final Value<int?> cover;
  final Value<int?> color;
  final Value<String?> reminderTime;
  final Value<String?> dna;
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
    this.origin = const Value.absent(),
    this.coupleSelfName = const Value.absent(),
    this.couplePartnerName = const Value.absent(),
    this.layout = const Value.absent(),
    this.cover = const Value.absent(),
    this.color = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.dna = const Value.absent(),
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
    this.origin = const Value.absent(),
    this.coupleSelfName = const Value.absent(),
    this.couplePartnerName = const Value.absent(),
    this.layout = const Value.absent(),
    this.cover = const Value.absent(),
    this.color = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.dna = const Value.absent(),
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
    Expression<String>? origin,
    Expression<String>? coupleSelfName,
    Expression<String>? couplePartnerName,
    Expression<String>? layout,
    Expression<int>? cover,
    Expression<int>? color,
    Expression<String>? reminderTime,
    Expression<String>? dna,
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
      if (origin != null) 'origin': origin,
      if (coupleSelfName != null) 'couple_self_name': coupleSelfName,
      if (couplePartnerName != null) 'couple_partner_name': couplePartnerName,
      if (layout != null) 'layout': layout,
      if (cover != null) 'cover': cover,
      if (color != null) 'color': color,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (dna != null) 'dna': dna,
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
    Value<String>? origin,
    Value<String?>? coupleSelfName,
    Value<String?>? couplePartnerName,
    Value<String?>? layout,
    Value<int?>? cover,
    Value<int?>? color,
    Value<String?>? reminderTime,
    Value<String?>? dna,
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
      origin: origin ?? this.origin,
      coupleSelfName: coupleSelfName ?? this.coupleSelfName,
      couplePartnerName: couplePartnerName ?? this.couplePartnerName,
      layout: layout ?? this.layout,
      cover: cover ?? this.cover,
      color: color ?? this.color,
      reminderTime: reminderTime ?? this.reminderTime,
      dna: dna ?? this.dna,
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
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (coupleSelfName.present) {
      map['couple_self_name'] = Variable<String>(coupleSelfName.value);
    }
    if (couplePartnerName.present) {
      map['couple_partner_name'] = Variable<String>(couplePartnerName.value);
    }
    if (layout.present) {
      map['layout'] = Variable<String>(layout.value);
    }
    if (cover.present) {
      map['cover'] = Variable<int>(cover.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (reminderTime.present) {
      map['reminder_time'] = Variable<String>(reminderTime.value);
    }
    if (dna.present) {
      map['dna'] = Variable<String>(dna.value);
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
          ..write('origin: $origin, ')
          ..write('coupleSelfName: $coupleSelfName, ')
          ..write('couplePartnerName: $couplePartnerName, ')
          ..write('layout: $layout, ')
          ..write('cover: $cover, ')
          ..write('color: $color, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('dna: $dna, ')
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
  static const VerificationMeta _hideExtrasMeta = const VerificationMeta(
    'hideExtras',
  );
  @override
  late final GeneratedColumn<bool> hideExtras = GeneratedColumn<bool>(
    'hide_extras',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hide_extras" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
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
    hideExtras,
    pinned,
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
    if (data.containsKey('hide_extras')) {
      context.handle(
        _hideExtrasMeta,
        hideExtras.isAcceptableOrUnknown(data['hide_extras']!, _hideExtrasMeta),
      );
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
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
      hideExtras: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hide_extras'],
      )!,
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
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

  /// `memberships.hide_extras` / `pinned` (0011; schema version 4).
  final bool hideExtras;
  final bool pinned;
  final String? updatedAt;
  const MembershipRow({
    required this.journeyId,
    required this.userId,
    required this.role,
    required this.status,
    required this.joinedAt,
    required this.hideMetric,
    required this.blurMedia,
    required this.hideExtras,
    required this.pinned,
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
    map['hide_extras'] = Variable<bool>(hideExtras);
    map['pinned'] = Variable<bool>(pinned);
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
      hideExtras: Value(hideExtras),
      pinned: Value(pinned),
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
      hideExtras: serializer.fromJson<bool>(json['hideExtras']),
      pinned: serializer.fromJson<bool>(json['pinned']),
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
      'hideExtras': serializer.toJson<bool>(hideExtras),
      'pinned': serializer.toJson<bool>(pinned),
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
    bool? hideExtras,
    bool? pinned,
    Value<String?> updatedAt = const Value.absent(),
  }) => MembershipRow(
    journeyId: journeyId ?? this.journeyId,
    userId: userId ?? this.userId,
    role: role ?? this.role,
    status: status ?? this.status,
    joinedAt: joinedAt ?? this.joinedAt,
    hideMetric: hideMetric ?? this.hideMetric,
    blurMedia: blurMedia ?? this.blurMedia,
    hideExtras: hideExtras ?? this.hideExtras,
    pinned: pinned ?? this.pinned,
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
      hideExtras: data.hideExtras.present
          ? data.hideExtras.value
          : this.hideExtras,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
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
          ..write('hideExtras: $hideExtras, ')
          ..write('pinned: $pinned, ')
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
    hideExtras,
    pinned,
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
          other.hideExtras == this.hideExtras &&
          other.pinned == this.pinned &&
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
  final Value<bool> hideExtras;
  final Value<bool> pinned;
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
    this.hideExtras = const Value.absent(),
    this.pinned = const Value.absent(),
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
    this.hideExtras = const Value.absent(),
    this.pinned = const Value.absent(),
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
    Expression<bool>? hideExtras,
    Expression<bool>? pinned,
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
      if (hideExtras != null) 'hide_extras': hideExtras,
      if (pinned != null) 'pinned': pinned,
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
    Value<bool>? hideExtras,
    Value<bool>? pinned,
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
      hideExtras: hideExtras ?? this.hideExtras,
      pinned: pinned ?? this.pinned,
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
    if (hideExtras.present) {
      map['hide_extras'] = Variable<bool>(hideExtras.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
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
          ..write('hideExtras: $hideExtras, ')
          ..write('pinned: $pinned, ')
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
  static const VerificationMeta _extrasMeta = const VerificationMeta('extras');
  @override
  late final GeneratedColumn<String> extras = GeneratedColumn<String>(
    'extras',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _partnerPhotoPathMeta = const VerificationMeta(
    'partnerPhotoPath',
  );
  @override
  late final GeneratedColumn<String> partnerPhotoPath = GeneratedColumn<String>(
    'partner_photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
    extras,
    partnerPhotoPath,
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
    if (data.containsKey('extras')) {
      context.handle(
        _extrasMeta,
        extras.isAcceptableOrUnknown(data['extras']!, _extrasMeta),
      );
    }
    if (data.containsKey('partner_photo_path')) {
      context.handle(
        _partnerPhotoPathMeta,
        partnerPhotoPath.isAcceptableOrUnknown(
          data['partner_photo_path']!,
          _partnerPhotoPathMeta,
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
      extras: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extras'],
      )!,
      partnerPhotoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}partner_photo_path'],
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

  /// `check_ins.extras` as JSON text (0007; schema version 3).
  final String extras;

  /// `check_ins.partner_photo_path` (couple journeys).
  final String? partnerPhotoPath;

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
    required this.extras,
    this.partnerPhotoPath,
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
    map['extras'] = Variable<String>(extras);
    if (!nullToAbsent || partnerPhotoPath != null) {
      map['partner_photo_path'] = Variable<String>(partnerPhotoPath);
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
      extras: Value(extras),
      partnerPhotoPath: partnerPhotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(partnerPhotoPath),
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
      extras: serializer.fromJson<String>(json['extras']),
      partnerPhotoPath: serializer.fromJson<String?>(json['partnerPhotoPath']),
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
      'extras': serializer.toJson<String>(extras),
      'partnerPhotoPath': serializer.toJson<String?>(partnerPhotoPath),
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
    String? extras,
    Value<String?> partnerPhotoPath = const Value.absent(),
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
    extras: extras ?? this.extras,
    partnerPhotoPath: partnerPhotoPath.present
        ? partnerPhotoPath.value
        : this.partnerPhotoPath,
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
      extras: data.extras.present ? data.extras.value : this.extras,
      partnerPhotoPath: data.partnerPhotoPath.present
          ? data.partnerPhotoPath.value
          : this.partnerPhotoPath,
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
          ..write('extras: $extras, ')
          ..write('partnerPhotoPath: $partnerPhotoPath, ')
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
    extras,
    partnerPhotoPath,
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
          other.extras == this.extras &&
          other.partnerPhotoPath == this.partnerPhotoPath &&
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
  final Value<String> extras;
  final Value<String?> partnerPhotoPath;
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
    this.extras = const Value.absent(),
    this.partnerPhotoPath = const Value.absent(),
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
    this.extras = const Value.absent(),
    this.partnerPhotoPath = const Value.absent(),
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
    Expression<String>? extras,
    Expression<String>? partnerPhotoPath,
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
      if (extras != null) 'extras': extras,
      if (partnerPhotoPath != null) 'partner_photo_path': partnerPhotoPath,
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
    Value<String>? extras,
    Value<String?>? partnerPhotoPath,
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
      extras: extras ?? this.extras,
      partnerPhotoPath: partnerPhotoPath ?? this.partnerPhotoPath,
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
    if (extras.present) {
      map['extras'] = Variable<String>(extras.value);
    }
    if (partnerPhotoPath.present) {
      map['partner_photo_path'] = Variable<String>(partnerPhotoPath.value);
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
          ..write('extras: $extras, ')
          ..write('partnerPhotoPath: $partnerPhotoPath, ')
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

class $ImportJobsTable extends ImportJobs
    with TableInfo<$ImportJobsTable, ImportJobRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _layoutMeta = const VerificationMeta('layout');
  @override
  late final GeneratedColumn<String> layout = GeneratedColumn<String>(
    'layout',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> startDate =
      GeneratedColumn<String>(
        'start_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($ImportJobsTable.$converterstartDate);
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> endDate =
      GeneratedColumn<String>(
        'end_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($ImportJobsTable.$converterendDate);
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
  static const VerificationMeta _continuesMeta = const VerificationMeta(
    'continues',
  );
  @override
  late final GeneratedColumn<bool> continues = GeneratedColumn<bool>(
    'continues',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("continues" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _phaseMeta = const VerificationMeta('phase');
  @override
  late final GeneratedColumn<String> phase = GeneratedColumn<String>(
    'phase',
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
  static const VerificationMeta _pausedMeta = const VerificationMeta('paused');
  @override
  late final GeneratedColumn<bool> paused = GeneratedColumn<bool>(
    'paused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("paused" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createFailureMeta = const VerificationMeta(
    'createFailure',
  );
  @override
  late final GeneratedColumn<String> createFailure = GeneratedColumn<String>(
    'create_failure',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ImportJobsTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    emoji,
    templateId,
    layout,
    startDate,
    endDate,
    timezone,
    continues,
    phase,
    ownerId,
    paused,
    createFailure,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportJobRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('layout')) {
      context.handle(
        _layoutMeta,
        layout.isAcceptableOrUnknown(data['layout']!, _layoutMeta),
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
    if (data.containsKey('continues')) {
      context.handle(
        _continuesMeta,
        continues.isAcceptableOrUnknown(data['continues']!, _continuesMeta),
      );
    }
    if (data.containsKey('phase')) {
      context.handle(
        _phaseMeta,
        phase.isAcceptableOrUnknown(data['phase']!, _phaseMeta),
      );
    } else if (isInserting) {
      context.missing(_phaseMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('paused')) {
      context.handle(
        _pausedMeta,
        paused.isAcceptableOrUnknown(data['paused']!, _pausedMeta),
      );
    }
    if (data.containsKey('create_failure')) {
      context.handle(
        _createFailureMeta,
        createFailure.isAcceptableOrUnknown(
          data['create_failure']!,
          _createFailureMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImportJobRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportJobRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      layout: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layout'],
      ),
      startDate: $ImportJobsTable.$converterstartDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}start_date'],
        )!,
      ),
      endDate: $ImportJobsTable.$converterendDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}end_date'],
        )!,
      ),
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      continues: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}continues'],
      )!,
      phase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phase'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      paused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}paused'],
      )!,
      createFailure: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}create_failure'],
      ),
      createdAt: $ImportJobsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $ImportJobsTable createAlias(String alias) {
    return $ImportJobsTable(attachedDatabase, alias);
  }

  static TypeConverter<LocalDate, String> $converterstartDate =
      const LocalDateConverter();
  static TypeConverter<LocalDate, String> $converterendDate =
      const LocalDateConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcMicrosConverter();
}

class ImportJobRow extends DataClass implements Insertable<ImportJobRow> {
  final String id;
  final String title;
  final String emoji;
  final String templateId;
  final String? layout;
  final LocalDate startDate;
  final LocalDate endDate;
  final String timezone;
  final bool continues;

  /// `ImportPhase.wire`.
  final String phase;

  /// The account that started the job; no other account may run it.
  final String ownerId;

  /// Saving was paused by the person; the launch resume leaves it alone.
  final bool paused;

  /// `ImportFailure.wire` of the last failed create (null: none).
  final String? createFailure;
  final DateTime createdAt;
  const ImportJobRow({
    required this.id,
    required this.title,
    required this.emoji,
    required this.templateId,
    this.layout,
    required this.startDate,
    required this.endDate,
    required this.timezone,
    required this.continues,
    required this.phase,
    required this.ownerId,
    required this.paused,
    this.createFailure,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['emoji'] = Variable<String>(emoji);
    map['template_id'] = Variable<String>(templateId);
    if (!nullToAbsent || layout != null) {
      map['layout'] = Variable<String>(layout);
    }
    {
      map['start_date'] = Variable<String>(
        $ImportJobsTable.$converterstartDate.toSql(startDate),
      );
    }
    {
      map['end_date'] = Variable<String>(
        $ImportJobsTable.$converterendDate.toSql(endDate),
      );
    }
    map['timezone'] = Variable<String>(timezone);
    map['continues'] = Variable<bool>(continues);
    map['phase'] = Variable<String>(phase);
    map['owner_id'] = Variable<String>(ownerId);
    map['paused'] = Variable<bool>(paused);
    if (!nullToAbsent || createFailure != null) {
      map['create_failure'] = Variable<String>(createFailure);
    }
    {
      map['created_at'] = Variable<int>(
        $ImportJobsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  ImportJobsCompanion toCompanion(bool nullToAbsent) {
    return ImportJobsCompanion(
      id: Value(id),
      title: Value(title),
      emoji: Value(emoji),
      templateId: Value(templateId),
      layout: layout == null && nullToAbsent
          ? const Value.absent()
          : Value(layout),
      startDate: Value(startDate),
      endDate: Value(endDate),
      timezone: Value(timezone),
      continues: Value(continues),
      phase: Value(phase),
      ownerId: Value(ownerId),
      paused: Value(paused),
      createFailure: createFailure == null && nullToAbsent
          ? const Value.absent()
          : Value(createFailure),
      createdAt: Value(createdAt),
    );
  }

  factory ImportJobRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportJobRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      emoji: serializer.fromJson<String>(json['emoji']),
      templateId: serializer.fromJson<String>(json['templateId']),
      layout: serializer.fromJson<String?>(json['layout']),
      startDate: serializer.fromJson<LocalDate>(json['startDate']),
      endDate: serializer.fromJson<LocalDate>(json['endDate']),
      timezone: serializer.fromJson<String>(json['timezone']),
      continues: serializer.fromJson<bool>(json['continues']),
      phase: serializer.fromJson<String>(json['phase']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      paused: serializer.fromJson<bool>(json['paused']),
      createFailure: serializer.fromJson<String?>(json['createFailure']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'emoji': serializer.toJson<String>(emoji),
      'templateId': serializer.toJson<String>(templateId),
      'layout': serializer.toJson<String?>(layout),
      'startDate': serializer.toJson<LocalDate>(startDate),
      'endDate': serializer.toJson<LocalDate>(endDate),
      'timezone': serializer.toJson<String>(timezone),
      'continues': serializer.toJson<bool>(continues),
      'phase': serializer.toJson<String>(phase),
      'ownerId': serializer.toJson<String>(ownerId),
      'paused': serializer.toJson<bool>(paused),
      'createFailure': serializer.toJson<String?>(createFailure),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ImportJobRow copyWith({
    String? id,
    String? title,
    String? emoji,
    String? templateId,
    Value<String?> layout = const Value.absent(),
    LocalDate? startDate,
    LocalDate? endDate,
    String? timezone,
    bool? continues,
    String? phase,
    String? ownerId,
    bool? paused,
    Value<String?> createFailure = const Value.absent(),
    DateTime? createdAt,
  }) => ImportJobRow(
    id: id ?? this.id,
    title: title ?? this.title,
    emoji: emoji ?? this.emoji,
    templateId: templateId ?? this.templateId,
    layout: layout.present ? layout.value : this.layout,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    timezone: timezone ?? this.timezone,
    continues: continues ?? this.continues,
    phase: phase ?? this.phase,
    ownerId: ownerId ?? this.ownerId,
    paused: paused ?? this.paused,
    createFailure: createFailure.present
        ? createFailure.value
        : this.createFailure,
    createdAt: createdAt ?? this.createdAt,
  );
  ImportJobRow copyWithCompanion(ImportJobsCompanion data) {
    return ImportJobRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      layout: data.layout.present ? data.layout.value : this.layout,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      continues: data.continues.present ? data.continues.value : this.continues,
      phase: data.phase.present ? data.phase.value : this.phase,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      paused: data.paused.present ? data.paused.value : this.paused,
      createFailure: data.createFailure.present
          ? data.createFailure.value
          : this.createFailure,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportJobRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('emoji: $emoji, ')
          ..write('templateId: $templateId, ')
          ..write('layout: $layout, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('timezone: $timezone, ')
          ..write('continues: $continues, ')
          ..write('phase: $phase, ')
          ..write('ownerId: $ownerId, ')
          ..write('paused: $paused, ')
          ..write('createFailure: $createFailure, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    emoji,
    templateId,
    layout,
    startDate,
    endDate,
    timezone,
    continues,
    phase,
    ownerId,
    paused,
    createFailure,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportJobRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.emoji == this.emoji &&
          other.templateId == this.templateId &&
          other.layout == this.layout &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.timezone == this.timezone &&
          other.continues == this.continues &&
          other.phase == this.phase &&
          other.ownerId == this.ownerId &&
          other.paused == this.paused &&
          other.createFailure == this.createFailure &&
          other.createdAt == this.createdAt);
}

class ImportJobsCompanion extends UpdateCompanion<ImportJobRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> emoji;
  final Value<String> templateId;
  final Value<String?> layout;
  final Value<LocalDate> startDate;
  final Value<LocalDate> endDate;
  final Value<String> timezone;
  final Value<bool> continues;
  final Value<String> phase;
  final Value<String> ownerId;
  final Value<bool> paused;
  final Value<String?> createFailure;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ImportJobsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.emoji = const Value.absent(),
    this.templateId = const Value.absent(),
    this.layout = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.timezone = const Value.absent(),
    this.continues = const Value.absent(),
    this.phase = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.paused = const Value.absent(),
    this.createFailure = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportJobsCompanion.insert({
    required String id,
    required String title,
    required String emoji,
    required String templateId,
    this.layout = const Value.absent(),
    required LocalDate startDate,
    required LocalDate endDate,
    required String timezone,
    this.continues = const Value.absent(),
    required String phase,
    required String ownerId,
    this.paused = const Value.absent(),
    this.createFailure = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       emoji = Value(emoji),
       templateId = Value(templateId),
       startDate = Value(startDate),
       endDate = Value(endDate),
       timezone = Value(timezone),
       phase = Value(phase),
       ownerId = Value(ownerId),
       createdAt = Value(createdAt);
  static Insertable<ImportJobRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? emoji,
    Expression<String>? templateId,
    Expression<String>? layout,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? timezone,
    Expression<bool>? continues,
    Expression<String>? phase,
    Expression<String>? ownerId,
    Expression<bool>? paused,
    Expression<String>? createFailure,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (emoji != null) 'emoji': emoji,
      if (templateId != null) 'template_id': templateId,
      if (layout != null) 'layout': layout,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (timezone != null) 'timezone': timezone,
      if (continues != null) 'continues': continues,
      if (phase != null) 'phase': phase,
      if (ownerId != null) 'owner_id': ownerId,
      if (paused != null) 'paused': paused,
      if (createFailure != null) 'create_failure': createFailure,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportJobsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? emoji,
    Value<String>? templateId,
    Value<String?>? layout,
    Value<LocalDate>? startDate,
    Value<LocalDate>? endDate,
    Value<String>? timezone,
    Value<bool>? continues,
    Value<String>? phase,
    Value<String>? ownerId,
    Value<bool>? paused,
    Value<String?>? createFailure,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ImportJobsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      templateId: templateId ?? this.templateId,
      layout: layout ?? this.layout,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      timezone: timezone ?? this.timezone,
      continues: continues ?? this.continues,
      phase: phase ?? this.phase,
      ownerId: ownerId ?? this.ownerId,
      paused: paused ?? this.paused,
      createFailure: createFailure ?? this.createFailure,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (layout.present) {
      map['layout'] = Variable<String>(layout.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(
        $ImportJobsTable.$converterstartDate.toSql(startDate.value),
      );
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(
        $ImportJobsTable.$converterendDate.toSql(endDate.value),
      );
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (continues.present) {
      map['continues'] = Variable<bool>(continues.value);
    }
    if (phase.present) {
      map['phase'] = Variable<String>(phase.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (paused.present) {
      map['paused'] = Variable<bool>(paused.value);
    }
    if (createFailure.present) {
      map['create_failure'] = Variable<String>(createFailure.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $ImportJobsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportJobsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('emoji: $emoji, ')
          ..write('templateId: $templateId, ')
          ..write('layout: $layout, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('timezone: $timezone, ')
          ..write('continues: $continues, ')
          ..write('phase: $phase, ')
          ..write('ownerId: $ownerId, ')
          ..write('paused: $paused, ')
          ..write('createFailure: $createFailure, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportJobPhotosTable extends ImportJobPhotos
    with TableInfo<$ImportJobPhotosTable, ImportJobPhotoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportJobPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourcePathMeta = const VerificationMeta(
    'sourcePath',
  );
  @override
  late final GeneratedColumn<String> sourcePath = GeneratedColumn<String>(
    'source_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoFileMeta = const VerificationMeta(
    'photoFile',
  );
  @override
  late final GeneratedColumn<String> photoFile = GeneratedColumn<String>(
    'photo_file',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbFileMeta = const VerificationMeta(
    'thumbFile',
  );
  @override
  late final GeneratedColumn<String> thumbFile = GeneratedColumn<String>(
    'thumb_file',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> localDate =
      GeneratedColumn<String>(
        'local_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($ImportJobPhotosTable.$converterlocalDate);
  static const VerificationMeta _secondsOfDayMeta = const VerificationMeta(
    'secondsOfDay',
  );
  @override
  late final GeneratedColumn<int> secondsOfDay = GeneratedColumn<int>(
    'seconds_of_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _offsetMinutesMeta = const VerificationMeta(
    'offsetMinutes',
  );
  @override
  late final GeneratedColumn<int> offsetMinutes = GeneratedColumn<int>(
    'offset_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dedupeKeyMeta = const VerificationMeta(
    'dedupeKey',
  );
  @override
  late final GeneratedColumn<String> dedupeKey = GeneratedColumn<String>(
    'dedupe_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _failureMeta = const VerificationMeta(
    'failure',
  );
  @override
  late final GeneratedColumn<String> failure = GeneratedColumn<String>(
    'failure',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    jobId,
    position,
    sourcePath,
    photoFile,
    thumbFile,
    localDate,
    secondsOfDay,
    offsetMinutes,
    dedupeKey,
    state,
    failure,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_job_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportJobPhotoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('source_path')) {
      context.handle(
        _sourcePathMeta,
        sourcePath.isAcceptableOrUnknown(data['source_path']!, _sourcePathMeta),
      );
    }
    if (data.containsKey('photo_file')) {
      context.handle(
        _photoFileMeta,
        photoFile.isAcceptableOrUnknown(data['photo_file']!, _photoFileMeta),
      );
    }
    if (data.containsKey('thumb_file')) {
      context.handle(
        _thumbFileMeta,
        thumbFile.isAcceptableOrUnknown(data['thumb_file']!, _thumbFileMeta),
      );
    }
    if (data.containsKey('seconds_of_day')) {
      context.handle(
        _secondsOfDayMeta,
        secondsOfDay.isAcceptableOrUnknown(
          data['seconds_of_day']!,
          _secondsOfDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_secondsOfDayMeta);
    }
    if (data.containsKey('offset_minutes')) {
      context.handle(
        _offsetMinutesMeta,
        offsetMinutes.isAcceptableOrUnknown(
          data['offset_minutes']!,
          _offsetMinutesMeta,
        ),
      );
    }
    if (data.containsKey('dedupe_key')) {
      context.handle(
        _dedupeKeyMeta,
        dedupeKey.isAcceptableOrUnknown(data['dedupe_key']!, _dedupeKeyMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('failure')) {
      context.handle(
        _failureMeta,
        failure.isAcceptableOrUnknown(data['failure']!, _failureMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImportJobPhotoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportJobPhotoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      sourcePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_path'],
      ),
      photoFile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_file'],
      ),
      thumbFile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb_file'],
      ),
      localDate: $ImportJobPhotosTable.$converterlocalDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}local_date'],
        )!,
      ),
      secondsOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seconds_of_day'],
      )!,
      offsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_minutes'],
      ),
      dedupeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dedupe_key'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      failure: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure'],
      ),
    );
  }

  @override
  $ImportJobPhotosTable createAlias(String alias) {
    return $ImportJobPhotosTable(attachedDatabase, alias);
  }

  static TypeConverter<LocalDate, String> $converterlocalDate =
      const LocalDateConverter();
}

class ImportJobPhotoRow extends DataClass
    implements Insertable<ImportJobPhotoRow> {
  final String id;
  final String jobId;
  final int position;
  final String? sourcePath;
  final String? photoFile;
  final String? thumbFile;
  final LocalDate localDate;
  final int secondsOfDay;
  final int? offsetMinutes;

  /// Content key of the picked photo (so "Edit details" still recognises it).
  final String? dedupeKey;

  /// `ImportPhotoState.wire`.
  final String state;

  /// `ImportFailure.wire`.
  final String? failure;
  const ImportJobPhotoRow({
    required this.id,
    required this.jobId,
    required this.position,
    this.sourcePath,
    this.photoFile,
    this.thumbFile,
    required this.localDate,
    required this.secondsOfDay,
    this.offsetMinutes,
    this.dedupeKey,
    required this.state,
    this.failure,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['job_id'] = Variable<String>(jobId);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || sourcePath != null) {
      map['source_path'] = Variable<String>(sourcePath);
    }
    if (!nullToAbsent || photoFile != null) {
      map['photo_file'] = Variable<String>(photoFile);
    }
    if (!nullToAbsent || thumbFile != null) {
      map['thumb_file'] = Variable<String>(thumbFile);
    }
    {
      map['local_date'] = Variable<String>(
        $ImportJobPhotosTable.$converterlocalDate.toSql(localDate),
      );
    }
    map['seconds_of_day'] = Variable<int>(secondsOfDay);
    if (!nullToAbsent || offsetMinutes != null) {
      map['offset_minutes'] = Variable<int>(offsetMinutes);
    }
    if (!nullToAbsent || dedupeKey != null) {
      map['dedupe_key'] = Variable<String>(dedupeKey);
    }
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || failure != null) {
      map['failure'] = Variable<String>(failure);
    }
    return map;
  }

  ImportJobPhotosCompanion toCompanion(bool nullToAbsent) {
    return ImportJobPhotosCompanion(
      id: Value(id),
      jobId: Value(jobId),
      position: Value(position),
      sourcePath: sourcePath == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePath),
      photoFile: photoFile == null && nullToAbsent
          ? const Value.absent()
          : Value(photoFile),
      thumbFile: thumbFile == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbFile),
      localDate: Value(localDate),
      secondsOfDay: Value(secondsOfDay),
      offsetMinutes: offsetMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(offsetMinutes),
      dedupeKey: dedupeKey == null && nullToAbsent
          ? const Value.absent()
          : Value(dedupeKey),
      state: Value(state),
      failure: failure == null && nullToAbsent
          ? const Value.absent()
          : Value(failure),
    );
  }

  factory ImportJobPhotoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportJobPhotoRow(
      id: serializer.fromJson<String>(json['id']),
      jobId: serializer.fromJson<String>(json['jobId']),
      position: serializer.fromJson<int>(json['position']),
      sourcePath: serializer.fromJson<String?>(json['sourcePath']),
      photoFile: serializer.fromJson<String?>(json['photoFile']),
      thumbFile: serializer.fromJson<String?>(json['thumbFile']),
      localDate: serializer.fromJson<LocalDate>(json['localDate']),
      secondsOfDay: serializer.fromJson<int>(json['secondsOfDay']),
      offsetMinutes: serializer.fromJson<int?>(json['offsetMinutes']),
      dedupeKey: serializer.fromJson<String?>(json['dedupeKey']),
      state: serializer.fromJson<String>(json['state']),
      failure: serializer.fromJson<String?>(json['failure']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'jobId': serializer.toJson<String>(jobId),
      'position': serializer.toJson<int>(position),
      'sourcePath': serializer.toJson<String?>(sourcePath),
      'photoFile': serializer.toJson<String?>(photoFile),
      'thumbFile': serializer.toJson<String?>(thumbFile),
      'localDate': serializer.toJson<LocalDate>(localDate),
      'secondsOfDay': serializer.toJson<int>(secondsOfDay),
      'offsetMinutes': serializer.toJson<int?>(offsetMinutes),
      'dedupeKey': serializer.toJson<String?>(dedupeKey),
      'state': serializer.toJson<String>(state),
      'failure': serializer.toJson<String?>(failure),
    };
  }

  ImportJobPhotoRow copyWith({
    String? id,
    String? jobId,
    int? position,
    Value<String?> sourcePath = const Value.absent(),
    Value<String?> photoFile = const Value.absent(),
    Value<String?> thumbFile = const Value.absent(),
    LocalDate? localDate,
    int? secondsOfDay,
    Value<int?> offsetMinutes = const Value.absent(),
    Value<String?> dedupeKey = const Value.absent(),
    String? state,
    Value<String?> failure = const Value.absent(),
  }) => ImportJobPhotoRow(
    id: id ?? this.id,
    jobId: jobId ?? this.jobId,
    position: position ?? this.position,
    sourcePath: sourcePath.present ? sourcePath.value : this.sourcePath,
    photoFile: photoFile.present ? photoFile.value : this.photoFile,
    thumbFile: thumbFile.present ? thumbFile.value : this.thumbFile,
    localDate: localDate ?? this.localDate,
    secondsOfDay: secondsOfDay ?? this.secondsOfDay,
    offsetMinutes: offsetMinutes.present
        ? offsetMinutes.value
        : this.offsetMinutes,
    dedupeKey: dedupeKey.present ? dedupeKey.value : this.dedupeKey,
    state: state ?? this.state,
    failure: failure.present ? failure.value : this.failure,
  );
  ImportJobPhotoRow copyWithCompanion(ImportJobPhotosCompanion data) {
    return ImportJobPhotoRow(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      position: data.position.present ? data.position.value : this.position,
      sourcePath: data.sourcePath.present
          ? data.sourcePath.value
          : this.sourcePath,
      photoFile: data.photoFile.present ? data.photoFile.value : this.photoFile,
      thumbFile: data.thumbFile.present ? data.thumbFile.value : this.thumbFile,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      secondsOfDay: data.secondsOfDay.present
          ? data.secondsOfDay.value
          : this.secondsOfDay,
      offsetMinutes: data.offsetMinutes.present
          ? data.offsetMinutes.value
          : this.offsetMinutes,
      dedupeKey: data.dedupeKey.present ? data.dedupeKey.value : this.dedupeKey,
      state: data.state.present ? data.state.value : this.state,
      failure: data.failure.present ? data.failure.value : this.failure,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportJobPhotoRow(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('position: $position, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('photoFile: $photoFile, ')
          ..write('thumbFile: $thumbFile, ')
          ..write('localDate: $localDate, ')
          ..write('secondsOfDay: $secondsOfDay, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('dedupeKey: $dedupeKey, ')
          ..write('state: $state, ')
          ..write('failure: $failure')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    jobId,
    position,
    sourcePath,
    photoFile,
    thumbFile,
    localDate,
    secondsOfDay,
    offsetMinutes,
    dedupeKey,
    state,
    failure,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportJobPhotoRow &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.position == this.position &&
          other.sourcePath == this.sourcePath &&
          other.photoFile == this.photoFile &&
          other.thumbFile == this.thumbFile &&
          other.localDate == this.localDate &&
          other.secondsOfDay == this.secondsOfDay &&
          other.offsetMinutes == this.offsetMinutes &&
          other.dedupeKey == this.dedupeKey &&
          other.state == this.state &&
          other.failure == this.failure);
}

class ImportJobPhotosCompanion extends UpdateCompanion<ImportJobPhotoRow> {
  final Value<String> id;
  final Value<String> jobId;
  final Value<int> position;
  final Value<String?> sourcePath;
  final Value<String?> photoFile;
  final Value<String?> thumbFile;
  final Value<LocalDate> localDate;
  final Value<int> secondsOfDay;
  final Value<int?> offsetMinutes;
  final Value<String?> dedupeKey;
  final Value<String> state;
  final Value<String?> failure;
  final Value<int> rowid;
  const ImportJobPhotosCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.position = const Value.absent(),
    this.sourcePath = const Value.absent(),
    this.photoFile = const Value.absent(),
    this.thumbFile = const Value.absent(),
    this.localDate = const Value.absent(),
    this.secondsOfDay = const Value.absent(),
    this.offsetMinutes = const Value.absent(),
    this.dedupeKey = const Value.absent(),
    this.state = const Value.absent(),
    this.failure = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportJobPhotosCompanion.insert({
    required String id,
    required String jobId,
    required int position,
    this.sourcePath = const Value.absent(),
    this.photoFile = const Value.absent(),
    this.thumbFile = const Value.absent(),
    required LocalDate localDate,
    required int secondsOfDay,
    this.offsetMinutes = const Value.absent(),
    this.dedupeKey = const Value.absent(),
    required String state,
    this.failure = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       jobId = Value(jobId),
       position = Value(position),
       localDate = Value(localDate),
       secondsOfDay = Value(secondsOfDay),
       state = Value(state);
  static Insertable<ImportJobPhotoRow> custom({
    Expression<String>? id,
    Expression<String>? jobId,
    Expression<int>? position,
    Expression<String>? sourcePath,
    Expression<String>? photoFile,
    Expression<String>? thumbFile,
    Expression<String>? localDate,
    Expression<int>? secondsOfDay,
    Expression<int>? offsetMinutes,
    Expression<String>? dedupeKey,
    Expression<String>? state,
    Expression<String>? failure,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (position != null) 'position': position,
      if (sourcePath != null) 'source_path': sourcePath,
      if (photoFile != null) 'photo_file': photoFile,
      if (thumbFile != null) 'thumb_file': thumbFile,
      if (localDate != null) 'local_date': localDate,
      if (secondsOfDay != null) 'seconds_of_day': secondsOfDay,
      if (offsetMinutes != null) 'offset_minutes': offsetMinutes,
      if (dedupeKey != null) 'dedupe_key': dedupeKey,
      if (state != null) 'state': state,
      if (failure != null) 'failure': failure,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportJobPhotosCompanion copyWith({
    Value<String>? id,
    Value<String>? jobId,
    Value<int>? position,
    Value<String?>? sourcePath,
    Value<String?>? photoFile,
    Value<String?>? thumbFile,
    Value<LocalDate>? localDate,
    Value<int>? secondsOfDay,
    Value<int?>? offsetMinutes,
    Value<String?>? dedupeKey,
    Value<String>? state,
    Value<String?>? failure,
    Value<int>? rowid,
  }) {
    return ImportJobPhotosCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      position: position ?? this.position,
      sourcePath: sourcePath ?? this.sourcePath,
      photoFile: photoFile ?? this.photoFile,
      thumbFile: thumbFile ?? this.thumbFile,
      localDate: localDate ?? this.localDate,
      secondsOfDay: secondsOfDay ?? this.secondsOfDay,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      dedupeKey: dedupeKey ?? this.dedupeKey,
      state: state ?? this.state,
      failure: failure ?? this.failure,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (sourcePath.present) {
      map['source_path'] = Variable<String>(sourcePath.value);
    }
    if (photoFile.present) {
      map['photo_file'] = Variable<String>(photoFile.value);
    }
    if (thumbFile.present) {
      map['thumb_file'] = Variable<String>(thumbFile.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(
        $ImportJobPhotosTable.$converterlocalDate.toSql(localDate.value),
      );
    }
    if (secondsOfDay.present) {
      map['seconds_of_day'] = Variable<int>(secondsOfDay.value);
    }
    if (offsetMinutes.present) {
      map['offset_minutes'] = Variable<int>(offsetMinutes.value);
    }
    if (dedupeKey.present) {
      map['dedupe_key'] = Variable<String>(dedupeKey.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (failure.present) {
      map['failure'] = Variable<String>(failure.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportJobPhotosCompanion(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('position: $position, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('photoFile: $photoFile, ')
          ..write('thumbFile: $thumbFile, ')
          ..write('localDate: $localDate, ')
          ..write('secondsOfDay: $secondsOfDay, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('dedupeKey: $dedupeKey, ')
          ..write('state: $state, ')
          ..write('failure: $failure, ')
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
  late final $ImportJobsTable importJobs = $ImportJobsTable(this);
  late final $ImportJobPhotosTable importJobPhotos = $ImportJobPhotosTable(
    this,
  );
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
    importJobs,
    importJobPhotos,
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
  Value<String> origin,
  Value<String?> coupleSelfName,
  Value<String?> couplePartnerName,
  Value<String?> layout,
  Value<int?> cover,
  Value<int?> color,
  Value<String?> reminderTime,
  Value<String?> dna,
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
  Value<String> origin,
  Value<String?> coupleSelfName,
  Value<String?> couplePartnerName,
  Value<String?> layout,
  Value<int?> cover,
  Value<int?> color,
  Value<String?> reminderTime,
  Value<String?> dna,
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

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coupleSelfName => $composableBuilder(
    column: $table.coupleSelfName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get couplePartnerName => $composableBuilder(
    column: $table.couplePartnerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get layout => $composableBuilder(
    column: $table.layout,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dna => $composableBuilder(
    column: $table.dna,
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

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coupleSelfName => $composableBuilder(
    column: $table.coupleSelfName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get couplePartnerName => $composableBuilder(
    column: $table.couplePartnerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get layout => $composableBuilder(
    column: $table.layout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dna => $composableBuilder(
    column: $table.dna,
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

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get coupleSelfName => $composableBuilder(
    column: $table.coupleSelfName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get couplePartnerName => $composableBuilder(
    column: $table.couplePartnerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get layout =>
      $composableBuilder(column: $table.layout, builder: (column) => column);

  GeneratedColumn<int> get cover =>
      $composableBuilder(column: $table.cover, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dna =>
      $composableBuilder(column: $table.dna, builder: (column) => column);

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
                Value<String> origin = const Value.absent(),
                Value<String?> coupleSelfName = const Value.absent(),
                Value<String?> couplePartnerName = const Value.absent(),
                Value<String?> layout = const Value.absent(),
                Value<int?> cover = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<String?> reminderTime = const Value.absent(),
                Value<String?> dna = const Value.absent(),
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
                origin: origin,
                coupleSelfName: coupleSelfName,
                couplePartnerName: couplePartnerName,
                layout: layout,
                cover: cover,
                color: color,
                reminderTime: reminderTime,
                dna: dna,
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
                Value<String> origin = const Value.absent(),
                Value<String?> coupleSelfName = const Value.absent(),
                Value<String?> couplePartnerName = const Value.absent(),
                Value<String?> layout = const Value.absent(),
                Value<int?> cover = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<String?> reminderTime = const Value.absent(),
                Value<String?> dna = const Value.absent(),
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
                origin: origin,
                coupleSelfName: coupleSelfName,
                couplePartnerName: couplePartnerName,
                layout: layout,
                cover: cover,
                color: color,
                reminderTime: reminderTime,
                dna: dna,
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
      Value<bool> hideExtras,
      Value<bool> pinned,
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
      Value<bool> hideExtras,
      Value<bool> pinned,
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

  ColumnFilters<bool> get hideExtras => $composableBuilder(
    column: $table.hideExtras,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
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

  ColumnOrderings<bool> get hideExtras => $composableBuilder(
    column: $table.hideExtras,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
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

  GeneratedColumn<bool> get hideExtras => $composableBuilder(
    column: $table.hideExtras,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

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
                Value<bool> hideExtras = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
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
                hideExtras: hideExtras,
                pinned: pinned,
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
                Value<bool> hideExtras = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
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
                hideExtras: hideExtras,
                pinned: pinned,
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
  Value<String> extras,
  Value<String?> partnerPhotoPath,
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
  Value<String> extras,
  Value<String?> partnerPhotoPath,
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

  ColumnFilters<String> get extras => $composableBuilder(
    column: $table.extras,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partnerPhotoPath => $composableBuilder(
    column: $table.partnerPhotoPath,
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

  ColumnOrderings<String> get extras => $composableBuilder(
    column: $table.extras,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partnerPhotoPath => $composableBuilder(
    column: $table.partnerPhotoPath,
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

  GeneratedColumn<String> get extras =>
      $composableBuilder(column: $table.extras, builder: (column) => column);

  GeneratedColumn<String> get partnerPhotoPath => $composableBuilder(
    column: $table.partnerPhotoPath,
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
                Value<String> extras = const Value.absent(),
                Value<String?> partnerPhotoPath = const Value.absent(),
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
                extras: extras,
                partnerPhotoPath: partnerPhotoPath,
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
                Value<String> extras = const Value.absent(),
                Value<String?> partnerPhotoPath = const Value.absent(),
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
                extras: extras,
                partnerPhotoPath: partnerPhotoPath,
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
typedef $$ImportJobsTableCreateCompanionBuilder = ImportJobsCompanion Function({
  required String id,
  required String title,
  required String emoji,
  required String templateId,
  Value<String?> layout,
  required LocalDate startDate,
  required LocalDate endDate,
  required String timezone,
  Value<bool> continues,
  required String phase,
  required String ownerId,
  Value<bool> paused,
  Value<String?> createFailure,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$ImportJobsTableUpdateCompanionBuilder = ImportJobsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> emoji,
  Value<String> templateId,
  Value<String?> layout,
  Value<LocalDate> startDate,
  Value<LocalDate> endDate,
  Value<String> timezone,
  Value<bool> continues,
  Value<String> phase,
  Value<String> ownerId,
  Value<bool> paused,
  Value<String?> createFailure,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$ImportJobsTableFilterComposer
    extends Composer<_$AppDatabase, $ImportJobsTable> {
  $$ImportJobsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get layout => $composableBuilder(
    column: $table.layout,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LocalDate, LocalDate, String> get startDate =>
      $composableBuilder(
        column: $table.startDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<LocalDate, LocalDate, String> get endDate =>
      $composableBuilder(
        column: $table.endDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get continues => $composableBuilder(
    column: $table.continues,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get paused => $composableBuilder(
    column: $table.paused,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createFailure => $composableBuilder(
    column: $table.createFailure,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$ImportJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportJobsTable> {
  $$ImportJobsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get layout => $composableBuilder(
    column: $table.layout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get continues => $composableBuilder(
    column: $table.continues,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get paused => $composableBuilder(
    column: $table.paused,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createFailure => $composableBuilder(
    column: $table.createFailure,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportJobsTable> {
  $$ImportJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get layout =>
      $composableBuilder(column: $table.layout, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocalDate, String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocalDate, String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<bool> get continues =>
      $composableBuilder(column: $table.continues, builder: (column) => column);

  GeneratedColumn<String> get phase =>
      $composableBuilder(column: $table.phase, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<bool> get paused =>
      $composableBuilder(column: $table.paused, builder: (column) => column);

  GeneratedColumn<String> get createFailure => $composableBuilder(
    column: $table.createFailure,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ImportJobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportJobsTable,
          ImportJobRow,
          $$ImportJobsTableFilterComposer,
          $$ImportJobsTableOrderingComposer,
          $$ImportJobsTableAnnotationComposer,
          $$ImportJobsTableCreateCompanionBuilder,
          $$ImportJobsTableUpdateCompanionBuilder,
          (
            ImportJobRow,
            BaseReferences<_$AppDatabase, $ImportJobsTable, ImportJobRow>,
          ),
          ImportJobRow,
          PrefetchHooks Function()
        > {
  $$ImportJobsTableTableManager(_$AppDatabase db, $ImportJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String?> layout = const Value.absent(),
                Value<LocalDate> startDate = const Value.absent(),
                Value<LocalDate> endDate = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<bool> continues = const Value.absent(),
                Value<String> phase = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<bool> paused = const Value.absent(),
                Value<String?> createFailure = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportJobsCompanion(
                id: id,
                title: title,
                emoji: emoji,
                templateId: templateId,
                layout: layout,
                startDate: startDate,
                endDate: endDate,
                timezone: timezone,
                continues: continues,
                phase: phase,
                ownerId: ownerId,
                paused: paused,
                createFailure: createFailure,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String emoji,
                required String templateId,
                Value<String?> layout = const Value.absent(),
                required LocalDate startDate,
                required LocalDate endDate,
                required String timezone,
                Value<bool> continues = const Value.absent(),
                required String phase,
                required String ownerId,
                Value<bool> paused = const Value.absent(),
                Value<String?> createFailure = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ImportJobsCompanion.insert(
                id: id,
                title: title,
                emoji: emoji,
                templateId: templateId,
                layout: layout,
                startDate: startDate,
                endDate: endDate,
                timezone: timezone,
                continues: continues,
                phase: phase,
                ownerId: ownerId,
                paused: paused,
                createFailure: createFailure,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ImportJobsTable, ImportJobRow>(table),
                  BaseReferences<_$AppDatabase, $ImportJobsTable, ImportJobRow>(
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

typedef $$ImportJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportJobsTable,
      ImportJobRow,
      $$ImportJobsTableFilterComposer,
      $$ImportJobsTableOrderingComposer,
      $$ImportJobsTableAnnotationComposer,
      $$ImportJobsTableCreateCompanionBuilder,
      $$ImportJobsTableUpdateCompanionBuilder,
      (
        ImportJobRow,
        BaseReferences<_$AppDatabase, $ImportJobsTable, ImportJobRow>,
      ),
      ImportJobRow,
      PrefetchHooks Function()
    >;
typedef $$ImportJobPhotosTableCreateCompanionBuilder =
    ImportJobPhotosCompanion Function({
      required String id,
      required String jobId,
      required int position,
      Value<String?> sourcePath,
      Value<String?> photoFile,
      Value<String?> thumbFile,
      required LocalDate localDate,
      required int secondsOfDay,
      Value<int?> offsetMinutes,
      Value<String?> dedupeKey,
      required String state,
      Value<String?> failure,
      Value<int> rowid,
    });
typedef $$ImportJobPhotosTableUpdateCompanionBuilder =
    ImportJobPhotosCompanion Function({
      Value<String> id,
      Value<String> jobId,
      Value<int> position,
      Value<String?> sourcePath,
      Value<String?> photoFile,
      Value<String?> thumbFile,
      Value<LocalDate> localDate,
      Value<int> secondsOfDay,
      Value<int?> offsetMinutes,
      Value<String?> dedupeKey,
      Value<String> state,
      Value<String?> failure,
      Value<int> rowid,
    });

class $$ImportJobPhotosTableFilterComposer
    extends Composer<_$AppDatabase, $ImportJobPhotosTable> {
  $$ImportJobPhotosTableFilterComposer({
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

  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoFile => $composableBuilder(
    column: $table.photoFile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbFile => $composableBuilder(
    column: $table.thumbFile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LocalDate, LocalDate, String> get localDate =>
      $composableBuilder(
        column: $table.localDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get secondsOfDay => $composableBuilder(
    column: $table.secondsOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dedupeKey => $composableBuilder(
    column: $table.dedupeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failure => $composableBuilder(
    column: $table.failure,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportJobPhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportJobPhotosTable> {
  $$ImportJobPhotosTableOrderingComposer({
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

  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoFile => $composableBuilder(
    column: $table.photoFile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbFile => $composableBuilder(
    column: $table.thumbFile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get secondsOfDay => $composableBuilder(
    column: $table.secondsOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dedupeKey => $composableBuilder(
    column: $table.dedupeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failure => $composableBuilder(
    column: $table.failure,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportJobPhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportJobPhotosTable> {
  $$ImportJobPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoFile =>
      $composableBuilder(column: $table.photoFile, builder: (column) => column);

  GeneratedColumn<String> get thumbFile =>
      $composableBuilder(column: $table.thumbFile, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocalDate, String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<int> get secondsOfDay => $composableBuilder(
    column: $table.secondsOfDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get offsetMinutes => $composableBuilder(
    column: $table.offsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dedupeKey =>
      $composableBuilder(column: $table.dedupeKey, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get failure =>
      $composableBuilder(column: $table.failure, builder: (column) => column);
}

class $$ImportJobPhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportJobPhotosTable,
          ImportJobPhotoRow,
          $$ImportJobPhotosTableFilterComposer,
          $$ImportJobPhotosTableOrderingComposer,
          $$ImportJobPhotosTableAnnotationComposer,
          $$ImportJobPhotosTableCreateCompanionBuilder,
          $$ImportJobPhotosTableUpdateCompanionBuilder,
          (
            ImportJobPhotoRow,
            BaseReferences<
              _$AppDatabase,
              $ImportJobPhotosTable,
              ImportJobPhotoRow
            >,
          ),
          ImportJobPhotoRow,
          PrefetchHooks Function()
        > {
  $$ImportJobPhotosTableTableManager(
    _$AppDatabase db,
    $ImportJobPhotosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportJobPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportJobPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportJobPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> jobId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> sourcePath = const Value.absent(),
                Value<String?> photoFile = const Value.absent(),
                Value<String?> thumbFile = const Value.absent(),
                Value<LocalDate> localDate = const Value.absent(),
                Value<int> secondsOfDay = const Value.absent(),
                Value<int?> offsetMinutes = const Value.absent(),
                Value<String?> dedupeKey = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> failure = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportJobPhotosCompanion(
                id: id,
                jobId: jobId,
                position: position,
                sourcePath: sourcePath,
                photoFile: photoFile,
                thumbFile: thumbFile,
                localDate: localDate,
                secondsOfDay: secondsOfDay,
                offsetMinutes: offsetMinutes,
                dedupeKey: dedupeKey,
                state: state,
                failure: failure,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String jobId,
                required int position,
                Value<String?> sourcePath = const Value.absent(),
                Value<String?> photoFile = const Value.absent(),
                Value<String?> thumbFile = const Value.absent(),
                required LocalDate localDate,
                required int secondsOfDay,
                Value<int?> offsetMinutes = const Value.absent(),
                Value<String?> dedupeKey = const Value.absent(),
                required String state,
                Value<String?> failure = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportJobPhotosCompanion.insert(
                id: id,
                jobId: jobId,
                position: position,
                sourcePath: sourcePath,
                photoFile: photoFile,
                thumbFile: thumbFile,
                localDate: localDate,
                secondsOfDay: secondsOfDay,
                offsetMinutes: offsetMinutes,
                dedupeKey: dedupeKey,
                state: state,
                failure: failure,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ImportJobPhotosTable, ImportJobPhotoRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ImportJobPhotosTable,
                    ImportJobPhotoRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportJobPhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportJobPhotosTable,
      ImportJobPhotoRow,
      $$ImportJobPhotosTableFilterComposer,
      $$ImportJobPhotosTableOrderingComposer,
      $$ImportJobPhotosTableAnnotationComposer,
      $$ImportJobPhotosTableCreateCompanionBuilder,
      $$ImportJobPhotosTableUpdateCompanionBuilder,
      (
        ImportJobPhotoRow,
        BaseReferences<_$AppDatabase, $ImportJobPhotosTable, ImportJobPhotoRow>,
      ),
      ImportJobPhotoRow,
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
  $$ImportJobsTableTableManager get importJobs =>
      $$ImportJobsTableTableManager(_db, _db.importJobs);
  $$ImportJobPhotosTableTableManager get importJobPhotos =>
      $$ImportJobPhotosTableTableManager(_db, _db.importJobPhotos);
}
