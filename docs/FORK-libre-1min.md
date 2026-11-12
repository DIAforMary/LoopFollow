# LoopFollow test branch `libre-1min-display` (DIAforMary/LoopFollow)

> Personal test version, written with Claude (AI) and marked as such in every commit.
> Not meant for a pull request to loopandlearn/LoopFollow.

## What it does

When the DIAforMary/Trio test branch uploads Libre 3 minute readings to Nightscout
(marked with `device: "Trio-LibreLoop-1min"`), the main BG display (top left of the
main screen) shows:

```
        112          ← last 5-minute reading (Trio's own entry), 70 pt instead of 85 pt
      ↗  +4          ← arrow and delta of the 5-minute readings
     2 min ago       ← age of the 5-minute reading
     118 (+6)        ← newest minute reading, deviation from the 5-minute value
    3rd minute       ← which minute after the 5-minute reading ("5-min reading" at +0)
```

The colours follow LoopFollow's "Color BG Text" setting and thresholds.

## When it is active, and when not

The new display appears only if **all** of these are true:

- a minute reading (`device == "Trio-LibreLoop-1min"`) is younger than 15 minutes,
- at least two 5-minute readings (entries without that marker) exist,
- the last 5-minute reading is younger than 15 minutes,
- the chart is not being scrubbed (retro view keeps the original display).

Otherwise LoopFollow shows its **original display, unchanged**. With original Trio,
Dexcom Share or any other uploader, no entry carries the marker, so nothing changes.

## What it does not change

Alarms, the app badge, Live Activity, the contact image, the graph, statistics,
"min ago" staleness logic, Apple Watch and widgets work exactly as in LoopFollow
`main`: they keep using all readings as before.

## Changed files

| File | Change |
|---|---|
| `RemoteShared/ShareClientExtension.swift` | `ShareGlucoseData` reads the optional Nightscout `device` field; `isMinuteReading` |
| `LoopFollow/Controllers/Nightscout/BGData.swift` | Keeps `device` in the graph data; builds the display values (`makeMinuteReadingDisplay`) |
| `LoopFollow/Storage/Observable.swift` | `MinuteReadingDisplay` and `minuteReadingDisplay` observable |
| `LoopFollow/ViewControllers/BGDisplayView.swift` | Alternative header while minute readings arrive |
| `.github/workflows/build_LoopFollow.yml` | Branch builds sync from upstream `main` |

## Building

- `main` stays plain loopandlearn/LoopFollow and is synced and built by the scheduled
  workflow as before.
- Test build: **Actions → "4. Build LoopFollow" → Run workflow → Branch
  `libre-1min-display`**. The build first merges the newest loopandlearn/LoopFollow
  `main` into the branch, then builds and uploads to TestFlight.
- Same App ID as your normal LoopFollow; switch between builds in TestFlight
  (turn off Automatic Updates while testing).
