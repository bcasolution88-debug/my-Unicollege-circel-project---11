import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../pages/event_detail_page.dart';
import '../pages/events_page.dart';
import '../state/app_state.dart';
import 'common.dart';

/// 活动报名 title + live event cards.
/// Shared by 首页 bottom section and 活动频道.
///
/// Design rule (final round): event covers are **circular (76×76)** —
/// `roundCover: true` on both the Home page and the Events channel.
class EventsSignupList extends StatelessWidget {
  final int? limit;
  final bool roundCover;
  final bool showChannelButton;

  const EventsSignupList({
    super.key,
    this.limit,
    this.roundCover = true,
    this.showChannelButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final all = context.watch<AppState>().events;
    final list = limit != null ? all.take(limit!).toList() : all;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('活动报名',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: p.ink)),
              if (showChannelButton)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const EventsPage())),
                  child: Icon(Icons.bar_chart_rounded, size: 22, color: p.ink),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
          child: Column(
            children: [
              for (int i = 0; i < list.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                EventCard(event: list[i], roundCover: roundCover),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Single 活动报名 tile card.
class EventCard extends StatelessWidget {
  final EventItem event;
  final bool roundCover;
  const EventCard({super.key, required this.event, this.roundCover = true});

  static const double coverSize = 76;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => EventDetailPage(eventId: event.id)));
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: p.shadowSm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Cover — circular 76×76 on Home / 活动频道
              _EventCover(seed: event.seed, round: roundCover),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: p.ink,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (event.signups.isNotEmpty) ...[
                          StackedAvatars(
                              users: event.signups.take(4).toList(),
                              size: 22),
                          const SizedBox(width: 8),
                        ],
                        Text('${event.signups.length} 人已报名',
                            style: TextStyle(
                                fontSize: 11.5, color: p.inkSubtle)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(event.date,
                            style:
                                TextStyle(fontSize: 11, color: p.inkSubtle)),
                        const SizedBox(width: 12),
                        Icon(Icons.remove_red_eye_outlined,
                            size: 12, color: p.inkSubtle),
                        const SizedBox(width: 3),
                        Text('${event.views}',
                            style:
                                TextStyle(fontSize: 11, color: p.inkSubtle)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCover extends StatelessWidget {
  final String seed;
  final bool round;
  const _EventCover({required this.seed, required this.round});

  @override
  Widget build(BuildContext context) {
    const s = EventCard.coverSize;
    if (round) {
      return ClipOval(
        child: SeedPlaceholder(
          seed: seed,
          width: s,
          height: s,
          shape: BoxShape.circle,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SeedPlaceholder(seed: seed, width: s, height: s, radius: 12),
    );
  }
}
