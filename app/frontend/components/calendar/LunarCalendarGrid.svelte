<script lang="ts">
  import { ChevronLeft, ChevronRight } from "@lucide/svelte"

  import {
    MONTH_NAMES,
    WEEKDAY_NAMES,
    buildCalendarGrid,
    dateToISO,
    formatShortDate,
  } from "@/utils"

  interface Props {
    initialDate?: Date
    selectedDate: string | null
    onSelect: (iso: string | null) => void
    reminderDatesSet?: Set<string>
  }

  let { initialDate, selectedDate, onSelect, reminderDatesSet }: Props = $props()

  // Internal navigation state
  let displayYear = $state((initialDate ?? new Date()).getFullYear())
  let displayMonth = $state((initialDate ?? new Date()).getMonth())
  let grid = $state(buildCalendarGrid(displayYear, displayMonth))

  // Today for highlight
  const todayISO = dateToISO(initialDate as Date)

  function navigateMonth(offset: number) {
    const d = new Date(displayYear, displayMonth + offset, 1)
    displayYear = d.getFullYear()
    displayMonth = d.getMonth()
    grid = buildCalendarGrid(displayYear, displayMonth)
  }

  function prevMonth() {
    navigateMonth(-1)
  }

  function nextMonth() {
    navigateMonth(1)
  }

  function goToToday() {
    displayYear = initialDate.getFullYear()
    displayMonth = initialDate.getMonth()
    grid = buildCalendarGrid(displayYear, displayMonth)
    onSelect(dateToISO(initialDate))
  }

  function selectCell(iso: string | null) {
    if (!iso) return
    onSelect(iso === selectedDate ? null : iso)
  }
</script>

<h1 class="month-title">{MONTH_NAMES[displayMonth]} {displayYear}</h1>

<div class="calendar-table-wrapper">
  <div class="calendar-btns">
    <button class="btn left-btn" onclick={prevMonth} aria-label="Previous month">
      <ChevronLeft />
    </button>
    <button class="btn today-btn" onclick={goToToday} aria-pressed="false">
      Today
    </button>
    <button class="btn right-btn" onclick={nextMonth} aria-label="Next month">
      <ChevronRight />
    </button>
  </div>

  <table
    class="calendar-table"
    role="grid"
    aria-label={MONTH_NAMES[displayMonth] + " " + displayYear + " calendar"}
  >
    <colgroup>
      {#each WEEKDAY_NAMES as _, i (i)}
        <col />
      {/each}
    </colgroup>
    <thead>
      <tr>
        {#each WEEKDAY_NAMES as wd (wd)}
          <th scope="col">{wd}</th>
        {/each}
      </tr>
    </thead>
    <tbody>
      {#each grid as row, rowIdx (rowIdx)}
        <tr>
          {#each row as cell, cellIdx (cell.iso ?? `blank-${rowIdx}-${cellIdx}`)}
            {#if cell.date}
              <td
                class="day"
                class:today={cell.iso === todayISO}
                class:selected={cell.iso === selectedDate}
                role="gridcell"
                aria-label={String(cell.iso)}
                aria-current={cell.iso === todayISO ? "date" : undefined}
                aria-selected={cell.iso === selectedDate ? "true" : undefined}
                onkeydown={(e) => {
                  if (e.key === "Enter" || e.key === " ") selectCell(cell.iso)
                }}
                onclick={() => {
                  selectCell(cell.iso)
                }}
              >
                <div class="cell-inner">
                  {#if cell.iso && reminderDatesSet?.has(cell.iso)}
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
</div>

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
</style>
