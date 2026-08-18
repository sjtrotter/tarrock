# `systems/progression` — Coins, shops, staff heads, graftings, Renown from deeds

Owns the Fool's purse and everything it buys, the shops that read the world, the one
staff head on the Bindle, the Rose graftings found, and the single place a deed becomes
Renown. Canon: [`docs/design/progression.md`](../../../docs/design/progression.md)
§Currency, shops, and gear-lite, §Renown, §Philosophy and §The White Rose;
[`docs/design/arcana.md`](../../../docs/design/arcana.md) Trump I and Trump XV (the two
Past passives that reach into a shop's stock);
[`docs/design/world.md`](../../../docs/design/world.md) §World-state matrix (the flag
that prices food) and §Regions (where a shop may stand);
[`docs/design/technical.md`](../../../docs/design/technical.md) §Godot 2D.

The Pocket Spread, Fortune and the White Rose themselves are **not** here — they are
[`systems/trumps/`](../trumps), because they are what a Trump plugs into. This folder is
the other half of `progression.md`: money.

## The shape of it

```
EconomyService                 the purse, the shelves, the deeds - one RefCounted
  EconomyRules                 every number, hand-authored          data/progression/economy_rules.tres
    PriceRule[]                a world-state x a category x a multiplier
  ItemCatalog                  what exists                          data/progression/items/
  ShopCatalog                  where it is sold                     data/progression/shops/
    ShopStockEntry[]           one shelf line, and its conditions
  DeedCatalog                  §Renown's four rows, GENERATED       data/progression/deeds/
ShopOffer                      one runtime price on one shelf
ItemCategory / Reaction        the two enums, spelled once each
ItemIds / ShopIds / DeedIds    no magic strings
```

## Generated vs. hand-authored

| What | Where | How |
|---|---|---|
| The four deeds and their per-suit reactions | `data/progression/deeds/*.tres`, `catalog.tres` | **generated** from `progression.md` §Renown's deed table by `tools/gen_definitions.py`; drift-tested twice (see below) |
| `DeedIds` | `systems/progression/deed_ids.gd` | **generated** from the same rows |
| The economy's numbers | `data/progression/economy_rules.tres` | **hand-authored**; `notes` says what is canon and what is TBD |
| Items, shops, `localization/items.csv` | `data/progression/items/`, `shops/` | **hand-authored** |

`progression.md` §Currency, shops, and gear-lite says why the second half cannot be
generated, in its own words: "the exact identity and location of each staff head, and
the full list of Rose-grafting sources, are **TBD** — content-design passes that happen
once regions are greyboxed". There is no table to read.

**The deeds are drift-tested twice, on purpose.** `gen_definitions.py --check` proves
the files on disk are what the tool would write today; `tests/unit/progression/
deed_data_test.gd` re-reads §Renown's table with a *second* reader
(`Reaction.from_doc_text()`, which shares no code with the generator's Python) and
checks the definitions against it. The first catches a stale file; the second catches a
generator that reads the doc wrongly and writes the same wrong thing every time.

## Rules worth not re-deriving

- **A price is read, never stored.** `progression.md`: "a shop's stock and prices are a
  live reflection of the world-state matrix … not a static price list". `price_of()`
  multiplies the item's base price by the shop's region multiplier, by the Renown tier
  the Fool holds **with that shop's local suit**, and by every `PriceRule` whose flag has
  fired — rounded, never below 1 Coin. The canon example (`WS_EMPRESS_UNBOUND` halves
  FOOD Spread-wide) is one row of `economy_rules.tres` and **not one line of code**. The
  day it becomes an `if`, `economy_data_test.gd` fails.
- **Renown is not a morality meter.** A deed carries four independent reactions and no
  summary of them, and `record_deed()` adjusts each suit separately with the deed id as
  the reason. Nothing anywhere adds the four movements up. A NEUTRAL suit is not
  adjusted at all — a zero adjustment would tell a listener that an indifferent culture
  had an opinion.
- **`record_deed()` is the only place a deed becomes Renown**, exactly as
  `WorldStateService.adjust_renown()` is the only place Renown moves. A quest that wants
  standing to move names a row of the doc; it does not pick a number.
- **The magnitudes are not canon and live in one place.** §Renown states four
  *reactions* and no figure anywhere, so `EconomyRules.renown_delta_for()` is where a
  word becomes points. Only the shape is defensible from the doc: a full reaction
  outweighs a slight one, indifference is worth nothing, the ladder is symmetric.
- **Growth stays horizontal.** A staff head names a `moveset_twist` strategy id and
  carries **no number** — "never a numeric upgrade" — and the combat effect runner owes
  the behaviour. An OUTFIT that grew a twist is a `validate()` error, not a balance
  question, so §Philosophy's scope cut is enforced in data rather than remembered.
- **The Rose owns its own cap.** `find_grafting(source_id)` is set-once **per source**
  and calls `WhiteRoseService.add_grafting()`; nothing here counts petals. A grafting the
  Rose cannot take (it is at its eight) is *not* recorded, so a source is never silently
  spent for nothing.
- **Hidden stock is not an empty shelf slot.** A line the Fool cannot see is not on the
  shelf at all, and a buy that names it is refused with the same reason as a line the
  shop never carried — a shop that refused differently would tell the Fool what is
  behind the counter. `hidden_until_manifest` waits on Trump I (`arcana.md`: "vendors
  show their hidden stock") and `fine_print` on Trump XV ("fine-print stock at every
  shop"); both are **hooks** — what a "cost printed honestly" then does to the Fool who
  pays it is the effect runner's.
- **Rest is what restocks.** `progression.md` §Waystations makes a rest the world's own
  tick, so `EconomyService` listens to `RegionService.rested` and never ticks. A line
  with `restocks_on_rest = false` — the stall's one staff head — stays sold.
- **`RegionService` is held WEAKLY.** It holds the save, and the save holds this
  service: an ordinary field closes a `RefCounted` cycle nothing collects, and Godot
  reports it at exit as `ERROR: N resources still in use`, which fails the whole test
  stage. `attach_regions()` keeps a `WeakRef`; the composition root stays the only owner.
- **The purse is save state.** Coins, item counts, the fitted head and the grafting
  sources travel as the save file's `inventory` section, whose keys this service owns
  (`SNAPSHOT_*`), on the same fresh-only, all-or-nothing contract every other
  progression service keeps. What a **shop** has sold is deliberately not saved: that is
  a fact about a shop between two rests.

## Owed / TBD

- **Every staff head is a placeholder.** Three are authored (`REACH_PLUS`,
  `HEAVY_WIDE`, `FIRE_TAG`) against a doc that expects 8–10; identity and location are
  a content pass. The twists themselves do nothing until the combat effect runner reads
  `ItemDefinition.moveset_twist`.
- **Rose-grafting sources are doc-TBD.** There is one `ROSE_GRAFTING` item and the
  *source* is what `find_grafting()` keys on, so the world can hand one over from
  anywhere the moment the list exists.
- **"Settled region" is a reading.** `world.md` §Regions never uses the word;
  `EconomyRules.settled_region_ids` records the reading region by region in `notes` and
  is TBD. One shop is authored — the Prestige's, for the proof slice — and it has **no
  keeper**: no doc names a shopkeeper there, so the person behind the stall is content
  design (`characters.md` owns named NPCs).
- **A shop's local suit is a reading too.** Nothing joins `GLOSSARY.md`'s four
  suit-terrains to `world.md`'s regions. The Prestige is authored as Wands and says why.
- **Shops sell, they do not buy — not in canon.** LEAD RULING: `progression.md` says
  Coins are found, looted, earned through quests, and spent; nowhere does a shop pay
  the Fool for anything. There was a `sell()`/`sell_price_of()` pair and a
  `sell_price_fraction` tuning number; both are gone. If the director wants a buy-back
  verb, it enters `progression.md` first.
- **Nobody spends Coins yet.** Quests, loot and chests hand nothing over: `add_coins()`
  and `add_item()` are the seams the quest and world-content rounds call.
- **The five TBD placeholder item names are not glossary terms.** `ITEM_SHOWBILL`,
  `ITEM_MOTLEY_COAT`, `STAFF_BROADHEAD`, `STAFF_EMBER` and `STAFF_REACHING` name
  nothing `GLOSSARY.md` owns — they are content-design placeholders, exactly as their
  own `.tres` `notes` say. Whoever names the real items adds those names to
  `GLOSSARY.md` in the same change.
