# ShamanPlan

A leveling companion for Enhancement shamans in **WoW Forever**: talent plan with highlights, Maelstrom and buff reminders, gear upgrade check, quest reward picker, dungeon guide with quest status and directions, Alchemy and Herbalism assistant, and an XP tracker. English and Swedish.

## Releasing a new version

1. Update the code.
2. Put the new version's notes at the top of `CHANGELOG.md`, starting with a heading like `# ShamanPlan 1.0.1`.
3. Push to `main`. GitHub Actions sees the new version, tags it, packages the addon as `ShamanPlan-1.0.1.zip` and uploads it to CurseForge with the changelog.

To test first, use a version like `# ShamanPlan 1.0.1-beta1`. CurseForge marks it as a beta.

Pushes that don't change the version in the first line of `CHANGELOG.md` don't release anything.

The upload needs the repository secret `CF_API_KEY` (a CurseForge API token) and the CurseForge project ID in `ShamanPlan.toc` (`## X-Curse-Project-ID`).

## License

GPL-3.0, see `LICENSE`. The dungeon quest data in `DungeonData.lua` is generated from [QuestieDB](https://github.com/Questie/QuestieDB) (GPL-3.0); `tools/README.md` shows how to refresh it.
