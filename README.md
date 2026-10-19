# HYG-Data

Game-Data for a particular cozy anime game.

## CB3

Provided as-is. No TextMap or other JSON, just Excels & most Lua.

* ~25 Excels did not dump this time around.

## CB2

Changed how Excels were stored. No longer in binData, but in "GeneratedAssets/ed.obb".
TextMaps show no changes, but according to new ExcelData, they now follow Genshin's style of having Hash-IDs, not Strings. TextMaps likely need to be redumped in the same way ExcelData is.

* Data: ~~1,823~~ ~~991~~ 367 files.
* Lua: 33 files (unchanged).
* _Bin: ~~253~~ ~~168~~ 157 files.
* ExcelData: 7 files refuse to dump.

## Changelog

- 19/10/2026 - Final Beta Test (0.95.2) - Uploaded after Beta Ended
- 20/04/2026 - Stardrift Test (0.92.7)
- 25/11/2025 - Coziness Test (0.83.5)

### Credits

- Escartem: [AnimeStudio](https://github.com/Escartem/AnimeStudio)
- Nullable: Massive help regarding CB2 dumping
- yarik0chka: Help with Hash Reversing
- modder4869: Help with xLua Reversing
- UnityPy Members: Various other bits and pieces
- tehtmi: [Unluac](https://sourceforge.net/projects/unluac/)
