# GAGE Workspace UI & Engineering Rules (Customer, Merchant, Driver, Admin)

All agent sessions working inside `c:\Users\ertyui\ZCodeProject\gage` across all 4 portals (Customer, Merchant, Driver, Admin) MUST follow `GAGE_FRONTEND_UI_STYLE_GUIDE.md` and the mandatory UI rules below.

## 1. Mandatory Full-Rounded Capsule for Segmented Switches & Pill Tabs

- **STRICT PROHIBITION**: NEVER use boxy rounded-rectangle corners (`BorderRadius.circular(8)` to `BorderRadius.circular(16)`) for segmented switches, tab switchers, mode toggles (e.g., Delivery vs Pickup, Merchant Favorit vs Produk Favorit, Order Masuk/Aktif/Selesai, Menu Aktif/Habis, Radar/Keuangan/Tarif), or filter chips.
- **REQUIRED GEOMETRY**: ALWAYS use full-rounded capsule/pill corners (`BorderRadius.circular(999)` or `StadiumBorder()`) on **BOTH** the outer track `Container` **AND** the inner active thumb (`AnimatedContainer` / `Container` / `InkWell`).
- **REQUIRED STYLING**:
  - Active thumb color: `GageTheme.primary` (`#E52320`) with white bold label text (`Colors.white`).
  - Outer track: `#F1F5F9` (Light) / `#0F172A` or `#1E293B` (Dark) with `EdgeInsets.all(3)` or `EdgeInsets.all(4)`.
  - Interaction: trigger `HapticFeedback.selectionClick()` on tap.
  - Reference implementations: `lib/features/food/presentation/resto_detail_screen.dart#L1540-L1615` (Delivery/Pickup) and `lib/features/food/presentation/shop_favorite_screen.dart#L372-L432`.

## 2. Contextual / Clutter-Free UI Rules

- Do not add redundant action buttons when the adjacent preview widget is already directly tappable (e.g., do not add `"Perbesar peta"` alongside a tappable `MiniLocationPreviewMap`).
- Do not add redundant context/status banners or unnecessary segmented switches when a view is already opened in a single-entity context (e.g., opening Favorites from inside a specific Merchant detail screen shows only that merchant's favorited items directly, with no switch and no status banner).
- For secondary media/photo actions in dense info cards (such as viewing a merchant location photo), prefer compact icon+text action buttons (`"Foto lokasi merchant ↗"`) instead of extra inline thumbnail previews and verbose multi-line subtitles.

## 3. Production & Coding Hygiene

- Do NOT introduce Unicode em dashes (`\u2014`) in code, comments, tests, or markdown docs.
- Never import `features/admin/` from `lib/features/home/` or `lib/shared/`.
- Honor `GageApiClient.useDevSeedData` for all seed/demo data guards.

## 4. Mandatory Cross-Portal Handoff Documentation

- Whenever any change in one portal (or shared service/API) affects another portal, data contract, pricing/voucher logic, deep-link route, or backend D1 schema, you MUST document it in the corresponding handoff file(s) before wrapping up:
  - Merchant Portal (`1c4b07ce-55ca-434a-821e-f12ef99bac9c`): `docs/handoffs/HANDOFF_MERCHANT.md`
  - Driver Portal (`d98ee887-52c5-46f7-b28e-7288f9eb5385`): `docs/handoffs/HANDOFF_DRIVER.md`
  - Admin & Backend D1 (`09b47b70-e6b6-4961-8c34-8f1b47e6f7d6`): `docs/handoffs/HANDOFF_ADMIN.md`
- Respect strict portal isolation: unless explicitly instructed, do NOT edit UI/provider code inside another portal's `lib/features/<other_portal>/` directory; record exact API/model contracts, UI drift findings, and SQL schema requirements in its handoff markdown instead.
