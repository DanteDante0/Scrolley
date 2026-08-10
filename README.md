# Scrolley

A macOS menu-bar utility that brings **Windows-style auto-scroll** and **click-and-drag panning** to every application, using the middle mouse button.

## Why I built Scrolley

I have been a Windows user for almost thirty years. Auto scroll and its features first appeared around Windows 98 and XP, and from those early days the middle click auto scroll became as natural as breathing. Click the wheel, nudge the cursor, and the page glides under your hand. For almost three decades, I never had to think about it.

Then I started using a Mac, because my line of work (theater tech) runs on industry standards that favor the Mac platform. The hardware was lovely and the OS was polished, but scrolling did not work the way I was used to. I hunted through utilities and tweaks, hoping to bring back that Windows style middle click behavior. Nothing quite matched it. The closer apps got, the further they felt from what I actually wanted: a mouse that behaves the way my muscle memory expects.

So I decided to just build it.

Scrolley is the result. A small, quiet menu bar utility that brings Windows style auto scroll and click and drag panning to the Mac. It respects middle click for the things you still want it for, scrolls smoothly, and stays out of the way until you need it. It is an almost thirty year old habit, finally ported.

If it saves you even a fraction of the annoyance it saved me, consider [buying me a cup of tea](https://www.paypal.com/ncp/payment/CFZVJGT2335HL).

## Features

- **Auto-scroll** — hold the middle button still, then move the cursor away from the anchor point to scroll (distance = speed), vertically and horizontally.
- **Click-to-drag panning** — press the middle button and drag to "grab" the page like a hand tool.
- **Middle-click pass-through** — a middle-click released before the *Middle-click hold time* (in the settings) is re-sent as a normal middle-click, so "open link in new tab" and middle-click paste keep working. Set the hold time very low and every click enters auto-scroll instead.
- **Smooth scrolling** — a 120 Hz engine eases velocity for a native, trackpad-like feel.
- **Exclusion list** — opt out specific apps so the middle button is untouched there.
- **Customizable overlay** — pick the cursor icon's shape (None / Circle / Rounded Square / Square / Hexagon / Diamond), per-element colors and opacity (Background / Cursor / Ring), frosted vs. solid background, overall opacity, and size.
- **In-app color picker** — tap a color wheel image or grab any pixel from the screen with a native eyedropper.
- **Menu-bar only** — no Dock icon, optional launch at login.

## Requirements

- macOS 13.0 or later
- Xcode 16+ to build (developed and tested with Xcode 26.2)

> **Compatibility note:** Scrolley is developed and tested on macOS 26 (Tahoe). It is built to run on macOS 13.0 and later, but it has not been verified on every release in between. If you run into an issue on an older version, please report it.

## Build & run

1. Clone the repo and open the project:

   ```
   git clone https://github.com/DanteDante0/Scrolley.git
   cd Scrolley
   open Scrolley.xcodeproj
   ```

2. Select the **Scrolley** scheme and hit Run (⌘R). Because the app is unsandboxed (required for global event taps), Xcode may prompt about code signing — choosing your personal team with **Automatic** signing works for local use.

3. On first launch, grant the two permissions it needs when prompted (or via the banner in the menu):
   - **Accessibility** — System Settings → Privacy & Security → Accessibility → enable Scrolley
   - **Input Monitoring** (optional, used for keyboard events like ESC) — Privacy & Security → Input Monitoring → enable Scrolley

> If scrolling stops working after a rebuild, macOS can drop the Accessibility grant — just re-toggle Scrolley in System Settings.

## Usage

| Gesture | Action |
| --- | --- |
| Middle-click released before the *Middle-click hold time* | Passed through as a normal middle-click |
| Hold middle button still (past the *Middle-click hold time*) | Enter auto-scroll; move the cursor from the anchor to scroll |
| Middle-click + drag | Hand-tool panning |
| Second middle-click / left-click / ESC | Exit auto-scroll |

Tweak hold time, sensitivity, smoothness, direction, and everything visual from the menu-bar panel.

## Notes

- This app is **unsandboxed** and distributed for personal use — it will not pass App Store review. Build it yourself or sign it with your own certificate.
- Not all apps respond to synthetic scroll events (games and raw-input apps in particular).

## Support

Scrolley is free. If you'd like to say thanks, [buy me a cup of tea ☕](https://www.paypal.com/ncp/payment/CFZVJGT2335HL).

## License

[PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0) — © DanteDante0. You may use, copy, modify, and share this software for **noncommercial** purposes only. Commercial use is not permitted.
