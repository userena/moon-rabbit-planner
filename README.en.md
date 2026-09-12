# Moon Rabbit

[한국어](README.md)

A little brown rabbit in a hanbok that keeps you company on your Mac. Includes a work stopwatch, focus countdown, goals, Korean/English UI, and 13 transparent character poses.

## Run

Requires macOS 13+. The provided app ZIP is for Apple Silicon. Unzip and open `MoonRabbit.app`. To build from source, install Xcode or a Swift 5.9+ toolchain:

```sh
./scripts/build-app.sh
open dist/MoonRabbit.app
```

No external build dependencies, proprietary server, or activity tracking. Weather uses the online Open-Meteo service. This is a locally ad-hoc signed app, not an Apple-notarized release. Quit an older running version before opening an update.

## Use

- Hover over the rabbit for a smile or a flower. Left-click for actions, today’s plan, weather, and settings. Right-click for settings; drag to move the pet.
- Move the compact settings window by its title bar. Its position is saved.
- Choose **Wander** or **Stay here**, and a size from 60–160%.
- Feed a snack, smile, dance, stretch/open shoulders, or offer a flower. Movements alternate arm/leg poses. The rabbit blinks while resting and performs random actions.
- Write a goal. Choose **Stopwatch** for accumulated work time or **Countdown** for a 1–720 minute focus timer, with 25/50 minute presets.
- Start/pause at any time. Every accumulated hour triggers a speech bubble. Countdown completion plays a sound, shows the pet with a goal message, and pauses.
- Resetting a countdown preserves total work time. Resetting the stopwatch clears total time. Both ask for confirmation.
- Screen lock/sleep pauses timing. Relaunch restores saved time in a paused state. Press Start to continue. Totals do not automatically reset each day.
- Language switches settings, dialogue, and alerts between Korean and English. Your goal text is preserved as entered.

Time is saved every 10 seconds and on normal exit. A force quit may lose the last 10 seconds. Away-from-desk time is not detected; pause manually.

## Save, goals, planner, and weather

Use **Save** in settings to persist preferences with a visible confirmation. Live application and automatic saving of existing preferences are retained. Turn on **Show goal in bubble** to keep your goal at the top of the bubble, with the rabbit’s messages below.

Open **Daily planner** from settings or **Today’s plan** from the left-click menu. The planner also opens at launch and from the menu-bar status icon. Select a date, add time, category, task and duration, mark tasks done, and save. A 24-hour timeline, daily notes and daily focus totals are included. Daily totals start with this version. Set a milestone name and date and enable its switch to show D-day above the rabbit’s message. Save your day stores the goal, milestone, tasks and notes. The rabbit summarizes up to three unfinished tasks for today. Plans are local; there is no external calendar sync.

Choose **Weather**, search for a city, and select the matching location. The window shows current/feels-like temperature, condition, wind, and local data time. Reopening or refreshing fetches updated data for the last chosen city. Network failures are shown with a retry option. Only city/location data is sent; goals and plans remain local. GPS permission is not used. Sources: [Open-Meteo](https://open-meteo.com/en/docs), [Geocoding / GeoNames](https://open-meteo.com/en/docs/geocoding-api).

## Development

```sh
swift test --disable-sandbox
./scripts/build-app.sh
```

The app uses Swift/AppKit/SwiftUI and keyframe images with smooth transitions, breathing, hopping, and movement. GitHub Actions runs tests and produces an app ZIP. Tests cover clocks, countdown completion, movement boundaries/parking, dialogue, translations, and transparent assets. Windows support is not included.

Create an empty GitHub repository, or use the GitHub CLI:

```sh
git init -b main
git add .
git commit -m "Add Moon Rabbit desktop companion"
gh repo create moon-rabbit-desktop-pet --private --source=. --remote=origin --push
```

Use `--public` if you want a public repository. Code is MIT licensed; artwork has separate free-use permission in ARTWORK-LICENSE.md. The original poster is not included. See [ARTWORK.md](ARTWORK.md) for asset provenance and prompts.

Use the palette button to customize the planner title, milestone heading, countdown label, planner background/cards/accent, and bubble background/border. Changes apply and persist immediately; text adapts to background brightness. New start times and duration adjustments use 10-minute increments. Existing task times are preserved.

Choose a 10- or 30-minute interval in the planner. Click a start time or duration to open a scrollable list, then scroll and select. Changing the interval preserves existing entries and applies to new selections only.

Default headings are Moon Rabbit Planner and Daily schedule. Timeline cells follow the 10/30-minute interval and can be clicked to add tasks. Korean and English neighborhood address search uses Photon/OpenStreetMap with GeoNames city fallback; forecasts use Open-Meteo at the selected coordinates. Forecast grid resolution can differ from neighborhood boundaries.

Each task has a color picker; overlapping blocks use the first matching task in list order. Coffee alternates between holding and sipping poses. Neighborhood lookup uses the [Photon demo service](https://github.com/komoot/photon) and [© OpenStreetMap contributors](https://www.openstreetmap.org/copyright). Requests are user initiated and repeated searches are cached in memory; use a dedicated service for large deployments.

## Role tools and autonomous walking

Expand Tools for your work in the planner for developer, designer, planner, student, and office-worker workspaces. Notes and checklists are saved per date and role. Designer tools include three palette swatches; student tools summarize planned and checked task durations by category. Add a role checklist to the schedule or start 25/50-minute focus sessions.

Wandering works while settings are open, chooses meaningful destinations within the current display, pauses for 3–8 seconds, and uses two side-profile walking frames mirrored to the movement direction. Hover, menu interaction, and dragging temporarily pause walking. Stay mode stops movement.

Today’s weather fetches the saved place and shows a 15-second bubble before returning to regular dialogue. Change the location through Weather location. Coffee poses have fully visible skirt hems. Timeline minute headings follow the selected 10/30-minute interval.

Planner mode is available at the top, with seven modes including solo startup and startup team. Mode tasks and work notes are separate; legacy tasks remain in the previous mode. Team and office tasks have owners, all tasks have priorities. Team mode is local and does not sync between teammates.

Use Monthly → to open the calendar and select a date to return to daily planning. Periods support one calendar month, 100 days, 200 days and one calendar year, with an inclusive end date. Alarms support dates, a scrollable time list, notes and daily repetition. Sound and bubbles require the app to be running; overdue active alarms fire once after wake or relaunch.

The original rabbit and hanbok remain. Work props adapt to the mode. Rejected mature outfits are not included. Walking uses four distance-driven frames and a three-quarter turn without an animated horizontal flip. Coffee artwork padding has been normalized.

Monthly planning now includes goals, notes, and a checklist saved per month and role. Click a calendar date to add or edit daily tasks without leaving the month; Daily details opens the full daily editor. Save month persists all records. Planner input text is enlarged to 13–14pt, calendar dates to 16pt, and timeline cells/check areas are wider.
