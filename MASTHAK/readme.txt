MASTHAK - LOCAL SETUP
====================

This package includes the website source, comic art/narration, ready-to-play
Godot web games, Godot source, editable Blender models, licenses and an optional
Windows game executable. No API key, account, database or .env file is needed.
Godot and Blender are NOT required to run the website.

QUICK START - WINDOWS
1. Install Node.js 22 LTS or newer, including npm: https://nodejs.org
   This Next.js version requires at least Node.js 20.9.
2. Extract the entire ZIP into a normal folder. Do not run it inside the ZIP.
3. Open the extracted MASTHAK folder and double-click START-LOCAL.cmd.
   It installs dependencies on the first run, then starts the local server.
4. When the terminal says Ready, open http://localhost:3000 in your browser.
5. Keep the terminal open. Press Ctrl+C when you want to stop the server.

MANUAL START - WINDOWS, macOS OR LINUX
Open a terminal IN the extracted MASTHAK folder (the one with package.json).
Run these commands, one at a time:

  npm ci
  npm run dev

Open http://localhost:3000. Internet is needed for installing dependencies;
the comic, fonts, narration and games are then served from your computer.
The server binds to 127.0.0.1 for local use. External resource links need internet.

PRODUCTION MODE
In the same folder run, one at a time:

  npm ci
  npm run build
  npm start

Then open http://localhost:3000. Do not run dev and start on the same port.
If port 3000 is occupied, stop the other server or use:
  npm run dev -- --port 3001
Then open http://localhost:3001. For production use npm start -- --port 3001.

THE LANDING PAGE AND STORY
Everything is stacked on the home page: illustrated courtyard, four arcade missions,
five-book story, material lab, and cast. Top navigation jumps to sections.
The original painted courtyard and editorial opening match the reference design.
Use Motion off to stop animation. System reduced-motion settings are respected.
Choose a book or keep scrolling to read all 43 panels. Next/Previous and
Space/Right/Left Arrow move through panels while the story is onscreen.
Focused buttons retain normal keyboard activation. Three Book 3 panels have
sorting choices with retries. Choices stay in memory and reset on reload.
Open the story transcript for a complete text reading without scrolling panels.
Sound starts enabled for the locally hosted Suno soundtrack, ElevenLabs
courtyard ambience, panel swish and successful-choice cue. If your browser
blocks autoplay, your first click or keypress starts playback. Use Sound next
to Reduced motion on the opening to mute it. The same control follows you
below the opening. Chapter previews rotate every 6.5 seconds; pause with the
small pause control beside the chapter numbers, or hover/focus the preview.
Audio pauses when the tab is hidden, and the page mutes when launching a game.
The older /comic route remains available with optional book narration.
No accounts or online audio services are needed to run the finished local page.
The supplied GIFs are motion references; they are not embedded in the website.
Story works on phones; 3D games retain their keyboard/mouse requirements.
HOW TO PLAY
Choose The arcade, a mission, Open game, then Launch mission.
The first game load downloads the shared engine from this local server.
Esc / P pauses. Settings controls sound, volume, difficulty and reduced motion.
- Conveyor: drag items into the matching bins; keys 1-4 also sort.
- Defense: click energy drops; choose a packet and a board tile. Keys 1-9
  choose packets, arrows choose tiles, Enter places and C collects energy.
- Tunnel: A/D or arrows rotate the tunnel around a fixed ship; Space fires.
- Garbage Court: WASD moves; click the view for mouse look. Click/F fires;
  1-5 chooses a tool, R reloads, Space jumps, E uses an unlocked elevator.
  Arrow keys provide movement/turn alternatives if pointer capture is blocked.
Use a modern browser with WebGL 2 and hardware acceleration for 3D games.
These games require keyboard/mouse; the 3D modes are not designed for phones.
Book narration starts using its audio player. Arcade sound starts on launch
unless muted in saved settings. Scores/settings stay on the current device.

WINDOWS GAME WITHOUT A WEBSITE
Open builds/windows/MASTHAK.exe. No Node.js, Godot editor or server is required.
This executable is for Windows x64. Other systems can use the browser games.

OPTIONAL DEVELOPMENT / GAME REBUILD
Website: src/app (routes/styles), src/components, src/data.
Game source: godot/project.godot and godot/scripts.
Editable models: godot/blender/masthak-assets.blend.
All game assets needed to play are already in public/games/masthak.

Website check: npm run typecheck
Website production check: npm run build
Optional panel asset regeneration (the included WebPs are already ready):
  python -m pip install Pillow
  python scripts/prepare-story-assets.py
This crops the supplied comic pages using the frame data in src/data/comic.ts.
The courtyard WebPs are included; no image-generation account is needed.
Game tests need Godot 4.7.2, not merely Node.js. Install Godot from its official
site, then put its executable on PATH as godot, or set GODOT_BIN:
  PowerShell: $env:GODOT_BIN='C:\path\Godot_console.exe'
  macOS/Linux: export GODOT_BIN='/path/to/godot'
Then run npm test. It imports the project and checks rules, input and scenes.

For game export templates, install Python 3.10+ and run:
  python scripts/get-godot-templates.py
Then use Godot 4.7.2 with the included Web/Windows export presets, or run:
  godot --headless --path godot --export-release Web
  node scripts/compress-godot.cjs
  godot --headless --path godot --export-release Windows
Replace godot with your actual executable path if it is not on PATH.
Template downloads and .tools caches are deliberately omitted from the ZIP.
If the optional partial-download helper fails, use the official template archive
and copy web_nothreads_debug.zip, web_nothreads_release.zip and
windows_release_x86_64.exe into .tools/godot-templates.

Model regeneration requires Blender 5.2.1:
  blender --background --factory-startup --python scripts/build-blender-assets.py
Original soundtrack regeneration: python scripts/build-game-audio.py
Kenney asset refresh: python scripts/get-kenney.py, then
  python scripts/install-kenney.py
These are developer tasks and are unnecessary for normal local play.

TROUBLESHOOTING
- npm/node not recognized: install Node.js, then reopen the terminal.
- PowerShell blocks npm.ps1: use npm.cmd instead of npm or START-LOCAL.cmd.
- npm ci fails: check internet and Node version; keep package-lock.json intact.
- Blank/failed game: use localhost through the server, not file:// or a bare
  index.html. Enable browser hardware acceleration and WebGL 2.
- No sound: launch a mission, check SOUND ON and Settings volume, and check
  browser/tab and system mute settings.
- Mouse capture blocked: click inside the game; unlocked mouse look and arrow
  controls are available. The Windows executable also supports captured mouse.
- Do not use a generic static file server for the whole app. Next.js serves the
  routes and compressed Godot files with the correct encoding/MIME headers.

PACKAGE CONTENTS AND NOTICES
node_modules, .next, Godot import caches, download caches, references, logs,
obsolete game code and unused assets are omitted. npm ci and the tools recreate
necessary caches. The package includes raw and Brotli game files intentionally:
Next.js selects Brotli where supported, with raw-file fallback.
Read docs/ASSET-LICENSES.md and public/licenses for artwork/audio/font notices.
This is a local educational demonstration. Supplied artwork and ElevenLabs
narration do not carry an asserted blanket redistribution/commercial license.
Runtime dependencies retain their own licenses when npm ci installs them.
No full campaign/hardware certification is claimed; see docs/godot/README.md.

