/**
 * Lunar calendar utilities for date conversion and calendar grid building.
 * Uses @forvn/vn-lunar-calendar for Vietnamese lunar calendar calculations.
 *
 * @example Basic usage
 * ```typescript
 * import { dateToISO, isoToDate, buildCalendarGrid, MONTH_NAMES } from "@/utils"
 *
 * // Convert Date to ISO string
 * dateToISO(new Date(2024, 11, 25)) // "2024-12-25"
 *
 * // Convert ISO string back to Date
 * isoToDate("2024-12-25") // Date object for Dec 25, 2024
 *
 * // Build a calendar grid for December 2024
 * const grid = buildCalendarGrid(2024, 11) // 0-indexed month
 * // Returns 5 or 6 rows of 7 cells each
 * ```
 */
import { LunarCalendar } from "@forvn/vn-lunar-calendar"

// Use Intl.DateTimeFormat for locale-aware month/weekday names
const monthFormatter = new Intl.DateTimeFormat("en-US", { month: "long" })
const weekdayFormatter = new Intl.DateTimeFormat("en-US", { weekday: "long" })

/**
 * Full month names in English.
 * @example MONTH_NAMES[0] // "January"
 * @example MONTH_NAMES[11] // "December"
 */
export const MONTH_NAMES = Array.from({ length: 12 }, (_, i) =>
  monthFormatter.format(new Date(2024, i, 1)),
)

/**
 * Full weekday names starting from Monday (Monday-first calendar).
 * @example WEEKDAY_NAMES[0] // "Monday"
 * @example WEEKDAY_NAMES[6] // "Sunday"
 */
export const WEEKDAY_NAMES = Array.from({ length: 7 }, (_, i) =>
  weekdayFormatter.format(new Date(2024, 0, i + 1)),
)

/**
 * Calendar cell data for grid rendering.
 * Represents one day in the calendar grid.
 *
 * @example Active day cell
 * ```typescript
 * {
 *   date: new Date(2024, 11, 25),  // Dec 25, 2024
 *   iso: "2024-12-25",              // For selection comparison
 *   lunarDisplay: "25/11"           // Lunar day/month (25th day of 11th lunar month)
 * }
 * ```
 *
 * @example Empty cell (padding before/after month)
 * ```typescript
 * { date: null, iso: null, lunarDisplay: null }
 * ```
 */
export interface CalendarCell {
  date: Date | null
  iso: string | null
  lunarDisplay: string | null
}

/**
 * Convert Date to ISO string (YYYY-MM-DD) for local timezone.
 * Does NOT use toISOString() which would convert to UTC and potentially shift the date.
 *
 * @param d - Date object to convert
 * @returns ISO date string in format "YYYY-MM-DD"
 *
 * @example
 * dateToISO(new Date(2024, 0, 15))  // "2024-01-15"
 * dateToISO(new Date(2024, 11, 31)) // "2024-12-31"
 */
export function dateToISO(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`
}

/**
 * Convert ISO string (YYYY-MM-DD) to Date in local timezone.
 *
 * @param iso - ISO date string "YYYY-MM-DD"
 * @returns Date object for local timezone
 *
 * @example
 * isoToDate("2024-01-15") // Date for Jan 15, 2024 midnight local time
 * isoToDate("2024-12-31") // Date for Dec 31, 2024 midnight local time
 */
export function isoToDate(iso: string): Date {
  const [y, m, d] = iso.split("-").map(Number)
  return new Date(y, m - 1, d)
}

/**
 * Get number of days in a month.
 * Uses the "day 0 of next month" trick to get last day of current month.
 *
 * @param year - Full year (e.g., 2024)
 * @param month - 0-indexed month (0 = January, 11 = December)
 * @returns Number of days in the month (28-31)
 *
 * @example
 * daysInMonth(2024, 1)  // 29 (Feb 2024 is a leap year)
 * daysInMonth(2023, 1)  // 28 (Feb 2023 is not a leap year)
 * daysInMonth(2024, 11) // 31 (December always has 31 days)
 */
export function daysInMonth(year: number, month: number): number {
  return new Date(year, month + 1, 0).getDate()
}

/**
 * Format date as two-digit day string.
 *
 * @param d - Date object
 * @returns Two-digit day string with leading zero
 *
 * @example
 * formatShortDate(new Date(2024, 0, 5))  // "05"
 * formatShortDate(new Date(2024, 0, 25)) // "25"
 */
export function formatShortDate(d: Date): string {
  return String(d.getDate()).padStart(2, "0")
}

/**
 * Format lunar date as DD/MM string for display.
 * Used to show lunar day and month in each calendar cell.
 *
 * @param lunar - Object with day and month properties from lunar calendar
 * @returns Formatted string "DD/MM" or null if input is null
 *
 * @example
 * getLunarDayMonth({ day: 1, month: 12 })  // "01/12"
 * getLunarDayMonth({ day: 15, month: 1 })  // "15/01"
 * getLunarDayMonth(null)                   // null
 */
export function getLunarDayMonth(
  lunar: { day: number; month: number } | null,
): string | null {
  if (!lunar) return null
  const { day, month } = lunar
  return `${String(day).padStart(2, "0")}/${String(month).padStart(2, "0")}`
}

/**
 * Build a calendar grid for a given month.
 * Creates a 2D array of cells representing the calendar view.
 *
 * The grid is Monday-first (Monday = column 0, Sunday = column 6).
 * Empty cells are added before the 1st and after the last day to fill complete rows.
 *
 * @param year - Full year (e.g., 2024)
 * @param month - 0-indexed month (0 = January, 11 = December)
 * @returns 2D array of CalendarCell objects (5 or 6 rows of 7 cells each)
 *
 * @example December 2024 grid visualization (simplified):
 * ```
 * Mon  Tue  Wed  Thu  Fri  Sat  Sun
 * ---  ---  ---  ---  ---  ---  01   <- row 0 starts with blanks, 1st is Sunday
 * 02   03   04   05   06   07   08   <- row 1
 * 09   10   11   12   13   14   15   <- row 2
 * 16   17   18   19   20   21   22   <- row 3
 * 23   24   25   26   27   28   29   <- row 4
 * 30   31   ---  ---  ---  ---  ---  <- row 5 ends with blanks
 * ```
 *
 * @example Usage
 * ```typescript
 * const grid = buildCalendarGrid(2024, 11) // December 2024
 * grid.length // 5 or 6 (number of rows)
 * grid[0].length // always 7 (days per week)
 *
 * // Access first actual day cell
 * const firstDay = grid[0].find(cell => cell.date !== null)
 * firstDay?.iso // "2024-12-01"
 * firstDay?.lunarDisplay // "01/11" (1st day of 11th lunar month)
 * ```
 */
export function buildCalendarGrid(
  year: number,
  month: number,
): CalendarCell[][] {
  const totalDays = daysInMonth(year, month)
  const firstWeekDay = new Date(year, month, 1).getDay()
  // Convert to Monday-first index (0 = Monday, 6 = Sunday)
  // JS getDay() returns 0 = Sunday, so we shift: (day + 6) % 7
  const startIndex = (firstWeekDay + 6) % 7

  const cells: CalendarCell[] = []

  // Fill blank cells before month start
  // Example: If month starts on Wednesday (index 2), add 2 blank cells
  for (let i = 0; i < startIndex; i++) {
    cells.push({ date: null, iso: null, lunarDisplay: null })
  }

  // Fill cells for each day of the month
  for (let d = 1; d <= totalDays; d++) {
    const dt = new Date(year, month, d)
    const iso = `${year}-${String(month + 1).padStart(2, "0")}-${String(d).padStart(2, "0")}`
    // Get lunar calendar data for this solar date
    const lunar = LunarCalendar.fromSolar(d, month + 1, year)
    const lunarDisplay = getLunarDayMonth(lunar.lunarDate)
    cells.push({ date: dt, iso, lunarDisplay })
  }

  // Determine if month fits in 5 rows (35 cells) or needs 6 rows (42 cells)
  // Most months fit in 5 rows, but some need 6 (e.g., when 1st is Saturday and has 31 days)
  const usedCells = startIndex + totalDays
  const desiredCells = usedCells <= 35 ? 35 : 42

  // Fill remaining blank cells to complete the grid
  while (cells.length < desiredCells) {
    cells.push({ date: null, iso: null, lunarDisplay: null })
  }

  // Chunk flat array into rows of 7 (one row per week)
  const rowsCount = desiredCells / 7
  const rows: CalendarCell[][] = []
  for (let r = 0; r < rowsCount; r++) {
    rows.push(cells.slice(r * 7, r * 7 + 7))
  }
  return rows
}
