import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/app_database.dart';

/// 角色关系图谱（M24 T25.8）：当前有效关系边的圆形布局。
///
/// 节点按名字去重排在圆周上，边是 source → target 的直线，箭头落在目标节点侧。
/// 边的文字说明放在图下方的清单里——边一多，文字压线比没有文字更难读。
class CharacterRelationGraph extends StatelessWidget {
  const CharacterRelationGraph({super.key, required this.edges});

  final List<CharacterRelation> edges;

  static const double nodeRadius = 16;

  @override
  Widget build(BuildContext context) {
    final names = _nodeNames(edges);
    if (names.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final edgeTextStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final height = math.max(260.0, names.length * 44.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final positions = _positions(
                names.length,
                Size(constraints.maxWidth, height),
              );
              return Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _EdgePainter(
                      edges: edges,
                      names: names,
                      positions: positions,
                      lineColor: theme.colorScheme.onSurfaceVariant,
                      arrowColor: theme.colorScheme.primary,
                    ),
                  ),
                  for (var i = 0; i < names.length; i++)
                    Positioned(
                      left: positions[i].dx,
                      top: positions[i].dy,
                      child: Transform.translate(
                        offset: const Offset(-46, -13),
                        child: SizedBox(
                          width: 92,
                          height: 26,
                          child: Center(
                            child: Text(
                              _short(names[i], 6),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        for (final edge in edges)
          if (edge.description.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                '${_short(edge.source, 8)} → ${_short(edge.target, 8)}'
                '（${_short(edge.description, 24)}）',
                style: edgeTextStyle,
              ),
            ),
      ],
    );
  }

  /// 节点名字按首次出现顺序去重。
  static List<String> _nodeNames(List<CharacterRelation> edges) {
    final names = <String>[];
    final seen = <String>{};
    for (final edge in edges) {
      for (final name in [edge.source.trim(), edge.target.trim()]) {
        if (name.isEmpty) continue;
        if (seen.add(name)) names.add(name);
      }
    }
    return names;
  }

  /// 圆形布局：单节点居中，其余按角度均分。
  static List<Offset> _positions(int count, Size size) {
    if (count == 1) {
      return [Offset(size.width / 2, size.height / 2)];
    }
    final radius = math.min(size.width, size.height) / 2 - nodeRadius - 24;
    final result = <Offset>[];
    for (var i = 0; i < count; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / count;
      result.add(
        Offset(
          size.width / 2 + radius * math.cos(angle),
          size.height / 2 + radius * math.sin(angle),
        ),
      );
    }
    return result;
  }

  static String _short(String text, int max) =>
      text.length <= max ? text : '${text.substring(0, max)}…';
}

class _EdgePainter extends CustomPainter {
  _EdgePainter({
    required this.edges,
    required this.names,
    required this.positions,
    required this.lineColor,
    required this.arrowColor,
  });

  final List<CharacterRelation> edges;
  final List<String> names;
  final List<Offset> positions;
  final Color lineColor;
  final Color arrowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = lineColor;
    final arrowPaint = Paint()..color = arrowColor;

    for (final edge in edges) {
      final from = _index(names, edge.source.trim());
      final to = _index(names, edge.target.trim());
      if (from == null || to == null) continue;

      final start = _offsetBy(
        positions[from],
        positions[to],
        CharacterRelationGraph.nodeRadius,
      );
      final end = _offsetBy(
        positions[to],
        positions[from],
        CharacterRelationGraph.nodeRadius,
      );
      canvas.drawLine(start, end, linePaint);
      canvas.drawPath(_arrowHead(end, start, 7), arrowPaint);
    }
  }

  static int? _index(List<String> names, String name) {
    return name.isEmpty ? null : names.indexOf(name);
  }

  /// 从 [from] 沿 [to] 方向退一段 [r]，避免线穿进节点标签。
  static Offset _offsetBy(Offset from, Offset to, double r) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist <= r) return from;
    final step = r / dist;
    return Offset(from.dx + dx * step, from.dy + dy * step);
  }

  static Path _arrowHead(Offset tip, Offset tail, double length) {
    final angle = (tail - tip).direction;
    final left = tip + Offset(
      length * math.cos(angle + math.pi / 6),
      length * math.sin(angle + math.pi / 6),
    );
    final right = tip + Offset(
      length * math.cos(angle - math.pi / 6),
      length * math.sin(angle - math.pi / 6),
    );
    return Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
  }

  @override
  bool shouldRepaint(_EdgePainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.edges != edges ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.arrowColor != arrowColor;
  }
}
