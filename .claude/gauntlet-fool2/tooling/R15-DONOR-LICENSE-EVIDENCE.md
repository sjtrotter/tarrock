# Donor Head — License Evidence

Date checked: 2026-08-03 (today, per session context).

## Primary source attempted: thebasemesh.com — REJECTED (no such asset exists)

The R15 brief and research doc named `thebasemesh.com` as the primary donor,
citing an asset at `/asset/head`. That URL 404s. Investigation of the site's
own sitemap confirms it is exhaustive:

- Full asset sitemap: `https://www.thebasemesh.com/dynamic-asset_p_ed7478c4_54f0_4f34_aa95_b766a3c7f144_0_5000-sitemap.xml`
  (1254 `<loc>` entries, fetched in full).
- Independently cross-checked against the GitHub mirror
  `https://github.com/M3-org/base-meshes` ("CC0 grey box game dev assets
  derived from thebasemesh.com as an asset pallet", 901 models, cloned
  locally and inspected).
- Neither the live sitemap nor the GitHub mirror contains a human head/face
  asset. The only "head"-named entries are non-human or hard-surface props:
  `screw-head`, `flat-head-screw(driver)`, `allen-key-screw-head`,
  `headstone-01..05`, `deer-head`, `rattlesnake-head`, `rail-(bull-head)`,
  `arrowhead`, `barbed-arrowhead`, `fire-arrowhead`, `u-arrowhead`,
  `greek-spear-head-01/02`, `computer-headphones-01`. The only anatomical
  item on the entire site is `skull-(no-teeth)` — a bare bone skull with no
  eye/mouth soft-tissue topology, unusable as an eye/mouth-loop retopo donor.
- Conclusion: thebasemesh.com is a hard-surface / prop / architectural /
  nature CC0 library, not a character-asset library. It has no human head
  asset at all, under any slug. The research doc's recommendation was an
  unverified assumption (it said so explicitly: "site's model library wasn't
  inspected in this pass"); this pass inspected it and the assumption does
  not hold. Falling back to the brief's named fallback per the brief's own
  "if genuinely unobtainable" clause.
- thebasemesh.com's general site license (confirmed, for completeness, even
  though no asset was taken from it): "CC0 License" / "100% Free" is stated
  sitewide and independently corroborated by the CC0-1.0 `LICENSE` file in
  the GitHub mirror repo (Creative Commons Legal Code, CC0 1.0 Universal,
  full public-domain dedication text, no restriction).

## Fallback source used: itch.io — "3D Low Poly Head" by zakariya el onsri

- Asset page: https://zakariya-el-onsri.itch.io/3d-low-poly-head
- Author profile: https://zakariya-el-onsri.itch.io
- Downloaded file: `3D Low Poly Head.zip` (32 MB listed / 34,548,598 bytes
  actual), containing `.blend` (+ `.blend1` backup), `.fbx`, `.obj`, `.glb`,
  two texture PNGs, and render/preview images. Saved to
  `/home/betty/tarrock-gauntlet-work/fool2-r15/donor/3D-Low-Poly-Head.zip`,
  extracted to `donor/extracted/3D Low Poly Head/`.
- Price: Free (itch.io `min_price`: 0, `actual_price`: 0 — confirmed via the
  page's own embedded game data during download).

### Exact license text (verbatim, as displayed on the asset page today)

> "Free for personal and commercial use – no attribution required (CC0). You
> are free to modify, use, or include it in your own projects and games,
> please do not offer it for sale."

Additional description text on the same page (context, not license, but
relevant to scope of intended use):

> "This is a free stylized low poly character head designed for use in
> games, prototyping, and educational purposes... Clean topology
> (quad-based)... UV unwrapped..."
> Listed use cases include: "Animators or rigging practice."

### Honest note on the license text's own internal tension

The page calls this "CC0" but then adds one restriction beyond what CC0
actually permits: "please do not offer it for sale" (true CC0/public-domain
dedication would permit resale of the asset itself). This is a common
informal misuse of the "CC0" label by individual creators. For our purposes
this is not a blocker: we are not reselling or redistributing the donor
asset — it is being used as an internal modeling reference/projection
donor for a derivative, hand-retopologized game character mesh that ships
inside Tarrock, not as a pass-through asset. Flagging this nuance for the
lead/director rather than silently treating it as unrestricted CC0.

### Site metadata corroborating "no generative AI" / free / commercial-use framing

The asset page's info panel states: Status: Released; Category: Assets;
Content: "No generative AI was used." Confirms the asset is treated by the
platform as a normal free commercial-use game asset, consistent with the
license blurb above.

## Retrieval method (for reproducibility / honesty)

Both sources were fetched programmatically (no interactive browser/GUI
used, per governor rules — network work only, no Blender GUI touched). The
itch.io file required reproducing itch.io's own AJAX download-token flow
(`POST .../download_url` → visit signed landing page → `POST
.../file/<upload_id>?source=game_download...` → time-limited S3-compatible
signed URL, 60 s expiry) since the button-driven flow has no plain static
link. This is itch.io's standard client-side flow (reverse-derived from its
own public `extern.min.js`/`intern.min.js`), not an exploit or bypass of any
paywall — the asset is genuinely free and requires no account/login.
