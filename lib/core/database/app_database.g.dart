// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UserProfilesTable extends UserProfiles
    with TableInfo<$UserProfilesTable, UserProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _currentRoleMeta = const VerificationMeta(
    'currentRole',
  );
  @override
  late final GeneratedColumn<String> currentRole = GeneratedColumn<String>(
    'current_role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _experienceYearsMeta = const VerificationMeta(
    'experienceYears',
  );
  @override
  late final GeneratedColumn<double> experienceYears = GeneratedColumn<double>(
    'experience_years',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _skillsMeta = const VerificationMeta('skills');
  @override
  late final GeneratedColumn<String> skills = GeneratedColumn<String>(
    'skills',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _programmingLanguagesMeta =
      const VerificationMeta('programmingLanguages');
  @override
  late final GeneratedColumn<String> programmingLanguages =
      GeneratedColumn<String>(
        'programming_languages',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _frameworksMeta = const VerificationMeta(
    'frameworks',
  );
  @override
  late final GeneratedColumn<String> frameworks = GeneratedColumn<String>(
    'frameworks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preferredRolesMeta = const VerificationMeta(
    'preferredRoles',
  );
  @override
  late final GeneratedColumn<String> preferredRoles = GeneratedColumn<String>(
    'preferred_roles',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preferredLocationsMeta =
      const VerificationMeta('preferredLocations');
  @override
  late final GeneratedColumn<String> preferredLocations =
      GeneratedColumn<String>(
        'preferred_locations',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _remotePreferenceMeta = const VerificationMeta(
    'remotePreference',
  );
  @override
  late final GeneratedColumn<String> remotePreference = GeneratedColumn<String>(
    'remote_preference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('any'),
  );
  static const VerificationMeta _expectedSalaryMeta = const VerificationMeta(
    'expectedSalary',
  );
  @override
  late final GeneratedColumn<String> expectedSalary = GeneratedColumn<String>(
    'expected_salary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preferredEmploymentTypeMeta =
      const VerificationMeta('preferredEmploymentType');
  @override
  late final GeneratedColumn<String> preferredEmploymentType =
      GeneratedColumn<String>(
        'preferred_employment_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _noticePeriodMeta = const VerificationMeta(
    'noticePeriod',
  );
  @override
  late final GeneratedColumn<String> noticePeriod = GeneratedColumn<String>(
    'notice_period',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _educationMeta = const VerificationMeta(
    'education',
  );
  @override
  late final GeneratedColumn<String> education = GeneratedColumn<String>(
    'education',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resumePreferencesMeta = const VerificationMeta(
    'resumePreferences',
  );
  @override
  late final GeneratedColumn<String> resumePreferences =
      GeneratedColumn<String>(
        'resume_preferences',
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
    name,
    currentRole,
    experienceYears,
    skills,
    programmingLanguages,
    frameworks,
    preferredRoles,
    preferredLocations,
    remotePreference,
    expectedSalary,
    preferredEmploymentType,
    noticePeriod,
    education,
    resumePreferences,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('current_role')) {
      context.handle(
        _currentRoleMeta,
        currentRole.isAcceptableOrUnknown(
          data['current_role']!,
          _currentRoleMeta,
        ),
      );
    }
    if (data.containsKey('experience_years')) {
      context.handle(
        _experienceYearsMeta,
        experienceYears.isAcceptableOrUnknown(
          data['experience_years']!,
          _experienceYearsMeta,
        ),
      );
    }
    if (data.containsKey('skills')) {
      context.handle(
        _skillsMeta,
        skills.isAcceptableOrUnknown(data['skills']!, _skillsMeta),
      );
    }
    if (data.containsKey('programming_languages')) {
      context.handle(
        _programmingLanguagesMeta,
        programmingLanguages.isAcceptableOrUnknown(
          data['programming_languages']!,
          _programmingLanguagesMeta,
        ),
      );
    }
    if (data.containsKey('frameworks')) {
      context.handle(
        _frameworksMeta,
        frameworks.isAcceptableOrUnknown(data['frameworks']!, _frameworksMeta),
      );
    }
    if (data.containsKey('preferred_roles')) {
      context.handle(
        _preferredRolesMeta,
        preferredRoles.isAcceptableOrUnknown(
          data['preferred_roles']!,
          _preferredRolesMeta,
        ),
      );
    }
    if (data.containsKey('preferred_locations')) {
      context.handle(
        _preferredLocationsMeta,
        preferredLocations.isAcceptableOrUnknown(
          data['preferred_locations']!,
          _preferredLocationsMeta,
        ),
      );
    }
    if (data.containsKey('remote_preference')) {
      context.handle(
        _remotePreferenceMeta,
        remotePreference.isAcceptableOrUnknown(
          data['remote_preference']!,
          _remotePreferenceMeta,
        ),
      );
    }
    if (data.containsKey('expected_salary')) {
      context.handle(
        _expectedSalaryMeta,
        expectedSalary.isAcceptableOrUnknown(
          data['expected_salary']!,
          _expectedSalaryMeta,
        ),
      );
    }
    if (data.containsKey('preferred_employment_type')) {
      context.handle(
        _preferredEmploymentTypeMeta,
        preferredEmploymentType.isAcceptableOrUnknown(
          data['preferred_employment_type']!,
          _preferredEmploymentTypeMeta,
        ),
      );
    }
    if (data.containsKey('notice_period')) {
      context.handle(
        _noticePeriodMeta,
        noticePeriod.isAcceptableOrUnknown(
          data['notice_period']!,
          _noticePeriodMeta,
        ),
      );
    }
    if (data.containsKey('education')) {
      context.handle(
        _educationMeta,
        education.isAcceptableOrUnknown(data['education']!, _educationMeta),
      );
    }
    if (data.containsKey('resume_preferences')) {
      context.handle(
        _resumePreferencesMeta,
        resumePreferences.isAcceptableOrUnknown(
          data['resume_preferences']!,
          _resumePreferencesMeta,
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
  UserProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      currentRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_role'],
      ),
      experienceYears: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}experience_years'],
      )!,
      skills: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skills'],
      ),
      programmingLanguages: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}programming_languages'],
      ),
      frameworks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frameworks'],
      ),
      preferredRoles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_roles'],
      ),
      preferredLocations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_locations'],
      ),
      remotePreference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_preference'],
      )!,
      expectedSalary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expected_salary'],
      ),
      preferredEmploymentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_employment_type'],
      ),
      noticePeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notice_period'],
      ),
      education: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}education'],
      ),
      resumePreferences: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resume_preferences'],
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
  $UserProfilesTable createAlias(String alias) {
    return $UserProfilesTable(attachedDatabase, alias);
  }
}

class UserProfile extends DataClass implements Insertable<UserProfile> {
  final String id;
  final String name;
  final String? currentRole;
  final double experienceYears;
  final String? skills;
  final String? programmingLanguages;
  final String? frameworks;
  final String? preferredRoles;
  final String? preferredLocations;
  final String remotePreference;
  final String? expectedSalary;
  final String? preferredEmploymentType;
  final String? noticePeriod;
  final String? education;
  final String? resumePreferences;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserProfile({
    required this.id,
    required this.name,
    this.currentRole,
    required this.experienceYears,
    this.skills,
    this.programmingLanguages,
    this.frameworks,
    this.preferredRoles,
    this.preferredLocations,
    required this.remotePreference,
    this.expectedSalary,
    this.preferredEmploymentType,
    this.noticePeriod,
    this.education,
    this.resumePreferences,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || currentRole != null) {
      map['current_role'] = Variable<String>(currentRole);
    }
    map['experience_years'] = Variable<double>(experienceYears);
    if (!nullToAbsent || skills != null) {
      map['skills'] = Variable<String>(skills);
    }
    if (!nullToAbsent || programmingLanguages != null) {
      map['programming_languages'] = Variable<String>(programmingLanguages);
    }
    if (!nullToAbsent || frameworks != null) {
      map['frameworks'] = Variable<String>(frameworks);
    }
    if (!nullToAbsent || preferredRoles != null) {
      map['preferred_roles'] = Variable<String>(preferredRoles);
    }
    if (!nullToAbsent || preferredLocations != null) {
      map['preferred_locations'] = Variable<String>(preferredLocations);
    }
    map['remote_preference'] = Variable<String>(remotePreference);
    if (!nullToAbsent || expectedSalary != null) {
      map['expected_salary'] = Variable<String>(expectedSalary);
    }
    if (!nullToAbsent || preferredEmploymentType != null) {
      map['preferred_employment_type'] = Variable<String>(
        preferredEmploymentType,
      );
    }
    if (!nullToAbsent || noticePeriod != null) {
      map['notice_period'] = Variable<String>(noticePeriod);
    }
    if (!nullToAbsent || education != null) {
      map['education'] = Variable<String>(education);
    }
    if (!nullToAbsent || resumePreferences != null) {
      map['resume_preferences'] = Variable<String>(resumePreferences);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserProfilesCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesCompanion(
      id: Value(id),
      name: Value(name),
      currentRole: currentRole == null && nullToAbsent
          ? const Value.absent()
          : Value(currentRole),
      experienceYears: Value(experienceYears),
      skills: skills == null && nullToAbsent
          ? const Value.absent()
          : Value(skills),
      programmingLanguages: programmingLanguages == null && nullToAbsent
          ? const Value.absent()
          : Value(programmingLanguages),
      frameworks: frameworks == null && nullToAbsent
          ? const Value.absent()
          : Value(frameworks),
      preferredRoles: preferredRoles == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredRoles),
      preferredLocations: preferredLocations == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredLocations),
      remotePreference: Value(remotePreference),
      expectedSalary: expectedSalary == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedSalary),
      preferredEmploymentType: preferredEmploymentType == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredEmploymentType),
      noticePeriod: noticePeriod == null && nullToAbsent
          ? const Value.absent()
          : Value(noticePeriod),
      education: education == null && nullToAbsent
          ? const Value.absent()
          : Value(education),
      resumePreferences: resumePreferences == null && nullToAbsent
          ? const Value.absent()
          : Value(resumePreferences),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      currentRole: serializer.fromJson<String?>(json['currentRole']),
      experienceYears: serializer.fromJson<double>(json['experienceYears']),
      skills: serializer.fromJson<String?>(json['skills']),
      programmingLanguages: serializer.fromJson<String?>(
        json['programmingLanguages'],
      ),
      frameworks: serializer.fromJson<String?>(json['frameworks']),
      preferredRoles: serializer.fromJson<String?>(json['preferredRoles']),
      preferredLocations: serializer.fromJson<String?>(
        json['preferredLocations'],
      ),
      remotePreference: serializer.fromJson<String>(json['remotePreference']),
      expectedSalary: serializer.fromJson<String?>(json['expectedSalary']),
      preferredEmploymentType: serializer.fromJson<String?>(
        json['preferredEmploymentType'],
      ),
      noticePeriod: serializer.fromJson<String?>(json['noticePeriod']),
      education: serializer.fromJson<String?>(json['education']),
      resumePreferences: serializer.fromJson<String?>(
        json['resumePreferences'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'currentRole': serializer.toJson<String?>(currentRole),
      'experienceYears': serializer.toJson<double>(experienceYears),
      'skills': serializer.toJson<String?>(skills),
      'programmingLanguages': serializer.toJson<String?>(programmingLanguages),
      'frameworks': serializer.toJson<String?>(frameworks),
      'preferredRoles': serializer.toJson<String?>(preferredRoles),
      'preferredLocations': serializer.toJson<String?>(preferredLocations),
      'remotePreference': serializer.toJson<String>(remotePreference),
      'expectedSalary': serializer.toJson<String?>(expectedSalary),
      'preferredEmploymentType': serializer.toJson<String?>(
        preferredEmploymentType,
      ),
      'noticePeriod': serializer.toJson<String?>(noticePeriod),
      'education': serializer.toJson<String?>(education),
      'resumePreferences': serializer.toJson<String?>(resumePreferences),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    Value<String?> currentRole = const Value.absent(),
    double? experienceYears,
    Value<String?> skills = const Value.absent(),
    Value<String?> programmingLanguages = const Value.absent(),
    Value<String?> frameworks = const Value.absent(),
    Value<String?> preferredRoles = const Value.absent(),
    Value<String?> preferredLocations = const Value.absent(),
    String? remotePreference,
    Value<String?> expectedSalary = const Value.absent(),
    Value<String?> preferredEmploymentType = const Value.absent(),
    Value<String?> noticePeriod = const Value.absent(),
    Value<String?> education = const Value.absent(),
    Value<String?> resumePreferences = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    currentRole: currentRole.present ? currentRole.value : this.currentRole,
    experienceYears: experienceYears ?? this.experienceYears,
    skills: skills.present ? skills.value : this.skills,
    programmingLanguages: programmingLanguages.present
        ? programmingLanguages.value
        : this.programmingLanguages,
    frameworks: frameworks.present ? frameworks.value : this.frameworks,
    preferredRoles: preferredRoles.present
        ? preferredRoles.value
        : this.preferredRoles,
    preferredLocations: preferredLocations.present
        ? preferredLocations.value
        : this.preferredLocations,
    remotePreference: remotePreference ?? this.remotePreference,
    expectedSalary: expectedSalary.present
        ? expectedSalary.value
        : this.expectedSalary,
    preferredEmploymentType: preferredEmploymentType.present
        ? preferredEmploymentType.value
        : this.preferredEmploymentType,
    noticePeriod: noticePeriod.present ? noticePeriod.value : this.noticePeriod,
    education: education.present ? education.value : this.education,
    resumePreferences: resumePreferences.present
        ? resumePreferences.value
        : this.resumePreferences,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserProfile copyWithCompanion(UserProfilesCompanion data) {
    return UserProfile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      currentRole: data.currentRole.present
          ? data.currentRole.value
          : this.currentRole,
      experienceYears: data.experienceYears.present
          ? data.experienceYears.value
          : this.experienceYears,
      skills: data.skills.present ? data.skills.value : this.skills,
      programmingLanguages: data.programmingLanguages.present
          ? data.programmingLanguages.value
          : this.programmingLanguages,
      frameworks: data.frameworks.present
          ? data.frameworks.value
          : this.frameworks,
      preferredRoles: data.preferredRoles.present
          ? data.preferredRoles.value
          : this.preferredRoles,
      preferredLocations: data.preferredLocations.present
          ? data.preferredLocations.value
          : this.preferredLocations,
      remotePreference: data.remotePreference.present
          ? data.remotePreference.value
          : this.remotePreference,
      expectedSalary: data.expectedSalary.present
          ? data.expectedSalary.value
          : this.expectedSalary,
      preferredEmploymentType: data.preferredEmploymentType.present
          ? data.preferredEmploymentType.value
          : this.preferredEmploymentType,
      noticePeriod: data.noticePeriod.present
          ? data.noticePeriod.value
          : this.noticePeriod,
      education: data.education.present ? data.education.value : this.education,
      resumePreferences: data.resumePreferences.present
          ? data.resumePreferences.value
          : this.resumePreferences,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('currentRole: $currentRole, ')
          ..write('experienceYears: $experienceYears, ')
          ..write('skills: $skills, ')
          ..write('programmingLanguages: $programmingLanguages, ')
          ..write('frameworks: $frameworks, ')
          ..write('preferredRoles: $preferredRoles, ')
          ..write('preferredLocations: $preferredLocations, ')
          ..write('remotePreference: $remotePreference, ')
          ..write('expectedSalary: $expectedSalary, ')
          ..write('preferredEmploymentType: $preferredEmploymentType, ')
          ..write('noticePeriod: $noticePeriod, ')
          ..write('education: $education, ')
          ..write('resumePreferences: $resumePreferences, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    currentRole,
    experienceYears,
    skills,
    programmingLanguages,
    frameworks,
    preferredRoles,
    preferredLocations,
    remotePreference,
    expectedSalary,
    preferredEmploymentType,
    noticePeriod,
    education,
    resumePreferences,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfile &&
          other.id == this.id &&
          other.name == this.name &&
          other.currentRole == this.currentRole &&
          other.experienceYears == this.experienceYears &&
          other.skills == this.skills &&
          other.programmingLanguages == this.programmingLanguages &&
          other.frameworks == this.frameworks &&
          other.preferredRoles == this.preferredRoles &&
          other.preferredLocations == this.preferredLocations &&
          other.remotePreference == this.remotePreference &&
          other.expectedSalary == this.expectedSalary &&
          other.preferredEmploymentType == this.preferredEmploymentType &&
          other.noticePeriod == this.noticePeriod &&
          other.education == this.education &&
          other.resumePreferences == this.resumePreferences &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserProfilesCompanion extends UpdateCompanion<UserProfile> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> currentRole;
  final Value<double> experienceYears;
  final Value<String?> skills;
  final Value<String?> programmingLanguages;
  final Value<String?> frameworks;
  final Value<String?> preferredRoles;
  final Value<String?> preferredLocations;
  final Value<String> remotePreference;
  final Value<String?> expectedSalary;
  final Value<String?> preferredEmploymentType;
  final Value<String?> noticePeriod;
  final Value<String?> education;
  final Value<String?> resumePreferences;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.currentRole = const Value.absent(),
    this.experienceYears = const Value.absent(),
    this.skills = const Value.absent(),
    this.programmingLanguages = const Value.absent(),
    this.frameworks = const Value.absent(),
    this.preferredRoles = const Value.absent(),
    this.preferredLocations = const Value.absent(),
    this.remotePreference = const Value.absent(),
    this.expectedSalary = const Value.absent(),
    this.preferredEmploymentType = const Value.absent(),
    this.noticePeriod = const Value.absent(),
    this.education = const Value.absent(),
    this.resumePreferences = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserProfilesCompanion.insert({
    required String id,
    required String name,
    this.currentRole = const Value.absent(),
    this.experienceYears = const Value.absent(),
    this.skills = const Value.absent(),
    this.programmingLanguages = const Value.absent(),
    this.frameworks = const Value.absent(),
    this.preferredRoles = const Value.absent(),
    this.preferredLocations = const Value.absent(),
    this.remotePreference = const Value.absent(),
    this.expectedSalary = const Value.absent(),
    this.preferredEmploymentType = const Value.absent(),
    this.noticePeriod = const Value.absent(),
    this.education = const Value.absent(),
    this.resumePreferences = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<UserProfile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? currentRole,
    Expression<double>? experienceYears,
    Expression<String>? skills,
    Expression<String>? programmingLanguages,
    Expression<String>? frameworks,
    Expression<String>? preferredRoles,
    Expression<String>? preferredLocations,
    Expression<String>? remotePreference,
    Expression<String>? expectedSalary,
    Expression<String>? preferredEmploymentType,
    Expression<String>? noticePeriod,
    Expression<String>? education,
    Expression<String>? resumePreferences,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (currentRole != null) 'current_role': currentRole,
      if (experienceYears != null) 'experience_years': experienceYears,
      if (skills != null) 'skills': skills,
      if (programmingLanguages != null)
        'programming_languages': programmingLanguages,
      if (frameworks != null) 'frameworks': frameworks,
      if (preferredRoles != null) 'preferred_roles': preferredRoles,
      if (preferredLocations != null) 'preferred_locations': preferredLocations,
      if (remotePreference != null) 'remote_preference': remotePreference,
      if (expectedSalary != null) 'expected_salary': expectedSalary,
      if (preferredEmploymentType != null)
        'preferred_employment_type': preferredEmploymentType,
      if (noticePeriod != null) 'notice_period': noticePeriod,
      if (education != null) 'education': education,
      if (resumePreferences != null) 'resume_preferences': resumePreferences,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? currentRole,
    Value<double>? experienceYears,
    Value<String?>? skills,
    Value<String?>? programmingLanguages,
    Value<String?>? frameworks,
    Value<String?>? preferredRoles,
    Value<String?>? preferredLocations,
    Value<String>? remotePreference,
    Value<String?>? expectedSalary,
    Value<String?>? preferredEmploymentType,
    Value<String?>? noticePeriod,
    Value<String?>? education,
    Value<String?>? resumePreferences,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      currentRole: currentRole ?? this.currentRole,
      experienceYears: experienceYears ?? this.experienceYears,
      skills: skills ?? this.skills,
      programmingLanguages: programmingLanguages ?? this.programmingLanguages,
      frameworks: frameworks ?? this.frameworks,
      preferredRoles: preferredRoles ?? this.preferredRoles,
      preferredLocations: preferredLocations ?? this.preferredLocations,
      remotePreference: remotePreference ?? this.remotePreference,
      expectedSalary: expectedSalary ?? this.expectedSalary,
      preferredEmploymentType:
          preferredEmploymentType ?? this.preferredEmploymentType,
      noticePeriod: noticePeriod ?? this.noticePeriod,
      education: education ?? this.education,
      resumePreferences: resumePreferences ?? this.resumePreferences,
      createdAt: createdAt ?? this.createdAt,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (currentRole.present) {
      map['current_role'] = Variable<String>(currentRole.value);
    }
    if (experienceYears.present) {
      map['experience_years'] = Variable<double>(experienceYears.value);
    }
    if (skills.present) {
      map['skills'] = Variable<String>(skills.value);
    }
    if (programmingLanguages.present) {
      map['programming_languages'] = Variable<String>(
        programmingLanguages.value,
      );
    }
    if (frameworks.present) {
      map['frameworks'] = Variable<String>(frameworks.value);
    }
    if (preferredRoles.present) {
      map['preferred_roles'] = Variable<String>(preferredRoles.value);
    }
    if (preferredLocations.present) {
      map['preferred_locations'] = Variable<String>(preferredLocations.value);
    }
    if (remotePreference.present) {
      map['remote_preference'] = Variable<String>(remotePreference.value);
    }
    if (expectedSalary.present) {
      map['expected_salary'] = Variable<String>(expectedSalary.value);
    }
    if (preferredEmploymentType.present) {
      map['preferred_employment_type'] = Variable<String>(
        preferredEmploymentType.value,
      );
    }
    if (noticePeriod.present) {
      map['notice_period'] = Variable<String>(noticePeriod.value);
    }
    if (education.present) {
      map['education'] = Variable<String>(education.value);
    }
    if (resumePreferences.present) {
      map['resume_preferences'] = Variable<String>(resumePreferences.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('currentRole: $currentRole, ')
          ..write('experienceYears: $experienceYears, ')
          ..write('skills: $skills, ')
          ..write('programmingLanguages: $programmingLanguages, ')
          ..write('frameworks: $frameworks, ')
          ..write('preferredRoles: $preferredRoles, ')
          ..write('preferredLocations: $preferredLocations, ')
          ..write('remotePreference: $remotePreference, ')
          ..write('expectedSalary: $expectedSalary, ')
          ..write('preferredEmploymentType: $preferredEmploymentType, ')
          ..write('noticePeriod: $noticePeriod, ')
          ..write('education: $education, ')
          ..write('resumePreferences: $resumePreferences, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 150,
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('in_progress'),
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _techStackMeta = const VerificationMeta(
    'techStack',
  );
  @override
  late final GeneratedColumn<String> techStack = GeneratedColumn<String>(
    'tech_stack',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _githubUrlMeta = const VerificationMeta(
    'githubUrl',
  );
  @override
  late final GeneratedColumn<String> githubUrl = GeneratedColumn<String>(
    'github_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _liveUrlMeta = const VerificationMeta(
    'liveUrl',
  );
  @override
  late final GeneratedColumn<String> liveUrl = GeneratedColumn<String>(
    'live_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deadlineMeta = const VerificationMeta(
    'deadline',
  );
  @override
  late final GeneratedColumn<DateTime> deadline = GeneratedColumn<DateTime>(
    'deadline',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
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
    name,
    description,
    status,
    progress,
    techStack,
    githubUrl,
    liveUrl,
    deadline,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Project> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
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
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('tech_stack')) {
      context.handle(
        _techStackMeta,
        techStack.isAcceptableOrUnknown(data['tech_stack']!, _techStackMeta),
      );
    }
    if (data.containsKey('github_url')) {
      context.handle(
        _githubUrlMeta,
        githubUrl.isAcceptableOrUnknown(data['github_url']!, _githubUrlMeta),
      );
    }
    if (data.containsKey('live_url')) {
      context.handle(
        _liveUrlMeta,
        liveUrl.isAcceptableOrUnknown(data['live_url']!, _liveUrlMeta),
      );
    }
    if (data.containsKey('deadline')) {
      context.handle(
        _deadlineMeta,
        deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
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
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      techStack: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tech_stack'],
      ),
      githubUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}github_url'],
      ),
      liveUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}live_url'],
      ),
      deadline: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deadline'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
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
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final String id;
  final String name;
  final String? description;
  final String status;
  final double progress;
  final String? techStack;
  final String? githubUrl;
  final String? liveUrl;
  final DateTime? deadline;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Project({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    required this.progress,
    this.techStack,
    this.githubUrl,
    this.liveUrl,
    this.deadline,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['status'] = Variable<String>(status);
    map['progress'] = Variable<double>(progress);
    if (!nullToAbsent || techStack != null) {
      map['tech_stack'] = Variable<String>(techStack);
    }
    if (!nullToAbsent || githubUrl != null) {
      map['github_url'] = Variable<String>(githubUrl);
    }
    if (!nullToAbsent || liveUrl != null) {
      map['live_url'] = Variable<String>(liveUrl);
    }
    if (!nullToAbsent || deadline != null) {
      map['deadline'] = Variable<DateTime>(deadline);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      status: Value(status),
      progress: Value(progress),
      techStack: techStack == null && nullToAbsent
          ? const Value.absent()
          : Value(techStack),
      githubUrl: githubUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(githubUrl),
      liveUrl: liveUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(liveUrl),
      deadline: deadline == null && nullToAbsent
          ? const Value.absent()
          : Value(deadline),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Project.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      status: serializer.fromJson<String>(json['status']),
      progress: serializer.fromJson<double>(json['progress']),
      techStack: serializer.fromJson<String?>(json['techStack']),
      githubUrl: serializer.fromJson<String?>(json['githubUrl']),
      liveUrl: serializer.fromJson<String?>(json['liveUrl']),
      deadline: serializer.fromJson<DateTime?>(json['deadline']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'status': serializer.toJson<String>(status),
      'progress': serializer.toJson<double>(progress),
      'techStack': serializer.toJson<String?>(techStack),
      'githubUrl': serializer.toJson<String?>(githubUrl),
      'liveUrl': serializer.toJson<String?>(liveUrl),
      'deadline': serializer.toJson<DateTime?>(deadline),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Project copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    String? status,
    double? progress,
    Value<String?> techStack = const Value.absent(),
    Value<String?> githubUrl = const Value.absent(),
    Value<String?> liveUrl = const Value.absent(),
    Value<DateTime?> deadline = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Project(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    techStack: techStack.present ? techStack.value : this.techStack,
    githubUrl: githubUrl.present ? githubUrl.value : this.githubUrl,
    liveUrl: liveUrl.present ? liveUrl.value : this.liveUrl,
    deadline: deadline.present ? deadline.value : this.deadline,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      status: data.status.present ? data.status.value : this.status,
      progress: data.progress.present ? data.progress.value : this.progress,
      techStack: data.techStack.present ? data.techStack.value : this.techStack,
      githubUrl: data.githubUrl.present ? data.githubUrl.value : this.githubUrl,
      liveUrl: data.liveUrl.present ? data.liveUrl.value : this.liveUrl,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('techStack: $techStack, ')
          ..write('githubUrl: $githubUrl, ')
          ..write('liveUrl: $liveUrl, ')
          ..write('deadline: $deadline, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    status,
    progress,
    techStack,
    githubUrl,
    liveUrl,
    deadline,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.status == this.status &&
          other.progress == this.progress &&
          other.techStack == this.techStack &&
          other.githubUrl == this.githubUrl &&
          other.liveUrl == this.liveUrl &&
          other.deadline == this.deadline &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> status;
  final Value<double> progress;
  final Value<String?> techStack;
  final Value<String?> githubUrl;
  final Value<String?> liveUrl;
  final Value<DateTime?> deadline;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.techStack = const Value.absent(),
    this.githubUrl = const Value.absent(),
    this.liveUrl = const Value.absent(),
    this.deadline = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.techStack = const Value.absent(),
    this.githubUrl = const Value.absent(),
    this.liveUrl = const Value.absent(),
    this.deadline = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Project> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? status,
    Expression<double>? progress,
    Expression<String>? techStack,
    Expression<String>? githubUrl,
    Expression<String>? liveUrl,
    Expression<DateTime>? deadline,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (techStack != null) 'tech_stack': techStack,
      if (githubUrl != null) 'github_url': githubUrl,
      if (liveUrl != null) 'live_url': liveUrl,
      if (deadline != null) 'deadline': deadline,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? status,
    Value<double>? progress,
    Value<String?>? techStack,
    Value<String?>? githubUrl,
    Value<String?>? liveUrl,
    Value<DateTime?>? deadline,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      techStack: techStack ?? this.techStack,
      githubUrl: githubUrl ?? this.githubUrl,
      liveUrl: liveUrl ?? this.liveUrl,
      deadline: deadline ?? this.deadline,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (techStack.present) {
      map['tech_stack'] = Variable<String>(techStack.value);
    }
    if (githubUrl.present) {
      map['github_url'] = Variable<String>(githubUrl.value);
    }
    if (liveUrl.present) {
      map['live_url'] = Variable<String>(liveUrl.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<DateTime>(deadline.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('techStack: $techStack, ')
          ..write('githubUrl: $githubUrl, ')
          ..write('liveUrl: $liveUrl, ')
          ..write('deadline: $deadline, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 250,
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
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('todo'),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('work'),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES projects (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
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
    title,
    description,
    priority,
    status,
    category,
    projectId,
    notes,
    dueDate,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
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
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
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
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
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
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String title;
  final String? description;
  final String priority;
  final String status;
  final String category;
  final String? projectId;
  final String? notes;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    required this.category,
    this.projectId,
    this.notes,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['priority'] = Variable<String>(priority);
    map['status'] = Variable<String>(status);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      priority: Value(priority),
      status: Value(status),
      category: Value(category),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      priority: serializer.fromJson<String>(json['priority']),
      status: serializer.fromJson<String>(json['status']),
      category: serializer.fromJson<String>(json['category']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      notes: serializer.fromJson<String?>(json['notes']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'priority': serializer.toJson<String>(priority),
      'status': serializer.toJson<String>(status),
      'category': serializer.toJson<String>(category),
      'projectId': serializer.toJson<String?>(projectId),
      'notes': serializer.toJson<String?>(notes),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    Value<String?> description = const Value.absent(),
    String? priority,
    String? status,
    String? category,
    Value<String?> projectId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<DateTime?> dueDate = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    category: category ?? this.category,
    projectId: projectId.present ? projectId.value : this.projectId,
    notes: notes.present ? notes.value : this.notes,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      category: data.category.present ? data.category.value : this.category,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      notes: data.notes.present ? data.notes.value : this.notes,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('category: $category, ')
          ..write('projectId: $projectId, ')
          ..write('notes: $notes, ')
          ..write('dueDate: $dueDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    priority,
    status,
    category,
    projectId,
    notes,
    dueDate,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.category == this.category &&
          other.projectId == this.projectId &&
          other.notes == this.notes &&
          other.dueDate == this.dueDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> priority;
  final Value<String> status;
  final Value<String> category;
  final Value<String?> projectId;
  final Value<String?> notes;
  final Value<DateTime?> dueDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.category = const Value.absent(),
    this.projectId = const Value.absent(),
    this.notes = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.category = const Value.absent(),
    this.projectId = const Value.absent(),
    this.notes = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? priority,
    Expression<String>? status,
    Expression<String>? category,
    Expression<String>? projectId,
    Expression<String>? notes,
    Expression<DateTime>? dueDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (category != null) 'category': category,
      if (projectId != null) 'project_id': projectId,
      if (notes != null) 'notes': notes,
      if (dueDate != null) 'due_date': dueDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? priority,
    Value<String>? status,
    Value<String>? category,
    Value<String?>? projectId,
    Value<String?>? notes,
    Value<DateTime?>? dueDate,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      category: category ?? this.category,
      projectId: projectId ?? this.projectId,
      notes: notes ?? this.notes,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('category: $category, ')
          ..write('projectId: $projectId, ')
          ..write('notes: $notes, ')
          ..write('dueDate: $dueDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ResumesTable extends Resumes with TableInfo<$ResumesTable, Resume> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ResumesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 150,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('v1.0'),
  );
  static const VerificationMeta _targetRoleMeta = const VerificationMeta(
    'targetRole',
  );
  @override
  late final GeneratedColumn<String> targetRole = GeneratedColumn<String>(
    'target_role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
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
    name,
    version,
    targetRole,
    filePath,
    fileName,
    notes,
    isPrimary,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'resumes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Resume> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('target_role')) {
      context.handle(
        _targetRoleMeta,
        targetRole.isAcceptableOrUnknown(data['target_role']!, _targetRoleMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
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
  Resume map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Resume(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      targetRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_role'],
      ),
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
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
  $ResumesTable createAlias(String alias) {
    return $ResumesTable(attachedDatabase, alias);
  }
}

class Resume extends DataClass implements Insertable<Resume> {
  final String id;
  final String name;
  final String version;
  final String? targetRole;
  final String filePath;
  final String fileName;
  final String? notes;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Resume({
    required this.id,
    required this.name,
    required this.version,
    this.targetRole,
    required this.filePath,
    required this.fileName,
    this.notes,
    required this.isPrimary,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['version'] = Variable<String>(version);
    if (!nullToAbsent || targetRole != null) {
      map['target_role'] = Variable<String>(targetRole);
    }
    map['file_path'] = Variable<String>(filePath);
    map['file_name'] = Variable<String>(fileName);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_primary'] = Variable<bool>(isPrimary);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ResumesCompanion toCompanion(bool nullToAbsent) {
    return ResumesCompanion(
      id: Value(id),
      name: Value(name),
      version: Value(version),
      targetRole: targetRole == null && nullToAbsent
          ? const Value.absent()
          : Value(targetRole),
      filePath: Value(filePath),
      fileName: Value(fileName),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isPrimary: Value(isPrimary),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Resume.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Resume(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      version: serializer.fromJson<String>(json['version']),
      targetRole: serializer.fromJson<String?>(json['targetRole']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileName: serializer.fromJson<String>(json['fileName']),
      notes: serializer.fromJson<String?>(json['notes']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'version': serializer.toJson<String>(version),
      'targetRole': serializer.toJson<String?>(targetRole),
      'filePath': serializer.toJson<String>(filePath),
      'fileName': serializer.toJson<String>(fileName),
      'notes': serializer.toJson<String?>(notes),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Resume copyWith({
    String? id,
    String? name,
    String? version,
    Value<String?> targetRole = const Value.absent(),
    String? filePath,
    String? fileName,
    Value<String?> notes = const Value.absent(),
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Resume(
    id: id ?? this.id,
    name: name ?? this.name,
    version: version ?? this.version,
    targetRole: targetRole.present ? targetRole.value : this.targetRole,
    filePath: filePath ?? this.filePath,
    fileName: fileName ?? this.fileName,
    notes: notes.present ? notes.value : this.notes,
    isPrimary: isPrimary ?? this.isPrimary,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Resume copyWithCompanion(ResumesCompanion data) {
    return Resume(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      version: data.version.present ? data.version.value : this.version,
      targetRole: data.targetRole.present
          ? data.targetRole.value
          : this.targetRole,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      notes: data.notes.present ? data.notes.value : this.notes,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Resume(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('version: $version, ')
          ..write('targetRole: $targetRole, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('notes: $notes, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    version,
    targetRole,
    filePath,
    fileName,
    notes,
    isPrimary,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Resume &&
          other.id == this.id &&
          other.name == this.name &&
          other.version == this.version &&
          other.targetRole == this.targetRole &&
          other.filePath == this.filePath &&
          other.fileName == this.fileName &&
          other.notes == this.notes &&
          other.isPrimary == this.isPrimary &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ResumesCompanion extends UpdateCompanion<Resume> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> version;
  final Value<String?> targetRole;
  final Value<String> filePath;
  final Value<String> fileName;
  final Value<String?> notes;
  final Value<bool> isPrimary;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ResumesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.version = const Value.absent(),
    this.targetRole = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileName = const Value.absent(),
    this.notes = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ResumesCompanion.insert({
    required String id,
    required String name,
    this.version = const Value.absent(),
    this.targetRole = const Value.absent(),
    required String filePath,
    required String fileName,
    this.notes = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       filePath = Value(filePath),
       fileName = Value(fileName);
  static Insertable<Resume> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? version,
    Expression<String>? targetRole,
    Expression<String>? filePath,
    Expression<String>? fileName,
    Expression<String>? notes,
    Expression<bool>? isPrimary,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (version != null) 'version': version,
      if (targetRole != null) 'target_role': targetRole,
      if (filePath != null) 'file_path': filePath,
      if (fileName != null) 'file_name': fileName,
      if (notes != null) 'notes': notes,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ResumesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? version,
    Value<String?>? targetRole,
    Value<String>? filePath,
    Value<String>? fileName,
    Value<String?>? notes,
    Value<bool>? isPrimary,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ResumesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      targetRole: targetRole ?? this.targetRole,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      notes: notes ?? this.notes,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (targetRole.present) {
      map['target_role'] = Variable<String>(targetRole.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ResumesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('version: $version, ')
          ..write('targetRole: $targetRole, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('notes: $notes, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JobsTable extends Jobs with TableInfo<$JobsTable, Job> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobsTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyMeta = const VerificationMeta(
    'company',
  );
  @override
  late final GeneratedColumn<String> company = GeneratedColumn<String>(
    'company',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 150,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _salaryMeta = const VerificationMeta('salary');
  @override
  late final GeneratedColumn<String> salary = GeneratedColumn<String>(
    'salary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _employmentTypeMeta = const VerificationMeta(
    'employmentType',
  );
  @override
  late final GeneratedColumn<String> employmentType = GeneratedColumn<String>(
    'employment_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _experienceRequirementMeta =
      const VerificationMeta('experienceRequirement');
  @override
  late final GeneratedColumn<String> experienceRequirement =
      GeneratedColumn<String>(
        'experience_requirement',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _skillsMeta = const VerificationMeta('skills');
  @override
  late final GeneratedColumn<String> skills = GeneratedColumn<String>(
    'skills',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _postedDateMeta = const VerificationMeta(
    'postedDate',
  );
  @override
  late final GeneratedColumn<DateTime> postedDate = GeneratedColumn<DateTime>(
    'posted_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _discoveredAtMeta = const VerificationMeta(
    'discoveredAt',
  );
  @override
  late final GeneratedColumn<DateTime> discoveredAt = GeneratedColumn<DateTime>(
    'discovered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isSavedMeta = const VerificationMeta(
    'isSaved',
  );
  @override
  late final GeneratedColumn<bool> isSaved = GeneratedColumn<bool>(
    'is_saved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_saved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
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
    title,
    company,
    location,
    salary,
    employmentType,
    experienceRequirement,
    url,
    source,
    description,
    skills,
    postedDate,
    discoveredAt,
    isSaved,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Job> instance, {
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
    if (data.containsKey('company')) {
      context.handle(
        _companyMeta,
        company.isAcceptableOrUnknown(data['company']!, _companyMeta),
      );
    } else if (isInserting) {
      context.missing(_companyMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('salary')) {
      context.handle(
        _salaryMeta,
        salary.isAcceptableOrUnknown(data['salary']!, _salaryMeta),
      );
    }
    if (data.containsKey('employment_type')) {
      context.handle(
        _employmentTypeMeta,
        employmentType.isAcceptableOrUnknown(
          data['employment_type']!,
          _employmentTypeMeta,
        ),
      );
    }
    if (data.containsKey('experience_requirement')) {
      context.handle(
        _experienceRequirementMeta,
        experienceRequirement.isAcceptableOrUnknown(
          data['experience_requirement']!,
          _experienceRequirementMeta,
        ),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
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
    if (data.containsKey('skills')) {
      context.handle(
        _skillsMeta,
        skills.isAcceptableOrUnknown(data['skills']!, _skillsMeta),
      );
    }
    if (data.containsKey('posted_date')) {
      context.handle(
        _postedDateMeta,
        postedDate.isAcceptableOrUnknown(data['posted_date']!, _postedDateMeta),
      );
    }
    if (data.containsKey('discovered_at')) {
      context.handle(
        _discoveredAtMeta,
        discoveredAt.isAcceptableOrUnknown(
          data['discovered_at']!,
          _discoveredAtMeta,
        ),
      );
    }
    if (data.containsKey('is_saved')) {
      context.handle(
        _isSavedMeta,
        isSaved.isAcceptableOrUnknown(data['is_saved']!, _isSavedMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
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
  Job map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Job(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      company: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      salary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}salary'],
      ),
      employmentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employment_type'],
      ),
      experienceRequirement: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}experience_requirement'],
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      skills: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skills'],
      ),
      postedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}posted_date'],
      ),
      discoveredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}discovered_at'],
      )!,
      isSaved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_saved'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
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
  $JobsTable createAlias(String alias) {
    return $JobsTable(attachedDatabase, alias);
  }
}

class Job extends DataClass implements Insertable<Job> {
  final String id;
  final String title;
  final String company;
  final String? location;
  final String? salary;
  final String? employmentType;
  final String? experienceRequirement;
  final String? url;
  final String? source;
  final String? description;
  final String? skills;
  final DateTime? postedDate;
  final DateTime discoveredAt;
  final bool isSaved;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Job({
    required this.id,
    required this.title,
    required this.company,
    this.location,
    this.salary,
    this.employmentType,
    this.experienceRequirement,
    this.url,
    this.source,
    this.description,
    this.skills,
    this.postedDate,
    required this.discoveredAt,
    required this.isSaved,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['company'] = Variable<String>(company);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || salary != null) {
      map['salary'] = Variable<String>(salary);
    }
    if (!nullToAbsent || employmentType != null) {
      map['employment_type'] = Variable<String>(employmentType);
    }
    if (!nullToAbsent || experienceRequirement != null) {
      map['experience_requirement'] = Variable<String>(experienceRequirement);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || skills != null) {
      map['skills'] = Variable<String>(skills);
    }
    if (!nullToAbsent || postedDate != null) {
      map['posted_date'] = Variable<DateTime>(postedDate);
    }
    map['discovered_at'] = Variable<DateTime>(discoveredAt);
    map['is_saved'] = Variable<bool>(isSaved);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  JobsCompanion toCompanion(bool nullToAbsent) {
    return JobsCompanion(
      id: Value(id),
      title: Value(title),
      company: Value(company),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      salary: salary == null && nullToAbsent
          ? const Value.absent()
          : Value(salary),
      employmentType: employmentType == null && nullToAbsent
          ? const Value.absent()
          : Value(employmentType),
      experienceRequirement: experienceRequirement == null && nullToAbsent
          ? const Value.absent()
          : Value(experienceRequirement),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      skills: skills == null && nullToAbsent
          ? const Value.absent()
          : Value(skills),
      postedDate: postedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(postedDate),
      discoveredAt: Value(discoveredAt),
      isSaved: Value(isSaved),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Job.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Job(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      company: serializer.fromJson<String>(json['company']),
      location: serializer.fromJson<String?>(json['location']),
      salary: serializer.fromJson<String?>(json['salary']),
      employmentType: serializer.fromJson<String?>(json['employmentType']),
      experienceRequirement: serializer.fromJson<String?>(
        json['experienceRequirement'],
      ),
      url: serializer.fromJson<String?>(json['url']),
      source: serializer.fromJson<String?>(json['source']),
      description: serializer.fromJson<String?>(json['description']),
      skills: serializer.fromJson<String?>(json['skills']),
      postedDate: serializer.fromJson<DateTime?>(json['postedDate']),
      discoveredAt: serializer.fromJson<DateTime>(json['discoveredAt']),
      isSaved: serializer.fromJson<bool>(json['isSaved']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'company': serializer.toJson<String>(company),
      'location': serializer.toJson<String?>(location),
      'salary': serializer.toJson<String?>(salary),
      'employmentType': serializer.toJson<String?>(employmentType),
      'experienceRequirement': serializer.toJson<String?>(
        experienceRequirement,
      ),
      'url': serializer.toJson<String?>(url),
      'source': serializer.toJson<String?>(source),
      'description': serializer.toJson<String?>(description),
      'skills': serializer.toJson<String?>(skills),
      'postedDate': serializer.toJson<DateTime?>(postedDate),
      'discoveredAt': serializer.toJson<DateTime>(discoveredAt),
      'isSaved': serializer.toJson<bool>(isSaved),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Job copyWith({
    String? id,
    String? title,
    String? company,
    Value<String?> location = const Value.absent(),
    Value<String?> salary = const Value.absent(),
    Value<String?> employmentType = const Value.absent(),
    Value<String?> experienceRequirement = const Value.absent(),
    Value<String?> url = const Value.absent(),
    Value<String?> source = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> skills = const Value.absent(),
    Value<DateTime?> postedDate = const Value.absent(),
    DateTime? discoveredAt,
    bool? isSaved,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Job(
    id: id ?? this.id,
    title: title ?? this.title,
    company: company ?? this.company,
    location: location.present ? location.value : this.location,
    salary: salary.present ? salary.value : this.salary,
    employmentType: employmentType.present
        ? employmentType.value
        : this.employmentType,
    experienceRequirement: experienceRequirement.present
        ? experienceRequirement.value
        : this.experienceRequirement,
    url: url.present ? url.value : this.url,
    source: source.present ? source.value : this.source,
    description: description.present ? description.value : this.description,
    skills: skills.present ? skills.value : this.skills,
    postedDate: postedDate.present ? postedDate.value : this.postedDate,
    discoveredAt: discoveredAt ?? this.discoveredAt,
    isSaved: isSaved ?? this.isSaved,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Job copyWithCompanion(JobsCompanion data) {
    return Job(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      company: data.company.present ? data.company.value : this.company,
      location: data.location.present ? data.location.value : this.location,
      salary: data.salary.present ? data.salary.value : this.salary,
      employmentType: data.employmentType.present
          ? data.employmentType.value
          : this.employmentType,
      experienceRequirement: data.experienceRequirement.present
          ? data.experienceRequirement.value
          : this.experienceRequirement,
      url: data.url.present ? data.url.value : this.url,
      source: data.source.present ? data.source.value : this.source,
      description: data.description.present
          ? data.description.value
          : this.description,
      skills: data.skills.present ? data.skills.value : this.skills,
      postedDate: data.postedDate.present
          ? data.postedDate.value
          : this.postedDate,
      discoveredAt: data.discoveredAt.present
          ? data.discoveredAt.value
          : this.discoveredAt,
      isSaved: data.isSaved.present ? data.isSaved.value : this.isSaved,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Job(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('company: $company, ')
          ..write('location: $location, ')
          ..write('salary: $salary, ')
          ..write('employmentType: $employmentType, ')
          ..write('experienceRequirement: $experienceRequirement, ')
          ..write('url: $url, ')
          ..write('source: $source, ')
          ..write('description: $description, ')
          ..write('skills: $skills, ')
          ..write('postedDate: $postedDate, ')
          ..write('discoveredAt: $discoveredAt, ')
          ..write('isSaved: $isSaved, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    company,
    location,
    salary,
    employmentType,
    experienceRequirement,
    url,
    source,
    description,
    skills,
    postedDate,
    discoveredAt,
    isSaved,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Job &&
          other.id == this.id &&
          other.title == this.title &&
          other.company == this.company &&
          other.location == this.location &&
          other.salary == this.salary &&
          other.employmentType == this.employmentType &&
          other.experienceRequirement == this.experienceRequirement &&
          other.url == this.url &&
          other.source == this.source &&
          other.description == this.description &&
          other.skills == this.skills &&
          other.postedDate == this.postedDate &&
          other.discoveredAt == this.discoveredAt &&
          other.isSaved == this.isSaved &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class JobsCompanion extends UpdateCompanion<Job> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> company;
  final Value<String?> location;
  final Value<String?> salary;
  final Value<String?> employmentType;
  final Value<String?> experienceRequirement;
  final Value<String?> url;
  final Value<String?> source;
  final Value<String?> description;
  final Value<String?> skills;
  final Value<DateTime?> postedDate;
  final Value<DateTime> discoveredAt;
  final Value<bool> isSaved;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const JobsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.company = const Value.absent(),
    this.location = const Value.absent(),
    this.salary = const Value.absent(),
    this.employmentType = const Value.absent(),
    this.experienceRequirement = const Value.absent(),
    this.url = const Value.absent(),
    this.source = const Value.absent(),
    this.description = const Value.absent(),
    this.skills = const Value.absent(),
    this.postedDate = const Value.absent(),
    this.discoveredAt = const Value.absent(),
    this.isSaved = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JobsCompanion.insert({
    required String id,
    required String title,
    required String company,
    this.location = const Value.absent(),
    this.salary = const Value.absent(),
    this.employmentType = const Value.absent(),
    this.experienceRequirement = const Value.absent(),
    this.url = const Value.absent(),
    this.source = const Value.absent(),
    this.description = const Value.absent(),
    this.skills = const Value.absent(),
    this.postedDate = const Value.absent(),
    this.discoveredAt = const Value.absent(),
    this.isSaved = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       company = Value(company);
  static Insertable<Job> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? company,
    Expression<String>? location,
    Expression<String>? salary,
    Expression<String>? employmentType,
    Expression<String>? experienceRequirement,
    Expression<String>? url,
    Expression<String>? source,
    Expression<String>? description,
    Expression<String>? skills,
    Expression<DateTime>? postedDate,
    Expression<DateTime>? discoveredAt,
    Expression<bool>? isSaved,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (company != null) 'company': company,
      if (location != null) 'location': location,
      if (salary != null) 'salary': salary,
      if (employmentType != null) 'employment_type': employmentType,
      if (experienceRequirement != null)
        'experience_requirement': experienceRequirement,
      if (url != null) 'url': url,
      if (source != null) 'source': source,
      if (description != null) 'description': description,
      if (skills != null) 'skills': skills,
      if (postedDate != null) 'posted_date': postedDate,
      if (discoveredAt != null) 'discovered_at': discoveredAt,
      if (isSaved != null) 'is_saved': isSaved,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JobsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? company,
    Value<String?>? location,
    Value<String?>? salary,
    Value<String?>? employmentType,
    Value<String?>? experienceRequirement,
    Value<String?>? url,
    Value<String?>? source,
    Value<String?>? description,
    Value<String?>? skills,
    Value<DateTime?>? postedDate,
    Value<DateTime>? discoveredAt,
    Value<bool>? isSaved,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return JobsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      location: location ?? this.location,
      salary: salary ?? this.salary,
      employmentType: employmentType ?? this.employmentType,
      experienceRequirement:
          experienceRequirement ?? this.experienceRequirement,
      url: url ?? this.url,
      source: source ?? this.source,
      description: description ?? this.description,
      skills: skills ?? this.skills,
      postedDate: postedDate ?? this.postedDate,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      isSaved: isSaved ?? this.isSaved,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (company.present) {
      map['company'] = Variable<String>(company.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (salary.present) {
      map['salary'] = Variable<String>(salary.value);
    }
    if (employmentType.present) {
      map['employment_type'] = Variable<String>(employmentType.value);
    }
    if (experienceRequirement.present) {
      map['experience_requirement'] = Variable<String>(
        experienceRequirement.value,
      );
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (skills.present) {
      map['skills'] = Variable<String>(skills.value);
    }
    if (postedDate.present) {
      map['posted_date'] = Variable<DateTime>(postedDate.value);
    }
    if (discoveredAt.present) {
      map['discovered_at'] = Variable<DateTime>(discoveredAt.value);
    }
    if (isSaved.present) {
      map['is_saved'] = Variable<bool>(isSaved.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('company: $company, ')
          ..write('location: $location, ')
          ..write('salary: $salary, ')
          ..write('employmentType: $employmentType, ')
          ..write('experienceRequirement: $experienceRequirement, ')
          ..write('url: $url, ')
          ..write('source: $source, ')
          ..write('description: $description, ')
          ..write('skills: $skills, ')
          ..write('postedDate: $postedDate, ')
          ..write('discoveredAt: $discoveredAt, ')
          ..write('isSaved: $isSaved, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JobApplicationsTable extends JobApplications
    with TableInfo<$JobApplicationsTable, JobApplication> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobApplicationsTable(this.attachedDatabase, [this._alias]);
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES jobs (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _companyMeta = const VerificationMeta(
    'company',
  );
  @override
  late final GeneratedColumn<String> company = GeneratedColumn<String>(
    'company',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 150,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _salaryMeta = const VerificationMeta('salary');
  @override
  late final GeneratedColumn<String> salary = GeneratedColumn<String>(
    'salary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('applied'),
  );
  static const VerificationMeta _appliedAtMeta = const VerificationMeta(
    'appliedAt',
  );
  @override
  late final GeneratedColumn<DateTime> appliedAt = GeneratedColumn<DateTime>(
    'applied_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _followUpDateMeta = const VerificationMeta(
    'followUpDate',
  );
  @override
  late final GeneratedColumn<DateTime> followUpDate = GeneratedColumn<DateTime>(
    'follow_up_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _interviewDateMeta = const VerificationMeta(
    'interviewDate',
  );
  @override
  late final GeneratedColumn<DateTime> interviewDate =
      GeneratedColumn<DateTime>(
        'interview_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _interviewStageMeta = const VerificationMeta(
    'interviewStage',
  );
  @override
  late final GeneratedColumn<String> interviewStage = GeneratedColumn<String>(
    'interview_stage',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recruiterNameMeta = const VerificationMeta(
    'recruiterName',
  );
  @override
  late final GeneratedColumn<String> recruiterName = GeneratedColumn<String>(
    'recruiter_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recruiterContactMeta = const VerificationMeta(
    'recruiterContact',
  );
  @override
  late final GeneratedColumn<String> recruiterContact = GeneratedColumn<String>(
    'recruiter_contact',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resumeIdMeta = const VerificationMeta(
    'resumeId',
  );
  @override
  late final GeneratedColumn<String> resumeId = GeneratedColumn<String>(
    'resume_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES resumes (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _resumeUsedMeta = const VerificationMeta(
    'resumeUsed',
  );
  @override
  late final GeneratedColumn<String> resumeUsed = GeneratedColumn<String>(
    'resume_used',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverLetterReferenceMeta =
      const VerificationMeta('coverLetterReference');
  @override
  late final GeneratedColumn<String> coverLetterReference =
      GeneratedColumn<String>(
        'cover_letter_reference',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _nextActionMeta = const VerificationMeta(
    'nextAction',
  );
  @override
  late final GeneratedColumn<String> nextAction = GeneratedColumn<String>(
    'next_action',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
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
    jobId,
    company,
    role,
    salary,
    location,
    url,
    status,
    appliedAt,
    followUpDate,
    interviewDate,
    interviewStage,
    recruiterName,
    recruiterContact,
    resumeId,
    resumeUsed,
    coverLetterReference,
    nextAction,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'job_applications';
  @override
  VerificationContext validateIntegrity(
    Insertable<JobApplication> instance, {
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
    }
    if (data.containsKey('company')) {
      context.handle(
        _companyMeta,
        company.isAcceptableOrUnknown(data['company']!, _companyMeta),
      );
    } else if (isInserting) {
      context.missing(_companyMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('salary')) {
      context.handle(
        _salaryMeta,
        salary.isAcceptableOrUnknown(data['salary']!, _salaryMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('applied_at')) {
      context.handle(
        _appliedAtMeta,
        appliedAt.isAcceptableOrUnknown(data['applied_at']!, _appliedAtMeta),
      );
    }
    if (data.containsKey('follow_up_date')) {
      context.handle(
        _followUpDateMeta,
        followUpDate.isAcceptableOrUnknown(
          data['follow_up_date']!,
          _followUpDateMeta,
        ),
      );
    }
    if (data.containsKey('interview_date')) {
      context.handle(
        _interviewDateMeta,
        interviewDate.isAcceptableOrUnknown(
          data['interview_date']!,
          _interviewDateMeta,
        ),
      );
    }
    if (data.containsKey('interview_stage')) {
      context.handle(
        _interviewStageMeta,
        interviewStage.isAcceptableOrUnknown(
          data['interview_stage']!,
          _interviewStageMeta,
        ),
      );
    }
    if (data.containsKey('recruiter_name')) {
      context.handle(
        _recruiterNameMeta,
        recruiterName.isAcceptableOrUnknown(
          data['recruiter_name']!,
          _recruiterNameMeta,
        ),
      );
    }
    if (data.containsKey('recruiter_contact')) {
      context.handle(
        _recruiterContactMeta,
        recruiterContact.isAcceptableOrUnknown(
          data['recruiter_contact']!,
          _recruiterContactMeta,
        ),
      );
    }
    if (data.containsKey('resume_id')) {
      context.handle(
        _resumeIdMeta,
        resumeId.isAcceptableOrUnknown(data['resume_id']!, _resumeIdMeta),
      );
    }
    if (data.containsKey('resume_used')) {
      context.handle(
        _resumeUsedMeta,
        resumeUsed.isAcceptableOrUnknown(data['resume_used']!, _resumeUsedMeta),
      );
    }
    if (data.containsKey('cover_letter_reference')) {
      context.handle(
        _coverLetterReferenceMeta,
        coverLetterReference.isAcceptableOrUnknown(
          data['cover_letter_reference']!,
          _coverLetterReferenceMeta,
        ),
      );
    }
    if (data.containsKey('next_action')) {
      context.handle(
        _nextActionMeta,
        nextAction.isAcceptableOrUnknown(data['next_action']!, _nextActionMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
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
  JobApplication map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JobApplication(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      ),
      company: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      salary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}salary'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      appliedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}applied_at'],
      ),
      followUpDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}follow_up_date'],
      ),
      interviewDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}interview_date'],
      ),
      interviewStage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}interview_stage'],
      ),
      recruiterName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recruiter_name'],
      ),
      recruiterContact: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recruiter_contact'],
      ),
      resumeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resume_id'],
      ),
      resumeUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resume_used'],
      ),
      coverLetterReference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_letter_reference'],
      ),
      nextAction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_action'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
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
  $JobApplicationsTable createAlias(String alias) {
    return $JobApplicationsTable(attachedDatabase, alias);
  }
}

class JobApplication extends DataClass implements Insertable<JobApplication> {
  final String id;
  final String? jobId;
  final String company;
  final String role;
  final String? salary;
  final String? location;
  final String? url;
  final String status;
  final DateTime? appliedAt;
  final DateTime? followUpDate;
  final DateTime? interviewDate;
  final String? interviewStage;
  final String? recruiterName;
  final String? recruiterContact;
  final String? resumeId;
  final String? resumeUsed;
  final String? coverLetterReference;
  final String? nextAction;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const JobApplication({
    required this.id,
    this.jobId,
    required this.company,
    required this.role,
    this.salary,
    this.location,
    this.url,
    required this.status,
    this.appliedAt,
    this.followUpDate,
    this.interviewDate,
    this.interviewStage,
    this.recruiterName,
    this.recruiterContact,
    this.resumeId,
    this.resumeUsed,
    this.coverLetterReference,
    this.nextAction,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || jobId != null) {
      map['job_id'] = Variable<String>(jobId);
    }
    map['company'] = Variable<String>(company);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || salary != null) {
      map['salary'] = Variable<String>(salary);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || appliedAt != null) {
      map['applied_at'] = Variable<DateTime>(appliedAt);
    }
    if (!nullToAbsent || followUpDate != null) {
      map['follow_up_date'] = Variable<DateTime>(followUpDate);
    }
    if (!nullToAbsent || interviewDate != null) {
      map['interview_date'] = Variable<DateTime>(interviewDate);
    }
    if (!nullToAbsent || interviewStage != null) {
      map['interview_stage'] = Variable<String>(interviewStage);
    }
    if (!nullToAbsent || recruiterName != null) {
      map['recruiter_name'] = Variable<String>(recruiterName);
    }
    if (!nullToAbsent || recruiterContact != null) {
      map['recruiter_contact'] = Variable<String>(recruiterContact);
    }
    if (!nullToAbsent || resumeId != null) {
      map['resume_id'] = Variable<String>(resumeId);
    }
    if (!nullToAbsent || resumeUsed != null) {
      map['resume_used'] = Variable<String>(resumeUsed);
    }
    if (!nullToAbsent || coverLetterReference != null) {
      map['cover_letter_reference'] = Variable<String>(coverLetterReference);
    }
    if (!nullToAbsent || nextAction != null) {
      map['next_action'] = Variable<String>(nextAction);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  JobApplicationsCompanion toCompanion(bool nullToAbsent) {
    return JobApplicationsCompanion(
      id: Value(id),
      jobId: jobId == null && nullToAbsent
          ? const Value.absent()
          : Value(jobId),
      company: Value(company),
      role: Value(role),
      salary: salary == null && nullToAbsent
          ? const Value.absent()
          : Value(salary),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      status: Value(status),
      appliedAt: appliedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(appliedAt),
      followUpDate: followUpDate == null && nullToAbsent
          ? const Value.absent()
          : Value(followUpDate),
      interviewDate: interviewDate == null && nullToAbsent
          ? const Value.absent()
          : Value(interviewDate),
      interviewStage: interviewStage == null && nullToAbsent
          ? const Value.absent()
          : Value(interviewStage),
      recruiterName: recruiterName == null && nullToAbsent
          ? const Value.absent()
          : Value(recruiterName),
      recruiterContact: recruiterContact == null && nullToAbsent
          ? const Value.absent()
          : Value(recruiterContact),
      resumeId: resumeId == null && nullToAbsent
          ? const Value.absent()
          : Value(resumeId),
      resumeUsed: resumeUsed == null && nullToAbsent
          ? const Value.absent()
          : Value(resumeUsed),
      coverLetterReference: coverLetterReference == null && nullToAbsent
          ? const Value.absent()
          : Value(coverLetterReference),
      nextAction: nextAction == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAction),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory JobApplication.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JobApplication(
      id: serializer.fromJson<String>(json['id']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      company: serializer.fromJson<String>(json['company']),
      role: serializer.fromJson<String>(json['role']),
      salary: serializer.fromJson<String?>(json['salary']),
      location: serializer.fromJson<String?>(json['location']),
      url: serializer.fromJson<String?>(json['url']),
      status: serializer.fromJson<String>(json['status']),
      appliedAt: serializer.fromJson<DateTime?>(json['appliedAt']),
      followUpDate: serializer.fromJson<DateTime?>(json['followUpDate']),
      interviewDate: serializer.fromJson<DateTime?>(json['interviewDate']),
      interviewStage: serializer.fromJson<String?>(json['interviewStage']),
      recruiterName: serializer.fromJson<String?>(json['recruiterName']),
      recruiterContact: serializer.fromJson<String?>(json['recruiterContact']),
      resumeId: serializer.fromJson<String?>(json['resumeId']),
      resumeUsed: serializer.fromJson<String?>(json['resumeUsed']),
      coverLetterReference: serializer.fromJson<String?>(
        json['coverLetterReference'],
      ),
      nextAction: serializer.fromJson<String?>(json['nextAction']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'jobId': serializer.toJson<String?>(jobId),
      'company': serializer.toJson<String>(company),
      'role': serializer.toJson<String>(role),
      'salary': serializer.toJson<String?>(salary),
      'location': serializer.toJson<String?>(location),
      'url': serializer.toJson<String?>(url),
      'status': serializer.toJson<String>(status),
      'appliedAt': serializer.toJson<DateTime?>(appliedAt),
      'followUpDate': serializer.toJson<DateTime?>(followUpDate),
      'interviewDate': serializer.toJson<DateTime?>(interviewDate),
      'interviewStage': serializer.toJson<String?>(interviewStage),
      'recruiterName': serializer.toJson<String?>(recruiterName),
      'recruiterContact': serializer.toJson<String?>(recruiterContact),
      'resumeId': serializer.toJson<String?>(resumeId),
      'resumeUsed': serializer.toJson<String?>(resumeUsed),
      'coverLetterReference': serializer.toJson<String?>(coverLetterReference),
      'nextAction': serializer.toJson<String?>(nextAction),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  JobApplication copyWith({
    String? id,
    Value<String?> jobId = const Value.absent(),
    String? company,
    String? role,
    Value<String?> salary = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> url = const Value.absent(),
    String? status,
    Value<DateTime?> appliedAt = const Value.absent(),
    Value<DateTime?> followUpDate = const Value.absent(),
    Value<DateTime?> interviewDate = const Value.absent(),
    Value<String?> interviewStage = const Value.absent(),
    Value<String?> recruiterName = const Value.absent(),
    Value<String?> recruiterContact = const Value.absent(),
    Value<String?> resumeId = const Value.absent(),
    Value<String?> resumeUsed = const Value.absent(),
    Value<String?> coverLetterReference = const Value.absent(),
    Value<String?> nextAction = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => JobApplication(
    id: id ?? this.id,
    jobId: jobId.present ? jobId.value : this.jobId,
    company: company ?? this.company,
    role: role ?? this.role,
    salary: salary.present ? salary.value : this.salary,
    location: location.present ? location.value : this.location,
    url: url.present ? url.value : this.url,
    status: status ?? this.status,
    appliedAt: appliedAt.present ? appliedAt.value : this.appliedAt,
    followUpDate: followUpDate.present ? followUpDate.value : this.followUpDate,
    interviewDate: interviewDate.present
        ? interviewDate.value
        : this.interviewDate,
    interviewStage: interviewStage.present
        ? interviewStage.value
        : this.interviewStage,
    recruiterName: recruiterName.present
        ? recruiterName.value
        : this.recruiterName,
    recruiterContact: recruiterContact.present
        ? recruiterContact.value
        : this.recruiterContact,
    resumeId: resumeId.present ? resumeId.value : this.resumeId,
    resumeUsed: resumeUsed.present ? resumeUsed.value : this.resumeUsed,
    coverLetterReference: coverLetterReference.present
        ? coverLetterReference.value
        : this.coverLetterReference,
    nextAction: nextAction.present ? nextAction.value : this.nextAction,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  JobApplication copyWithCompanion(JobApplicationsCompanion data) {
    return JobApplication(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      company: data.company.present ? data.company.value : this.company,
      role: data.role.present ? data.role.value : this.role,
      salary: data.salary.present ? data.salary.value : this.salary,
      location: data.location.present ? data.location.value : this.location,
      url: data.url.present ? data.url.value : this.url,
      status: data.status.present ? data.status.value : this.status,
      appliedAt: data.appliedAt.present ? data.appliedAt.value : this.appliedAt,
      followUpDate: data.followUpDate.present
          ? data.followUpDate.value
          : this.followUpDate,
      interviewDate: data.interviewDate.present
          ? data.interviewDate.value
          : this.interviewDate,
      interviewStage: data.interviewStage.present
          ? data.interviewStage.value
          : this.interviewStage,
      recruiterName: data.recruiterName.present
          ? data.recruiterName.value
          : this.recruiterName,
      recruiterContact: data.recruiterContact.present
          ? data.recruiterContact.value
          : this.recruiterContact,
      resumeId: data.resumeId.present ? data.resumeId.value : this.resumeId,
      resumeUsed: data.resumeUsed.present
          ? data.resumeUsed.value
          : this.resumeUsed,
      coverLetterReference: data.coverLetterReference.present
          ? data.coverLetterReference.value
          : this.coverLetterReference,
      nextAction: data.nextAction.present
          ? data.nextAction.value
          : this.nextAction,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JobApplication(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('company: $company, ')
          ..write('role: $role, ')
          ..write('salary: $salary, ')
          ..write('location: $location, ')
          ..write('url: $url, ')
          ..write('status: $status, ')
          ..write('appliedAt: $appliedAt, ')
          ..write('followUpDate: $followUpDate, ')
          ..write('interviewDate: $interviewDate, ')
          ..write('interviewStage: $interviewStage, ')
          ..write('recruiterName: $recruiterName, ')
          ..write('recruiterContact: $recruiterContact, ')
          ..write('resumeId: $resumeId, ')
          ..write('resumeUsed: $resumeUsed, ')
          ..write('coverLetterReference: $coverLetterReference, ')
          ..write('nextAction: $nextAction, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    jobId,
    company,
    role,
    salary,
    location,
    url,
    status,
    appliedAt,
    followUpDate,
    interviewDate,
    interviewStage,
    recruiterName,
    recruiterContact,
    resumeId,
    resumeUsed,
    coverLetterReference,
    nextAction,
    notes,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JobApplication &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.company == this.company &&
          other.role == this.role &&
          other.salary == this.salary &&
          other.location == this.location &&
          other.url == this.url &&
          other.status == this.status &&
          other.appliedAt == this.appliedAt &&
          other.followUpDate == this.followUpDate &&
          other.interviewDate == this.interviewDate &&
          other.interviewStage == this.interviewStage &&
          other.recruiterName == this.recruiterName &&
          other.recruiterContact == this.recruiterContact &&
          other.resumeId == this.resumeId &&
          other.resumeUsed == this.resumeUsed &&
          other.coverLetterReference == this.coverLetterReference &&
          other.nextAction == this.nextAction &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class JobApplicationsCompanion extends UpdateCompanion<JobApplication> {
  final Value<String> id;
  final Value<String?> jobId;
  final Value<String> company;
  final Value<String> role;
  final Value<String?> salary;
  final Value<String?> location;
  final Value<String?> url;
  final Value<String> status;
  final Value<DateTime?> appliedAt;
  final Value<DateTime?> followUpDate;
  final Value<DateTime?> interviewDate;
  final Value<String?> interviewStage;
  final Value<String?> recruiterName;
  final Value<String?> recruiterContact;
  final Value<String?> resumeId;
  final Value<String?> resumeUsed;
  final Value<String?> coverLetterReference;
  final Value<String?> nextAction;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const JobApplicationsCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.company = const Value.absent(),
    this.role = const Value.absent(),
    this.salary = const Value.absent(),
    this.location = const Value.absent(),
    this.url = const Value.absent(),
    this.status = const Value.absent(),
    this.appliedAt = const Value.absent(),
    this.followUpDate = const Value.absent(),
    this.interviewDate = const Value.absent(),
    this.interviewStage = const Value.absent(),
    this.recruiterName = const Value.absent(),
    this.recruiterContact = const Value.absent(),
    this.resumeId = const Value.absent(),
    this.resumeUsed = const Value.absent(),
    this.coverLetterReference = const Value.absent(),
    this.nextAction = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JobApplicationsCompanion.insert({
    required String id,
    this.jobId = const Value.absent(),
    required String company,
    required String role,
    this.salary = const Value.absent(),
    this.location = const Value.absent(),
    this.url = const Value.absent(),
    this.status = const Value.absent(),
    this.appliedAt = const Value.absent(),
    this.followUpDate = const Value.absent(),
    this.interviewDate = const Value.absent(),
    this.interviewStage = const Value.absent(),
    this.recruiterName = const Value.absent(),
    this.recruiterContact = const Value.absent(),
    this.resumeId = const Value.absent(),
    this.resumeUsed = const Value.absent(),
    this.coverLetterReference = const Value.absent(),
    this.nextAction = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       company = Value(company),
       role = Value(role);
  static Insertable<JobApplication> custom({
    Expression<String>? id,
    Expression<String>? jobId,
    Expression<String>? company,
    Expression<String>? role,
    Expression<String>? salary,
    Expression<String>? location,
    Expression<String>? url,
    Expression<String>? status,
    Expression<DateTime>? appliedAt,
    Expression<DateTime>? followUpDate,
    Expression<DateTime>? interviewDate,
    Expression<String>? interviewStage,
    Expression<String>? recruiterName,
    Expression<String>? recruiterContact,
    Expression<String>? resumeId,
    Expression<String>? resumeUsed,
    Expression<String>? coverLetterReference,
    Expression<String>? nextAction,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (company != null) 'company': company,
      if (role != null) 'role': role,
      if (salary != null) 'salary': salary,
      if (location != null) 'location': location,
      if (url != null) 'url': url,
      if (status != null) 'status': status,
      if (appliedAt != null) 'applied_at': appliedAt,
      if (followUpDate != null) 'follow_up_date': followUpDate,
      if (interviewDate != null) 'interview_date': interviewDate,
      if (interviewStage != null) 'interview_stage': interviewStage,
      if (recruiterName != null) 'recruiter_name': recruiterName,
      if (recruiterContact != null) 'recruiter_contact': recruiterContact,
      if (resumeId != null) 'resume_id': resumeId,
      if (resumeUsed != null) 'resume_used': resumeUsed,
      if (coverLetterReference != null)
        'cover_letter_reference': coverLetterReference,
      if (nextAction != null) 'next_action': nextAction,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JobApplicationsCompanion copyWith({
    Value<String>? id,
    Value<String?>? jobId,
    Value<String>? company,
    Value<String>? role,
    Value<String?>? salary,
    Value<String?>? location,
    Value<String?>? url,
    Value<String>? status,
    Value<DateTime?>? appliedAt,
    Value<DateTime?>? followUpDate,
    Value<DateTime?>? interviewDate,
    Value<String?>? interviewStage,
    Value<String?>? recruiterName,
    Value<String?>? recruiterContact,
    Value<String?>? resumeId,
    Value<String?>? resumeUsed,
    Value<String?>? coverLetterReference,
    Value<String?>? nextAction,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return JobApplicationsCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      company: company ?? this.company,
      role: role ?? this.role,
      salary: salary ?? this.salary,
      location: location ?? this.location,
      url: url ?? this.url,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      followUpDate: followUpDate ?? this.followUpDate,
      interviewDate: interviewDate ?? this.interviewDate,
      interviewStage: interviewStage ?? this.interviewStage,
      recruiterName: recruiterName ?? this.recruiterName,
      recruiterContact: recruiterContact ?? this.recruiterContact,
      resumeId: resumeId ?? this.resumeId,
      resumeUsed: resumeUsed ?? this.resumeUsed,
      coverLetterReference: coverLetterReference ?? this.coverLetterReference,
      nextAction: nextAction ?? this.nextAction,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
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
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (company.present) {
      map['company'] = Variable<String>(company.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (salary.present) {
      map['salary'] = Variable<String>(salary.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (appliedAt.present) {
      map['applied_at'] = Variable<DateTime>(appliedAt.value);
    }
    if (followUpDate.present) {
      map['follow_up_date'] = Variable<DateTime>(followUpDate.value);
    }
    if (interviewDate.present) {
      map['interview_date'] = Variable<DateTime>(interviewDate.value);
    }
    if (interviewStage.present) {
      map['interview_stage'] = Variable<String>(interviewStage.value);
    }
    if (recruiterName.present) {
      map['recruiter_name'] = Variable<String>(recruiterName.value);
    }
    if (recruiterContact.present) {
      map['recruiter_contact'] = Variable<String>(recruiterContact.value);
    }
    if (resumeId.present) {
      map['resume_id'] = Variable<String>(resumeId.value);
    }
    if (resumeUsed.present) {
      map['resume_used'] = Variable<String>(resumeUsed.value);
    }
    if (coverLetterReference.present) {
      map['cover_letter_reference'] = Variable<String>(
        coverLetterReference.value,
      );
    }
    if (nextAction.present) {
      map['next_action'] = Variable<String>(nextAction.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobApplicationsCompanion(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('company: $company, ')
          ..write('role: $role, ')
          ..write('salary: $salary, ')
          ..write('location: $location, ')
          ..write('url: $url, ')
          ..write('status: $status, ')
          ..write('appliedAt: $appliedAt, ')
          ..write('followUpDate: $followUpDate, ')
          ..write('interviewDate: $interviewDate, ')
          ..write('interviewStage: $interviewStage, ')
          ..write('recruiterName: $recruiterName, ')
          ..write('recruiterContact: $recruiterContact, ')
          ..write('resumeId: $resumeId, ')
          ..write('resumeUsed: $resumeUsed, ')
          ..write('coverLetterReference: $coverLetterReference, ')
          ..write('nextAction: $nextAction, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedSearchesTable extends SavedSearches
    with TableInfo<$SavedSearchesTable, SavedSearch> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedSearchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 150,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keywordsMeta = const VerificationMeta(
    'keywords',
  );
  @override
  late final GeneratedColumn<String> keywords = GeneratedColumn<String>(
    'keywords',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jobTitleMeta = const VerificationMeta(
    'jobTitle',
  );
  @override
  late final GeneratedColumn<String> jobTitle = GeneratedColumn<String>(
    'job_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _companyMeta = const VerificationMeta(
    'company',
  );
  @override
  late final GeneratedColumn<String> company = GeneratedColumn<String>(
    'company',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remotePreferenceMeta = const VerificationMeta(
    'remotePreference',
  );
  @override
  late final GeneratedColumn<String> remotePreference = GeneratedColumn<String>(
    'remote_preference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _employmentTypeMeta = const VerificationMeta(
    'employmentType',
  );
  @override
  late final GeneratedColumn<String> employmentType = GeneratedColumn<String>(
    'employment_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _experienceMeta = const VerificationMeta(
    'experience',
  );
  @override
  late final GeneratedColumn<String> experience = GeneratedColumn<String>(
    'experience',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _salaryMeta = const VerificationMeta('salary');
  @override
  late final GeneratedColumn<String> salary = GeneratedColumn<String>(
    'salary',
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
    name,
    keywords,
    jobTitle,
    company,
    location,
    remotePreference,
    employmentType,
    experience,
    salary,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_searches';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedSearch> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('keywords')) {
      context.handle(
        _keywordsMeta,
        keywords.isAcceptableOrUnknown(data['keywords']!, _keywordsMeta),
      );
    }
    if (data.containsKey('job_title')) {
      context.handle(
        _jobTitleMeta,
        jobTitle.isAcceptableOrUnknown(data['job_title']!, _jobTitleMeta),
      );
    }
    if (data.containsKey('company')) {
      context.handle(
        _companyMeta,
        company.isAcceptableOrUnknown(data['company']!, _companyMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('remote_preference')) {
      context.handle(
        _remotePreferenceMeta,
        remotePreference.isAcceptableOrUnknown(
          data['remote_preference']!,
          _remotePreferenceMeta,
        ),
      );
    }
    if (data.containsKey('employment_type')) {
      context.handle(
        _employmentTypeMeta,
        employmentType.isAcceptableOrUnknown(
          data['employment_type']!,
          _employmentTypeMeta,
        ),
      );
    }
    if (data.containsKey('experience')) {
      context.handle(
        _experienceMeta,
        experience.isAcceptableOrUnknown(data['experience']!, _experienceMeta),
      );
    }
    if (data.containsKey('salary')) {
      context.handle(
        _salaryMeta,
        salary.isAcceptableOrUnknown(data['salary']!, _salaryMeta),
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
  SavedSearch map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedSearch(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      keywords: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keywords'],
      ),
      jobTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_title'],
      ),
      company: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      remotePreference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_preference'],
      ),
      employmentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employment_type'],
      ),
      experience: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}experience'],
      ),
      salary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}salary'],
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
  $SavedSearchesTable createAlias(String alias) {
    return $SavedSearchesTable(attachedDatabase, alias);
  }
}

class SavedSearch extends DataClass implements Insertable<SavedSearch> {
  final String id;
  final String name;
  final String? keywords;
  final String? jobTitle;
  final String? company;
  final String? location;
  final String? remotePreference;
  final String? employmentType;
  final String? experience;
  final String? salary;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SavedSearch({
    required this.id,
    required this.name,
    this.keywords,
    this.jobTitle,
    this.company,
    this.location,
    this.remotePreference,
    this.employmentType,
    this.experience,
    this.salary,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || keywords != null) {
      map['keywords'] = Variable<String>(keywords);
    }
    if (!nullToAbsent || jobTitle != null) {
      map['job_title'] = Variable<String>(jobTitle);
    }
    if (!nullToAbsent || company != null) {
      map['company'] = Variable<String>(company);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || remotePreference != null) {
      map['remote_preference'] = Variable<String>(remotePreference);
    }
    if (!nullToAbsent || employmentType != null) {
      map['employment_type'] = Variable<String>(employmentType);
    }
    if (!nullToAbsent || experience != null) {
      map['experience'] = Variable<String>(experience);
    }
    if (!nullToAbsent || salary != null) {
      map['salary'] = Variable<String>(salary);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SavedSearchesCompanion toCompanion(bool nullToAbsent) {
    return SavedSearchesCompanion(
      id: Value(id),
      name: Value(name),
      keywords: keywords == null && nullToAbsent
          ? const Value.absent()
          : Value(keywords),
      jobTitle: jobTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(jobTitle),
      company: company == null && nullToAbsent
          ? const Value.absent()
          : Value(company),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      remotePreference: remotePreference == null && nullToAbsent
          ? const Value.absent()
          : Value(remotePreference),
      employmentType: employmentType == null && nullToAbsent
          ? const Value.absent()
          : Value(employmentType),
      experience: experience == null && nullToAbsent
          ? const Value.absent()
          : Value(experience),
      salary: salary == null && nullToAbsent
          ? const Value.absent()
          : Value(salary),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SavedSearch.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedSearch(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      keywords: serializer.fromJson<String?>(json['keywords']),
      jobTitle: serializer.fromJson<String?>(json['jobTitle']),
      company: serializer.fromJson<String?>(json['company']),
      location: serializer.fromJson<String?>(json['location']),
      remotePreference: serializer.fromJson<String?>(json['remotePreference']),
      employmentType: serializer.fromJson<String?>(json['employmentType']),
      experience: serializer.fromJson<String?>(json['experience']),
      salary: serializer.fromJson<String?>(json['salary']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'keywords': serializer.toJson<String?>(keywords),
      'jobTitle': serializer.toJson<String?>(jobTitle),
      'company': serializer.toJson<String?>(company),
      'location': serializer.toJson<String?>(location),
      'remotePreference': serializer.toJson<String?>(remotePreference),
      'employmentType': serializer.toJson<String?>(employmentType),
      'experience': serializer.toJson<String?>(experience),
      'salary': serializer.toJson<String?>(salary),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SavedSearch copyWith({
    String? id,
    String? name,
    Value<String?> keywords = const Value.absent(),
    Value<String?> jobTitle = const Value.absent(),
    Value<String?> company = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> remotePreference = const Value.absent(),
    Value<String?> employmentType = const Value.absent(),
    Value<String?> experience = const Value.absent(),
    Value<String?> salary = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SavedSearch(
    id: id ?? this.id,
    name: name ?? this.name,
    keywords: keywords.present ? keywords.value : this.keywords,
    jobTitle: jobTitle.present ? jobTitle.value : this.jobTitle,
    company: company.present ? company.value : this.company,
    location: location.present ? location.value : this.location,
    remotePreference: remotePreference.present
        ? remotePreference.value
        : this.remotePreference,
    employmentType: employmentType.present
        ? employmentType.value
        : this.employmentType,
    experience: experience.present ? experience.value : this.experience,
    salary: salary.present ? salary.value : this.salary,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SavedSearch copyWithCompanion(SavedSearchesCompanion data) {
    return SavedSearch(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      keywords: data.keywords.present ? data.keywords.value : this.keywords,
      jobTitle: data.jobTitle.present ? data.jobTitle.value : this.jobTitle,
      company: data.company.present ? data.company.value : this.company,
      location: data.location.present ? data.location.value : this.location,
      remotePreference: data.remotePreference.present
          ? data.remotePreference.value
          : this.remotePreference,
      employmentType: data.employmentType.present
          ? data.employmentType.value
          : this.employmentType,
      experience: data.experience.present
          ? data.experience.value
          : this.experience,
      salary: data.salary.present ? data.salary.value : this.salary,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedSearch(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('keywords: $keywords, ')
          ..write('jobTitle: $jobTitle, ')
          ..write('company: $company, ')
          ..write('location: $location, ')
          ..write('remotePreference: $remotePreference, ')
          ..write('employmentType: $employmentType, ')
          ..write('experience: $experience, ')
          ..write('salary: $salary, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    keywords,
    jobTitle,
    company,
    location,
    remotePreference,
    employmentType,
    experience,
    salary,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedSearch &&
          other.id == this.id &&
          other.name == this.name &&
          other.keywords == this.keywords &&
          other.jobTitle == this.jobTitle &&
          other.company == this.company &&
          other.location == this.location &&
          other.remotePreference == this.remotePreference &&
          other.employmentType == this.employmentType &&
          other.experience == this.experience &&
          other.salary == this.salary &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SavedSearchesCompanion extends UpdateCompanion<SavedSearch> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> keywords;
  final Value<String?> jobTitle;
  final Value<String?> company;
  final Value<String?> location;
  final Value<String?> remotePreference;
  final Value<String?> employmentType;
  final Value<String?> experience;
  final Value<String?> salary;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SavedSearchesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.keywords = const Value.absent(),
    this.jobTitle = const Value.absent(),
    this.company = const Value.absent(),
    this.location = const Value.absent(),
    this.remotePreference = const Value.absent(),
    this.employmentType = const Value.absent(),
    this.experience = const Value.absent(),
    this.salary = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedSearchesCompanion.insert({
    required String id,
    required String name,
    this.keywords = const Value.absent(),
    this.jobTitle = const Value.absent(),
    this.company = const Value.absent(),
    this.location = const Value.absent(),
    this.remotePreference = const Value.absent(),
    this.employmentType = const Value.absent(),
    this.experience = const Value.absent(),
    this.salary = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<SavedSearch> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? keywords,
    Expression<String>? jobTitle,
    Expression<String>? company,
    Expression<String>? location,
    Expression<String>? remotePreference,
    Expression<String>? employmentType,
    Expression<String>? experience,
    Expression<String>? salary,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (keywords != null) 'keywords': keywords,
      if (jobTitle != null) 'job_title': jobTitle,
      if (company != null) 'company': company,
      if (location != null) 'location': location,
      if (remotePreference != null) 'remote_preference': remotePreference,
      if (employmentType != null) 'employment_type': employmentType,
      if (experience != null) 'experience': experience,
      if (salary != null) 'salary': salary,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedSearchesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? keywords,
    Value<String?>? jobTitle,
    Value<String?>? company,
    Value<String?>? location,
    Value<String?>? remotePreference,
    Value<String?>? employmentType,
    Value<String?>? experience,
    Value<String?>? salary,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SavedSearchesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      keywords: keywords ?? this.keywords,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      location: location ?? this.location,
      remotePreference: remotePreference ?? this.remotePreference,
      employmentType: employmentType ?? this.employmentType,
      experience: experience ?? this.experience,
      salary: salary ?? this.salary,
      createdAt: createdAt ?? this.createdAt,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (keywords.present) {
      map['keywords'] = Variable<String>(keywords.value);
    }
    if (jobTitle.present) {
      map['job_title'] = Variable<String>(jobTitle.value);
    }
    if (company.present) {
      map['company'] = Variable<String>(company.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (remotePreference.present) {
      map['remote_preference'] = Variable<String>(remotePreference.value);
    }
    if (employmentType.present) {
      map['employment_type'] = Variable<String>(employmentType.value);
    }
    if (experience.present) {
      map['experience'] = Variable<String>(experience.value);
    }
    if (salary.present) {
      map['salary'] = Variable<String>(salary.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedSearchesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('keywords: $keywords, ')
          ..write('jobTitle: $jobTitle, ')
          ..write('company: $company, ')
          ..write('location: $location, ')
          ..write('remotePreference: $remotePreference, ')
          ..write('employmentType: $employmentType, ')
          ..write('experience: $experience, ')
          ..write('salary: $salary, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EODNotesTable extends EODNotes with TableInfo<$EODNotesTable, EODNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EODNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _completedWorkMeta = const VerificationMeta(
    'completedWork',
  );
  @override
  late final GeneratedColumn<String> completedWork = GeneratedColumn<String>(
    'completed_work',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inProgressWorkMeta = const VerificationMeta(
    'inProgressWork',
  );
  @override
  late final GeneratedColumn<String> inProgressWork = GeneratedColumn<String>(
    'in_progress_work',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blockersMeta = const VerificationMeta(
    'blockers',
  );
  @override
  late final GeneratedColumn<String> blockers = GeneratedColumn<String>(
    'blockers',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tomorrowPlanMeta = const VerificationMeta(
    'tomorrowPlan',
  );
  @override
  late final GeneratedColumn<String> tomorrowPlan = GeneratedColumn<String>(
    'tomorrow_plan',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
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
    date,
    completedWork,
    inProgressWork,
    blockers,
    tomorrowPlan,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'e_o_d_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<EODNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('completed_work')) {
      context.handle(
        _completedWorkMeta,
        completedWork.isAcceptableOrUnknown(
          data['completed_work']!,
          _completedWorkMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedWorkMeta);
    }
    if (data.containsKey('in_progress_work')) {
      context.handle(
        _inProgressWorkMeta,
        inProgressWork.isAcceptableOrUnknown(
          data['in_progress_work']!,
          _inProgressWorkMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inProgressWorkMeta);
    }
    if (data.containsKey('blockers')) {
      context.handle(
        _blockersMeta,
        blockers.isAcceptableOrUnknown(data['blockers']!, _blockersMeta),
      );
    }
    if (data.containsKey('tomorrow_plan')) {
      context.handle(
        _tomorrowPlanMeta,
        tomorrowPlan.isAcceptableOrUnknown(
          data['tomorrow_plan']!,
          _tomorrowPlanMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
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
  EODNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EODNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      completedWork: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_work'],
      )!,
      inProgressWork: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}in_progress_work'],
      )!,
      blockers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blockers'],
      ),
      tomorrowPlan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tomorrow_plan'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
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
  $EODNotesTable createAlias(String alias) {
    return $EODNotesTable(attachedDatabase, alias);
  }
}

class EODNote extends DataClass implements Insertable<EODNote> {
  final String id;
  final DateTime date;
  final String completedWork;
  final String inProgressWork;
  final String? blockers;
  final String? tomorrowPlan;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const EODNote({
    required this.id,
    required this.date,
    required this.completedWork,
    required this.inProgressWork,
    this.blockers,
    this.tomorrowPlan,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<DateTime>(date);
    map['completed_work'] = Variable<String>(completedWork);
    map['in_progress_work'] = Variable<String>(inProgressWork);
    if (!nullToAbsent || blockers != null) {
      map['blockers'] = Variable<String>(blockers);
    }
    if (!nullToAbsent || tomorrowPlan != null) {
      map['tomorrow_plan'] = Variable<String>(tomorrowPlan);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EODNotesCompanion toCompanion(bool nullToAbsent) {
    return EODNotesCompanion(
      id: Value(id),
      date: Value(date),
      completedWork: Value(completedWork),
      inProgressWork: Value(inProgressWork),
      blockers: blockers == null && nullToAbsent
          ? const Value.absent()
          : Value(blockers),
      tomorrowPlan: tomorrowPlan == null && nullToAbsent
          ? const Value.absent()
          : Value(tomorrowPlan),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory EODNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EODNote(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      completedWork: serializer.fromJson<String>(json['completedWork']),
      inProgressWork: serializer.fromJson<String>(json['inProgressWork']),
      blockers: serializer.fromJson<String?>(json['blockers']),
      tomorrowPlan: serializer.fromJson<String?>(json['tomorrowPlan']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<DateTime>(date),
      'completedWork': serializer.toJson<String>(completedWork),
      'inProgressWork': serializer.toJson<String>(inProgressWork),
      'blockers': serializer.toJson<String?>(blockers),
      'tomorrowPlan': serializer.toJson<String?>(tomorrowPlan),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EODNote copyWith({
    String? id,
    DateTime? date,
    String? completedWork,
    String? inProgressWork,
    Value<String?> blockers = const Value.absent(),
    Value<String?> tomorrowPlan = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => EODNote(
    id: id ?? this.id,
    date: date ?? this.date,
    completedWork: completedWork ?? this.completedWork,
    inProgressWork: inProgressWork ?? this.inProgressWork,
    blockers: blockers.present ? blockers.value : this.blockers,
    tomorrowPlan: tomorrowPlan.present ? tomorrowPlan.value : this.tomorrowPlan,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EODNote copyWithCompanion(EODNotesCompanion data) {
    return EODNote(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      completedWork: data.completedWork.present
          ? data.completedWork.value
          : this.completedWork,
      inProgressWork: data.inProgressWork.present
          ? data.inProgressWork.value
          : this.inProgressWork,
      blockers: data.blockers.present ? data.blockers.value : this.blockers,
      tomorrowPlan: data.tomorrowPlan.present
          ? data.tomorrowPlan.value
          : this.tomorrowPlan,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EODNote(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('completedWork: $completedWork, ')
          ..write('inProgressWork: $inProgressWork, ')
          ..write('blockers: $blockers, ')
          ..write('tomorrowPlan: $tomorrowPlan, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    completedWork,
    inProgressWork,
    blockers,
    tomorrowPlan,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EODNote &&
          other.id == this.id &&
          other.date == this.date &&
          other.completedWork == this.completedWork &&
          other.inProgressWork == this.inProgressWork &&
          other.blockers == this.blockers &&
          other.tomorrowPlan == this.tomorrowPlan &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EODNotesCompanion extends UpdateCompanion<EODNote> {
  final Value<String> id;
  final Value<DateTime> date;
  final Value<String> completedWork;
  final Value<String> inProgressWork;
  final Value<String?> blockers;
  final Value<String?> tomorrowPlan;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EODNotesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.completedWork = const Value.absent(),
    this.inProgressWork = const Value.absent(),
    this.blockers = const Value.absent(),
    this.tomorrowPlan = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EODNotesCompanion.insert({
    required String id,
    required DateTime date,
    required String completedWork,
    required String inProgressWork,
    this.blockers = const Value.absent(),
    this.tomorrowPlan = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       completedWork = Value(completedWork),
       inProgressWork = Value(inProgressWork);
  static Insertable<EODNote> custom({
    Expression<String>? id,
    Expression<DateTime>? date,
    Expression<String>? completedWork,
    Expression<String>? inProgressWork,
    Expression<String>? blockers,
    Expression<String>? tomorrowPlan,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (completedWork != null) 'completed_work': completedWork,
      if (inProgressWork != null) 'in_progress_work': inProgressWork,
      if (blockers != null) 'blockers': blockers,
      if (tomorrowPlan != null) 'tomorrow_plan': tomorrowPlan,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EODNotesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? date,
    Value<String>? completedWork,
    Value<String>? inProgressWork,
    Value<String?>? blockers,
    Value<String?>? tomorrowPlan,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return EODNotesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      completedWork: completedWork ?? this.completedWork,
      inProgressWork: inProgressWork ?? this.inProgressWork,
      blockers: blockers ?? this.blockers,
      tomorrowPlan: tomorrowPlan ?? this.tomorrowPlan,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
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
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (completedWork.present) {
      map['completed_work'] = Variable<String>(completedWork.value);
    }
    if (inProgressWork.present) {
      map['in_progress_work'] = Variable<String>(inProgressWork.value);
    }
    if (blockers.present) {
      map['blockers'] = Variable<String>(blockers.value);
    }
    if (tomorrowPlan.present) {
      map['tomorrow_plan'] = Variable<String>(tomorrowPlan.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EODNotesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('completedWork: $completedWork, ')
          ..write('inProgressWork: $inProgressWork, ')
          ..write('blockers: $blockers, ')
          ..write('tomorrowPlan: $tomorrowPlan, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ThingsToAsksTable extends ThingsToAsks
    with TableInfo<$ThingsToAsksTable, ThingsToAsk> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ThingsToAsksTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 250,
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
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('open'),
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
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    priority,
    status,
    createdAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'things_to_asks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ThingsToAsk> instance, {
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
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ThingsToAsk map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ThingsToAsk(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $ThingsToAsksTable createAlias(String alias) {
    return $ThingsToAsksTable(attachedDatabase, alias);
  }
}

class ThingsToAsk extends DataClass implements Insertable<ThingsToAsk> {
  final String id;
  final String title;
  final String? description;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  const ThingsToAsk({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['priority'] = Variable<String>(priority);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  ThingsToAsksCompanion toCompanion(bool nullToAbsent) {
    return ThingsToAsksCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      priority: Value(priority),
      status: Value(status),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory ThingsToAsk.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ThingsToAsk(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      priority: serializer.fromJson<String>(json['priority']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'priority': serializer.toJson<String>(priority),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  ThingsToAsk copyWith({
    String? id,
    String? title,
    Value<String?> description = const Value.absent(),
    String? priority,
    String? status,
    DateTime? createdAt,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => ThingsToAsk(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  ThingsToAsk copyWithCompanion(ThingsToAsksCompanion data) {
    return ThingsToAsk(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ThingsToAsk(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    priority,
    status,
    createdAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ThingsToAsk &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt);
}

class ThingsToAsksCompanion extends UpdateCompanion<ThingsToAsk> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> priority;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const ThingsToAsksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ThingsToAsksCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<ThingsToAsk> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? priority,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ThingsToAsksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? priority,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return ThingsToAsksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ThingsToAsksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkNotesTable extends WorkNotes
    with TableInfo<$WorkNotesTable, WorkNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkNotesTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 250,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteTypeMeta = const VerificationMeta(
    'noteType',
  );
  @override
  late final GeneratedColumn<String> noteType = GeneratedColumn<String>(
    'note_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('general'),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES projects (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _meetingDateMeta = const VerificationMeta(
    'meetingDate',
  );
  @override
  late final GeneratedColumn<DateTime> meetingDate = GeneratedColumn<DateTime>(
    'meeting_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _participantsMeta = const VerificationMeta(
    'participants',
  );
  @override
  late final GeneratedColumn<String> participants = GeneratedColumn<String>(
    'participants',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionItemsMeta = const VerificationMeta(
    'actionItems',
  );
  @override
  late final GeneratedColumn<String> actionItems = GeneratedColumn<String>(
    'action_items',
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
    title,
    content,
    noteType,
    projectId,
    meetingDate,
    participants,
    actionItems,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'work_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkNote> instance, {
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
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('note_type')) {
      context.handle(
        _noteTypeMeta,
        noteType.isAcceptableOrUnknown(data['note_type']!, _noteTypeMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('meeting_date')) {
      context.handle(
        _meetingDateMeta,
        meetingDate.isAcceptableOrUnknown(
          data['meeting_date']!,
          _meetingDateMeta,
        ),
      );
    }
    if (data.containsKey('participants')) {
      context.handle(
        _participantsMeta,
        participants.isAcceptableOrUnknown(
          data['participants']!,
          _participantsMeta,
        ),
      );
    }
    if (data.containsKey('action_items')) {
      context.handle(
        _actionItemsMeta,
        actionItems.isAcceptableOrUnknown(
          data['action_items']!,
          _actionItemsMeta,
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
  WorkNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      noteType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_type'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      meetingDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}meeting_date'],
      ),
      participants: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participants'],
      ),
      actionItems: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_items'],
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
  $WorkNotesTable createAlias(String alias) {
    return $WorkNotesTable(attachedDatabase, alias);
  }
}

class WorkNote extends DataClass implements Insertable<WorkNote> {
  final String id;
  final String title;
  final String content;
  final String noteType;
  final String? projectId;
  final DateTime? meetingDate;
  final String? participants;
  final String? actionItems;
  final DateTime createdAt;
  final DateTime updatedAt;
  const WorkNote({
    required this.id,
    required this.title,
    required this.content,
    required this.noteType,
    this.projectId,
    this.meetingDate,
    this.participants,
    this.actionItems,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['note_type'] = Variable<String>(noteType);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    if (!nullToAbsent || meetingDate != null) {
      map['meeting_date'] = Variable<DateTime>(meetingDate);
    }
    if (!nullToAbsent || participants != null) {
      map['participants'] = Variable<String>(participants);
    }
    if (!nullToAbsent || actionItems != null) {
      map['action_items'] = Variable<String>(actionItems);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WorkNotesCompanion toCompanion(bool nullToAbsent) {
    return WorkNotesCompanion(
      id: Value(id),
      title: Value(title),
      content: Value(content),
      noteType: Value(noteType),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      meetingDate: meetingDate == null && nullToAbsent
          ? const Value.absent()
          : Value(meetingDate),
      participants: participants == null && nullToAbsent
          ? const Value.absent()
          : Value(participants),
      actionItems: actionItems == null && nullToAbsent
          ? const Value.absent()
          : Value(actionItems),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WorkNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkNote(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      noteType: serializer.fromJson<String>(json['noteType']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      meetingDate: serializer.fromJson<DateTime?>(json['meetingDate']),
      participants: serializer.fromJson<String?>(json['participants']),
      actionItems: serializer.fromJson<String?>(json['actionItems']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'noteType': serializer.toJson<String>(noteType),
      'projectId': serializer.toJson<String?>(projectId),
      'meetingDate': serializer.toJson<DateTime?>(meetingDate),
      'participants': serializer.toJson<String?>(participants),
      'actionItems': serializer.toJson<String?>(actionItems),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WorkNote copyWith({
    String? id,
    String? title,
    String? content,
    String? noteType,
    Value<String?> projectId = const Value.absent(),
    Value<DateTime?> meetingDate = const Value.absent(),
    Value<String?> participants = const Value.absent(),
    Value<String?> actionItems = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WorkNote(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    noteType: noteType ?? this.noteType,
    projectId: projectId.present ? projectId.value : this.projectId,
    meetingDate: meetingDate.present ? meetingDate.value : this.meetingDate,
    participants: participants.present ? participants.value : this.participants,
    actionItems: actionItems.present ? actionItems.value : this.actionItems,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WorkNote copyWithCompanion(WorkNotesCompanion data) {
    return WorkNote(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      noteType: data.noteType.present ? data.noteType.value : this.noteType,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      meetingDate: data.meetingDate.present
          ? data.meetingDate.value
          : this.meetingDate,
      participants: data.participants.present
          ? data.participants.value
          : this.participants,
      actionItems: data.actionItems.present
          ? data.actionItems.value
          : this.actionItems,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkNote(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('noteType: $noteType, ')
          ..write('projectId: $projectId, ')
          ..write('meetingDate: $meetingDate, ')
          ..write('participants: $participants, ')
          ..write('actionItems: $actionItems, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    content,
    noteType,
    projectId,
    meetingDate,
    participants,
    actionItems,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkNote &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.noteType == this.noteType &&
          other.projectId == this.projectId &&
          other.meetingDate == this.meetingDate &&
          other.participants == this.participants &&
          other.actionItems == this.actionItems &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WorkNotesCompanion extends UpdateCompanion<WorkNote> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> content;
  final Value<String> noteType;
  final Value<String?> projectId;
  final Value<DateTime?> meetingDate;
  final Value<String?> participants;
  final Value<String?> actionItems;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const WorkNotesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.noteType = const Value.absent(),
    this.projectId = const Value.absent(),
    this.meetingDate = const Value.absent(),
    this.participants = const Value.absent(),
    this.actionItems = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkNotesCompanion.insert({
    required String id,
    required String title,
    required String content,
    this.noteType = const Value.absent(),
    this.projectId = const Value.absent(),
    this.meetingDate = const Value.absent(),
    this.participants = const Value.absent(),
    this.actionItems = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       content = Value(content);
  static Insertable<WorkNote> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? noteType,
    Expression<String>? projectId,
    Expression<DateTime>? meetingDate,
    Expression<String>? participants,
    Expression<String>? actionItems,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (noteType != null) 'note_type': noteType,
      if (projectId != null) 'project_id': projectId,
      if (meetingDate != null) 'meeting_date': meetingDate,
      if (participants != null) 'participants': participants,
      if (actionItems != null) 'action_items': actionItems,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkNotesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? content,
    Value<String>? noteType,
    Value<String?>? projectId,
    Value<DateTime?>? meetingDate,
    Value<String?>? participants,
    Value<String?>? actionItems,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return WorkNotesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      noteType: noteType ?? this.noteType,
      projectId: projectId ?? this.projectId,
      meetingDate: meetingDate ?? this.meetingDate,
      participants: participants ?? this.participants,
      actionItems: actionItems ?? this.actionItems,
      createdAt: createdAt ?? this.createdAt,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (noteType.present) {
      map['note_type'] = Variable<String>(noteType.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (meetingDate.present) {
      map['meeting_date'] = Variable<DateTime>(meetingDate.value);
    }
    if (participants.present) {
      map['participants'] = Variable<String>(participants.value);
    }
    if (actionItems.present) {
      map['action_items'] = Variable<String>(actionItems.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkNotesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('noteType: $noteType, ')
          ..write('projectId: $projectId, ')
          ..write('meetingDate: $meetingDate, ')
          ..write('participants: $participants, ')
          ..write('actionItems: $actionItems, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserProfilesTable userProfiles = $UserProfilesTable(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $ResumesTable resumes = $ResumesTable(this);
  late final $JobsTable jobs = $JobsTable(this);
  late final $JobApplicationsTable jobApplications = $JobApplicationsTable(
    this,
  );
  late final $SavedSearchesTable savedSearches = $SavedSearchesTable(this);
  late final $EODNotesTable eODNotes = $EODNotesTable(this);
  late final $ThingsToAsksTable thingsToAsks = $ThingsToAsksTable(this);
  late final $WorkNotesTable workNotes = $WorkNotesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    userProfiles,
    projects,
    tasks,
    resumes,
    jobs,
    jobApplications,
    savedSearches,
    eODNotes,
    thingsToAsks,
    workNotes,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'jobs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('job_applications', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'resumes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('job_applications', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('work_notes', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$UserProfilesTableCreateCompanionBuilder =
    UserProfilesCompanion Function({
      required String id,
      required String name,
      Value<String?> currentRole,
      Value<double> experienceYears,
      Value<String?> skills,
      Value<String?> programmingLanguages,
      Value<String?> frameworks,
      Value<String?> preferredRoles,
      Value<String?> preferredLocations,
      Value<String> remotePreference,
      Value<String?> expectedSalary,
      Value<String?> preferredEmploymentType,
      Value<String?> noticePeriod,
      Value<String?> education,
      Value<String?> resumePreferences,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$UserProfilesTableUpdateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> currentRole,
      Value<double> experienceYears,
      Value<String?> skills,
      Value<String?> programmingLanguages,
      Value<String?> frameworks,
      Value<String?> preferredRoles,
      Value<String?> preferredLocations,
      Value<String> remotePreference,
      Value<String?> expectedSalary,
      Value<String?> preferredEmploymentType,
      Value<String?> noticePeriod,
      Value<String?> education,
      Value<String?> resumePreferences,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentRole => $composableBuilder(
    column: $table.currentRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get experienceYears => $composableBuilder(
    column: $table.experienceYears,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skills => $composableBuilder(
    column: $table.skills,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get programmingLanguages => $composableBuilder(
    column: $table.programmingLanguages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frameworks => $composableBuilder(
    column: $table.frameworks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredRoles => $composableBuilder(
    column: $table.preferredRoles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredLocations => $composableBuilder(
    column: $table.preferredLocations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remotePreference => $composableBuilder(
    column: $table.remotePreference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expectedSalary => $composableBuilder(
    column: $table.expectedSalary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredEmploymentType => $composableBuilder(
    column: $table.preferredEmploymentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noticePeriod => $composableBuilder(
    column: $table.noticePeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get education => $composableBuilder(
    column: $table.education,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resumePreferences => $composableBuilder(
    column: $table.resumePreferences,
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
}

class $$UserProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentRole => $composableBuilder(
    column: $table.currentRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get experienceYears => $composableBuilder(
    column: $table.experienceYears,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skills => $composableBuilder(
    column: $table.skills,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get programmingLanguages => $composableBuilder(
    column: $table.programmingLanguages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frameworks => $composableBuilder(
    column: $table.frameworks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredRoles => $composableBuilder(
    column: $table.preferredRoles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredLocations => $composableBuilder(
    column: $table.preferredLocations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remotePreference => $composableBuilder(
    column: $table.remotePreference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expectedSalary => $composableBuilder(
    column: $table.expectedSalary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredEmploymentType => $composableBuilder(
    column: $table.preferredEmploymentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noticePeriod => $composableBuilder(
    column: $table.noticePeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get education => $composableBuilder(
    column: $table.education,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resumePreferences => $composableBuilder(
    column: $table.resumePreferences,
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

class $$UserProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get currentRole => $composableBuilder(
    column: $table.currentRole,
    builder: (column) => column,
  );

  GeneratedColumn<double> get experienceYears => $composableBuilder(
    column: $table.experienceYears,
    builder: (column) => column,
  );

  GeneratedColumn<String> get skills =>
      $composableBuilder(column: $table.skills, builder: (column) => column);

  GeneratedColumn<String> get programmingLanguages => $composableBuilder(
    column: $table.programmingLanguages,
    builder: (column) => column,
  );

  GeneratedColumn<String> get frameworks => $composableBuilder(
    column: $table.frameworks,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredRoles => $composableBuilder(
    column: $table.preferredRoles,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredLocations => $composableBuilder(
    column: $table.preferredLocations,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remotePreference => $composableBuilder(
    column: $table.remotePreference,
    builder: (column) => column,
  );

  GeneratedColumn<String> get expectedSalary => $composableBuilder(
    column: $table.expectedSalary,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredEmploymentType => $composableBuilder(
    column: $table.preferredEmploymentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get noticePeriod => $composableBuilder(
    column: $table.noticePeriod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get education =>
      $composableBuilder(column: $table.education, builder: (column) => column);

  GeneratedColumn<String> get resumePreferences => $composableBuilder(
    column: $table.resumePreferences,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfilesTable,
          UserProfile,
          $$UserProfilesTableFilterComposer,
          $$UserProfilesTableOrderingComposer,
          $$UserProfilesTableAnnotationComposer,
          $$UserProfilesTableCreateCompanionBuilder,
          $$UserProfilesTableUpdateCompanionBuilder,
          (
            UserProfile,
            BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfile>,
          ),
          UserProfile,
          PrefetchHooks Function()
        > {
  $$UserProfilesTableTableManager(_$AppDatabase db, $UserProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> currentRole = const Value.absent(),
                Value<double> experienceYears = const Value.absent(),
                Value<String?> skills = const Value.absent(),
                Value<String?> programmingLanguages = const Value.absent(),
                Value<String?> frameworks = const Value.absent(),
                Value<String?> preferredRoles = const Value.absent(),
                Value<String?> preferredLocations = const Value.absent(),
                Value<String> remotePreference = const Value.absent(),
                Value<String?> expectedSalary = const Value.absent(),
                Value<String?> preferredEmploymentType = const Value.absent(),
                Value<String?> noticePeriod = const Value.absent(),
                Value<String?> education = const Value.absent(),
                Value<String?> resumePreferences = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserProfilesCompanion(
                id: id,
                name: name,
                currentRole: currentRole,
                experienceYears: experienceYears,
                skills: skills,
                programmingLanguages: programmingLanguages,
                frameworks: frameworks,
                preferredRoles: preferredRoles,
                preferredLocations: preferredLocations,
                remotePreference: remotePreference,
                expectedSalary: expectedSalary,
                preferredEmploymentType: preferredEmploymentType,
                noticePeriod: noticePeriod,
                education: education,
                resumePreferences: resumePreferences,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> currentRole = const Value.absent(),
                Value<double> experienceYears = const Value.absent(),
                Value<String?> skills = const Value.absent(),
                Value<String?> programmingLanguages = const Value.absent(),
                Value<String?> frameworks = const Value.absent(),
                Value<String?> preferredRoles = const Value.absent(),
                Value<String?> preferredLocations = const Value.absent(),
                Value<String> remotePreference = const Value.absent(),
                Value<String?> expectedSalary = const Value.absent(),
                Value<String?> preferredEmploymentType = const Value.absent(),
                Value<String?> noticePeriod = const Value.absent(),
                Value<String?> education = const Value.absent(),
                Value<String?> resumePreferences = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserProfilesCompanion.insert(
                id: id,
                name: name,
                currentRole: currentRole,
                experienceYears: experienceYears,
                skills: skills,
                programmingLanguages: programmingLanguages,
                frameworks: frameworks,
                preferredRoles: preferredRoles,
                preferredLocations: preferredLocations,
                remotePreference: remotePreference,
                expectedSalary: expectedSalary,
                preferredEmploymentType: preferredEmploymentType,
                noticePeriod: noticePeriod,
                education: education,
                resumePreferences: resumePreferences,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserProfilesTable, UserProfile>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $UserProfilesTable,
                    UserProfile
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfilesTable,
      UserProfile,
      $$UserProfilesTableFilterComposer,
      $$UserProfilesTableOrderingComposer,
      $$UserProfilesTableAnnotationComposer,
      $$UserProfilesTableCreateCompanionBuilder,
      $$UserProfilesTableUpdateCompanionBuilder,
      (
        UserProfile,
        BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfile>,
      ),
      UserProfile,
      PrefetchHooks Function()
    >;
typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  required String id,
  required String name,
  Value<String?> description,
  Value<String> status,
  Value<double> progress,
  Value<String?> techStack,
  Value<String?> githubUrl,
  Value<String?> liveUrl,
  Value<DateTime?> deadline,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> description,
  Value<String> status,
  Value<double> progress,
  Value<String?> techStack,
  Value<String?> githubUrl,
  Value<String?> liveUrl,
  Value<DateTime?> deadline,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$ProjectsTableReferences
    extends BaseReferences<_$AppDatabase, $ProjectsTable, Project> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TasksTable, List<Task>> _tasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: 'projects__id__tasks__project_id',
  );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WorkNotesTable, List<WorkNote>>
  _workNotesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workNotes,
    aliasName: 'projects__id__work_notes__project_id',
  );

  $$WorkNotesTableProcessedTableManager get workNotesRefs {
    final manager = $$WorkNotesTableTableManager(
      $_db,
      $_db.workNotes,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workNotesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get techStack => $composableBuilder(
    column: $table.techStack,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get githubUrl => $composableBuilder(
    column: $table.githubUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get liveUrl => $composableBuilder(
    column: $table.liveUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
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

  Expression<bool> tasksRefs(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workNotesRefs(
    Expression<bool> Function($$WorkNotesTableFilterComposer f) f,
  ) {
    final $$WorkNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workNotes,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkNotesTableFilterComposer(
            $db: $db,
            $table: $db.workNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get techStack => $composableBuilder(
    column: $table.techStack,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get githubUrl => $composableBuilder(
    column: $table.githubUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get liveUrl => $composableBuilder(
    column: $table.liveUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
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

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<String> get techStack =>
      $composableBuilder(column: $table.techStack, builder: (column) => column);

  GeneratedColumn<String> get githubUrl =>
      $composableBuilder(column: $table.githubUrl, builder: (column) => column);

  GeneratedColumn<String> get liveUrl =>
      $composableBuilder(column: $table.liveUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> workNotesRefs<T extends Object>(
    Expression<T> Function($$WorkNotesTableAnnotationComposer a) f,
  ) {
    final $$WorkNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workNotes,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.workNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTable,
          Project,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (Project, $$ProjectsTableReferences),
          Project,
          PrefetchHooks Function({bool tasksRefs, bool workNotesRefs})
        > {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<String?> techStack = const Value.absent(),
                Value<String?> githubUrl = const Value.absent(),
                Value<String?> liveUrl = const Value.absent(),
                Value<DateTime?> deadline = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                name: name,
                description: description,
                status: status,
                progress: progress,
                techStack: techStack,
                githubUrl: githubUrl,
                liveUrl: liveUrl,
                deadline: deadline,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<String?> techStack = const Value.absent(),
                Value<String?> githubUrl = const Value.absent(),
                Value<String?> liveUrl = const Value.absent(),
                Value<DateTime?> deadline = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                name: name,
                description: description,
                status: status,
                progress: progress,
                techStack: techStack,
                githubUrl: githubUrl,
                liveUrl: liveUrl,
                deadline: deadline,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectsTable, Project>(table),
                  $$ProjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tasksRefs = false, workNotesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (tasksRefs) db.tasks,
                if (workNotesRefs) db.workNotes,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tasksRefs)
                    await $_getPrefetchedData<Project, $ProjectsTable, Task>(
                      currentTable: table,
                      referencedTable: $$ProjectsTableReferences
                          ._tasksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ProjectsTableReferences(db, table, p0).tasksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.projectId == item.id),
                      typedResults: items,
                    ),
                  if (workNotesRefs)
                    await $_getPrefetchedData<
                      Project,
                      $ProjectsTable,
                      WorkNote
                    >(
                      currentTable: table,
                      referencedTable: $$ProjectsTableReferences
                          ._workNotesRefsTable(db),
                      managerFromTypedResult: (p0) => $$ProjectsTableReferences(
                        db,
                        table,
                        p0,
                      ).workNotesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.projectId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTable,
      Project,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (Project, $$ProjectsTableReferences),
      Project,
      PrefetchHooks Function({bool tasksRefs, bool workNotesRefs})
    >;
typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  required String title,
  Value<String?> description,
  Value<String> priority,
  Value<String> status,
  Value<String> category,
  Value<String?> projectId,
  Value<String?> notes,
  Value<DateTime?> dueDate,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> description,
  Value<String> priority,
  Value<String> status,
  Value<String> category,
  Value<String?> projectId,
  Value<String?> notes,
  Value<DateTime?> dueDate,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias('tasks__project_id__projects__id');

  $$ProjectsTableProcessedTableManager? get projectId {
    final $_column = $_itemColumn<String>('project_id');
    if ($_column == null) return null;
    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
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

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
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

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, $$TasksTableReferences),
          Task,
          PrefetchHooks Function({bool projectId})
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                description: description,
                priority: priority,
                status: status,
                category: category,
                projectId: projectId,
                notes: notes,
                dueDate: dueDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                description: description,
                priority: priority,
                status: status,
                category: category,
                projectId: projectId,
                notes: notes,
                dueDate: dueDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTable, Task>(table),
                  $$TasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
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
                    if (projectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.projectId,
                        referencedTable: $$TasksTableReferences._projectIdTable(
                          db,
                        ),
                        referencedColumn: $$TasksTableReferences
                            ._projectIdTable(db)
                            .id,
                      ) as T;
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

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, $$TasksTableReferences),
      Task,
      PrefetchHooks Function({bool projectId})
    >;
typedef $$ResumesTableCreateCompanionBuilder = ResumesCompanion Function({
  required String id,
  required String name,
  Value<String> version,
  Value<String?> targetRole,
  required String filePath,
  required String fileName,
  Value<String?> notes,
  Value<bool> isPrimary,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$ResumesTableUpdateCompanionBuilder = ResumesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> version,
  Value<String?> targetRole,
  Value<String> filePath,
  Value<String> fileName,
  Value<String?> notes,
  Value<bool> isPrimary,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$ResumesTableReferences
    extends BaseReferences<_$AppDatabase, $ResumesTable, Resume> {
  $$ResumesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$JobApplicationsTable, List<JobApplication>>
  _jobApplicationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.jobApplications,
    aliasName: 'resumes__id__job_applications__resume_id',
  );

  $$JobApplicationsTableProcessedTableManager get jobApplicationsRefs {
    final manager = $$JobApplicationsTableTableManager(
      $_db,
      $_db.jobApplications,
    ).filter((f) => f.resumeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _jobApplicationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ResumesTableFilterComposer
    extends Composer<_$AppDatabase, $ResumesTable> {
  $$ResumesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetRole => $composableBuilder(
    column: $table.targetRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
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

  Expression<bool> jobApplicationsRefs(
    Expression<bool> Function($$JobApplicationsTableFilterComposer f) f,
  ) {
    final $$JobApplicationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jobApplications,
      getReferencedColumn: (t) => t.resumeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobApplicationsTableFilterComposer(
            $db: $db,
            $table: $db.jobApplications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ResumesTableOrderingComposer
    extends Composer<_$AppDatabase, $ResumesTable> {
  $$ResumesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetRole => $composableBuilder(
    column: $table.targetRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
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

class $$ResumesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ResumesTable> {
  $$ResumesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get targetRole => $composableBuilder(
    column: $table.targetRole,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> jobApplicationsRefs<T extends Object>(
    Expression<T> Function($$JobApplicationsTableAnnotationComposer a) f,
  ) {
    final $$JobApplicationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jobApplications,
      getReferencedColumn: (t) => t.resumeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobApplicationsTableAnnotationComposer(
            $db: $db,
            $table: $db.jobApplications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ResumesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ResumesTable,
          Resume,
          $$ResumesTableFilterComposer,
          $$ResumesTableOrderingComposer,
          $$ResumesTableAnnotationComposer,
          $$ResumesTableCreateCompanionBuilder,
          $$ResumesTableUpdateCompanionBuilder,
          (Resume, $$ResumesTableReferences),
          Resume,
          PrefetchHooks Function({bool jobApplicationsRefs})
        > {
  $$ResumesTableTableManager(_$AppDatabase db, $ResumesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ResumesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ResumesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ResumesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<String?> targetRole = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ResumesCompanion(
                id: id,
                name: name,
                version: version,
                targetRole: targetRole,
                filePath: filePath,
                fileName: fileName,
                notes: notes,
                isPrimary: isPrimary,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> version = const Value.absent(),
                Value<String?> targetRole = const Value.absent(),
                required String filePath,
                required String fileName,
                Value<String?> notes = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ResumesCompanion.insert(
                id: id,
                name: name,
                version: version,
                targetRole: targetRole,
                filePath: filePath,
                fileName: fileName,
                notes: notes,
                isPrimary: isPrimary,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ResumesTable, Resume>(table),
                  $$ResumesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({jobApplicationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (jobApplicationsRefs) db.jobApplications,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (jobApplicationsRefs)
                    await $_getPrefetchedData<
                      Resume,
                      $ResumesTable,
                      JobApplication
                    >(
                      currentTable: table,
                      referencedTable: $$ResumesTableReferences
                          ._jobApplicationsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ResumesTableReferences(
                        db,
                        table,
                        p0,
                      ).jobApplicationsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.resumeId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ResumesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ResumesTable,
      Resume,
      $$ResumesTableFilterComposer,
      $$ResumesTableOrderingComposer,
      $$ResumesTableAnnotationComposer,
      $$ResumesTableCreateCompanionBuilder,
      $$ResumesTableUpdateCompanionBuilder,
      (Resume, $$ResumesTableReferences),
      Resume,
      PrefetchHooks Function({bool jobApplicationsRefs})
    >;
typedef $$JobsTableCreateCompanionBuilder = JobsCompanion Function({
  required String id,
  required String title,
  required String company,
  Value<String?> location,
  Value<String?> salary,
  Value<String?> employmentType,
  Value<String?> experienceRequirement,
  Value<String?> url,
  Value<String?> source,
  Value<String?> description,
  Value<String?> skills,
  Value<DateTime?> postedDate,
  Value<DateTime> discoveredAt,
  Value<bool> isSaved,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$JobsTableUpdateCompanionBuilder = JobsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> company,
  Value<String?> location,
  Value<String?> salary,
  Value<String?> employmentType,
  Value<String?> experienceRequirement,
  Value<String?> url,
  Value<String?> source,
  Value<String?> description,
  Value<String?> skills,
  Value<DateTime?> postedDate,
  Value<DateTime> discoveredAt,
  Value<bool> isSaved,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$JobsTableReferences
    extends BaseReferences<_$AppDatabase, $JobsTable, Job> {
  $$JobsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$JobApplicationsTable, List<JobApplication>>
  _jobApplicationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.jobApplications,
    aliasName: 'jobs__id__job_applications__job_id',
  );

  $$JobApplicationsTableProcessedTableManager get jobApplicationsRefs {
    final manager = $$JobApplicationsTableTableManager(
      $_db,
      $_db.jobApplications,
    ).filter((f) => f.jobId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _jobApplicationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$JobsTableFilterComposer extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableFilterComposer({
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

  ColumnFilters<String> get company => $composableBuilder(
    column: $table.company,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get salary => $composableBuilder(
    column: $table.salary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employmentType => $composableBuilder(
    column: $table.employmentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get experienceRequirement => $composableBuilder(
    column: $table.experienceRequirement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skills => $composableBuilder(
    column: $table.skills,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get postedDate => $composableBuilder(
    column: $table.postedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get discoveredAt => $composableBuilder(
    column: $table.discoveredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSaved => $composableBuilder(
    column: $table.isSaved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
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

  Expression<bool> jobApplicationsRefs(
    Expression<bool> Function($$JobApplicationsTableFilterComposer f) f,
  ) {
    final $$JobApplicationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jobApplications,
      getReferencedColumn: (t) => t.jobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobApplicationsTableFilterComposer(
            $db: $db,
            $table: $db.jobApplications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$JobsTableOrderingComposer extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableOrderingComposer({
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

  ColumnOrderings<String> get company => $composableBuilder(
    column: $table.company,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get salary => $composableBuilder(
    column: $table.salary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employmentType => $composableBuilder(
    column: $table.employmentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get experienceRequirement => $composableBuilder(
    column: $table.experienceRequirement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skills => $composableBuilder(
    column: $table.skills,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get postedDate => $composableBuilder(
    column: $table.postedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get discoveredAt => $composableBuilder(
    column: $table.discoveredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSaved => $composableBuilder(
    column: $table.isSaved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
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

class $$JobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableAnnotationComposer({
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

  GeneratedColumn<String> get company =>
      $composableBuilder(column: $table.company, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get salary =>
      $composableBuilder(column: $table.salary, builder: (column) => column);

  GeneratedColumn<String> get employmentType => $composableBuilder(
    column: $table.employmentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get experienceRequirement => $composableBuilder(
    column: $table.experienceRequirement,
    builder: (column) => column,
  );

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get skills =>
      $composableBuilder(column: $table.skills, builder: (column) => column);

  GeneratedColumn<DateTime> get postedDate => $composableBuilder(
    column: $table.postedDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get discoveredAt => $composableBuilder(
    column: $table.discoveredAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSaved =>
      $composableBuilder(column: $table.isSaved, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> jobApplicationsRefs<T extends Object>(
    Expression<T> Function($$JobApplicationsTableAnnotationComposer a) f,
  ) {
    final $$JobApplicationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jobApplications,
      getReferencedColumn: (t) => t.jobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobApplicationsTableAnnotationComposer(
            $db: $db,
            $table: $db.jobApplications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$JobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JobsTable,
          Job,
          $$JobsTableFilterComposer,
          $$JobsTableOrderingComposer,
          $$JobsTableAnnotationComposer,
          $$JobsTableCreateCompanionBuilder,
          $$JobsTableUpdateCompanionBuilder,
          (Job, $$JobsTableReferences),
          Job,
          PrefetchHooks Function({bool jobApplicationsRefs})
        > {
  $$JobsTableTableManager(_$AppDatabase db, $JobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> company = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> salary = const Value.absent(),
                Value<String?> employmentType = const Value.absent(),
                Value<String?> experienceRequirement = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> skills = const Value.absent(),
                Value<DateTime?> postedDate = const Value.absent(),
                Value<DateTime> discoveredAt = const Value.absent(),
                Value<bool> isSaved = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobsCompanion(
                id: id,
                title: title,
                company: company,
                location: location,
                salary: salary,
                employmentType: employmentType,
                experienceRequirement: experienceRequirement,
                url: url,
                source: source,
                description: description,
                skills: skills,
                postedDate: postedDate,
                discoveredAt: discoveredAt,
                isSaved: isSaved,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String company,
                Value<String?> location = const Value.absent(),
                Value<String?> salary = const Value.absent(),
                Value<String?> employmentType = const Value.absent(),
                Value<String?> experienceRequirement = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> skills = const Value.absent(),
                Value<DateTime?> postedDate = const Value.absent(),
                Value<DateTime> discoveredAt = const Value.absent(),
                Value<bool> isSaved = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobsCompanion.insert(
                id: id,
                title: title,
                company: company,
                location: location,
                salary: salary,
                employmentType: employmentType,
                experienceRequirement: experienceRequirement,
                url: url,
                source: source,
                description: description,
                skills: skills,
                postedDate: postedDate,
                discoveredAt: discoveredAt,
                isSaved: isSaved,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JobsTable, Job>(table),
                  $$JobsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({jobApplicationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (jobApplicationsRefs) db.jobApplications,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (jobApplicationsRefs)
                    await $_getPrefetchedData<Job, $JobsTable, JobApplication>(
                      currentTable: table,
                      referencedTable: $$JobsTableReferences
                          ._jobApplicationsRefsTable(db),
                      managerFromTypedResult: (p0) => $$JobsTableReferences(
                        db,
                        table,
                        p0,
                      ).jobApplicationsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.jobId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$JobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JobsTable,
      Job,
      $$JobsTableFilterComposer,
      $$JobsTableOrderingComposer,
      $$JobsTableAnnotationComposer,
      $$JobsTableCreateCompanionBuilder,
      $$JobsTableUpdateCompanionBuilder,
      (Job, $$JobsTableReferences),
      Job,
      PrefetchHooks Function({bool jobApplicationsRefs})
    >;
typedef $$JobApplicationsTableCreateCompanionBuilder =
    JobApplicationsCompanion Function({
      required String id,
      Value<String?> jobId,
      required String company,
      required String role,
      Value<String?> salary,
      Value<String?> location,
      Value<String?> url,
      Value<String> status,
      Value<DateTime?> appliedAt,
      Value<DateTime?> followUpDate,
      Value<DateTime?> interviewDate,
      Value<String?> interviewStage,
      Value<String?> recruiterName,
      Value<String?> recruiterContact,
      Value<String?> resumeId,
      Value<String?> resumeUsed,
      Value<String?> coverLetterReference,
      Value<String?> nextAction,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$JobApplicationsTableUpdateCompanionBuilder =
    JobApplicationsCompanion Function({
      Value<String> id,
      Value<String?> jobId,
      Value<String> company,
      Value<String> role,
      Value<String?> salary,
      Value<String?> location,
      Value<String?> url,
      Value<String> status,
      Value<DateTime?> appliedAt,
      Value<DateTime?> followUpDate,
      Value<DateTime?> interviewDate,
      Value<String?> interviewStage,
      Value<String?> recruiterName,
      Value<String?> recruiterContact,
      Value<String?> resumeId,
      Value<String?> resumeUsed,
      Value<String?> coverLetterReference,
      Value<String?> nextAction,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$JobApplicationsTableReferences
    extends
        BaseReferences<_$AppDatabase, $JobApplicationsTable, JobApplication> {
  $$JobApplicationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $JobsTable _jobIdTable(_$AppDatabase db) =>
      db.jobs.createAlias('job_applications__job_id__jobs__id');

  $$JobsTableProcessedTableManager? get jobId {
    final $_column = $_itemColumn<String>('job_id');
    if ($_column == null) return null;
    final manager = $$JobsTableTableManager(
      $_db,
      $_db.jobs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_jobIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ResumesTable _resumeIdTable(_$AppDatabase db) =>
      db.resumes.createAlias('job_applications__resume_id__resumes__id');

  $$ResumesTableProcessedTableManager? get resumeId {
    final $_column = $_itemColumn<String>('resume_id');
    if ($_column == null) return null;
    final manager = $$ResumesTableTableManager(
      $_db,
      $_db.resumes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_resumeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$JobApplicationsTableFilterComposer
    extends Composer<_$AppDatabase, $JobApplicationsTable> {
  $$JobApplicationsTableFilterComposer({
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

  ColumnFilters<String> get company => $composableBuilder(
    column: $table.company,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get salary => $composableBuilder(
    column: $table.salary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get followUpDate => $composableBuilder(
    column: $table.followUpDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get interviewDate => $composableBuilder(
    column: $table.interviewDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get interviewStage => $composableBuilder(
    column: $table.interviewStage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recruiterName => $composableBuilder(
    column: $table.recruiterName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recruiterContact => $composableBuilder(
    column: $table.recruiterContact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resumeUsed => $composableBuilder(
    column: $table.resumeUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverLetterReference => $composableBuilder(
    column: $table.coverLetterReference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextAction => $composableBuilder(
    column: $table.nextAction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
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

  $$JobsTableFilterComposer get jobId {
    final $$JobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableFilterComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ResumesTableFilterComposer get resumeId {
    final $$ResumesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resumeId,
      referencedTable: $db.resumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResumesTableFilterComposer(
            $db: $db,
            $table: $db.resumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JobApplicationsTableOrderingComposer
    extends Composer<_$AppDatabase, $JobApplicationsTable> {
  $$JobApplicationsTableOrderingComposer({
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

  ColumnOrderings<String> get company => $composableBuilder(
    column: $table.company,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get salary => $composableBuilder(
    column: $table.salary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get followUpDate => $composableBuilder(
    column: $table.followUpDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get interviewDate => $composableBuilder(
    column: $table.interviewDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get interviewStage => $composableBuilder(
    column: $table.interviewStage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recruiterName => $composableBuilder(
    column: $table.recruiterName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recruiterContact => $composableBuilder(
    column: $table.recruiterContact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resumeUsed => $composableBuilder(
    column: $table.resumeUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverLetterReference => $composableBuilder(
    column: $table.coverLetterReference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextAction => $composableBuilder(
    column: $table.nextAction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
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

  $$JobsTableOrderingComposer get jobId {
    final $$JobsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableOrderingComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ResumesTableOrderingComposer get resumeId {
    final $$ResumesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resumeId,
      referencedTable: $db.resumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResumesTableOrderingComposer(
            $db: $db,
            $table: $db.resumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JobApplicationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JobApplicationsTable> {
  $$JobApplicationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get company =>
      $composableBuilder(column: $table.company, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get salary =>
      $composableBuilder(column: $table.salary, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get appliedAt =>
      $composableBuilder(column: $table.appliedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get followUpDate => $composableBuilder(
    column: $table.followUpDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get interviewDate => $composableBuilder(
    column: $table.interviewDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get interviewStage => $composableBuilder(
    column: $table.interviewStage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recruiterName => $composableBuilder(
    column: $table.recruiterName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recruiterContact => $composableBuilder(
    column: $table.recruiterContact,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resumeUsed => $composableBuilder(
    column: $table.resumeUsed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverLetterReference => $composableBuilder(
    column: $table.coverLetterReference,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nextAction => $composableBuilder(
    column: $table.nextAction,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$JobsTableAnnotationComposer get jobId {
    final $$JobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableAnnotationComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ResumesTableAnnotationComposer get resumeId {
    final $$ResumesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.resumeId,
      referencedTable: $db.resumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResumesTableAnnotationComposer(
            $db: $db,
            $table: $db.resumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JobApplicationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JobApplicationsTable,
          JobApplication,
          $$JobApplicationsTableFilterComposer,
          $$JobApplicationsTableOrderingComposer,
          $$JobApplicationsTableAnnotationComposer,
          $$JobApplicationsTableCreateCompanionBuilder,
          $$JobApplicationsTableUpdateCompanionBuilder,
          (JobApplication, $$JobApplicationsTableReferences),
          JobApplication,
          PrefetchHooks Function({bool jobId, bool resumeId})
        > {
  $$JobApplicationsTableTableManager(
    _$AppDatabase db,
    $JobApplicationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobApplicationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobApplicationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobApplicationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> jobId = const Value.absent(),
                Value<String> company = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> salary = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> appliedAt = const Value.absent(),
                Value<DateTime?> followUpDate = const Value.absent(),
                Value<DateTime?> interviewDate = const Value.absent(),
                Value<String?> interviewStage = const Value.absent(),
                Value<String?> recruiterName = const Value.absent(),
                Value<String?> recruiterContact = const Value.absent(),
                Value<String?> resumeId = const Value.absent(),
                Value<String?> resumeUsed = const Value.absent(),
                Value<String?> coverLetterReference = const Value.absent(),
                Value<String?> nextAction = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobApplicationsCompanion(
                id: id,
                jobId: jobId,
                company: company,
                role: role,
                salary: salary,
                location: location,
                url: url,
                status: status,
                appliedAt: appliedAt,
                followUpDate: followUpDate,
                interviewDate: interviewDate,
                interviewStage: interviewStage,
                recruiterName: recruiterName,
                recruiterContact: recruiterContact,
                resumeId: resumeId,
                resumeUsed: resumeUsed,
                coverLetterReference: coverLetterReference,
                nextAction: nextAction,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> jobId = const Value.absent(),
                required String company,
                required String role,
                Value<String?> salary = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> appliedAt = const Value.absent(),
                Value<DateTime?> followUpDate = const Value.absent(),
                Value<DateTime?> interviewDate = const Value.absent(),
                Value<String?> interviewStage = const Value.absent(),
                Value<String?> recruiterName = const Value.absent(),
                Value<String?> recruiterContact = const Value.absent(),
                Value<String?> resumeId = const Value.absent(),
                Value<String?> resumeUsed = const Value.absent(),
                Value<String?> coverLetterReference = const Value.absent(),
                Value<String?> nextAction = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobApplicationsCompanion.insert(
                id: id,
                jobId: jobId,
                company: company,
                role: role,
                salary: salary,
                location: location,
                url: url,
                status: status,
                appliedAt: appliedAt,
                followUpDate: followUpDate,
                interviewDate: interviewDate,
                interviewStage: interviewStage,
                recruiterName: recruiterName,
                recruiterContact: recruiterContact,
                resumeId: resumeId,
                resumeUsed: resumeUsed,
                coverLetterReference: coverLetterReference,
                nextAction: nextAction,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JobApplicationsTable, JobApplication>(table),
                  $$JobApplicationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({jobId = false, resumeId = false}) {
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
                    if (jobId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.jobId,
                        referencedTable: $$JobApplicationsTableReferences
                            ._jobIdTable(db),
                        referencedColumn: $$JobApplicationsTableReferences
                            ._jobIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (resumeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.resumeId,
                        referencedTable: $$JobApplicationsTableReferences
                            ._resumeIdTable(db),
                        referencedColumn: $$JobApplicationsTableReferences
                            ._resumeIdTable(db)
                            .id,
                      ) as T;
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

typedef $$JobApplicationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JobApplicationsTable,
      JobApplication,
      $$JobApplicationsTableFilterComposer,
      $$JobApplicationsTableOrderingComposer,
      $$JobApplicationsTableAnnotationComposer,
      $$JobApplicationsTableCreateCompanionBuilder,
      $$JobApplicationsTableUpdateCompanionBuilder,
      (JobApplication, $$JobApplicationsTableReferences),
      JobApplication,
      PrefetchHooks Function({bool jobId, bool resumeId})
    >;
typedef $$SavedSearchesTableCreateCompanionBuilder =
    SavedSearchesCompanion Function({
      required String id,
      required String name,
      Value<String?> keywords,
      Value<String?> jobTitle,
      Value<String?> company,
      Value<String?> location,
      Value<String?> remotePreference,
      Value<String?> employmentType,
      Value<String?> experience,
      Value<String?> salary,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$SavedSearchesTableUpdateCompanionBuilder =
    SavedSearchesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> keywords,
      Value<String?> jobTitle,
      Value<String?> company,
      Value<String?> location,
      Value<String?> remotePreference,
      Value<String?> employmentType,
      Value<String?> experience,
      Value<String?> salary,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SavedSearchesTableFilterComposer
    extends Composer<_$AppDatabase, $SavedSearchesTable> {
  $$SavedSearchesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keywords => $composableBuilder(
    column: $table.keywords,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobTitle => $composableBuilder(
    column: $table.jobTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get company => $composableBuilder(
    column: $table.company,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remotePreference => $composableBuilder(
    column: $table.remotePreference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employmentType => $composableBuilder(
    column: $table.employmentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get experience => $composableBuilder(
    column: $table.experience,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get salary => $composableBuilder(
    column: $table.salary,
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
}

class $$SavedSearchesTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedSearchesTable> {
  $$SavedSearchesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keywords => $composableBuilder(
    column: $table.keywords,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobTitle => $composableBuilder(
    column: $table.jobTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get company => $composableBuilder(
    column: $table.company,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remotePreference => $composableBuilder(
    column: $table.remotePreference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employmentType => $composableBuilder(
    column: $table.employmentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get experience => $composableBuilder(
    column: $table.experience,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get salary => $composableBuilder(
    column: $table.salary,
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

class $$SavedSearchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedSearchesTable> {
  $$SavedSearchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get keywords =>
      $composableBuilder(column: $table.keywords, builder: (column) => column);

  GeneratedColumn<String> get jobTitle =>
      $composableBuilder(column: $table.jobTitle, builder: (column) => column);

  GeneratedColumn<String> get company =>
      $composableBuilder(column: $table.company, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get remotePreference => $composableBuilder(
    column: $table.remotePreference,
    builder: (column) => column,
  );

  GeneratedColumn<String> get employmentType => $composableBuilder(
    column: $table.employmentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get experience => $composableBuilder(
    column: $table.experience,
    builder: (column) => column,
  );

  GeneratedColumn<String> get salary =>
      $composableBuilder(column: $table.salary, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SavedSearchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedSearchesTable,
          SavedSearch,
          $$SavedSearchesTableFilterComposer,
          $$SavedSearchesTableOrderingComposer,
          $$SavedSearchesTableAnnotationComposer,
          $$SavedSearchesTableCreateCompanionBuilder,
          $$SavedSearchesTableUpdateCompanionBuilder,
          (
            SavedSearch,
            BaseReferences<_$AppDatabase, $SavedSearchesTable, SavedSearch>,
          ),
          SavedSearch,
          PrefetchHooks Function()
        > {
  $$SavedSearchesTableTableManager(_$AppDatabase db, $SavedSearchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedSearchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedSearchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedSearchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> keywords = const Value.absent(),
                Value<String?> jobTitle = const Value.absent(),
                Value<String?> company = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> remotePreference = const Value.absent(),
                Value<String?> employmentType = const Value.absent(),
                Value<String?> experience = const Value.absent(),
                Value<String?> salary = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedSearchesCompanion(
                id: id,
                name: name,
                keywords: keywords,
                jobTitle: jobTitle,
                company: company,
                location: location,
                remotePreference: remotePreference,
                employmentType: employmentType,
                experience: experience,
                salary: salary,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> keywords = const Value.absent(),
                Value<String?> jobTitle = const Value.absent(),
                Value<String?> company = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> remotePreference = const Value.absent(),
                Value<String?> employmentType = const Value.absent(),
                Value<String?> experience = const Value.absent(),
                Value<String?> salary = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedSearchesCompanion.insert(
                id: id,
                name: name,
                keywords: keywords,
                jobTitle: jobTitle,
                company: company,
                location: location,
                remotePreference: remotePreference,
                employmentType: employmentType,
                experience: experience,
                salary: salary,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavedSearchesTable, SavedSearch>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SavedSearchesTable,
                    SavedSearch
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedSearchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedSearchesTable,
      SavedSearch,
      $$SavedSearchesTableFilterComposer,
      $$SavedSearchesTableOrderingComposer,
      $$SavedSearchesTableAnnotationComposer,
      $$SavedSearchesTableCreateCompanionBuilder,
      $$SavedSearchesTableUpdateCompanionBuilder,
      (
        SavedSearch,
        BaseReferences<_$AppDatabase, $SavedSearchesTable, SavedSearch>,
      ),
      SavedSearch,
      PrefetchHooks Function()
    >;
typedef $$EODNotesTableCreateCompanionBuilder = EODNotesCompanion Function({
  required String id,
  required DateTime date,
  required String completedWork,
  required String inProgressWork,
  Value<String?> blockers,
  Value<String?> tomorrowPlan,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$EODNotesTableUpdateCompanionBuilder = EODNotesCompanion Function({
  Value<String> id,
  Value<DateTime> date,
  Value<String> completedWork,
  Value<String> inProgressWork,
  Value<String?> blockers,
  Value<String?> tomorrowPlan,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$EODNotesTableFilterComposer
    extends Composer<_$AppDatabase, $EODNotesTable> {
  $$EODNotesTableFilterComposer({
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

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedWork => $composableBuilder(
    column: $table.completedWork,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inProgressWork => $composableBuilder(
    column: $table.inProgressWork,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blockers => $composableBuilder(
    column: $table.blockers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tomorrowPlan => $composableBuilder(
    column: $table.tomorrowPlan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
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
}

class $$EODNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $EODNotesTable> {
  $$EODNotesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedWork => $composableBuilder(
    column: $table.completedWork,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inProgressWork => $composableBuilder(
    column: $table.inProgressWork,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blockers => $composableBuilder(
    column: $table.blockers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tomorrowPlan => $composableBuilder(
    column: $table.tomorrowPlan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
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

class $$EODNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EODNotesTable> {
  $$EODNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get completedWork => $composableBuilder(
    column: $table.completedWork,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inProgressWork => $composableBuilder(
    column: $table.inProgressWork,
    builder: (column) => column,
  );

  GeneratedColumn<String> get blockers =>
      $composableBuilder(column: $table.blockers, builder: (column) => column);

  GeneratedColumn<String> get tomorrowPlan => $composableBuilder(
    column: $table.tomorrowPlan,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EODNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EODNotesTable,
          EODNote,
          $$EODNotesTableFilterComposer,
          $$EODNotesTableOrderingComposer,
          $$EODNotesTableAnnotationComposer,
          $$EODNotesTableCreateCompanionBuilder,
          $$EODNotesTableUpdateCompanionBuilder,
          (EODNote, BaseReferences<_$AppDatabase, $EODNotesTable, EODNote>),
          EODNote,
          PrefetchHooks Function()
        > {
  $$EODNotesTableTableManager(_$AppDatabase db, $EODNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EODNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EODNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EODNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> completedWork = const Value.absent(),
                Value<String> inProgressWork = const Value.absent(),
                Value<String?> blockers = const Value.absent(),
                Value<String?> tomorrowPlan = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EODNotesCompanion(
                id: id,
                date: date,
                completedWork: completedWork,
                inProgressWork: inProgressWork,
                blockers: blockers,
                tomorrowPlan: tomorrowPlan,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime date,
                required String completedWork,
                required String inProgressWork,
                Value<String?> blockers = const Value.absent(),
                Value<String?> tomorrowPlan = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EODNotesCompanion.insert(
                id: id,
                date: date,
                completedWork: completedWork,
                inProgressWork: inProgressWork,
                blockers: blockers,
                tomorrowPlan: tomorrowPlan,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EODNotesTable, EODNote>(table),
                  BaseReferences<_$AppDatabase, $EODNotesTable, EODNote>(
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

typedef $$EODNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EODNotesTable,
      EODNote,
      $$EODNotesTableFilterComposer,
      $$EODNotesTableOrderingComposer,
      $$EODNotesTableAnnotationComposer,
      $$EODNotesTableCreateCompanionBuilder,
      $$EODNotesTableUpdateCompanionBuilder,
      (EODNote, BaseReferences<_$AppDatabase, $EODNotesTable, EODNote>),
      EODNote,
      PrefetchHooks Function()
    >;
typedef $$ThingsToAsksTableCreateCompanionBuilder =
    ThingsToAsksCompanion Function({
      required String id,
      required String title,
      Value<String?> description,
      Value<String> priority,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$ThingsToAsksTableUpdateCompanionBuilder =
    ThingsToAsksCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> description,
      Value<String> priority,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

class $$ThingsToAsksTableFilterComposer
    extends Composer<_$AppDatabase, $ThingsToAsksTable> {
  $$ThingsToAsksTableFilterComposer({
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ThingsToAsksTableOrderingComposer
    extends Composer<_$AppDatabase, $ThingsToAsksTable> {
  $$ThingsToAsksTableOrderingComposer({
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ThingsToAsksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ThingsToAsksTable> {
  $$ThingsToAsksTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$ThingsToAsksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ThingsToAsksTable,
          ThingsToAsk,
          $$ThingsToAsksTableFilterComposer,
          $$ThingsToAsksTableOrderingComposer,
          $$ThingsToAsksTableAnnotationComposer,
          $$ThingsToAsksTableCreateCompanionBuilder,
          $$ThingsToAsksTableUpdateCompanionBuilder,
          (
            ThingsToAsk,
            BaseReferences<_$AppDatabase, $ThingsToAsksTable, ThingsToAsk>,
          ),
          ThingsToAsk,
          PrefetchHooks Function()
        > {
  $$ThingsToAsksTableTableManager(_$AppDatabase db, $ThingsToAsksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ThingsToAsksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ThingsToAsksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ThingsToAsksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ThingsToAsksCompanion(
                id: id,
                title: title,
                description: description,
                priority: priority,
                status: status,
                createdAt: createdAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ThingsToAsksCompanion.insert(
                id: id,
                title: title,
                description: description,
                priority: priority,
                status: status,
                createdAt: createdAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ThingsToAsksTable, ThingsToAsk>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ThingsToAsksTable,
                    ThingsToAsk
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ThingsToAsksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ThingsToAsksTable,
      ThingsToAsk,
      $$ThingsToAsksTableFilterComposer,
      $$ThingsToAsksTableOrderingComposer,
      $$ThingsToAsksTableAnnotationComposer,
      $$ThingsToAsksTableCreateCompanionBuilder,
      $$ThingsToAsksTableUpdateCompanionBuilder,
      (
        ThingsToAsk,
        BaseReferences<_$AppDatabase, $ThingsToAsksTable, ThingsToAsk>,
      ),
      ThingsToAsk,
      PrefetchHooks Function()
    >;
typedef $$WorkNotesTableCreateCompanionBuilder = WorkNotesCompanion Function({
  required String id,
  required String title,
  required String content,
  Value<String> noteType,
  Value<String?> projectId,
  Value<DateTime?> meetingDate,
  Value<String?> participants,
  Value<String?> actionItems,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$WorkNotesTableUpdateCompanionBuilder = WorkNotesCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> content,
  Value<String> noteType,
  Value<String?> projectId,
  Value<DateTime?> meetingDate,
  Value<String?> participants,
  Value<String?> actionItems,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$WorkNotesTableReferences
    extends BaseReferences<_$AppDatabase, $WorkNotesTable, WorkNote> {
  $$WorkNotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias('work_notes__project_id__projects__id');

  $$ProjectsTableProcessedTableManager? get projectId {
    final $_column = $_itemColumn<String>('project_id');
    if ($_column == null) return null;
    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WorkNotesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkNotesTable> {
  $$WorkNotesTableFilterComposer({
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

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteType => $composableBuilder(
    column: $table.noteType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get meetingDate => $composableBuilder(
    column: $table.meetingDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get participants => $composableBuilder(
    column: $table.participants,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionItems => $composableBuilder(
    column: $table.actionItems,
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

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkNotesTable> {
  $$WorkNotesTableOrderingComposer({
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

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteType => $composableBuilder(
    column: $table.noteType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get meetingDate => $composableBuilder(
    column: $table.meetingDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get participants => $composableBuilder(
    column: $table.participants,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionItems => $composableBuilder(
    column: $table.actionItems,
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

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkNotesTable> {
  $$WorkNotesTableAnnotationComposer({
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

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get noteType =>
      $composableBuilder(column: $table.noteType, builder: (column) => column);

  GeneratedColumn<DateTime> get meetingDate => $composableBuilder(
    column: $table.meetingDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get participants => $composableBuilder(
    column: $table.participants,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actionItems => $composableBuilder(
    column: $table.actionItems,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkNotesTable,
          WorkNote,
          $$WorkNotesTableFilterComposer,
          $$WorkNotesTableOrderingComposer,
          $$WorkNotesTableAnnotationComposer,
          $$WorkNotesTableCreateCompanionBuilder,
          $$WorkNotesTableUpdateCompanionBuilder,
          (WorkNote, $$WorkNotesTableReferences),
          WorkNote,
          PrefetchHooks Function({bool projectId})
        > {
  $$WorkNotesTableTableManager(_$AppDatabase db, $WorkNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> noteType = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<DateTime?> meetingDate = const Value.absent(),
                Value<String?> participants = const Value.absent(),
                Value<String?> actionItems = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkNotesCompanion(
                id: id,
                title: title,
                content: content,
                noteType: noteType,
                projectId: projectId,
                meetingDate: meetingDate,
                participants: participants,
                actionItems: actionItems,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String content,
                Value<String> noteType = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<DateTime?> meetingDate = const Value.absent(),
                Value<String?> participants = const Value.absent(),
                Value<String?> actionItems = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkNotesCompanion.insert(
                id: id,
                title: title,
                content: content,
                noteType: noteType,
                projectId: projectId,
                meetingDate: meetingDate,
                participants: participants,
                actionItems: actionItems,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkNotesTable, WorkNote>(table),
                  $$WorkNotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
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
                    if (projectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.projectId,
                        referencedTable: $$WorkNotesTableReferences
                            ._projectIdTable(db),
                        referencedColumn: $$WorkNotesTableReferences
                            ._projectIdTable(db)
                            .id,
                      ) as T;
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

typedef $$WorkNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkNotesTable,
      WorkNote,
      $$WorkNotesTableFilterComposer,
      $$WorkNotesTableOrderingComposer,
      $$WorkNotesTableAnnotationComposer,
      $$WorkNotesTableCreateCompanionBuilder,
      $$WorkNotesTableUpdateCompanionBuilder,
      (WorkNote, $$WorkNotesTableReferences),
      WorkNote,
      PrefetchHooks Function({bool projectId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserProfilesTableTableManager get userProfiles =>
      $$UserProfilesTableTableManager(_db, _db.userProfiles);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$ResumesTableTableManager get resumes =>
      $$ResumesTableTableManager(_db, _db.resumes);
  $$JobsTableTableManager get jobs => $$JobsTableTableManager(_db, _db.jobs);
  $$JobApplicationsTableTableManager get jobApplications =>
      $$JobApplicationsTableTableManager(_db, _db.jobApplications);
  $$SavedSearchesTableTableManager get savedSearches =>
      $$SavedSearchesTableTableManager(_db, _db.savedSearches);
  $$EODNotesTableTableManager get eODNotes =>
      $$EODNotesTableTableManager(_db, _db.eODNotes);
  $$ThingsToAsksTableTableManager get thingsToAsks =>
      $$ThingsToAsksTableTableManager(_db, _db.thingsToAsks);
  $$WorkNotesTableTableManager get workNotes =>
      $$WorkNotesTableTableManager(_db, _db.workNotes);
}
