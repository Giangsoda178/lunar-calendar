<script lang="ts">
  import CalendarLayout from "@/layouts/CalendarLayout.svelte"
  import { ChevronLeft, ChevronRight } from "@lucide/svelte"

  // Default display month/year to the current date
  let displayYear = $state(new Date().getFullYear())
  let displayMonth = $state(new Date().getMonth())

  // Get today's date for highlight
  const today = new Date()
  const todayISO = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`

  // Selected date as ISO string (YYYY-MM-DD)
  let selectedISO = $state<string | null>(null)

  const monthNames = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ]
  const monthShortNames = monthNames.map((m) => m.slice(0, 3))
  const weekdayNames = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ]
  // Helper to get number of days in a month
  function daysInMonth(year: number, month: number) {
    return new Date(year, month + 1, 0).getDate()
  }

  // Build a grid for the displayed month
  function buildGrid(year: number, month: number) {
    const totalDays = daysInMonth(year, month)
    const firstWeekDay = new Date(year, month, 1).getDay()
    // convert to Monday-first index (0 = Monday)
    const startIndex = (firstWeekDay + 6) % 7

    const cells: Array<{ date: Date | null; iso: string | null }> = []

    // Fill blanks before month start
    for (let i = 0; i < startIndex; i++) cells.push({ date: null, iso: null })

    // Fill month dates
    for (let d = 1; d <= totalDays; d++) {
      const dt = new Date(year, month, d)
      const iso = `${year}-${String(month + 1).padStart(2, "0")}-${String(d).padStart(2, "0")}`
      cells.push({ date: dt, iso })
    }

    // Determine whether the month fits within 5 rows (35 cells) or needs 6 rows (42 cells)
    const usedCells = startIndex + totalDays
    const desiredCells = usedCells <= 35 ? 35 : 42

    // Fill remaining blanks up to desiredCells
    while (cells.length < desiredCells) cells.push({ date: null, iso: null })

    // Chunk into rows of 7 (rowsCount will be 5 or 6)
    const rowsCount = desiredCells / 7
    const rows: Array<Array<{ date: Date | null; iso: string | null }>> = []
    for (let r = 0; r < rowsCount; r++) rows.push(cells.slice(r * 7, r * 7 + 7))
    return rows
  }

  // Reactive grid for the current display month
  let grid = $state(buildGrid(displayYear, displayMonth))

  function prevMonth() {
    if (displayMonth === 0) {
      displayMonth = 11
      displayYear -= 1
    } else {
      displayMonth -= 1
    }
    grid = buildGrid(displayYear, displayMonth)
  }

  function nextMonth() {
    if (displayMonth === 11) {
      displayMonth = 0
      displayYear += 1
    } else {
      displayMonth += 1
    }
    grid = buildGrid(displayYear, displayMonth)
  }

  function goToToday() {
    const now = new Date()
    displayYear = now.getFullYear()
    displayMonth = now.getMonth()
    grid = buildGrid(displayYear, displayMonth)
    selectedISO = `${displayYear}-${String(displayMonth + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`
  }
