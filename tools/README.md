# Tools

`gendungeons.lua` rebuilds `DungeonData.lua` from QuestieDB's WoW Forever data.

```sh
git clone --depth 1 https://github.com/Questie/QuestieDB QDB
(cd QDB && ./tools/lua-binary/linux-x64/lua tools/export-forever.lua --include-authored)
texlua tools/gendungeons.lua DungeonData.lua   # any Lua 5.3+, run from the repo root with QDB/ next to it
```
