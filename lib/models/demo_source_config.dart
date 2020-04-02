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
}
