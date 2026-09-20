---
name: Logiq Freight Pulse
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#45464d'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#76777d'
  outline-variant: '#c6c6cd'
  surface-tint: '#565e74'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#131b2e'
  on-primary-container: '#7c839b'
  inverse-primary: '#bec6e0'
  secondary: '#0051d5'
  on-secondary: '#ffffff'
  secondary-container: '#316bf3'
  on-secondary-container: '#fefcff'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#2a1700'
  on-tertiary-container: '#b87500'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dae2fd'
  primary-fixed-dim: '#bec6e0'
  on-primary-fixed: '#131b2e'
  on-primary-fixed-variant: '#3f465c'
  secondary-fixed: '#dbe1ff'
  secondary-fixed-dim: '#b4c5ff'
  on-secondary-fixed: '#00174b'
  on-secondary-fixed-variant: '#003ea8'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb95f'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
  surface-canvas: '#F8FAFC'
  surface-card: '#FFFFFF'
  surface-navy: '#1E293B'
  border-subtle: '#E2E8F0'
  border-strong: '#CBD5E1'
  emerald-success: '#10B981'
  rose-alert: '#EF4444'
  ice-soft: '#BAE3F8'
  amber-soft: '#FEF3C7'
  blue-soft: '#DBEAFE'
typography:
  display-lg:
    fontFamily: Outfit
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Outfit
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 30px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Outfit
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Outfit
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  numeric-timer:
    fontFamily: Outfit
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: 0.02em
  numeric-bid:
    fontFamily: Outfit
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.01em
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
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.05em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
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

This design system establishes a high-performance, mission-critical operational workspace for enterprise logistics, freight procurement, and dynamic reverse auctions. It serves freight procurement officers, supply chain directors, fleet dispatchers, and independent commercial carriers operating in high-pressure, time-sensitive contexts.

The brand archetype sits at the intersection of **Industrial Precision** and **Modern FinTech / Corporate Modernism**. The visual atmosphere must evoke immediate operational trust, uncompromising clarity, and real-time urgency without inducing anxiety. High-stakes financial bids and strict transit deadbands demand split-second legibility under extreme field conditions—from glaring cab daylight to dimly lit logistics docks and executive monitoring rooms.

To eliminate cognitive friction, the system rejects decorative skeuomorphism and excessive glassmorphism. Instead, it adopts structured information architecture, utilitarian data density, clean tonal boundaries, and high-visibility status telemetry.

## Colors

The color architecture is built around functional hierarchy and distinct semantic roles:

- **Primary Slate Navy (`#0F172A` / `#1E293B`)**: Represents authoritative grounding. Applied across primary actions, dominant text layers, navigation structures, and high-tier enterprise status banners.
- **Electric Blue (`#2563EB`)**: Drives interactive focus, primary system transitions, data selection states, and Stage 2 Blind Auction environments.
- **Safety / Freight Amber (`#F59E0B`)**: Signals auction urgency, live countdown telemetry (< 5 minutes), warnings, and pending counter-offers. Paired with `#FEF3C7` for soft badge fills.
- **Emerald Success (`#10B981`)**: Dedicated to positive procurement states, winning L1 rank markers, margin improvements, and completed tenders.
- **Cool Neutral Canvas (`#F8FAFC`, `#FFFFFF`, `#E2E8F0`)**: Provides an anti-glare, pristine backdrop engineered to maximize contrast across high-density numeric tables and dense transport lane manifests.

### Auction Stage Theming
- **Stage 1 (Open Auction / Ranked L1–L5)**: Driven by Slate Navy and Emerald cues. Transparent ranking tags emphasize competitive positioning.
- **Stage 2 (Blind Auction / Best & Final)**: Driven by Electric Blue accents and neutral mystery scrims. Hides competitive ranks and shifts attention directly to target profitability thresholds and single-action ceiling submits.

## Typography

The type system pairs **Outfit** for structural clarity and immediate numeric recognition with **Inter** for dense freight metrics, lane specs, and tabular compliance notes.

- **Outfit** provides geometric precision and open counters, giving bid values, dynamic timers, and high-tier lane identifiers crisp visibility at a glance.
- **Inter** ensures exceptional micro-legibility at 10px to 14px sizes across equipment types, fuel surcharge lines, weight allowances, and dispatch metadata.
- **Tabular Figures**: All monetary bid rates, countdown clocks, and trailer load capacities must utilize tabular/monospaced numeric figures (`font-variant-numeric: tabular-nums`) to prevent layout shift during high-frequency reverse auction updates.

## Layout & Spacing

The layout model implements a structured, fluid single-column architecture for mobile logistics operations with a 12-column dynamic grid on expanded tablet views. 

- **Outer Margins**: Fixed at `1rem` (16px) on mobile viewports to preserve maximum data real estate while shielding touch targets from bezel edges.
- **Rhythm & Padding**: An 8-point base scale governs all vertical and horizontal spacing. `space-xs` (4px) separates tightly coupled metric pairs (e.g., currency symbols and raw bid numbers). `space-md` (16px) defines interior card padding and primary stack layouts.
- **Sticky Critical Rail**: Live auction clocks and quick-increment bid consoles attach permanently to the bottom screen safe area, maintaining thumb-zone reachability without obscuring lane specs.

## Elevation & Depth

Visual hierarchy uses crisp surface-container contrast and precise structural outlines rather than heavy atmospheric shadows:

- **Level 0 (Floor/Canvas)**: Slate canvas (`#F8FAFC`).
- **Level 1 (Card/Surface)**: Pristine white (`#FFFFFF`) with a 1px boundary stroke (`#E2E8F0`). No shadow in resting state.
- **Level 2 (Active/Selected Card)**: White surface anchored by a subtle ambient shadow (`0 4px 12px -2px rgba(15, 23, 42, 0.08)`) with a high-contrast slate-navy or electric-blue border.
- **Level 3 (Sticky Bidding Tray / Dynamic Modal)**: `#FFFFFF` or `#1E293B` elevated via a directional contact shadow (`0 -4px 16px -1px rgba(15, 23, 42, 0.12)`).

Stage transitions apply subtle contextual tinting: Stage 1 cards use clean slate borders, while Stage 2 Blind Auction containers adopt a calibrated `#2563EB` top accent rule (2px) to instantly communicate the shift to sealed bids.

## Shapes

The shape system adopts **Level 1 (Soft)** geometry, calibrated for an industrial, technical product.

- Standard buttons, badges, input triggers, and cards feature a **0.25rem (4px)** radius.
- Large floating containers and bottom bidding drawers scale up to **0.5rem (8px)** (`rounded-lg`).
- Strict suppression of pill-shaped or bubbly radii maintains an uncompromising tool aesthetic, aligning with telematics consoles and fleet hardware screens.

## Components

### Buttons & Quick-Bid Steppers
- **Primary CTA**: Solid `#0F172A` background, `#FFFFFF` bold text, height `48px`, `rounded-sm` (4px). Focus ring: 2px `#2563EB` offset 2px.
- **Quick Decrement/Increment Bidding Buttons**: 44x48px chunky tap targets with an `#E2E8F0` border and `#0F172A` bold numerals (`-$25`, `-$50`, `-$100`). Designed for one-touch driver-friendly input.
- **Urgent Action (Accept Target/Confirm)**: Solid `#10B981` with white text for positive tender acceptance.

### Live Auction Countdowns & Status Badges
- **Normal Timer**: `#F1F5F9` background with `#0F172A` text and `#CBD5E1` border.
- **Critical Timer (< 5m)**: High-visibility flash using `#FEF3C7` background, `#D97706` text, and bold pulse amber indicator.
- **L1–L5 Rank Pills**:
  - *L1 (Current Leader / Winning)*: `#ECFDF5` background, `#047857` border, `#065F46` bold text with trophy/checkmark token.
  - *L2–L5 (Trailing)*: `#F8FAFC` background, `#64748B` border and text.
  - *Out of Money / At Risk*: `#FEF2F2` background, `#B91C1C` text.

### Freight Manifest & Auction Cards
- Surface: `#FFFFFF`, 1px solid `#E2E8F0`, interior padding `1rem`.
- Split-header layout: Origin & Destination IATA/ZIP codes in `headline-sm`, linked by a directional freight vector arrow.
- Middle metric block: 3-column micro-grid detailing Equipment (e.g., 53' Dry Van), Weight (e.g., 42,500 lbs), and Loading Deadlines.
- Stage-Dependent Footer: Displays real-time rank indicator and lowest active bid in Stage 1; switches to "Blind Ceiling Target" in Stage 2.

### Numeric Bid Input Console
- Full-width fixed bottom unit with high-contrast input field: 56px height, 24px `Outfit` bold typography, prominent fixed currency symbol (`$`), and clear validation styling.