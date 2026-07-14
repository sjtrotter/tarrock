# Third-Party Notices

Every third-party asset or package used by Tarrock is catalogued here — source, version,
license, and where it lives in the project. **Nothing third-party enters the repo without
a row in this table** (enforced by the CLAUDE.md review checklist). CC0 content requires
no attribution; we track and credit it anyway.

## Engine & packages

| What | Source | License | Location |
|---|---|---|---|
| Unity 6000.5.3f1 + official packages (URP, Input System, Cinemachine, Localization, Test Framework, etc.) | Unity Technologies | [Unity Terms of Service / package licenses](https://unity.com/legal) | `Packages/manifest.json`, `PackageTarballs/` |

## Art & audio (stand-ins and finals)

| What | Source | License | Location | Notes |
|---|---|---|---|---|
| KayKit Adventurers 1.0 (RogueHooded character + 75 embedded animations, atlas texture) | Kay Lousberg — [kaylousberg.com](https://www.kaylousberg.com) / [itch.io](https://kaylousberg.itch.io/kaykit-adventurers) | CC0 1.0 | `Assets/ThirdParty/KayKit/` | Stand-in for the Fool. CC0 requires no attribution; credited anyway. |
| Kenney Prototype Textures 1.0 (green/stone/orange/light grid textures) | Kenney — [kenney.nl](https://www.kenney.nl) (obtained via OpenGameArt mirror) | CC0 1.0 | `Assets/ThirdParty/Kenney/` | Greybox grid ground/props so motion reads. CC0 requires no attribution; credited anyway. |
| Quaternius Universal Base Characters (Superhero_Male body + textures) | Quaternius — [quaternius.com](https://quaternius.com) | CC0 1.0 | `Assets/ThirdParty/Quaternius/UniversalBaseCharacters/` | Adult-proportioned skinned body — Fool stand-in v2 candidate. Standard (free) edition. |
| Quaternius Universal Animation Library 1 & 2 (UAL1/UAL2 Standard, in-place variants) | Quaternius — [quaternius.com](https://quaternius.com) | CC0 1.0 | `Assets/ThirdParty/Quaternius/UniversalAnimationLibrary/` | 120+/130+ humanoid animations on the universal rig; drives the UBC body. |
| Quaternius Modular Character Outfits – Fantasy (Male Peasant set + Ranger hood, Standard) | Quaternius — [quaternius.com](https://quaternius.com) | CC0 1.0 | `Assets/ThirdParty/Quaternius/ModularOutfitsFantasy/` | The Fool's traveler costume. |
| Quaternius Fantasy Props MegaKit (19-prop camp/waystation subset, Standard) | Quaternius — [quaternius.com](https://quaternius.com) | CC0 1.0 | `Assets/ThirdParty/Quaternius/FantasyProps/` | Cliff scene dressing. |
| Quaternius Medieval Village MegaKit (Standard, downloaded, not yet vendored) | Quaternius — [quaternius.com](https://quaternius.com) | CC0 1.0 | staged in `~/Downloads`; vendored on first use | Modular buildings for settled regions (Prestige etc.). |
| Quaternius Ultimate Stylized Nature (May 2022; dead trees, trees, rocks, grass, bushes subset) | Quaternius — [quaternius.com](https://quaternius.com) | CC0 1.0 | `Assets/ThirdParty/Quaternius/StylizedNature/` | Cliff nature dressing — incl. MQ00's canon dead tree. |

## Documents

| What | Source | License | Location |
|---|---|---|---|
| GDD template structure | Alec Markarian & Benjamin Stanley | Free to use/modify, not sell; credit retained | `docs/GDD.md` |
