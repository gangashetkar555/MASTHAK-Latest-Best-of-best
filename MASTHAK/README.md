# MASTHAK - The Garbage Court

Start with [readme.txt](readme.txt) for complete local setup, controls, troubleshooting and optional developer commands. Windows users can run START-LOCAL.cmd after installing Node.js. Godot and Blender are not required to play through the website.

The landing courtyard uses compressed illustrated scenery with optional light parallax. The five-book story reader has focused panels, sorting choices, captions and optional locally hosted narration. The arcade uses Godot 4.7.2, custom animated Blender characters and selected Kenney assets. The material explorer uses an explicitly illustrative decay model.

- [Game source, mechanics and validation](docs/godot/README.md)
- [Implementation notes](docs/IMPLEMENTATION.md)
- [Asset notices](docs/ASSET-LICENSES.md)

To create a clean distributable ZIP: python scripts/package-project.py. Generated dependencies, caches and download tools are excluded; the locked dependency file and compiled web games are included.
