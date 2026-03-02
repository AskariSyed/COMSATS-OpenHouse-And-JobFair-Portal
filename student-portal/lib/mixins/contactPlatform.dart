// Helper function to parse the enum safely
import 'package:student_job_fair_portal/mixins/enums.dart';

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
