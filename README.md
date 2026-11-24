# cursor-cloak

Hide the real Windows cursor from screen recordings while you still see a pointer.
It fixes the **double cursor** in recorders that draw their own, smoothed cursor on top
of the video, for example [Openscreen](https://github.com/siddharthvaddem/openscreen)
in browser-capture mode.

Two `.bat` files and one PowerShell script. No install, no admin rights, and nothing
stays changed after you turn it off.

> Po polsku: [README.pl.md](README.pl.md)

## The problem

Auto-zoom recorders save the mouse position and draw their own, nicer cursor in the
editor. If the captured video also contains the real Windows cursor (Chromium's screen
capture bakes it in and ignores `cursor: "never"`), the result shows two cursors that
drift apart whenever you move the mouse.

## How it works

- **On** (`kursor-ukryj.bat`): the 12 common system cursors (arrow, I-beam, hand, wait,
  resize and others) are replaced with a fully transparent one via `SetSystemCursor`.
  The recording no longer contains a real cursor, but Windows still tracks the mouse
  position, so auto-zoom and the recorder's own cursor keep working.
- **A ghost arrow only you can see:** a small white arrow follows the mouse. It is a
  window excluded from screen capture (`SetWindowDisplayAffinity` with
  `WDA_EXCLUDEFROMCAPTURE`), so it is on your screen but not in the video. It sits 1 px
  off the cursor hotspot, so clicks and hover go to the app below it.
- **Off** (`kursor-przywroc.bat`): restores the cursors from your Windows settings
  (`SPI_SETCURSORS`) and closes the ghost. Signing out or restarting also restores them.
- **Safety:** "on" hides the cursor only if the ghost window actually started.

## Requirements

- Windows 10 version 2004 (build 19041) or newer, or Windows 11.
  `WDA_EXCLUDEFROMCAPTURE` does not exist on older builds.
- Windows PowerShell 5.1, which is built into Windows.

Tested on Windows 10 22H2 with Openscreen 1.5.0 (browser capture) and two monitors.

## Usage

1. Download the repository (Code → Download ZIP) and keep the files together in one folder.
2. Before recording, run `kursor-ukryj.bat`. Your cursor turns into the white ghost arrow.
3. Record as usual. The video shows only the cursor your recorder draws.
4. After recording, run `kursor-przywroc.bat`.

From a terminal:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\cursor-cloak.ps1 on
powershell -NoProfile -ExecutionPolicy Bypass -File .\cursor-cloak.ps1 off
```

On the first run the script creates `blank.cur` (a transparent 32×32 cursor) next to
itself, so the folder must be writable.

Windows may ask for confirmation before running a `.bat` file downloaded from the
internet. To avoid that, right-click the ZIP, choose Properties, tick Unblock, and only
then extract it.

**If you are ever left without a visible cursor**, use the keyboard: press Win+R, type
the full path to `kursor-przywroc.bat` and press Enter. Signing out also brings the
cursor back.

## Diagnostic modes

- `test`: the ghost is NOT excluded from capture and is offset by 24 px, so screenshots
  and recordings can see it.
- `ghost`: the ghost is excluded from capture as in normal use and offset by 24 px; the
  real cursor is not hidden. Use it to check that you can see the ghost.

Close a diagnostic ghost with `off`.

## Gotchas we hit

- A layered window with color-key transparency (`TransparencyKey`) combined with
  `WDA_EXCLUDEFROMCAPTURE` disappeared from the local screen too, which left us with no
  cursor at all. That is why the ghost is a plain window shaped with a GDI region.
- `off` finds the ghost process by its exact command line (`cursor-cloak.ps1 overlay…`).
  A loose match on the word "overlay" once killed the PowerShell window the script was
  started from.
- The ghost is always an arrow. It does not mirror the I-beam or hand shapes.

## License

MIT, see [LICENSE](LICENSE).

The background and the recording setup we use are described (in Polish) in
[Jaki program do nagrywania ekranu wybrać](https://zautomatyzowani.ai/faq/program-do-nagrywania-ekranu/).
