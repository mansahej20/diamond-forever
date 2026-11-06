# Diamond Forever

*Sparkle for Eternity* — an interactive jewellery catalogue. Each piece turns in
3D or spins through its photographs, with its hallmark plate alongside.

Installs to an iPhone home screen as a standalone app.

## What runs where

| Piece | Service |
|---|---|
| The page itself | Vercel (static — no build step) |
| Catalogue rows | Supabase Postgres, table `pieces` |
| Photographs | Supabase Storage, bucket `piece-photos` |
| Owner sign-in | Supabase Auth, email magic link |

There is no build and no framework. `index.html` is the whole app; three.js is
the single dependency and loads from a CDN.

## Who can do what

Row-level security, not UI, decides this:

- **Anyone** may read the catalogue and see the photographs. It is a shop window.
- **Only the owner** — the address in `OWNER_EMAIL` and in `is_owner()` — may
  add, edit or delete pieces.

Changing the owner means changing it in **both** `config.js` and
`supabase/schema.sql`, then re-applying the schema.

## Adding a piece

1. Open the site and press **Sign in to edit**. A magic link arrives by email;
   open it on the same device.
2. **+ Add your piece**.
3. Drop photographs or a turntable video. A video is cut into 24 frames in the
   browser — nothing is uploaded until you save.
4. Fill in the details and specification, then **Save piece**.

How many frames you give it decides what you get:

| Frames | Step | Result |
|---|---|---|
| 1 | — | A still. Zooms, but cannot turn. |
| 4 | 90° | Angle switcher — front, side, three-quarter, detail. |
| 16 | 22.5° | Reads as rotation, still visibly stepped. |
| 24 | 15° | Smooth spin. The practical sweet spot. |
| 36 | 10° | Showroom grade. |

Photographs are resized to 1400px and re-encoded as JPEG before upload, so a
24-frame spin costs a few MB rather than a hundred. **Keep your originals** —
what is stored here is a web copy, not an archive.

## Installing on an iPhone

Open the site in **Safari** (it must be Safari — Chrome on iOS cannot install
web apps), then Share → **Add to Home Screen**. It opens full screen with no
browser chrome.

## Local development

```bash
python3 -m http.server 8000
```

Then open <http://localhost:8000>. Service workers and Supabase auth both need
a real `http://` origin — opening `index.html` as a file will not work.

## Deploying

Vercel serves the repository as-is; every push to `main` deploys.

```bash
npx vercel --prod
```

## Regenerating the icons

`make-icons.js` draws them from scratch (an astroid — the four-cusped star of
the mark) with no image dependencies:

```bash
node make-icons.js
```

To use the real logo artwork instead, drop the files into `icons/` under the
same names and set `src="./icons/logo.png"` on the masthead `<img>` in
`index.html`.

## The sample pieces

The five modelled pieces — Aurea Court Band, Meridian Hoops, Riviera Line
Bracelet, Aurora Solitaire, Nilaya Halo Pendant — are procedurally generated
in three.js, not photographs. They demonstrate the 3D viewer. Once real pieces
are in, a toggle on the collection page hides them; deleting them for good
means removing the `PIECES` array from `index.html`.
