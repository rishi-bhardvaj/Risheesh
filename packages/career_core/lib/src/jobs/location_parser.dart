enum WorkMode {
  remote,
  hybrid,
  onsite,
  unknown,
}

class LocationDetails {
  final String city;
  final String country;
  final WorkMode workMode;
  final List<String> restrictedCountries;
  final bool isRestrictedToUs;

  const LocationDetails({
    this.city = '',
    this.country = '',
    this.workMode = WorkMode.unknown,
    this.restrictedCountries = const [],
    this.isRestrictedToUs = false,
  });
}

class LocationParser {
  LocationParser._();

  static const List<String> techCities = [
    'Bengaluru', 'Bangalore', 'Hyderabad', 'Pune', 'Mumbai', 'Delhi', 'Noida',
    'Gurugram', 'Gurgaon', 'Chennai', 'Kolkata', 'Ahmedabad', 'Kochi', 'San Francisco',
    'New York', 'Seattle', 'Austin', 'London', 'Berlin', 'Amsterdam', 'Singapore', 'Toronto',
  ];

  static LocationDetails parse({
    String? location,
    String? title,
    String? description,
  }) {
    final combined = '${location ?? ''} ${title ?? ''} ${description ?? ''}'.toLowerCase();
    var mode = WorkMode.unknown;

    if (combined.contains('hybrid')) {
      mode = WorkMode.hybrid;
    } else if (combined.contains('remote') || combined.contains('wfh') || combined.contains('work from home') || combined.contains('anywhere')) {
      mode = WorkMode.remote;
    } else if (combined.contains('onsite') || combined.contains('on-site') || combined.contains('in-office')) {
      mode = WorkMode.onsite;
    }

    String city = '';
    final locText = location ?? '';
    for (final c in techCities) {
      if (locText.toLowerCase().contains(c.toLowerCase()) || combined.contains(c.toLowerCase())) {
        city = (c == 'Bangalore' ? 'Bengaluru' : (c == 'Gurgaon' ? 'Gurugram' : c));
        break;
      }
    }

    String country = '';
    if (city.isNotEmpty && ['Bengaluru', 'Hyderabad', 'Pune', 'Mumbai', 'Delhi', 'Noida', 'Gurugram', 'Chennai', 'Kolkata', 'Ahmedabad', 'Kochi'].contains(city)) {
      country = 'India';
    } else if (combined.contains('india')) {
      country = 'India';
    } else if (combined.contains('united states') || combined.contains('usa') || combined.contains(' u.s.') || combined.contains(' us only')) {
      country = 'United States';
    }

    // Remote restrictions
    final isUsOnly = combined.contains('us only') ||
        combined.contains('u.s. only') ||
        combined.contains('united states only') ||
        combined.contains('authorized to work in the united states') ||
        combined.contains('must reside in the us') ||
        combined.contains('must be based in the us');

    return LocationDetails(
      city: city,
      country: country,
      workMode: mode,
      isRestrictedToUs: isUsOnly,
      restrictedCountries: isUsOnly ? const ['US'] : const [],
    );
  }
}
