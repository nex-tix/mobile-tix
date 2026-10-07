---
name: Uluwatu Kecak Gate Validator
colors:
  surface: '#031427'
  surface-dim: '#031427'
  surface-bright: '#2a3a4f'
  surface-container-lowest: '#000f21'
  surface-container-low: '#0b1c30'
  surface-container: '#102034'
  surface-container-high: '#1b2b3f'
  surface-container-highest: '#26364a'
  on-surface: '#d3e4fe'
  on-surface-variant: '#e0bfbc'
  inverse-surface: '#d3e4fe'
  inverse-on-surface: '#213145'
  outline: '#a78a88'
  outline-variant: '#59413f'
  surface-tint: '#ffb3af'
  primary: '#ffb3af'
  on-primary: '#68000e'
  primary-container: '#cf4647'
  on-primary-container: '#ffffff'
  inverse-primary: '#ae2e32'
  secondary: '#4edea3'
  on-secondary: '#003824'
  secondary-container: '#00a572'
  on-secondary-container: '#00311f'
  tertiary: '#ffb95f'
  on-tertiary: '#472a00'
  tertiary-container: '#a66900'
  on-tertiary-container: '#ffffff'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdad7'
  primary-fixed-dim: '#ffb3af'
  on-primary-fixed: '#410005'
  on-primary-fixed-variant: '#8d141d'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb95f'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#031427'
  on-background: '#d3e4fe'
  surface-variant: '#26364a'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  title-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.02em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.04em
  label-sm:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.06em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system establishes an ultra-clean, mission-critical field utility designed specifically for outdoor evening gate scanning at the iconic Uluwatu Temple amphitheater. The interface balances high-performance utility with cultural dignity. 

### Visual Direction: Utilitarian Minimalist
- **Core Aesthetic:** Monolithic, high-contrast dark surfaces punctuated by an electric crimson accent—evoking the sacred sunset fire of the Kecak dance while delivering crisp, outdoor-legible visual feedback.
- **Atmosphere:** Industrial, focused, authoritative, and calm under high throughput and adverse lighting (dusk to nightfall, bright mobile screen reflections).
- **Target Audience:** Gate staff, security leads, and cultural event coordinators needing instantaneous validation under sub-second scanning conditions.

## Colors

The palette is engineered for rapid status identification and high outdoor contrast. Backgrounds avoid pure pitch black in favor of deep obsidian to control eye strain while preserving luminance separation.

### Color Tokens & System Roles
- **Base Surface (`#0F1216`):** Deep charcoal substrate, serving as the foundational canvas across all views.
- **Elevated Container (`#181C22`):** Elevated container layer for scanner viewfinders, ticket payload cards, and operational modules.
- **Border / Structural Stroke (`#262B34`):** Crisp boundary definitions ensuring cards pop without reliance on heavy shadows.
- **Primary Accent (`#CF4647`):** Electric crimson; reserved for primary triggers, camera active indicators, and critical brand anchors.
- **Success (`#10B981`):** High-luminance emerald for valid tickets, grant entries, and synced states.
- **Error (`#EF4444`):** Punchy scarlet for invalid passes, duplicates, and hardware errors.
- **Warning / Expired (`#F59E0B`):** Amber for expired slots, wrong time windows, and manual intervention prompts.
- **Text Primary (`#F3F4F6`):** Pristine off-white for names, seat numbers, and validation statuses.
- **Text Muted (`#94A3B8`):** Slate grey for metadata, timestamps, and secondary labels.

## Typography

Typography prioritizes tabular legibility and rapid scanning speed. **Inter** serves all text hierarchies, leaning on structured font weights and tracking to differentiate status indicators from operational content.

- **Tabular Figures:** Numbers (gate counters, timestamps, seat indices, and ticket serial numbers) must utilize monospace tabular figures (`font-variant-numeric: tabular-nums`) to prevent optical jitter during live counting.
- **Hierarchy Distinction:** Status outcomes (e.g., "ENTRY GRANTED", "INVALID PASS") utilize uppercase `label-lg` or `headline-md` with slight letter tracking (`0.04em` to `0.06em`) for rapid outdoor identification.

## Layout & Spacing

Designed primarily for Android mobile devices (handheld scanners and rugged phones) with responsive expansion for tablet check-in desks.

### Layout Rules
- **Grid Architecture:** 4-column fluid layout on mobile, expanding to an 8-column layout on tablet/POS devices. Margins and gutters remain compact (`1rem`) to maximize screen estate for the scanner target and guest verification details.
- **Thumb-Zone Prioritization:** All primary actions (Manual Code Entry, Torch Toggle, Flash/Mute, Batch Actions) sit within the lower 40% vertical viewport for one-handed operation.
- **Scanner Viewport:** The top 45–55% of the mobile viewport is dedicated to the camera viewfinder and targeting reticle, framing results directly underneath.

## Elevation & Depth

Visual hierarchy uses a flat, structural tonal layering approach rather than heavy drop shadows, preventing muddy UI rendering in high-brightness outdoor conditions.

- **Level 0 (Canvas Base):** Solid `#0F1216` backplane.
- **Level 1 (Structural Cards & Containers):** `#181C22` background with a crisp, 1px solid border of `#262B34`. No shadow.
- **Level 2 (Active/Floating Modals & Sheets):** `#1F242C` surface with a 1px border of `#374151` and an ambient atmospheric shadow: `0 8px 32px rgba(0, 0, 0, 0.45)`.
- **Level 3 (Scan Overlays & Result Banners):** Direct semantic flood fills (e.g., `#10B981` at 12% opacity with a 2px `#10B981` border for valid scans; `#EF4444` at 12% opacity with a 2px `#EF4444` border for invalid scans).

## Shapes

The design system incorporates intentional corner radii that balance ergonomic handheld feel with modern technical precision.

- **Cards & Primary Panels:** Set to `1rem` (16px, `rounded-2xl`) for a smooth, tactile enclosure that cleanly separates individual scanning records and camera viewports.
- **Buttons, Inputs, and Badges:** Standardized at `0.5rem` (8px) for buttons and text inputs, while contextual status chips and tags use full pill contours (`9999px`) to distinguish actionable elements from status signals.

## Components

### Buttons
- **Primary:** Background `#CF4647`, text `#FFFFFF`, height `52px` (optimal 48px+ Android touch target), weight `600`, corner radius `8px`. Active press scales down slightly (`0.98`) with subtle opacity shift (`0.9`).
- **Secondary / Action Icon:** Background `#181C22`, border `1px solid #262B34`, icon/text `#F3F4F6`.
- **Feedback Haptics:** All buttons must invoke standard native Android confirmation vibration feedback.

### Status Banner & Result Cards
- **Valid Entry Card:** Background `#181C22`, top accent bar (4px) or full perimeter border in `#10B981`. Includes high-contrast check icon, ticket tier badge, guest name (`headline-sm`), seat designation, and "SCAN NEXT" instant trigger.
- **Rejected Entry Card:** Background `#181C22`, border `2px solid #EF4444`. Immediate large visual banner reading "ALREADY SCANNED" or "INVALID TICKET" with previous entry timestamp in `#94A3B8`.

### Scanner Viewfinder
- High-contrast camera viewport framed with rounded corner reticles in `#CF4647` during scanning, snapping into `#10B981` (Valid) or `#EF4444` (Rejected) instantly upon code acquisition.
- Torch/Flashlight toggle floating at the bottom right corner with persistent state indicator.

### Chips & Badges
- **Status Pills:** Background `#181C22`, border `1px solid`, pill-shaped (`rounded-full`), horizontal padding `10px`, vertical padding `4px`.
  - *Regular:* Border `#64748B`, text `#94A3B8`.
  - *VIP / Sunset Slot:* Border `#CF4647`, text `#F3F4F6`, crimson tinted background (`rgba(207, 70, 71, 0.15)`).
  - *Verified:* Border `#10B981`, text `#10B981`, emerald tinted background (`rgba(16, 185, 129, 0.12)`).

### Input Fields (Manual Entry / Override)
- Background `#0F1216`, container surface `#181C22`, border `1px solid #262B34`, text `#F3F4F6`, height `52px`.
- Focus state: border shifts to `1.5px solid #CF4647` with no glow blur to maintain clean definition.
- Monospace keyboard preset for alphanumeric ticket code lookup.

### Lists & Recent Scans Stream
- Dividerless cards using `#181C22` resting surfaces separated by `0.5rem` spacing.
- Each row reveals attendee name, timestamp, ticket type, and mini status dot (Emerald / Red / Amber).