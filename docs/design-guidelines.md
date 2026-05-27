# Design Guidelines

## Responsive Calendar Experience

- Design calendar pages mobile-first, then enhance spacing and scale for tablet and desktop.
- Keep primary calendar actions touch-friendly with at least 44px hit targets.
- Prefer fluid widths (`w-full`, `min(100%, ...)`, `clamp(...)`) over fixed desktop widths.
- Use safe-area spacing for floating actions so controls avoid notches and home indicators.
- Present dense desktop grids as compact, readable mobile layouts instead of forcing horizontal overflow.

## Reminder Forms

- Form controls should fill the available mobile width and only constrain to smaller fixed widths from the `sm` breakpoint upward.
- Primary form actions should be full-width on phones and natural-width on larger screens.
- Keep reminder metadata scannable on mobile by stacking time, title, notes, and actions into card-like rows.
