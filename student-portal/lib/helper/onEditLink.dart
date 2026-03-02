import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/main.dart';
import 'package:student_job_fair_portal/model/contact_link.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/widgets/showDialogueBox.dart';

void onEditLink(dynamic link) {
  showContactLinkDialog(
    navigatorKey.currentContext!,
    link: link,
    onSaveLink: (updated) async {
      await Provider.of<StudentProvider>(
        navigatorKey.currentContext!,
        listen: false,
      ).updateContactLink((link as ContactLink).linkId, updated);
    },
  );
}
