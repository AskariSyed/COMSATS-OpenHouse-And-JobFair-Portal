import 'package:student_job_fair_portal/mixins/contactPlatform.dart';
import 'package:student_job_fair_portal/mixins/enums.dart';

String contactPlatformToString(ContactPlatform platform) {
  switch (platform) {
    case ContactPlatform.LinkedIn:
      return 'LinkedIn';
    case ContactPlatform.GitHub:
      return 'GitHub';
    case ContactPlatform.Portfolio:
      return 'Portfolio';
    case ContactPlatform.Twitter:
      return 'Twitter';
    case ContactPlatform.Facebook:
      return 'Facebook';
    case ContactPlatform.Instagram:
      return 'Instagram';
    case ContactPlatform.Other:
      return 'Other';
  }
}
