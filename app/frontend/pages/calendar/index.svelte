<script lang="ts">
  import CalendarLayout from "@/layouts/CalendarLayout.svelte"
  import { ChevronLeft, ChevronRight } from "@lucide/svelte"
  import { LunarCalendar } from "@forvn/vn-lunar-calendar"
  import { onMount } from "svelte"

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

  // Default display month/year to the current date
  let displayYear = $state(new Date().getFullYear())
  let displayMonth = $state(new Date().getMonth())

  function dateToISO(d: Date) {
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`
  }

  function isoToDate(iso: string) {
    const [y, m, d] = iso.split("-").map(Number)
    return new Date(y, m - 1, d)
  }

  // Get today's date for highlight
  const today = new Date()
  const todayISO = dateToISO(today)

  // Selected date as ISO string (YYYY-MM-DD)
  let selectedISO = $state<string | null>(null)

  let selectedSolarDate = $derived(
    selectedISO ? selectedISO.slice(8, 10) : null,
  )

  let selectedSolarMonthYear = $derived.by(() => {
    if (!selectedISO) return null

    const monthIndex = Number(selectedISO.slice(5, 7)) - 1
    const year = selectedISO.slice(0, 4)

    return `${monthNames[monthIndex]} ${year}`
  })

  let selectedLunarDate = $derived.by(() => {
    if (!selectedISO) return null

    const d = isoToDate(selectedISO)
    const lunar = LunarCalendar.fromSolar(
      d.getDate(),
      d.getMonth() + 1,
      d.getFullYear(),
    )

    return lunar.lunarDate.day
  })

  let selectedLunarMonthYear = $derived.by(() => {
    if (!selectedISO) return null

    const d = isoToDate(selectedISO)
    const lunar = LunarCalendar.fromSolar(
      d.getDate(),
      d.getMonth() + 1,
      d.getFullYear(),
    )

    const monthIndex = lunar.lunarDate.month - 1
    const year = lunar.lunarDate.year

    return `${monthNames[monthIndex]} ${year}`
  })

  let selectedLunarCanChi = $derived.by(() => {
    if (!selectedISO) return null

    const d = isoToDate(selectedISO)
    const lunar = LunarCalendar.fromSolar(
      d.getDate(),
      d.getMonth() + 1,
      d.getFullYear(),
    )

    const dayCanChi = lunar.dayCanChi
    const monthCanChi = lunar.monthCanChi
    const yearCanChi = lunar.yearCanChi

    return `Ngày ${dayCanChi} - Tháng ${monthCanChi} - Năm ${yearCanChi}`
  })

  function formatShortDate(d: Date) {
    return `${String(d.getDate()).padStart(2, "0")}`
  }

  // Helper to get number of days in a month
  function daysInMonth(year: number, month: number) {
    return new Date(year, month + 1, 0).getDate()
  }

  function getLunarDayMonth(lunar: any): string | null {
    if (!lunar) return null
    const day = lunar.day
    const month = lunar.month

    if (typeof day === "number" && typeof month === "number") {
      return `${String(day).padStart(2, "0")}/${String(month).padStart(2, "0")}`
    }
  }

  // Build a grid for the displayed month
  function buildGrid(year: number, month: number) {
    const totalDays = daysInMonth(year, month)
    const firstWeekDay = new Date(year, month, 1).getDay()
    // convert to Monday-first index (0 = Monday)
    const startIndex = (firstWeekDay + 6) % 7

    const cells: Array<{
      date: Date | null
      iso: string | null
      lunarDisplay: string | null
    }> = []

    // Fill blanks before month start
    for (let i = 0; i < startIndex; i++)
      cells.push({ date: null, iso: null, lunarDisplay: null })

    // Fill month dates
    for (let d = 1; d <= totalDays; d++) {
      const dt = new Date(year, month, d)
      const iso = `${year}-${String(month + 1).padStart(2, "0")}-${String(d).padStart(2, "0")}`
      const lunar = LunarCalendar.fromSolar(d, month + 1, year)
      const lunarDisplay = getLunarDayMonth(lunar.lunarDate)
      cells.push({ date: dt, iso, lunarDisplay })
    }

    // Determine whether the month fits within 5 rows (35 cells) or needs 6 rows (42 cells)
    const usedCells = startIndex + totalDays
    const desiredCells = usedCells <= 35 ? 35 : 42

    // Fill remaining blanks up to desiredCells
    while (cells.length < desiredCells)
      cells.push({ date: null, iso: null, lunarDisplay: null })

    // Chunk into rows of 7 (rowsCount will be 5 or 6)
    const rowsCount = desiredCells / 7
    const rows: Array<
      Array<{
        date: Date | null
        iso: string | null
        lunarDisplay: string | null
      }>
    > = []
    for (let r = 0; r < rowsCount; r++) rows.push(cells.slice(r * 7, r * 7 + 7))
    return rows
  }

  // Reactive grid for the current display month
  let grid = $state(buildGrid(displayYear, displayMonth))

  onMount(() => {
    if (selectedISO) return
    selectedISO = todayISO
  })

  function setSelectedDate(iso: string) {
    selectedISO = iso
    const d = isoToDate(iso)
    const y = d.getFullYear()
    const m = d.getMonth()

    if (displayYear !== y || displayMonth !== m) {
      displayYear = y
      displayMonth = m
      grid = buildGrid(displayYear, displayMonth)
    }
  }

  function offsetSelectedBy(days: number) {
    const base = selectedISO ? isoToDate(selectedISO) : isoToDate(todayISO)
    const d = new Date(base.getTime())
    d.setDate(d.getDate() + days)
    setSelectedDate(dateToISO(d))
  }

  function prevDay() {
    offsetSelectedBy(-1)
  }

  function nextDay() {
    offsetSelectedBy(1)
  }

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

  function selectCell(iso: string | null) {
    if (!iso) return
    selectedISO = iso === selectedISO ? null : iso
  }
</script>

<svelte:head>
  <title>Lunar Calendar</title>
</svelte:head>

<CalendarLayout>
  <div class="flex min-w-0 flex-col gap-6">
    <main class="main-content">
      <h1 class="month-title">{monthNames[displayMonth]} {displayYear}</h1>

      <div class="calendar-table-wrapper">
        <div class="calendar-btns">
          <button
            class="btn left-btn"
            onclick={prevMonth}
            aria-label="Previous month"
          >
            <ChevronLeft />
          </button>
          <button class="btn today-btn" onclick={goToToday} aria-pressed="false"
            >Today</button
          >
          <button
            class="btn right-btn"
            onclick={nextMonth}
            aria-label="Next month"
          >
            <ChevronRight />
          </button>
        </div>

        <table
          class="calendar-table"
          role="grid"
          aria-label={monthNames[displayMonth] +
            " " +
            displayYear +
            " calendar"}
        >
          <colgroup>
            {#each weekdayNames as wd, i}
              <col />
            {/each}
          </colgroup>
          <thead>
            <tr>
              {#each weekdayNames as wd}
                <th scope="col">{wd}</th>
              {/each}
            </tr>
          </thead>
          <tbody>
            {#each grid as row}
              <tr>
                {#each row as cell}
                  {#if cell.date}
                    <td
                      class="day"
                      class:today={cell.iso === todayISO}
                      class:selected={cell.iso === selectedISO}
                      role="gridcell"
                      aria-label={String(cell.iso)}
                      aria-current={cell.iso === todayISO ? "date" : undefined}
                      aria-selected={cell.iso === selectedISO
                        ? "true"
                        : undefined}
                      onkeydown={(e) => {
                        if (e.key === "Enter" || e.key === " ")
                          selectCell(cell.iso)
                      }}
                      onclick={() => {
                        selectCell(cell.iso)
                      }}
                    >
                      <div class="cell-inner">
                        {#if hasReminderOn(cell.iso)}
                          <span class="reminder-dot" aria-hidden="true"></span>
                        {/if}
                        <div class="solar-date">
                          {formatShortDate(cell.date)}
                        </div>
                        <div
                          class="lunar-date"
                          class:first-day={cell.lunarDisplay?.startsWith("01/")}
                          class:mid-day={cell.lunarDisplay?.startsWith("15/")}
                        >
                          {cell.lunarDisplay ?? ""}
                        </div>
                        <div class="slots"></div>
                      </div>
                    </td>
                  {:else}
                    <td class="blank" role="gridcell" aria-hidden="true"></td>
                  {/if}
                {/each}
              </tr>
            {/each}
          </tbody>
        </table>
        <div class="date-info-container">
          <button
            class="btn left-btn"
            onclick={prevDay}
            aria-label="Previous day"
          >
            <ChevronLeft />
          </button>
          <div class="date-info-wrapper">
            <div class="date-info">
              <span class="type">Solar</span>
              <span class="date">{selectedSolarDate ?? ""}</span>
              <span class="month-year">{selectedSolarMonthYear ?? ""}</span>
            </div>
            <div class="date-info">
              <span class="type">Lunar</span>
              <span class="date">{selectedLunarDate ?? ""}</span>
              <span class="month-year">{selectedLunarMonthYear ?? ""}</span>
              <span class="canchi">{selectedLunarCanChi ?? ""}</span>
            </div>
          </div>
          <button class="btn right-btn" onclick={nextDay} aria-label="Next day">
            <ChevronRight />
          </button>
        </div>
      </div>
    </main>
  </div>
</CalendarLayout>

<style lang="postcss">
  .month-title {
    margin: 0 auto;
    font-size: 2rem;
    font-weight: 700;
    text-align: center;
    text-transform: uppercase;
  }

  .calendar-btns {
    display: flex;
    justify-content: flex-end;
    align-items: center;
    gap: 0.25rem;
    margin-left: 2rem;

    .left-btn,
    .right-btn {
      border-radius: 20px;
      padding: 10px;
    }
  }

  .calendar-table-wrapper {
    width: fit-content;
    margin: 2rem auto;
    border-radius: 16px;
    overflow-x: auto;
  }

  .calendar-table {
    border-collapse: separate;
    table-layout: fixed;
    margin: 1rem auto;

    th,
    td {
      padding: 0.5rem 0.75rem;
      text-align: center;
      vertical-align: middle;
    }

    tr {
      border-bottom: 1px solid red;
    }
  }

  .cell-inner {
    position: relative;
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    justify-content: flex-start;
    gap: 0.25rem;
    padding: 0.5rem 1.5rem;
    border-radius: 12px;
    box-sizing: border-box;
    cursor: pointer;
    border-bottom: 1px solid var(--color-border);

    &:hover {
      background-color: var(--color-sidebar-accent);
    }

    .solar-date {
      font-size: 2rem;
      font-weight: 600;
      margin-bottom: 0.5rem;
    }

    .lunar-date {
      font-size: 1.2rem;
      margin-left: 4rem;

      &.first-day,
      &.mid-day {
        font-weight: 700;
        color: var(--color-destructive);
      }
    }

    .reminder-dot {
      position: absolute;
      top: 12px;
      right: 12px;
      width: 10px;
      height: 10px;
      border-radius: 10px;
      background-color: var(--color-destructive);
      box-shadow: 0 0 0 2px rgba(0, 0, 0, 0.04);
      pointer-events: none;
    }
  }

  .calendar-table .day.today .cell-inner {
    background-color: var(--color-accent);
  }

  .date-info-container {
    display: flex;
    justify-content: center;
    align-items: center;
    gap: 8rem;
    margin: 2rem auto;

    .date-info-wrapper {
      display: flex;
      gap: 6rem;

      .date-info {
        display: flex;
        flex-direction: column;
        align-items: center;

        .type {
          font-size: 2rem;
          font-weight: 500;
        }

        .date {
          font-size: 5rem;
          font-weight: 700;
        }

        .month-year {
          font-size: 2rem;
          font-weight: 500;
        }

        .canchi {
          font-size: 1.2rem;
          margin-top: 1rem;
        }
      }
    }
  }
</style>
