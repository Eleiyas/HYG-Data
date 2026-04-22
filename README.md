# HYG-Data

Game-Data for a particular cozy anime game.

## Notes

* CB2 changed how ExcelData was stored. They are no longer inside BinData, but inside .obb files. I've dumped what I can, but I do not promise they are complete.
* TextMaps show no changes, but according to new ExcelData, they now follow Genshin's style of having Hash-IDs, not Strings. TextMaps likely need to be redumped in the same way ExcelData is.
* Maybe due to dumping method, some desc_ and textmap_ tags are pre-mapped to English. Don't ask me to fix it, getting this far already took me the best part of a day.

## Unsorted

* Data: ~~1,823~~ ~~991~~ 367 files.
* Lua: 33 files (unchanged).
* _Bin: ~~253~~ ~~168~~ 157 files.
* ExcelData: 7 files refuse to dump.

## Changelog

- 20/04/2026 - Stardrift Test (0.92.7)
- 25/11/2025 - Coziness Test (0.83.5)

### Credits

- Escartem: [AnimeStudio](https://github.com/Escartem/AnimeStudio)
- Nullable: Massive help regarding CB2 dumping
- yarik0chka: Help with Hash Reversing
- modder4869: Help with xLua Reversing
- UnityPy Members: Various other bits and pieces
- tehtmi: [Unluac](https://sourceforge.net/projects/unluac/)
