String formatDate(dynamic dateStr) {
  if (dateStr == null) return "";
  try {
    DateTime date = dateStr is DateTime
        ? dateStr
        : DateTime.parse(dateStr.toString());
    return "${date.year}-${date.month.toString().padLeft(2, '0')}";
  } catch (e) {
    return "";
  }
}
