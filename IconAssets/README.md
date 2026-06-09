# SilentFleet Icon Assets

Vector components used to compose the app icon and Game Center achievement art.

## Layout

```
IconAssets/
├── components/
│   ├── base/        # Pieces that make up the current app icon
│   │   ├── background-gradient.svg
│   │   ├── sonar-grid.svg
│   │   ├── waves.svg
│   │   ├── crosshair-reticle.svg
│   │   ├── ship-battleship.svg
│   │   └── target-blip.svg
│   ├── ships/       # Drop-in alternatives for the ship layer
│   │   ├── ship-battleship.svg
│   │   ├── ship-carrier.svg
│   │   ├── ship-destroyer.svg
│   │   ├── ship-submarine.svg
│   │   └── ship-patrol.svg
│   ├── badges/      # Award ring you can stack behind the reticle
│   │   ├── badge-bronze.svg
│   │   ├── badge-silver.svg
│   │   └── badge-gold.svg
│   └── overlays/    # Status art for achievement variants
│       ├── overlay-hit.svg
│       ├── overlay-miss.svg
│       └── overlay-sunk.svg
└── SilentFleet.icon/   # Icon Composer bundle (base composition)
    ├── icon.json
    └── Assets/
```

All SVGs are authored on a `1024 × 1024` canvas so they line up when stacked
without any extra positioning. Drop them into Icon Composer in the order they
appear under `base/` to reproduce the current app icon.

## Opening in Icon Composer

1. Open Icon Composer (ships with Xcode 26).
2. **Option A — open the bundle:** `File → Open` and pick
   `IconAssets/SilentFleet.icon`. The included `icon.json` is a best-effort
   manifest; if Icon Composer complains, use Option B.
3. **Option B — build fresh:** `File → New Icon`, then drag the six SVGs from
   `components/base/` into the layer list in this bottom-to-top order:
   1. `background-gradient.svg`
   2. `sonar-grid.svg`
   3. `waves.svg`
   4. `crosshair-reticle.svg`
   5. `ship-battleship.svg`
   6. `target-blip.svg`

Once loaded, every layer is independent — you can tint, blur, swap, or hide
each one for Dark / Tinted / Clear appearances.

## Composing achievement art

Game Center wants flat `512 × 512` PNGs, not the `.icon` format. The fastest
workflow:

1. Duplicate `SilentFleet.icon` (e.g. `FirstBlood.icon`).
2. Swap the ship layer for a different `ships/*.svg` if the achievement is
   tied to a hull type.
3. Add a badge from `badges/` underneath the reticle for tier (bronze/silver/
   gold).
4. Drop an overlay from `overlays/` on top for state (hit / miss / sunk).
5. Export at `512 × 512` PNG (`File → Export…` in Icon Composer) and upload to
   App Store Connect → My Apps → Game Center → Achievements.

### Suggested combos

| Achievement idea            | Ship          | Badge   | Overlay        |
| --------------------------- | ------------- | ------- | -------------- |
| First Blood (first hit)     | battleship    | bronze  | hit            |
| Sharpshooter (10 hits)      | destroyer     | silver  | hit            |
| Fleet Admiral (win 50)      | carrier       | gold    | —              |
| Silent Hunter (sub kill)    | submarine     | silver  | sunk           |
| Bombs Away (miss streak)    | patrol        | bronze  | miss           |
| Sunk the Bismarck           | battleship    | gold    | sunk           |

## Editing tips

* Colors live as hex values directly in each SVG — search/replace in the file
  to recolor (e.g. swap the ship's `#FFFFFF` for a faction color).
* The reticle, ship, and target are all centered on `(512, 512)`, so resizing
  them around that point keeps the composition aligned.
* Need a new ship silhouette? Copy `ship-patrol.svg` as a starting template;
  it's the simplest.
