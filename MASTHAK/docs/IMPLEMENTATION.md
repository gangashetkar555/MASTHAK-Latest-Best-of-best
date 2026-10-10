# Implementation and validation

Home page: one continuous journey, with navigation anchors to the beginning, arcade, books, material lab and characters. `Landing.tsx` composes the original illustrated courtyard, one selected inline Godot game, five-book/43-panel scrolling story, the existing interactive material lab, and cast. Existing direct routes remain as compatibility views.

The opening uses the original compressed courtyard illustration, with responsive desktop/mobile sources and a high-priority image request. The reference headline, buttons, chapter preview, typography and positioning are restored. No WebGL renderer or continuous animation loop runs behind this hero. Motion settings still control story transitions; system reduced-motion preferences are respected.

`ScrollStory.tsx` uses a sticky illustrated stage. Native page scrolling selects one of 43 panels; the next compressed panel is preloaded. Book covers jump to the relevant reading position. Explicit Previous/Next and Space/arrows support discrete advancement. Three sorting interactions offer feedback and retries; batteries go to special collection. A complete transcript is available without traversing the scrolling sequence. Answers stay in memory only. The standalone legacy reader retains optional chapter narration.

Audio: Suno v6-mini generated Courtyard of the Trees (3:12). ElevenLabs generated courtyard ambience, a leaf/paper transition and a success cue. Files are served from `public/assets/soundscape`; services are not called by the website. Sound defaults to enabled, with preload disabled; playback retries on the first pointer or keyboard interaction when browser autoplay policy blocks it, loops pause on document hiding and starting a game mutes the page. Transition sounds have a cooldown to avoid stacking during fast scroll. See ASSET-LICENSES.md for provenance and account limitations.

Arcade: original Godot 4.7.2 export and animated Blender models remain unchanged. The home page launches a single selected mission iframe on demand. Changing mission unloads it; Close game also unloads it. The standalone game routes remain available. Kenney CC0 licenses remain bundled.

References: supplied KAGE recording, Street Holds story reference and the three GIF motion references. GIFs informed forward camera travel, sideways drift and foreground foliage depth; none are embedded. Their artwork, branding or code was not imported.

No accounts, forms, payment collection, analytics or third-party SDKs. Local game deletion controls and privacy/terms pages remain. Fonts are hosted locally. The decay chart remains explicitly illustrative, not measured data.

Checks: TypeScript and production build pass. Live desktop/mobile checks cover chapter jumps, Previous/Next, choice feedback, navigation anchors, local sound playback and inline game launch. Runtime browser console checked. Existing Godot regression tests cover the unchanged engine; complete campaigns and performance across all hardware are not guaranteed. No new ZIP is generated during this revision.

UI restoration: the release/MASTHAK-Local.zip snapshot supplied the original headline, CTA, bold sans-serif wordmark, vertical side note, chapter selector and preview card. These are restored over the original painted courtyard; top navigation is transparent over the scene and gains a solid background below it. Preview chapters open the corresponding position in the continuous reader. The ZIP itself is not rewritten.

Hero polish: grid rows prevent overlap on wide and short desktop screens; mobile keeps dedicated space for the preview and controls. Sound appears beside Reduced motion. Chapter previews advance every 6.5 seconds, pause on hover/focus or via the pause button, and suspend offscreen/when hidden. Motion adds a slow backdrop drift, entrance reveals and gentle exploration cue; reduced motion removes transforms.

Page sequence: Beginning > Arcade > Books / scrolling story > Material lab > Characters. The continuous page uses one cream/gold/forest palette, Fraunces display typography, Nunito controls, shared section gutters and restrained rectangular cards throughout.
