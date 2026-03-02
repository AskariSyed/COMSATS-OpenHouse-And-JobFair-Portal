import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

IconData getPlatformIcon(String platform) {
  final p = platform.toLowerCase();

  if (p.contains('github')) return FontAwesomeIcons.github;
  if (p.contains('linkedin')) return FontAwesomeIcons.linkedinIn;
  if (p.contains('twitter')) return FontAwesomeIcons.twitter;
  if (p.contains('facebook')) return FontAwesomeIcons.facebookF;
  if (p.contains('instagram')) return FontAwesomeIcons.instagram;
  if (p.contains('youtube')) return FontAwesomeIcons.youtube;
  if (p.contains('website')) return FontAwesomeIcons.globe;
  if (p.contains('stack')) return FontAwesomeIcons.stackOverflow;
  if (p.contains('medium')) return FontAwesomeIcons.medium;
  if (p.contains('dev')) return FontAwesomeIcons.dev;
  if (p.contains('twitch')) return FontAwesomeIcons.twitch;
  if (p.contains('reddit')) return FontAwesomeIcons.redditAlien;
  if (p.contains('pinterest')) return FontAwesomeIcons.pinterestP;
  if (p.contains('quora')) return FontAwesomeIcons.quora;
  if (p.contains('slack')) return FontAwesomeIcons.slack;

  return Icons.link;
}
