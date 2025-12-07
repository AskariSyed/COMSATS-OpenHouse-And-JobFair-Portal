import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:student_job_fair_portal/model/student.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class CVGenerator {
  static Future<void> generateAndSaveCV(
    Student student, {
    String? customEmail,
  }) async {
    final pdf = pw.Document();
    // Load Unicode-capable TTF fonts from assets. Provide a clear fallback
    // if the assets aren't available (the fallback may not support full
    // Unicode; bundling the fonts is recommended).
    pw.Font regularFont;
    pw.Font boldFont;
    try {
      final regularData = await rootBundle.load(
        'assets/fonts/NotoSans-Regular.ttf',
      );
      final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      regularFont = pw.Font.ttf(regularData);
      boldFont = pw.Font.ttf(boldData);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not load bundled fonts from assets: $e');
        print('Attempting to fetch NotoSans from Google via PdfGoogleFonts...');
      }
      // If loading bundled fonts fails (404 on web), try fetching Google
      // hosted NotoSans at runtime via PdfGoogleFonts (printing package).
      try {
        regularFont = await PdfGoogleFonts.notoSansRegular();
        boldFont = await PdfGoogleFonts.notoSansBold();
        if (kDebugMode) print('✅ Loaded NotoSans via PdfGoogleFonts');
      } catch (e2) {
        if (kDebugMode) print('❌ PdfGoogleFonts fetch failed: $e2');
        // Final fallback to a built-in font (may not support full Unicode).
        regularFont = pw.Font.times();
        boldFont = pw.Font.times();
      }
    }

    // Load profile image if available
    pw.ImageProvider? profileImage;
    if (student.profilePicUrl != null && student.profilePicUrl!.isNotEmpty) {
      try {
        // Ensure URL is properly formatted
        String imageUrl = student.profilePicUrl!;
        if (!imageUrl.startsWith('http')) {
          // If relative URL, assume it's from the backend server
          imageUrl =
              'http://192.168.137.1:5158$imageUrl'; // Update with your actual server
        }

        final response = await http
            .get(Uri.parse(imageUrl))
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => http.Response('', 500),
            );

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          profileImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        // Image loading failed, continue without image
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          // --- HEADER: Profile Image & Contact Info ---
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Profile Image
              if (profileImage != null)
                pw.Container(
                  width: 100,
                  height: 100,
                  margin: pw.EdgeInsets.only(right: 20),
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.grey400, width: 2),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 50,
                    verticalRadius: 50,
                    child: pw.Image(profileImage),
                  ),
                ),
              // Contact Info
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      student.user.fullName ?? 'Student Name',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        font: boldFont,
                        fontFallback: [regularFont],
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    if ((customEmail ?? student.user.email).isNotEmpty)
                      pw.Text(
                        'Email: ${customEmail ?? student.user.email}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          font: regularFont,
                          fontFallback: [regularFont],
                        ),
                      ),
                    if (student.user.phone != null &&
                        student.user.phone!.isNotEmpty)
                      pw.Text(
                        'Phone: ${student.user.phone}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          font: regularFont,
                          fontFallback: [regularFont],
                        ),
                      ),
                    if (student.department != null &&
                        student.department!.isNotEmpty)
                      pw.Text(
                        'Department: ${student.department}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          font: regularFont,
                          fontFallback: [regularFont],
                        ),
                      ),
                    if (student.cgpa > 0)
                      pw.Text(
                        'CGPA: ${student.cgpa.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          font: regularFont,
                          fontFallback: [regularFont],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          // Divider
          pw.Container(
            height: 1,
            color: PdfColors.grey400,
            margin: pw.EdgeInsets.symmetric(vertical: 12),
          ),

          // --- EXPERIENCE ---
          if (student.experiences.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  'PROFESSIONAL EXPERIENCE',
                  headerFont: boldFont,
                ),
                ...(student.experiences.toList()
                      ..sort((a, b) => b.startDate.compareTo(a.startDate)))
                    .map((exp) {
                      final startDate = DateFormat(
                        'MMM yyyy',
                      ).format(exp.startDate);
                      final endDate = exp.isCurrent
                          ? 'Present'
                          : DateFormat(
                              'MMM yyyy',
                            ).format(exp.endDate ?? DateTime.now());

                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                exp.role,
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  font: boldFont,
                                ),
                              ),
                              pw.Text(
                                '$startDate - $endDate',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey700,
                                  font: regularFont,
                                  fontFallback: [regularFont],
                                ),
                              ),
                            ],
                          ),
                          pw.Text(
                            'Company: ${exp.companyName}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                              font: regularFont,
                            ),
                          ),
                          if (exp.location != null && exp.location!.isNotEmpty)
                            pw.Text(
                              'Location: ${exp.location}',
                              style: pw.TextStyle(
                                fontSize: 9,
                                font: regularFont,
                              ),
                            ),
                          if (exp.description != null &&
                              exp.description!.isNotEmpty)
                            pw.Padding(
                              padding: pw.EdgeInsets.only(top: 6),
                              child: pw.Text(
                                exp.description!,
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  height: 1.3,
                                  font: regularFont,
                                ),
                              ),
                            ),
                          pw.SizedBox(height: 8),
                        ],
                      );
                    })
                    .toList(),
                pw.SizedBox(height: 4),
              ],
            ),

          // --- EDUCATION ---
          if (student.educations.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('EDUCATION', headerFont: boldFont),
                ...(student.educations.toList()..sort(
                      (a, b) => (b.startDate ?? DateTime(1900)).compareTo(
                        a.startDate ?? DateTime(1900),
                      ),
                    ))
                    .map((edu) {
                      final startYear = DateFormat(
                        'yyyy',
                      ).format(edu.startDate ?? DateTime.now());
                      final endYear = DateFormat(
                        'yyyy',
                      ).format(edu.endDate ?? DateTime.now());

                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                edu.degree,
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  font: boldFont,
                                ),
                              ),
                              pw.Text(
                                '$startYear - $endYear',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey700,
                                  font: regularFont,
                                ),
                              ),
                            ],
                          ),
                          pw.Text(
                            'Institution: ${edu.institutionName}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                              font: regularFont,
                            ),
                          ),
                          if (edu.fieldOfStudy != null &&
                              edu.fieldOfStudy!.isNotEmpty)
                            pw.Text(
                              'Field of Study: ${edu.fieldOfStudy}',
                              style: pw.TextStyle(
                                fontSize: 9,
                                font: regularFont,
                              ),
                            ),
                          pw.SizedBox(height: 8),
                        ],
                      );
                    })
                    .toList(),
                pw.SizedBox(height: 4),
              ],
            ),

          // --- SKILLS ---
          if (student.skills.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('SKILLS', headerFont: boldFont),
                pw.Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: student.skills.map((skill) {
                    return pw.Container(
                      padding: pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        skill,
                        style: pw.TextStyle(
                          fontSize: 9,
                          font: regularFont,
                          fontFallback: [regularFont],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                pw.SizedBox(height: 12),
              ],
            ),

          // --- CERTIFICATIONS ---
          if (student.certifications.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('CERTIFICATIONS', headerFont: boldFont),
                ...(student.certifications.toList()..sort(
                      (a, b) => (b.issueDate ?? DateTime(1900)).compareTo(
                        a.issueDate ?? DateTime(1900),
                      ),
                    ))
                    .map((cert) {
                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                cert.title,
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  font: boldFont,
                                ),
                              ),
                              if (cert.issueDate != null)
                                pw.Text(
                                  DateFormat(
                                    'MMM yyyy',
                                  ).format(cert.issueDate!),
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.grey700,
                                    font: regularFont,
                                  ),
                                ),
                            ],
                          ),
                          if (cert.issuer != null && cert.issuer!.isNotEmpty)
                            pw.Text(
                              'Issuer: ${cert.issuer}',
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey700,
                                font: regularFont,
                              ),
                            ),
                          pw.SizedBox(height: 6),
                        ],
                      );
                    })
                    .toList(),
                pw.SizedBox(height: 4),
              ],
            ),

          // --- PROJECTS ---
          if (student.projects.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('PROJECTS', headerFont: boldFont),
                ...student.projects.map((proj) {
                  final startDate = proj.startDate != null
                      ? DateFormat('MMM yyyy').format(proj.startDate!)
                      : '';
                  final endDate = proj.endDate != null
                      ? DateFormat('MMM yyyy').format(proj.endDate!)
                      : (proj.startDate != null ? 'Present' : '');

                  final dateText = (startDate.isNotEmpty || endDate.isNotEmpty)
                      ? (startDate.isNotEmpty && endDate.isNotEmpty
                            ? '$startDate - $endDate'
                            : startDate.isNotEmpty
                            ? '$startDate - Present'
                            : endDate)
                      : '';

                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            proj.title,
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              font: boldFont,
                            ),
                          ),
                          pw.Text(
                            dateText,
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                              font: regularFont,
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        'Type: ${proj.type.toString().split('.').last}',
                        style: pw.TextStyle(fontSize: 9, font: regularFont),
                      ),
                      if (proj.description != null &&
                          proj.description!.isNotEmpty)
                        pw.Padding(
                          padding: pw.EdgeInsets.only(top: 6),
                          child: pw.Text(
                            proj.description!,
                            style: pw.TextStyle(
                              fontSize: 9,
                              height: 1.3,
                              font: regularFont,
                            ),
                          ),
                        ),
                      if (proj.skills != null && proj.skills!.isNotEmpty)
                        pw.Text(
                          'Skills: ${proj.skills}',
                          style: pw.TextStyle(fontSize: 9, font: regularFont),
                        ),
                      if (proj.gitHubUrl != null && proj.gitHubUrl!.isNotEmpty)
                        pw.Text(
                          'GitHub: ${proj.gitHubUrl}',
                          style: pw.TextStyle(fontSize: 9, font: regularFont),
                        ),
                      if (proj.demoUrl != null && proj.demoUrl!.isNotEmpty)
                        pw.Text(
                          'Demo: ${proj.demoUrl}',
                          style: pw.TextStyle(fontSize: 9, font: regularFont),
                        ),
                      pw.SizedBox(height: 8),
                    ],
                  );
                }).toList(),
                pw.SizedBox(height: 4),
              ],
            ),

          // --- ACHIEVEMENTS ---
          if (student.achievements.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('ACHIEVEMENTS', headerFont: boldFont),
                ...(student.achievements.toList()..sort(
                      (a, b) => b.dateAchieved.compareTo(a.dateAchieved),
                    ))
                    .map((ach) {
                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  ach.title,
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                    font: boldFont,
                                  ),
                                ),
                              ),
                              pw.Text(
                                DateFormat('MMM yyyy').format(ach.dateAchieved),
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey700,
                                  font: regularFont,
                                ),
                              ),
                            ],
                          ),
                          if (ach.description != null &&
                              ach.description!.isNotEmpty)
                            pw.Padding(
                              padding: pw.EdgeInsets.only(top: 4),
                              child: pw.Text(
                                ach.description!,
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  height: 1.3,
                                  font: regularFont,
                                ),
                              ),
                            ),
                          pw.SizedBox(height: 8),
                        ],
                      );
                    })
                    .toList(),
              ],
            ),

          // --- CONTACT LINKS ---
          if (student.contactLinks.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 12),
                _buildSectionHeader('CONTACT LINKS', headerFont: boldFont),
                ...student.contactLinks.map((link) {
                  return pw.Padding(
                    padding: pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      '${link.platform.name.toUpperCase()}: ${link.url}',
                      style: pw.TextStyle(fontSize: 9, font: pw.Font.times()),
                    ),
                  );
                }).toList(),
              ],
            ),
        ],
      ),
    );

    // Generate filename with student name and date
    final fileName =
        '${student.user.fullName?.replaceAll(' ', '_') ?? 'CV'}_${DateTime.now().year}.pdf';

    // Generate PDF bytes
    final pdfBytes = await pdf.save();

    // Check if running on web using kIsWeb
    if (kIsWeb) {
      // Web platform - use browser download
      _downloadPdfWeb(pdfBytes, fileName);
    } else {
      // Mobile platform (Android/iOS) - use printing package
      try {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
        );
      } catch (e) {
        // If printing fails, try sharePdf as fallback
        try {
          await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
        } catch (shareError) {
          rethrow;
        }
      }
    }
  }

  /// Share CV as PDF - uses system share sheet on mobile
  static Future<void> shareCV(Student student, {String? customEmail}) async {
    // Generate the PDF bytes using the same logic as generateAndSaveCV
    final pdfBytes = await _generatePdfBytes(student, customEmail: customEmail);

    final fileName =
        '${student.user.fullName?.replaceAll(' ', '_') ?? 'CV'}_${DateTime.now().year}.pdf';

    // Use Printing.sharePdf to show system share sheet
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }

  /// Internal method to generate PDF bytes
  static Future<Uint8List> _generatePdfBytes(
    Student student, {
    String? customEmail,
  }) async {
    final pdf = pw.Document();

    // Load fonts
    pw.Font regularFont;
    pw.Font boldFont;
    try {
      final regularData = await rootBundle.load(
        'assets/fonts/NotoSans-Regular.ttf',
      );
      final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      regularFont = pw.Font.ttf(regularData);
      boldFont = pw.Font.ttf(boldData);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not load bundled fonts from assets: $e');
        print('Attempting to fetch NotoSans from Google via PdfGoogleFonts...');
      }
      try {
        regularFont = await PdfGoogleFonts.notoSansRegular();
        boldFont = await PdfGoogleFonts.notoSansBold();
        if (kDebugMode) print('✅ Loaded NotoSans via PdfGoogleFonts');
      } catch (e2) {
        if (kDebugMode) print('❌ PdfGoogleFonts fetch failed: $e2');
        regularFont = pw.Font.times();
        boldFont = pw.Font.times();
      }
    }

    // Load profile image if available
    pw.ImageProvider? profileImage;
    if (student.profilePicUrl != null && student.profilePicUrl!.isNotEmpty) {
      try {
        String imageUrl = student.profilePicUrl!;
        if (!imageUrl.startsWith('http')) {
          imageUrl = 'http://192.168.137.1:5158$imageUrl';
        }
        final response = await http
            .get(Uri.parse(imageUrl))
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => http.Response('', 500),
            );
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          profileImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        // Continue without image
      }
    }

    // Use custom email if provided, otherwise use student's email
    final emailToDisplay = customEmail ?? student.user.email;

    // Build the PDF content - same as generateAndSaveCV
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          // --- HEADER: Profile Image & Contact Info ---
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Profile Image
              if (profileImage != null)
                pw.Container(
                  width: 100,
                  height: 100,
                  margin: pw.EdgeInsets.only(right: 20),
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.grey400, width: 2),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 50,
                    verticalRadius: 50,
                    child: pw.Image(profileImage),
                  ),
                ),

              // Contact Info (name, phone, email, location)
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      student.user.fullName ?? 'Student Name',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        font: boldFont,
                        fontFallback: [regularFont],
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    if (emailToDisplay.isNotEmpty)
                      pw.Text(
                        'Email: $emailToDisplay',
                        style: pw.TextStyle(
                          fontSize: 10,
                          font: regularFont,
                          fontFallback: [regularFont],
                        ),
                      ),
                    if (student.user.phone != null &&
                        student.user.phone!.isNotEmpty)
                      pw.Text(
                        'Phone: ${student.user.phone}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          font: regularFont,
                          fontFallback: [regularFont],
                        ),
                      ),
                    if (student.department != null &&
                        student.department!.isNotEmpty)
                      pw.Text(
                        'Department: ${student.department}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          font: regularFont,
                          fontFallback: [regularFont],
                        ),
                      ),
                    if (student.cgpa > 0)
                      pw.Text(
                        'CGPA: ${student.cgpa.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          font: regularFont,
                          fontFallback: [regularFont],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 4),
          // Divider
          pw.Container(
            height: 1,
            color: PdfColors.grey400,
            margin: pw.EdgeInsets.symmetric(vertical: 12),
          ),

          // --- EXPERIENCE ---
          if (student.experiences.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  'PROFESSIONAL EXPERIENCE',
                  headerFont: boldFont,
                ),
                ...(student.experiences.toList()
                      ..sort((a, b) => b.startDate.compareTo(a.startDate)))
                    .map((exp) {
                      final startDate = DateFormat(
                        'MMM yyyy',
                      ).format(exp.startDate);
                      final endDate = exp.isCurrent
                          ? 'Present'
                          : DateFormat(
                              'MMM yyyy',
                            ).format(exp.endDate ?? DateTime.now());

                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                exp.role,
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  font: boldFont,
                                ),
                              ),
                              pw.Text(
                                '$startDate - $endDate',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey700,
                                  font: regularFont,
                                  fontFallback: [regularFont],
                                ),
                              ),
                            ],
                          ),
                          pw.Text(
                            exp.companyName,
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                              font: regularFont,
                              fontFallback: [regularFont],
                            ),
                          ),
                          if (exp.description != null &&
                              exp.description!.isNotEmpty)
                            pw.Padding(
                              padding: pw.EdgeInsets.only(top: 6),
                              child: pw.Text(
                                exp.description!,
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  height: 1.3,
                                  font: regularFont,
                                  fontFallback: [regularFont],
                                ),
                              ),
                            ),
                          pw.SizedBox(height: 12),
                        ],
                      );
                    })
                    .toList(),
              ],
            ),

          // --- EDUCATION ---
          if (student.educations.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('EDUCATION', headerFont: boldFont),
                ...(student.educations.toList()..sort(
                      (a, b) => (b.startDate ?? DateTime(1900)).compareTo(
                        a.startDate ?? DateTime(1900),
                      ),
                    ))
                    .map((edu) {
                      final startYear = DateFormat(
                        'yyyy',
                      ).format(edu.startDate ?? DateTime.now());
                      final endYear = DateFormat(
                        'yyyy',
                      ).format(edu.endDate ?? DateTime.now());

                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                edu.degree,
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  font: boldFont,
                                ),
                              ),
                              pw.Text(
                                '$startYear - $endYear',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey700,
                                  font: regularFont,
                                ),
                              ),
                            ],
                          ),
                          pw.Text(
                            'Institution: ${edu.institutionName}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                              font: regularFont,
                            ),
                          ),
                          if (edu.fieldOfStudy != null &&
                              edu.fieldOfStudy!.isNotEmpty)
                            pw.Text(
                              'Field of Study: ${edu.fieldOfStudy}',
                              style: pw.TextStyle(
                                fontSize: 9,
                                font: regularFont,
                              ),
                            ),
                          pw.SizedBox(height: 8),
                        ],
                      );
                    })
                    .toList(),
                pw.SizedBox(height: 4),
              ],
            ),

          // --- SKILLS ---
          if (student.skills.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('SKILLS', headerFont: boldFont),
                pw.Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: student.skills.map((skill) {
                    return pw.Container(
                      padding: pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        skill,
                        style: pw.TextStyle(
                          fontSize: 9,
                          font: regularFont,
                          fontFallback: [regularFont],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                pw.SizedBox(height: 12),
              ],
            ),

          // --- CERTIFICATIONS ---
          if (student.certifications.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('CERTIFICATIONS', headerFont: boldFont),
                ...(student.certifications.toList()..sort(
                      (a, b) => (b.issueDate ?? DateTime(1900)).compareTo(
                        a.issueDate ?? DateTime(1900),
                      ),
                    ))
                    .map((cert) {
                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                cert.title,
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  font: boldFont,
                                ),
                              ),
                              if (cert.issueDate != null)
                                pw.Text(
                                  DateFormat(
                                    'MMM yyyy',
                                  ).format(cert.issueDate!),
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.grey700,
                                    font: regularFont,
                                  ),
                                ),
                            ],
                          ),
                          if (cert.issuer != null && cert.issuer!.isNotEmpty)
                            pw.Text(
                              'Issuer: ${cert.issuer}',
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey700,
                                font: regularFont,
                              ),
                            ),
                          pw.SizedBox(height: 6),
                        ],
                      );
                    })
                    .toList(),
                pw.SizedBox(height: 4),
              ],
            ),

          // --- PROJECTS ---
          if (student.projects.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('PROJECTS', headerFont: boldFont),
                ...student.projects.map((proj) {
                  final startDate = proj.startDate != null
                      ? DateFormat('MMM yyyy').format(proj.startDate!)
                      : '';
                  final endDate = proj.endDate != null
                      ? DateFormat('MMM yyyy').format(proj.endDate!)
                      : (proj.startDate != null ? 'Present' : '');

                  final dateText = (startDate.isNotEmpty || endDate.isNotEmpty)
                      ? (startDate.isNotEmpty && endDate.isNotEmpty
                            ? '$startDate - $endDate'
                            : startDate.isNotEmpty
                            ? '$startDate - Present'
                            : endDate)
                      : '';

                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            proj.title,
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              font: boldFont,
                            ),
                          ),
                          pw.Text(
                            dateText,
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                              font: regularFont,
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        'Type: ${proj.type.toString().split('.').last}',
                        style: pw.TextStyle(fontSize: 9, font: regularFont),
                      ),
                      if (proj.description != null &&
                          proj.description!.isNotEmpty)
                        pw.Padding(
                          padding: pw.EdgeInsets.only(top: 6),
                          child: pw.Text(
                            proj.description!,
                            style: pw.TextStyle(
                              fontSize: 9,
                              height: 1.3,
                              font: regularFont,
                            ),
                          ),
                        ),
                      if (proj.skills != null && proj.skills!.isNotEmpty)
                        pw.Text(
                          'Skills: ${proj.skills}',
                          style: pw.TextStyle(fontSize: 9, font: regularFont),
                        ),
                      if (proj.gitHubUrl != null && proj.gitHubUrl!.isNotEmpty)
                        pw.Text(
                          'GitHub: ${proj.gitHubUrl}',
                          style: pw.TextStyle(fontSize: 9, font: regularFont),
                        ),
                      if (proj.demoUrl != null && proj.demoUrl!.isNotEmpty)
                        pw.Text(
                          'Demo: ${proj.demoUrl}',
                          style: pw.TextStyle(fontSize: 9, font: regularFont),
                        ),
                      pw.SizedBox(height: 8),
                    ],
                  );
                }).toList(),
                pw.SizedBox(height: 4),
              ],
            ),

          // --- ACHIEVEMENTS ---
          if (student.achievements.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('ACHIEVEMENTS', headerFont: boldFont),
                ...(student.achievements.toList()..sort(
                      (a, b) => b.dateAchieved.compareTo(a.dateAchieved),
                    ))
                    .map((ach) {
                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  ach.title,
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                    font: boldFont,
                                  ),
                                ),
                              ),
                              pw.Text(
                                DateFormat('MMM yyyy').format(ach.dateAchieved),
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey700,
                                  font: regularFont,
                                ),
                              ),
                            ],
                          ),
                          if (ach.description != null &&
                              ach.description!.isNotEmpty)
                            pw.Padding(
                              padding: pw.EdgeInsets.only(top: 4),
                              child: pw.Text(
                                ach.description!,
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  height: 1.3,
                                  font: regularFont,
                                ),
                              ),
                            ),
                          pw.SizedBox(height: 8),
                        ],
                      );
                    })
                    .toList(),
              ],
            ),

          // --- CONTACT LINKS ---
          if (student.contactLinks.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 12),
                _buildSectionHeader('CONTACT LINKS', headerFont: boldFont),
                ...student.contactLinks.map((link) {
                  return pw.Padding(
                    padding: pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      '${link.platform.name.toUpperCase()}: ${link.url}',
                      style: pw.TextStyle(fontSize: 9, font: pw.Font.times()),
                    ),
                  );
                }).toList(),
              ],
            ),
        ],
      ),
    );

    return await pdf.save();
  }

  /// Download PDF on web platform
  static void _downloadPdfWeb(Uint8List pdfBytes, String fileName) {
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final link = html.document.createElement('a') as html.AnchorElement;
    link.href = url;
    link.download = fileName;
    link.click();
    html.Url.revokeObjectUrl(url);
  }

  static pw.Widget _buildSectionHeader(String title, {pw.Font? headerFont}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
            font: headerFont ?? pw.Font.times(),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          height: 1,
          color: PdfColors.blue900,
          margin: pw.EdgeInsets.only(bottom: 8),
        ),
      ],
    );
  }
}
