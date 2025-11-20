enum ContactPlatform {
  LinkedIn,
  GitHub,
  Portfolio,
  Twitter,
  Facebook,
  Instagram,
  Other,
}

// Helper function to parse the enum safely
ContactPlatform contactPlatformFromString(String? platform) {
  switch (platform) {
    case 'LinkedIn':
      return ContactPlatform.LinkedIn;
    case 'GitHub':
      return ContactPlatform.GitHub;
    case 'Portfolio':
      return ContactPlatform.Portfolio;
    case 'Twitter':
      return ContactPlatform.Twitter;
    case 'Facebook':
      return ContactPlatform.Facebook;
    case 'Instagram':
      return ContactPlatform.Instagram;
    default:
      return ContactPlatform.Other;
  }
}
