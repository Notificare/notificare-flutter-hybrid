class DemoSourceConfig {
  final Config config;
  final String url;
  final String urlScheme;
  final String host;
  final String email;
  final String api;
  final List<String> nativeViews;
  final Social social;
  final MemberCard memberCard;

  DemoSourceConfig(
      {this.config,
      this.url,
      this.urlScheme,
      this.host,
      this.email,
      this.api,
      this.nativeViews,
      this.social,
      this.memberCard});

  factory DemoSourceConfig.fromJson(Map<String, dynamic> json) {
    return DemoSourceConfig(
      config: Config.fromJson(json['config']),
      url: json['url'],
      urlScheme: json['urlScheme'],
      host: json['host'],
      email: json['email'],
      api: json['api'],
      nativeViews: List<String>.from(json['nativeViews']),
      social: Social.fromJson(json['social']),
      memberCard: MemberCard.fromJson(json['memberCard']),
    );
  }

  Map<String, dynamic> toJson() => {
        'config': config.toJson(),
        'url': url,
        'urlScheme': urlScheme,
        'host': host,
        'email': email,
        'api': api,
        'nativeViews': nativeViews,
        'social': social.toJson(),
        'memberCard': memberCard.toJson(),
      };
}

class Config {
  final bool useLocationServices;
  final bool useNavigationDrawer;

  Config({this.useLocationServices, this.useNavigationDrawer});

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      useLocationServices: json['useLocationServices'],
      useNavigationDrawer: json['useNavigationDrawer'],
    );
  }

  Map<String, dynamic> toJson() => {
        'useLocationServices': useLocationServices,
        'useNavigationDrawer': useNavigationDrawer,
      };
}

class Social {
  final String facebook;
  final String twitter;

  Social({this.facebook, this.twitter});

  factory Social.fromJson(Map<String, dynamic> json) {
    return Social(
      facebook: json['facebook'],
      twitter: json['twitter'],
    );
  }

  Map<String, dynamic> toJson() => {
    'facebook': facebook,
    'twitter': twitter,
  };
}

class MemberCard {
  final String templateId;
  final List<MemberCardField> primaryFields;
  final List<MemberCardField> secondaryFields;

  MemberCard({this.templateId, this.primaryFields, this.secondaryFields});

  factory MemberCard.fromJson(Map<String, dynamic> json) {
    return MemberCard(
      templateId: json['templateId'],
      primaryFields: (json['primaryFields'] as List).map((value) {
        return MemberCardField.fromJson(value);
      }).toList(),
      secondaryFields: (json['secondaryFields'] as List).map((value) {
        return MemberCardField.fromJson(value);
      }).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'templateId': templateId,
    'primaryFields': primaryFields.map((value) => value.toJson()).toList(),
    'secondaryFields': secondaryFields.map((value) => value.toJson()).toList(),
  };
}

class MemberCardField {
  final String name;
  final String email;

  MemberCardField({this.name, this.email});

  factory MemberCardField.fromJson(Map<String, dynamic> json) {
    return MemberCardField(
      name: json['name'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
  };
}
