<script lang="ts">
  import { ChevronLeft, ChevronRight } from "@lucide/svelte"

  import {
    MONTH_NAMES,
    WEEKDAY_NAMES,
    buildCalendarGrid,
    dateToISO,
    formatShortDate,
    isoToDate,
  } from "@/utils"

  interface Props {
    initialDate?: Date
    selectedDate: string | null
    onSelect: (iso: string | null) => void
    reminderDatesSet?: Set<string>
  }

  let {
    initialDate = new Date(),
    selectedDate,
    onSelect,
    reminderDatesSet,
  }: Props = $props()

  // Internal navigation state
  const dateInfo = $derived.by(() => {
    if (!selectedDate) return null
    const d = isoToDate(selectedDate)
    return { y: d.getFullYear(), m: d.getMonth() }
  })

  let displayYear = $derived(dateInfo?.y ?? 0)
  let displayMonth = $derived(dateInfo?.m ?? 0)

  let grid = $derived.by(() => {
    if (!dateInfo) return []
    return buildCalendarGrid(dateInfo.y, dateInfo.m)
  })

  // Today for highlight
  const todayISO = $derived(dateToISO(initialDate))

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
    if (iso === selectedDate) return
    onSelect(iso)
  }

  const shortWeekdayNames = WEEKDAY_NAMES.map((weekday) => weekday.slice(0, 3))
</script>

<h1 class="month-title">{MONTH_NAMES[displayMonth]} {displayYear}</h1>

<div class="calendar-table-wrapper">
  <div class="calendar-btns">
    <button
      class="btn left-btn"
      onclick={prevMonth}
      aria-label="Previous month"
    >
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
        {#each WEEKDAY_NAMES as wd, i (wd)}
          <th scope="col" aria-label={wd}>
            <span class="weekday-full">{wd}</span>
            <span class="weekday-short" aria-hidden="true">
              {shortWeekdayNames[i]}
            </span>
          </th>
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
    margin: clamp(1.5rem, 6vw, 3rem) auto 1rem;
    font-size: clamp(1.5rem, 5vw, 2rem);
    font-weight: 700;
    text-align: center;
    text-transform: uppercase;
    line-height: 1.1;
  }

  .calendar-btns {
    display: flex;
    justify-content: flex-end;
    align-items: center;
    gap: 0.25rem;
    margin-inline: auto 0;

    .left-btn,
    .right-btn {
      border-radius: 20px;
      padding: 10px;
    }
  }

  .calendar-table-wrapper {
    width: min(100%, 1232px);
    margin: clamp(1rem, 4vw, 2rem) auto;
    border-radius: 16px;
    overflow-x: auto;
    -webkit-overflow-scrolling: touch;
  }

  .calendar-table {
    border-collapse: separate;
    table-layout: fixed;
    width: 100%;
    min-width: 42rem;
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
    min-height: 7rem;
    padding: 0.5rem 1.25rem;
    border-radius: 12px;
    box-sizing: border-box;
    cursor: pointer;
    border-bottom: 1px solid var(--color-border);

    &:hover {
      background-color: var(--color-sidebar-accent);
    }

    .solar-date {
      font-size: clamp(1.5rem, 3vw, 2rem);
      font-weight: 600;
      margin-bottom: 0.5rem;
    }

    .lunar-date {
      align-self: flex-end;
      font-size: clamp(0.875rem, 2vw, 1.2rem);

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
    border: 1px solid var(--color-primary);
  }

  .calendar-table .day.selected .cell-inner {
    background-color: var(--color-accent);
  }

  .weekday-short {
    display: none;
  }

  @media (max-width: 767px) {
    .month-title {
      margin-top: 1rem;
    }

    .calendar-btns {
      justify-content: center;
      margin-inline: 0;

      .left-btn,
      .right-btn,
      .today-btn {
        min-width: 2.25rem;
        min-height: 2.25rem;
      }

      .left-btn,
      .right-btn {
        padding: 0.375rem;
      }

      .today-btn {
        padding-inline: 0.625rem;
      }
    }

    .calendar-table-wrapper {
      margin-block: 0.75rem;
      padding-bottom: 0.25rem;
      border-radius: 0;
    }

    .calendar-table {
      min-width: 100%;
      margin-block: 0.75rem;

      th,
      td {
        padding: 0.125rem;
      }

      th {
        font-size: 1rem;
        font-weight: 600;
        letter-spacing: 0.01em;
      }

      .weekday-full {
        display: none;
      }

      .weekday-short {
        display: inline;
      }
    }

    .cell-inner {
      min-height: 4.25rem;
      gap: 0.125rem;
      padding: 0.375rem;
      align-items: center;
      border-radius: 0.625rem;

      .solar-date {
        order: 1;
        margin-bottom: 0;
        font-size: 1.125rem;
        line-height: 1;
      }

      .reminder-dot {
        position: static;
        order: 3;
        width: 0.4375rem;
        height: 0.4375rem;
      }

      .lunar-date {
        order: 2;
        align-self: center;
        min-height: 1rem;
        font-size: 0.6875rem;
        line-height: 1.1;
      }
    }
  }
</style>
