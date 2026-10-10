# Godot arcade rebuild

The website launches the Godot project in `godot/`. Blender source is `godot/blender/masthak-assets.blend`; `scripts/build-blender-assets.py` builds original low-poly characters with walk morph animations, detailed FPS tools, props and eight-frame rendered strips. The supplied sheets inform the cast; custom animated art is used in every game. Kenney's CC0 Interface Sounds, Sci-Fi Sounds, UI Pack - Sci-Fi and Retro Urban Kit supply effects, UI skins, font and environment textures/props. License files are retained in `godot/kenney/licenses` and source/download scripts in `scripts/`.

## Play and edit

- Website: run `npm run dev`, then open `/arcade` and choose a mission. Open game loads the shared engine, followed by a briefing and Launch mission.
- Windows: open `builds/windows/MASTHAK.exe`. It runs without the editor or a web server.
- Editor: import `godot/project.godot` in Godot 4.7.2. The `.blend` source is excluded from Godot import/export; exported GLBs are used at runtime.
- Sound, volume, gentler difficulty, reduced motion and local data deletion are in Settings. Sound starts when a mission launches; a visible SOUND ON/OFF control is in the HUD. Esc/P pauses, releases the FPS mouse, and offers resume/restart/mission selection. Saved explicit sound preferences persist. The previous build's default muted setting migrates to sound-on once.

## Missions

Conveyor: drag sorting or 1–4; stable item IDs, three mistakes, progressive speed, 2,400-point completion. Defense: 9×5 board, nine packets including shovel, clickable energy drops, matching projectiles, locks and recharge, shields/slow/burst, one-use lane rescues, five stages with three waves each. Tunnel: the track and targets rotate around a fixed ship and camera; three speed phases over 90 seconds. Pulses clear red targets or capture green/blue supplies, with visible impact bursts and scoring. FPS: textured enclosed corridors, colored lamps, animated enemies, mouse look with an unlocked fallback if browser pointer capture fails, five tools, muzzle flash, recoil, hit markers, reload motion, ranged/melee combat, pickups/acid, five stages and a three-phase judge.

## Optimization

Compatibility renderer, single-thread web build (no cross-origin-isolation requirement), no real-time shadows, low-poly meshes, shared model/material resources, cached flat UI styles, 24 recycled tunnel sections, fixed 60 Hz physics with clamped deltas, eight pooled sound voices, capped enemies/projectiles/effects. Web engine Brotli: approximately 7.6 MiB; shared content approximately 1.1 MiB after excluding obsolete assets. Engine download begins only after Open game. Next before-files rewrites serve `.br` assets with correct encoding/MIME; raw assets remain for clients without Brotli. Other static hosts must reproduce those headers or use the raw files.

## Verify and rebuild

`npm test` / `npm run test:godot` runs gameplay rules, imported animation checks, four-scene menu/pause/resume/cleanup checks, and full viewport input routing. Mouse events pass through the actual HUD to test drag/release sorting, coin collection, packet choice/placement, FPS look/fire/release and ray-hit damage/ammunition, fixed ship rotation, and pulse impacts. The runner imports a fresh project first and fails on script errors even when Godot returns zero. Set `GODOT_BIN` to your Godot executable, or use `godot` on PATH. `npm run build` validates the website.

Export with Godot `--headless --path godot --export-release Web`, then run `node scripts/compress-godot.cjs`. Windows uses `--export-release Windows`. Custom official templates are in ignored `.tools/godot-templates`; `python scripts/get-godot-templates.py` fetches only required official archive entries.

The shared mouse failure was a full-screen Control using the default STOP filter. The UI root, decorative panels and artwork now ignore mouse events; actual buttons retain normal hit testing. Tests explicitly exercise that GUI dispatch path. Browser pointer capture returned a Chromium error in the in-app test surface, so live mouse movement also controls the camera when capture is unavailable. The first motion after launch/resume is ignored to avoid a cursor-warp jump.

Validation covers automated interaction/rules and live browser checks. This does not certify every hardware configuration or every later campaign wave. The 3D games use keyboard/mouse and WebGL 2. There are no accounts, analytics or paid features; scores/settings stay in local IndexedDB or the desktop configuration file. Obsolete JavaScript game sources and unused assets were removed during package cleanup.

Live browser verification (8 October 2026): banana drag/drop scored 100; an energy drop raised 125 to 150; tunnel pulses scored 110; FPS recovered a target with three shots (18 to 15 rounds) and mouse movement changed the view. Final exported Windows executable completed its headless four-mode smoke launch with exit code 0. Player/enemy collision masks prevent walking through enemies. Screenshots are saved beside this document.

