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

    /// Last 5-minute reading big (a bit smaller than the original 85 pt) with
    /// its arrow, 5-minute delta and "min ago"; below it the newest minute
    /// reading with its deviation from the 5-minute value and which minute
    /// after the 5-minute reading it is.
    @ViewBuilder private func minuteReadingHeader(_ minute: MinuteReadingDisplay, isStale: Bool) -> some View {
        Text(minute.fiveMinuteBGText)
            .font(.system(size: 70, weight: .black))
            .foregroundColor(minute.fiveMinuteBGColor)
            .strikethrough(
                isStale,
                pattern: .solid,
                color: isStale ? .red : .clear
            )
            .frame(maxWidth: .infinity)
            .lineLimit(1)
            .minimumScaleFactor(0.5)

        HStack {
            Text(minute.fiveMinuteDirectionText)
                .font(.system(size: 50, weight: .black))
            Text(minute.fiveMinuteDeltaText)
                .font(.system(size: 28))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)

        // "min ago" of the 5-minute reading, refreshed every 15 s.
        TimelineView(.periodic(from: .now, by: 15)) { context in
            let minutes = max(0, Int((context.date.timeIntervalSince1970 - minute.fiveMinuteDate) / 60))
            Text("\(minutes) min ago")
                .font(.system(size: 17))
        }

        Text(minute.minuteValueText)
            .font(.system(size: 30, weight: .bold))
            .foregroundColor(minute.minuteValueColor)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.top, 4)

        Text(minute.minuteCountText)
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.secondary)
            .lineLimit(1)
    }
}
