# LoopFollow test branch `libre-1min-display` (DIAforMary/LoopFollow)

> Personal test version, written with Claude (AI) and marked as such in every commit.
> Not meant for a pull request to loopandlearn/LoopFollow.

## What it does

When the DIAforMary/Trio test branch uploads Libre 3 minute readings to Nightscout
(marked with `device: "Trio-LibreLoop-1min"`), the main BG display (top left of the
main screen) shows:

```
       118  ↗              ← newest (minute) reading, big, with its trend arrow
     3rd reading           ← which reading after the 5-min reading
     next in 23 s          ← seconds to the next minute reading
  5-min dev:  +6  ↗        ← newest reading − last 5-minute reading, arrow for that change
  1-min dev:  +2  →        ← newest reading − the reading before it (~1 min), arrow for that change
  ─────────────────        ← thin separation line
  5-min: 112 ↗ +4          ← last 5-minute reading (Trio's own entry), its arrow and 5-min delta
  next 5-min in 2:13       ← countdown to the next 5-minute reading
```

- The big value and the trend arrows next to the big value and the 5-minute reading come
  from the readings themselves (Trio/LibreLoop trend).
- The arrows next to the deviations show how fast that change was, with Nightscout's
  trend thresholds per minute: > 3 mg/dL/min ⇈, > 2 ↑, > 1 ↗, −1 … 1 →, < −1 ↘,
  < −2 ↓, < −3 ⇊.
- "1st/2nd/3rd/4th reading" counts the minutes since the last 5-minute reading;
  "5-min reading" when the newest reading is the 5-minute reading itself. "1-min dev" shows
  `--` if the previous reading is not 30 s … 3 min older.
- Countdowns: next minute reading = newest reading + 60 s; next 5-minute reading = last
  5-minute reading + 5 min. "next due" when the time has passed.
- While fresh minute readings arrive, LoopFollow fetches new data about every minute
  (instead of about every 5 minutes) so the display keeps up. With a live Nightscout
  connection (websocket) LoopFollow's own timing rules apply as before.
- Colours follow LoopFollow's "Color BG Text" setting and thresholds.

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
staleness logic, Apple Watch and widgets work exactly as in LoopFollow `main`: they keep
using all readings as before. The only behavioural change outside the display is the
faster fetch interval (about every minute) while minute readings arrive.

## Changed files

| File | Change |
|---|---|
| `RemoteShared/ShareClientExtension.swift` | `ShareGlucoseData` reads the optional Nightscout `device` field; `isMinuteReading` |
| `LoopFollow/Controllers/Nightscout/BGData.swift` | Keeps `device` in the graph data; builds the display values (`makeMinuteReadingDisplay`); fetches about every minute while fresh minute readings arrive |
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
