import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/main.dart';
import 'package:student_job_fair_portal/model/contact_link.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';

void onDeleteLink(dynamic link) async {
  await Provider.of<StudentProvider>(
    navigatorKey.currentContext!,
    listen: false,
  ).deleteContactLink((link as ContactLink).linkId);
}
