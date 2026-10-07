# Mobile Ticket Validator — PRODUCT.md

## What this is

A gate-operations app for ticketing staff at a visitor attraction. Staff stand at a
physical gate with a phone, scan (or hand-type) a ticket's QR code, and immediately need
one of two truths: **may this person enter?** — and, at the exit, **is this ticket still
active?** The app is the checkpoint's instrument, not a consumer product. It is used in
a hurry, often in poor light, often while someone waits in front of it.

Surface: Flutter app for Android phones (and iOS), portrait, one-handed use.
Visitor mode: **Operate** — the user came to get a job done.

Scope of this stage: the assigned work is **UI/UX only, with dummy data**. No network,
no authentication, no real scanner, no business logic. Every fact the UI displays is
synthetic and labelled as such where it could be mistaken for real data.

## Who uses it

- **Gate staff (primary).** Works a shift at one checkpoint. Needs: scan, a verdict they
  can read from arm's length in under a second, and a way to key in a code when the QR
  is torn or the camera refuses. Rarely explores the app.
- **Supervisor / shift lead (secondary).** Reads the day's tally per gate to decide
  whether to open another lane: how many entered, how many were turned away, and why.

Real scene: outdoors, entrance gate, mixed daylight to dusk, gloves or wet hands in bad
weather, phone held at chest height, no patience for a second screen.

## The two jobs

1. **Validate a ticket** (Scanner). Modes: `CHECK-IN` (first entry, writes the ticket) and
   `CEK` (read-only check at the exit). Outcome is one of five states:
   VALID · ALREADY_USED · EXPIRED · NOT_FOUND · CANCELLED. The verdict must be legible at
   a glance, and the failure states must say *what to do next*, not just what went wrong.
2. **Report the shift** (Dashboard, History). Numbers the supervisor trusts, newest-first
   log of what this gate did, and the option to correct the checkpoint when a staff member
   is moved to another lane mid-shift.

## Commitments

- The verdict is the product. Everything else is quieter than it.
- One checkpoint is active at a time, and the active checkpoint is always visible.
- The gate never blocks on a spinner, and never shows an unlabelled failure.
- Indonesian copy, operational register: short, imperative, no marketing voice.

## Constraints

- Own visual world pinned by the brief: primary #CF4647, secondary #F5D061, ground
  #F8F6F6, ink #2A363B, status colours (green / red / gold / gray).
- Material 3 governs structure, navigation, and interaction: navigation bar, top app bar,
  bottom sheets, standard controls. Brand enters through type, palette, density, and one
  signature move — never through invented controls or decorative costumes.
- Touch targets ≥48dp; no overflow at small phone widths; keyboard must not cover the
  input; both light and dark schemes ship.

## Out of scope at this stage

API integration (Dio stays untouched), authentication, token/session persistence,
real QR decoding (`mobile_scanner` stays unimplemented), offline queue, database.
