// LoopFollow
// Observable.swift

import Foundation
import HealthKit
import SwiftUI

/*
 Observable in memory storage
 */

/// Fork feature (DIAforMary/LoopFollow, branch libre-1min-display): what the
/// main BG display shows while Libre 3 minute readings from the DIAforMary/Trio
/// test branch arrive. `nil` = original LoopFollow display.
struct MinuteReadingDisplay: Equatable {
    // Upper part: newest reading (normally a minute reading).

    /// Newest reading, big number, with its own trend arrow.
    let minuteBGText: String
    let minuteBGColor: Color
    let minuteDirectionText: String
    /// Time of the newest reading (seconds since 1970); next one expected 60 s later.
    let minuteDate: TimeInterval
    /// Which reading after the 5-minute reading, e.g. "3rd reading".
    let minuteCountText: String
    /// Newest reading minus the last 5-minute reading, with arrow.
    let fiveMinuteDeviationText: String
    let fiveMinuteDeviationArrow: String
    /// Newest reading minus the reading before it (about 1 minute earlier), with arrow.
    /// `nil` if there is no reading 30 s ... 3 min earlier.
    let oneMinuteDeviationText: String?
    let oneMinuteDeviationArrow: String?

    // Lower part: last 5-minute reading (Trio's own entry).

    let fiveMinuteBGText: String
    let fiveMinuteBGColor: Color
    /// Trend arrow of the 5-minute reading and its delta to the previous one.
    let fiveMinuteDirectionText: String
    let fiveMinuteDeltaText: String
    /// Time of the last 5-minute reading; next one expected about 5 minutes later.
    let fiveMinuteDate: TimeInterval
}

class Observable {
    static let shared = Observable()

    /// Fork feature (libre-1min-display), see `MinuteReadingDisplay`.
    var minuteReadingDisplay = ObservableValue<MinuteReadingDisplay?>(default: nil)

    var tempTarget = ObservableValue<HKQuantity?>(default: nil)
    var override = ObservableValue<String?>(default: nil)

    /// End of the active override as Unix epoch seconds; nil = no override or indefinite.
    var overrideEndAt = ObservableValue<TimeInterval?>(default: nil)
    /// End of the active temp target as Unix epoch seconds; nil = no active temp target.
    var tempTargetEndAt = ObservableValue<TimeInterval?>(default: nil)

    var minAgoText = ObservableValue<String>(default: "?? min ago")
    var bgText = ObservableValue<String>(default: "BG")
    var bg = ObservableValue<Int?>(default: nil)
    var bgStale = ObservableValue<Bool>(default: true)
    var bgTextColor = ObservableValue<Color>(default: .primary)
    var directionText = ObservableValue<String>(default: "-")
    var deltaText = ObservableValue<String>(default: "+0")
    var iobText = ObservableValue<String>(default: "--")

    var serverText = ObservableValue<String>(default: "Server")
    var loopStatusText = ObservableValue<String>(default: "")
    var loopStatusColor = ObservableValue<Color>(default: .primary)
    var predictionText = ObservableValue<String>(default: "")
    var predictionColor = ObservableValue<Color>(default: .purple)

    var currentAlarm = ObservableValue<UUID?>(default: nil)
    /// Replaces the current alarm's name on screen when the firing needs its
    /// own wording (e.g. an end alarm's early warning); nil shows the name.
    var currentAlarmTitleOverride = ObservableValue<String?>(default: nil)
    var alarmSoundPlaying = ObservableValue<Bool>(default: false)

    var debug = ObservableValue<Bool>(default: false)

    var chartSettingsChanged = ObservableValue<Bool>(default: false)

    var alertLastLoopTime = ObservableValue<TimeInterval?>(default: nil)
    var previousAlertLastLoopTime = ObservableValue<TimeInterval?>(default: nil)
    var deviceRecBolus = ObservableValue<Double?>(default: nil)
    /// When the loop cycle behind `deviceRecBolus` ran. Unlike `alertLastLoopTime`,
    /// a failed cycle, which keeps the previous recommendation, does not move it.
    var deviceRecBolusAt = ObservableValue<TimeInterval?>(default: nil)
    var deviceBatteryLevel = ObservableValue<Double?>(default: nil)
    var deviceBatteryIsCharging = ObservableValue<Bool?>(default: nil)
    var pumpBatteryLevel = ObservableValue<Double?>(default: nil)
    var dbSizePercentage = ObservableValue<Double?>(default: nil)
    var enactedOrSuggested = ObservableValue<TimeInterval?>(default: nil)

    var lastSentTOTP = ObservableValue<String?>(default: nil)

    var loopFollowDeviceToken = ObservableValue<String>(default: "")

    /// Saved profiles from the latest Loop profile upload; nil until one is loaded.
    var loopProfiles = ObservableValue<LoopProfileSet?>(default: nil)

    var isNotLooping = ObservableValue<Bool>(default: false)

    /// CGM state reported after the newest reading; nil while readings flow.
    var cgmSensorState = ObservableValue<CGMSensorState?>(default: nil)

    /// Selected tab index used by SwiftUI TabView — set from MainViewController to switch tabs
    var selectedTabIndex = ObservableValue<Int>(default: 0)

    /// Currently visible app-wide banner (nil = hidden). Managed by BannerManager.
    var activeBanner = ObservableValue<BannerMessage?>(default: nil)

    /// True while the onboarding cover is on screen; AlarmManager doesn't act
    /// on alarms while set. In-memory, so background launches are unaffected.
    var isOnboardingActive = ObservableValue<Bool>(default: false)

    private init() {}
}
