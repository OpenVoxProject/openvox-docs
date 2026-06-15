# Maintaining openvox-docs

Maintainer procedures for this site. For day-to-day content contribution and local
preview, see [CONTRIBUTING.md](CONTRIBUTING.md).

## Adding a new major version (cutover)

The site uses a **copy-on-major-release** model. Each major version of a product
lives in its own collection (e.g. `docs/_openvox_8x/`), and `_<product>_latest` is a
symlink to the current stable one. When a product ships a new major, you copy the
collection, register it, pin its references, and — once the new major is the stable
release — promote it to `latest` and freeze the old one. Products version
independently (OpenVox, OpenFact, and OpenBolt have generated references; OpenVox
Server, OpenVoxDB, Ecosystem, and OpenVox Containers are authored-only).

The example below adds **OpenVox 9** alongside OpenVox 8; substitute product/version
as needed.

### How versions are wired (background)

- **Collections** — `docs/_<product>_<major>/`, declared in `_config.yml` under both
  `collections:` (permalink) and `defaults:` (which nav to use). `_<product>_latest`
  is a **symlink** to the current stable collection dir, so `/<product>/latest/`
  serves the same files as `/<product>/<major>.x/`.
- **`_data/products.yml`** — the version registry. Per product: a `label`, which
  version `latest` aliases, and (for products with generated references) the
  `references:` rake task. Per version: `id`, `label`, `collection`, `base` URL, and
  — for generated products — the exact upstream `ref:` tag to build from.
- **Navigation** — `_data/nav/<key>.yml` (sidebar trees), `_data/nav_map.yml`
  (which collections map to a nav key), `_data/navigation.yml` (top product bar).
- **Version selector** — reads `products.yml`; it appears automatically once a
  product has 2+ versions (so it stays hidden until the first cutover).
- **Reference docs** — generated (not committed) by `rake references:all` from the
  pinned tags. The new version builds from its pin; the old version stays frozen at
  its pin.

> `_config.yml` collections can't be generated from `products.yml` (Jekyll reads the
> config before `_data`), so they are hand-maintained — keep the two in sync.

### Phase 1 — stand up the new version (preview)

Do this when the new major has a tag to build against (a prerelease/RC is fine), but
is **not yet** the stable release. `latest` stays on the current major.

1. **Copy the collection and its nav file, and stage them** so the sweep in step 2
   sees all the authored content:

   ```console
   cp -r docs/_openvox_8x docs/_openvox_9x
   cp _data/nav/openvox_8x.yml _data/nav/openvox_9x.yml
   git add docs/_openvox_9x _data/nav/openvox_9x.yml
   ```

   Generated reference pages are gitignored within the collection, so `git add`
   stages only the authored content — and `git grep` below then skips the generated
   pages automatically (they self-update from the new tag at build time).

2. **Sweep the copied authored content for version-specific strings** and review each
   in context (page titles, prose, compatibility notes, "upgrading from N" pages, and
   the **nav file's** section headings and link text). Target the **major you're
   leaving behind** (here, `8`):

   ```console
   git grep -nE 'OpenVox 8|8\.x' -- docs/_openvox_9x _data/nav/openvox_9x.yml
   ```

   Don't forget the nav file — its headings (e.g. "OpenVox 8 Platform") and link
   text ("Upgrading OpenVox 8") are authored strings that won't update on their own.

   This is a review, **not** a blind find/replace. The hits fall into two kinds:
   straightforward current-version labels (page titles, "OpenVox 8 uses…") that bump
   to the new major, and version-*specific* content (e.g. "8.x still supports hiera 4
   for backward compat", the release-notes list of 8.x releases, "upgrading from 8"
   paths) that needs rewriting or judgment for the new major — not a mechanical bump.
   Targeting the specific old major (rather than a generic `[0-9]+\.x`) keeps out
   noise like Puppet / hiera / function-API versions in code examples.

3. **Register the collection** in `_config.yml`:

   ```yaml
   # under collections:
   openvox_9x:
     output: true
     permalink: '/openvox/9.x/:path:output_ext'

   # under defaults:
   - scope:
       path: ''
       type: openvox_9x
     values:
       nav: openvox_9x
   ```

4. **Wire up navigation.** The nav file (`_data/nav/openvox_9x.yml`) was already
   copied and swept in steps 1–2; adjust it further as the 9.x structure diverges
   (its links are relative, so they resolve under `/openvox/9.x/...` automatically).
   Then add a **new** entry to `_data/nav_map.yml` whose `nav_key` matches the `nav:`
   default from step 3 (do *not* add the collection to the existing 8.x entry —
   `nav: openvox_9x` only resolves against a `nav_key: openvox_9x`):

   ```yaml
   - nav_key: openvox_9x
     collections: openvox_9x
     base: /openvox/9.x/
   ```

   Finally, add the new collection to OpenVox's entry in `_data/navigation.yml` (the
   top product bar) so the "OpenVox" link is marked active on the new version's pages
   too:

   ```yaml
   - title: OpenVox
     url: /openvox/latest/
     collections: [openvox_latest, openvox_9x, openvox_8x]   # add openvox_9x
   ```

5. **Add the version to `_data/products.yml`** (newest first), keeping `latest: 8x`
   for now:

   ```yaml
   openvox:
     label: OpenVox
     latest: 8x
     references: references:openvox
     versions:
       - id: 9x
         label: "9.x"
         collection: _openvox_9x
         base: /openvox/9.x/
         ref: "9.0.0-rc1"   # the prerelease/RC tag to build from
       - id: 8x
         label: "8.x"
         collection: _openvox_8x
         base: /openvox/8.x/
         ref: "8.28.0"
   ```

6. **Generate references and build locally to verify:**

   ```console
   bundle exec rake references:all INSTALLPATH=docs
   bundle exec jekyll build
   bundle exec rake test:links
   ```

   Confirm `/openvox/8.x/`, `/openvox/9.x/`, and `/openvox/latest/` all render, and
   that the version selector now shows both `9.x` and `8.x (latest)`.

Open a PR with these changes. On merge, CI regenerates both versions from their pins
and publishes.

### Phase 2 — promote the new version to `latest` (GA)

Do this when the new major becomes the stable release.

1. **Repoint the `latest` symlink:**

   ```console
   ln -sfn _openvox_9x docs/_openvox_latest
   ```

2. **Point the `latest` collection's navigation at the new version.** The
   `/<product>/latest/` pages belong to the `openvox_latest` collection, so their nav
   has to move from 8.x to 9.x:
   - In `_config.yml`, change the `openvox_latest` defaults scope from
     `nav: openvox_8x` to `nav: openvox_9x`.
   - In `_data/nav_map.yml`, move `openvox_latest` into the 9.x entry's `collections`
     and update the `base:` fields so the frozen 8.x entry points at its own URL and
     the 9.x entry owns `/latest/`:

     ```yaml
     - nav_key: openvox_8x
       collections: openvox_8x
       base: /openvox/8.x/
     - nav_key: openvox_9x
       collections: openvox_9x|openvox_latest
       base: /openvox/latest/
     ```

3. **In `_data/products.yml`:** set the OpenVox `latest:` to `9x` (a targeted
   per-product edit — don't sweep every product's `latest:`), and **freeze 8.x** by
   pinning its `ref:` to its final 8.x tag (so the frozen collection stays
   reproducible).

4. **No-redirect check:** the site has no redirect mechanism. Once `latest` points at
   9.x, any page **removed or renamed** in 9.x will 404 at `/openvox/latest/<page>`
   for `latest` bookmarks (the content still lives at `/openvox/8.x/<page>`). Diff the
   8.x vs 9.x page sets and decide how to handle removed pages before promoting.

5. Rebuild and verify: `/openvox/latest/` now serves the 9.x content, `/openvox/8.x/`
   stays frozen, and the version selector marks 9.x as `latest`.

### Rollback

To back out a cutover: repoint the `_<product>_latest` symlink to the previous
collection, revert the `_config.yml` / `nav_map.yml` / `products.yml` / `_data/nav`
changes, and remove the new `docs/_<product>_<major>/` directory.
