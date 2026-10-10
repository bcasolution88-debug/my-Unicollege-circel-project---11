import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/carousel.dart';
import '../widgets/common.dart';
import '../widgets/events_signup_list.dart';
import 'simple_pages.dart';

/// 09 Events — 活动频道: carousel + 活动报名 list (circular covers) + publish FAB.
class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: const SubHeader(title: '活动列表'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            HeroCarousel(
              slides: kEventSlides,
              height: 148,
              radius: 14,
              interval: Duration(milliseconds: 3800),
              padding: EdgeInsets.fromLTRB(14, 12, 14, 4),
            ),
            EventsSignupList(roundCover: true, showChannelButton: false),
            SizedBox(height: 70),
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const SimplePage(title: '发布活动'))),
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFB923C), Color(0xFFF97316)],
            ),
            boxShadow: [
              BoxShadow(
                  color: Color(0x80F97316),
                  blurRadius: 22,
                  offset: Offset(0, 8)),
            ],
          ),
          child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
        ),
      ),
    );
  }
}
