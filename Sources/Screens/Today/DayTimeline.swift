//
//  DayTimeline.swift
//  PULSE
//
//  Вертикальный таймлайн дня: часовые линии, блоки событий и задач,
//  индикатор «сейчас».
//

import SwiftUI

struct TimelineItem: Identifiable, Hashable {
    var id: UUID
    var block: TimeBlock
    var lane: Int
    var y: CGFloat
    var height: CGFloat
}

struct DayTimeline: View {
    @Environment(AppStore.self) private var store

    let blocks: [TimeBlock]
    var day: Date
    var startHour: Int = 8
    var endHour: Int = 22
    var hourHeight: CGFloat = 56
    var showsNow: Bool = true
    var onTap: ((TimeBlock) -> Void)?

    private var totalHeight: CGFloat {
        CGFloat(max(1, endHour - startHour)) * hourHeight
    }

    private var hours: [Int] {
        Array(startHour...max(startHour, endHour))
    }

    var body: some View {
        GeometryReader { proxy in
            let labelWidth: CGFloat = 42
            let gutter: CGFloat = 10
            let laneWidth = max(40, (proxy.size.width - labelWidth - gutter) / 2 - 3)

            ZStack(alignment: .topLeading) {
                // Часовые линии
                ForEach(hours, id: \.self) { hour in
                    HStack(alignment: .center, spacing: gutter) {
                        Text(PulseDate.timeText(hour: hour))
                            .font(PulseFont.micro)
                            .foregroundStyle(PulsePalette.inkTertiary)
                            .frame(width: labelWidth, alignment: .trailing)
                            .offset(y: -6)
                        Rectangle()
                            .fill(PulsePalette.divider)
                            .frame(height: 1)
                    }
                    .offset(y: CGFloat(hour - startHour) * hourHeight)
                }

                // Блоки
                ForEach(placedItems(laneWidth: laneWidth)) { item in
                    TimelineBlockView(item: item, accent: store.settings.accent.color)
                        .frame(width: laneWidth, height: max(26, item.height))
                        .offset(
                            x: labelWidth + gutter + CGFloat(item.lane) * (laneWidth + 4),
                            y: item.y
                        )
                        .onTapGesture {
                            Haptics.tap()
                            onTap?(item.block)
                        }
                }

                // Линия «сейчас»
                if showsNow, day.isToday {
                    nowLine(labelWidth: labelWidth, gutter: gutter)
                }
            }
        }
        .frame(height: totalHeight)
    }

    @ViewBuilder
    private func nowLine(labelWidth: CGFloat, gutter: CGFloat) -> some View {
        let now = Date()
        let minutes = CGFloat(now.hour * 60 + now.minute)
        let startMinutes = CGFloat(startHour * 60)
        let y = (minutes - startMinutes) / 60 * hourHeight
        if y >= 0 && y <= totalHeight {
            HStack(spacing: 0) {
                Circle()
                    .fill(PulsePalette.danger)
                    .frame(width: 6, height: 6)
                    .offset(x: labelWidth - 3)
                Rectangle()
                    .fill(PulsePalette.danger.opacity(0.65))
                    .frame(height: 1.2)
            }
            .offset(y: y)
            .allowsHitTesting(false)
        }
    }

    private func placedItems(laneWidth: CGFloat) -> [TimelineItem] {
        let dayStart = day.combiningTime(hour: startHour, minute: 0, calendar: store.calendar)
        let dayEnd = day.combiningTime(hour: endHour, minute: 0, calendar: store.calendar)
        var laneEnds: [Date] = []
        var result: [TimelineItem] = []

        for block in blocks.sorted(by: { $0.start < $1.start }) {
            let start = max(block.start, dayStart)
            let end = min(block.end, dayEnd)
            guard end > start else { continue }

            var lane = 0
            while lane < 2 {
                if lane >= laneEnds.count {
                    laneEnds.append(end)
                    break
                }
                if laneEnds[lane] <= start {
                    laneEnds[lane] = end
                    break
                }
                lane += 1
            }
            if lane >= 2 { lane = 1 }

            let startMinutes = CGFloat(PulseDate.minutesBetween(dayStart, start))
            let durationMinutes = CGFloat(PulseDate.minutesBetween(start, end))
            let y = startMinutes / 60 * hourHeight
            let height = max(24, durationMinutes / 60 * hourHeight - 2)
            result.append(
                TimelineItem(id: block.id, block: block, lane: lane, y: y, height: height)
            )
        }
        return result
    }
}

struct TimelineBlockView: View {
    let item: TimelineItem
    var accent: Color

    private var color: Color {
        item.block.kind == .event ? Color.category(item.block.colorHex) : Color.category(item.block.colorHex)
    }

    private var isTask: Bool { item.block.kind == .task }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color)
                .frame(width: isTask ? 3 : 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.block.title)
                    .font(PulseFont.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(item.block.isDone ? PulsePalette.inkTertiary : PulsePalette.ink)
                    .strikethrough(item.block.isDone, color: PulsePalette.inkTertiary)
                    .lineLimit(2)
                if item.height > 40 {
                    Text("\(item.block.start.timeString)–\(item.block.end.timeString)")
                        .font(PulseFont.micro)
                        .foregroundStyle(PulsePalette.inkTertiary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(isTask ? 0.10 : 0.16))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(color.opacity(0.22), lineWidth: 1)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
