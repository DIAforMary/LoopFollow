// LoopFollow
// BGDisplayView.swift

import SwiftUI

struct BGDisplayView: View {
    @ObservedObject var serverText = Observable.shared.serverText
    @ObservedObject var bgText = Observable.shared.bgText
    @ObservedObject var bgTextColor = Observable.shared.bgTextColor
    @ObservedObject var bgStale = Observable.shared.bgStale
    @ObservedObject var directionText = Observable.shared.directionText
    @ObservedObject var deltaText = Observable.shared.deltaText
    @ObservedObject var minAgoText = Observable.shared.minAgoText
    @ObservedObject var loopStatusText = Observable.shared.loopStatusText
    @ObservedObject var loopStatusColor = Observable.shared.loopStatusColor
    @ObservedObject var predictionText = Observable.shared.predictionText
    @ObservedObject var predictionColor = Observable.shared.predictionColor
    @ObservedObject var isNotLooping = Observable.shared.isNotLooping
    @ObservedObject var cgmSensorState = Observable.shared.cgmSensorState
    @ObservedObject var retro = RetroSelection.shared
    /// Fork feature (DIAforMary/LoopFollow, branch libre-1min-display).
    @ObservedObject var minuteReadingDisplay = Observable.shared.minuteReadingDisplay

    var onRefresh: (() -> Void)?

    var body: some View {
        // While scrubbing the chart, the display shows the scrubbed time.
        let snapshot = retro.snapshot
        let isStale = snapshot == nil && bgStale.value
        // Fork feature (libre-1min-display): only while Libre 3 minute readings
        // arrive and the chart is not being scrubbed; otherwise original display.
        let minute = snapshot == nil ? minuteReadingDisplay.value : nil

        ScrollView {
            VStack(spacing: 0) {
                Text(serverText.value)
                    .font(.system(size: 13))

                if let minute {
                    minuteReadingHeader(minute, isStale: isStale)
                } else {
                    Text(snapshot?.bgText ?? bgText.value)
                        .font(.system(size: 85, weight: .black))
                        .foregroundColor(snapshot?.bgColor ?? bgTextColor.value)
                        .strikethrough(
                            isStale,
                            pattern: .solid,
                            color: isStale ? .red : .clear
                        )
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    HStack {
                        Text(snapshot?.directionText ?? directionText.value)
                            .font(.system(size: 60, weight: .black))
                        Text(snapshot?.deltaText ?? deltaText.value)
                            .font(.system(size: 32))
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                }

                if let snapshot {
                    Label(snapshot.timeText, systemImage: "clock.arrow.circlepath")
                        .font(.system(size: 17, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(RetroSnapshot.accent.opacity(0.3)))
                    Text(snapshot.predictionText)
                        .foregroundColor(snapshot.predictionColor)
                        .font(.system(size: 17))
                } else {
                    if minute == nil {
                        Text(minAgoText.value)
                            .font(.system(size: 17))
                    }

                    if let state = cgmSensorState.value {
                        Text("CGM: \(state.summary)")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }

                    if isNotLooping.value {
                        Text(loopStatusText.value)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(loopStatusColor.value)
                            .frame(maxWidth: .infinity)
                    } else {
                        HStack {
                            Spacer()
                            Text(loopStatusText.value)
                                .foregroundColor(loopStatusColor.value)
                            Text(predictionText.value)
                                .foregroundColor(predictionColor.value)
                            Spacer()
                        }
                        .font(.system(size: 17))
                    }
                }
            }
        }
        .background {
            if snapshot != nil {
                RetroCardBackground()
            }
        }
        .refreshable {
            onRefresh?()
        }
    }

    // MARK: - Fork feature (DIAforMary/LoopFollow, branch libre-1min-display)

    /// Same style as the DIAforMary/Trio bubble "Minute value with 5-min footnote":
    ///
    ///        118  ↗           ← newest (minute) reading with its trend arrow
    ///      #3 (+2) →          ← position in the 5-min cycle, change from the previous reading + arrow
    ///     next in 23 s        ← countdown to the next minute reading
    ///   ────────────────
    ///   5-min 112 (+6) ↗      ← last 5-min value, total change since it + arrow
    ///   next 5-min in 2:13    ← countdown to the next 5-min reading
    @ViewBuilder private func minuteReadingHeader(_ minute: MinuteReadingDisplay, isStale: Bool) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(minute.minuteBGText)
                .font(.system(size: 80, weight: .black))
                .foregroundColor(minute.minuteBGColor)
                .strikethrough(
                    isStale,
                    pattern: .solid,
                    color: isStale ? .red : .clear
                )
            if !minute.minuteDirectionText.isEmpty {
                Text(minute.minuteDirectionText)
                    .font(.system(size: 44, weight: .black))
            }
        }
        .frame(maxWidth: .infinity)
        .lineLimit(1)
        .minimumScaleFactor(0.5)

        // "#3 (+2) →"
        changeRow(
            prefix: minute.minuteCountText,
            prefixColor: .primary,
            value: nil,
            valueColor: .primary,
            change: minute.oneMinuteDeviationText ?? "--",
            arrow: minute.oneMinuteDeviationArrow ?? "",
            size: 24
        )

        // Countdown to the next minute reading, refreshed every second.
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = Int((minute.minuteDate + 60 - context.date.timeIntervalSince1970).rounded(.up))
            Text(remaining > 0 ? "next in \(remaining) s" : "next due")
                .font(.system(size: 17))
                .foregroundColor(.secondary)
                .monospacedDigit()
                .lineLimit(1)
        }

        // Discreet separation line.
        Rectangle()
            .fill(Color.secondary.opacity(0.35))
            .frame(height: 0.5)
            .padding(.horizontal, 24)
            .padding(.vertical, 6)

        // "5-min 112 (+6) ↗": last 5-minute value, total change since it.
        changeRow(
            prefix: "5-min",
            prefixColor: .secondary,
            value: minute.fiveMinuteBGText,
            valueColor: minute.fiveMinuteBGColor,
            change: minute.fiveMinuteDeviationText,
            arrow: minute.fiveMinuteDeviationArrow,
            size: 20
        )

        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = Int((minute.fiveMinuteDate + 300 - context.date.timeIntervalSince1970).rounded(.up))
            Text(remaining > 0 ? String(format: "next 5-min in %d:%02d", remaining / 60, remaining % 60) : "next 5-min due")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .monospacedDigit()
        }
        .padding(.bottom, 4)
    }

    /// One line like "#3 (+2) →" or "5-min 112 (+6) ↗".
    private func changeRow(
        prefix: String,
        prefixColor: Color,
        value: String?,
        valueColor: Color,
        change: String,
        arrow: String,
        size: CGFloat
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(prefix)
                .font(.system(size: value == nil ? size : size * 0.75, weight: value == nil ? .bold : .regular))
                .foregroundColor(prefixColor)
            if let value {
                Text(value)
                    .font(.system(size: size * 1.2, weight: .bold))
                    .foregroundColor(valueColor)
            }
            Text("(\(change))")
                .font(.system(size: size, weight: .semibold))
                .monospacedDigit()
            if !arrow.isEmpty {
                Text(arrow)
                    .font(.system(size: size, weight: .bold))
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
}
