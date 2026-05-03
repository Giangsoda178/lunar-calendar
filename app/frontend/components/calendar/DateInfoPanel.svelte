<script lang="ts">
  import { LunarCalendar } from "@forvn/vn-lunar-calendar"
  import { ChevronLeft, ChevronRight, Pencil, Trash2 } from "@lucide/svelte"
  import { inertia, router } from "@inertiajs/svelte"

  import { MONTH_NAMES, isoToDate, formatDisplayTime } from "@/utils"
  import { editReminderPath, reminderPath } from "@/routes"
  import type { Reminder, Occurrence } from "@/types/reminder"

  interface Props {
    selectedISO: string | null
    reminders: Reminder[]
    occurrences: Occurrence[]
    onPrevDay: () => void
    onNextDay: () => void
  }

  let { selectedISO, reminders, occurrences, onPrevDay, onNextDay }: Props =
    $props()

  // Index reminders by id so we can resolve an Occurrence to its source
  // record in O(1) while rendering.
  const remindersById = $derived.by(
    () => new Map(reminders.map((r) => [r.id, r])),
  )

  // Compute lunar calendar data once for selected date
  let selectedLunar = $derived.by(() => {
    if (!selectedISO) return null
    const d = isoToDate(selectedISO)
    return LunarCalendar.fromSolar(
      d.getDate(),
      d.getMonth() + 1,
      d.getFullYear(),
    )
  })

  // Derive display values from single solar computation
  let selectedSolarDate = $derived(selectedISO?.slice(8, 10) ?? null)

  let selectedSolarMonthYear = $derived.by(() => {
    if (!selectedISO) return null
    const monthIndex = Number(selectedISO.slice(5, 7)) - 1
    return `${MONTH_NAMES[monthIndex]} ${selectedISO.slice(0, 4)}`
  })

  let selectedLunarDate = $derived(selectedLunar?.lunarDate.day ?? null)

  let selectedLunarMonthYear = $derived.by(() => {
    if (!selectedLunar) return null
    const { month, year } = selectedLunar.lunarDate
    return `${MONTH_NAMES[month - 1]} ${year}`
  })

  let selectedLunarCanChi = $derived.by(() => {
    if (!selectedLunar) return null
    const { dayCanChi, monthCanChi, yearCanChi } = selectedLunar
    return `Ngày ${dayCanChi} - Tháng ${monthCanChi} - Năm ${yearCanChi}`
  })

  // Match occurrences (NOT raw reminders) against the selected day. This
  // way a weekly/monthly/yearly reminder shows on every firing date, not
  // just its original start.
  let selectedReminders = $derived.by(() => {
    if (!selectedISO) return []
    return occurrences
      .filter((o) => o.date === selectedISO)
      .map((o) => remindersById.get(o.reminder_id))
      .filter((r): r is Reminder => r !== undefined)
  })

  function deleteReminder(id: number) {
    if (!confirm("Delete this reminder?")) return
    router.delete(reminderPath(id), { preserveScroll: true })
  }
</script>

<div class="date-info-container">
  <button class="btn left-btn" onclick={onPrevDay} aria-label="Previous day">
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
  <button class="btn right-btn" onclick={onNextDay} aria-label="Next day">
    <ChevronRight />
  </button>
</div>
<ul class="reminders-container">
  {#each selectedReminders as reminder}
    <li class="reminder">
      <span class="time">
        {formatDisplayTime(reminder.start)} - {formatDisplayTime(reminder.end)}
      </span>
      <span class="title">
        {reminder.title}
      </span>
      <span class="notes">
        {reminder.notes}
      </span>
      <span class="actions">
        <a
          href={editReminderPath(reminder.id)}
          use:inertia
          class="action"
          aria-label="Edit reminder"
        >
          <Pencil size="18" />
        </a>
        <button
          type="button"
          class="action"
          aria-label="Delete reminder"
          onclick={() => deleteReminder(reminder.id)}
        >
          <Trash2 size="18" />
        </button>
      </span>
    </li>
  {/each}
</ul>

<style lang="postcss">
  .date-info-container {
    max-width: fit-content;
    display: flex;
    justify-content: center;
    align-items: center;
    gap: 8rem;
    margin: 1rem auto;

    .date-info-wrapper {
      display: flex;
      gap: 6rem;

      .date-info {
        min-width: 400px;
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

  .reminders-container {
    max-width: 1232px;
    margin: 0 auto;

    .reminder {
      display: grid;
      grid-template-columns: auto 1fr 2fr auto;
      align-items: center;
      padding: 0.5rem 0;
      border-bottom: 1px solid var(--color-border);
      font-size: 1.1rem;
      transition: background 0.12s ease;

      &:hover {
        background: var(--color-background);
      }

      .time,
      .title,
      .notes {
        padding: 0.25rem 1rem;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: wrap;
      }

      .title {
        font-weight: 600;
      }

      .notes {
        display: -webkit-box;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
      }

      .actions {
        display: flex;
        gap: 0.5rem;
        padding: 0 1rem;

        .action {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          width: 2rem;
          height: 2rem;
          border-radius: 0.375rem;
          color: var(--color-muted-foreground);
          background: transparent;
          border: none;
          cursor: pointer;
          transition: background 0.12s ease, color 0.12s ease;

          &:hover {
            background: var(--color-sidebar-accent);
            color: var(--color-foreground);
          }
        }
      }
    }
  }
</style>
