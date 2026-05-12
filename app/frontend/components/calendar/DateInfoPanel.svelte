<script lang="ts">
  import { LunarCalendar } from "@forvn/vn-lunar-calendar"
  import { ChevronLeft, ChevronRight, Pencil, Trash2 } from "@lucide/svelte"
  import { inertia, page } from "@inertiajs/svelte"

  import { useNetworkStatus } from "@/offline/network.svelte"
  import { useReminderStore } from "@/offline/reminder-store.svelte"
  import { flushReminderQueue } from "@/offline/sync"
  import { MONTH_NAMES, isoToDate, formatDisplayTime } from "@/utils"
  import { editReminderPath } from "@/routes"
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
  const network = useNetworkStatus()
  const reminderStore = useReminderStore()

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

  function operationId() {
    if (typeof crypto !== "undefined" && "randomUUID" in crypto) {
      return crypto.randomUUID()
    }
    return `${Date.now()}-${Math.random().toString(36).slice(2)}`
  }

  function selectedMonth() {
    if (!selectedISO) return undefined
    return `${selectedISO.slice(0, 7)}-01`
  }

  async function deleteReminder(id: number) {
    if (!confirm("Delete this reminder?")) return
    const auth = $page.props.auth as { user?: { id?: string | number } } | undefined
    const currentUserId = auth?.user?.id == null ? null : String(auth.user.id)
    if (!currentUserId) return

    if (id <= 0) {
      await reminderStore.removeOperationsForRecord(id)
      await reminderStore.removeLocalReminder(id)
      return
    }

    await reminderStore.removeLocalReminder(id)
    const operation = {
      client_operation_id: operationId(),
      user_id: currentUserId,
      operation: "delete" as const,
      server_id: id,
      base_updated_at: new Date().toISOString(),
      created_at: new Date().toISOString(),
    }
    await reminderStore.enqueueOperation(operation)

    if (!network.isOnline) return

    const result = await flushReminderQueue({
      userId: currentUserId,
      operations: [...reminderStore.operations],
      month: selectedMonth(),
    })
    await Promise.all(result.applied.map((appliedId) => reminderStore.removeOperation(appliedId)))
    if (result.reminders.length > 0) {
      await reminderStore.replaceFromServer(currentUserId, result.reminders)
    }
  }
</script>

<div class="date-info-container">
  <button class="btn left-btn" onclick={onPrevDay} aria-label="Previous day">
    <ChevronLeft />
  </button>
  <div class="date-info-wrapper">
    <div class="date-info solar-info">
      <span class="type">Solar</span>
      <span class="date">{selectedSolarDate ?? ""}</span>
      <span class="month-year">{selectedSolarMonthYear ?? ""}</span>
    </div>
    <div class="date-info lunar-info">
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
{#if selectedReminders.length > 0}
  <ul class="reminders-container">
    {#each selectedReminders as reminder}
      <li class="reminder">
        <span class="time">
          {formatDisplayTime(reminder.start)}{#if reminder.end}
            {" "}- {formatDisplayTime(reminder.end)}{/if}
        </span>
        <span class="title">
          {reminder.title}
        </span>
        {#if reminder.notes}
          <span class="notes">
            {reminder.notes}
          </span>
        {/if}
        <span class="actions">
          {#if reminder.id > 0}
            <a
              href={editReminderPath(reminder.id)}
              use:inertia
              class="action"
              aria-label="Edit reminder"
            >
              <Pencil size="18" />
            </a>
          {/if}
          <button
            type="button"
            class="action"
            aria-label="Delete reminder"
            onclick={() => void deleteReminder(reminder.id)}
          >
            <Trash2 size="18" />
          </button>
        </span>
      </li>
    {/each}
  </ul>
{:else}
  <p class="empty-reminders">No reminders for this day.</p>
{/if}

<style lang="postcss">
  .date-info-container {
    width: min(100%, 1232px);
    display: flex;
    justify-content: center;
    align-items: center;
    gap: clamp(0.75rem, 5vw, 8rem);
    margin: 1rem auto;
    padding-inline: 0.25rem;

    .date-info-wrapper {
      min-width: 0;
      flex: 1;
      display: flex;
      justify-content: center;
      gap: clamp(0.75rem, 4vw, 6rem);

      .date-info {
        min-width: min(18rem, 100%);
        flex: 1 1 0;
        display: flex;
        flex-direction: column;
        align-items: center;
        border-radius: 1rem;
        padding: 1rem;
        background: var(--color-card);

        .type {
          font-size: clamp(0.875rem, 2.4vw, 2rem);
          font-weight: 500;
        }

        .date {
          font-size: clamp(3rem, 8vw, 5rem);
          font-weight: 700;
          line-height: 1;
        }

        .month-year {
          font-size: clamp(1rem, 2.4vw, 2rem);
          font-weight: 500;
          text-align: center;
        }

        .canchi {
          font-size: clamp(0.75rem, 1.8vw, 1.2rem);
          margin-top: 1rem;
          text-align: center;
        }
      }
    }

    > button {
      min-width: 2.75rem;
      min-height: 2.75rem;
      border-radius: 999px;
    }
  }

  .reminders-container {
    width: min(100%, 1232px);
    margin: 0 auto;
    padding: 0;
    list-style: none;

    .reminder {
      display: grid;
      grid-template-columns: minmax(7rem, auto) 1fr minmax(0, 2fr) auto;
      gap: 0.5rem;
      align-items: center;
      padding: 0.75rem 0;
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
        white-space: normal;
      }

      .time {
        color: var(--color-muted-foreground);
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
          transition:
            background 0.12s ease,
            color 0.12s ease;

          &:hover {
            background: var(--color-sidebar-accent);
            color: var(--color-foreground);
          }
        }
      }
    }
  }

  .empty-reminders {
    width: min(100%, 1232px);
    margin: 0 auto;
    border: 1px dashed var(--color-border);
    border-radius: 0.75rem;
    padding: 1rem;
    color: var(--color-muted-foreground);
    text-align: center;
  }

  @media (max-width: 767px) {
    .date-info-container {
      gap: 0.5rem;
      align-items: stretch;
      margin-block: 0.5rem 1rem;

      .date-info-wrapper {
        gap: 0.5rem;

        .date-info {
          min-width: 0;
          padding: 0.875rem 0.5rem;

          .type {
            font-size: 0.8125rem;
          }

          .date {
            font-size: 2.75rem;
          }

          .month-year {
            font-size: 0.875rem;
          }

          .canchi {
            display: none;
          }
        }
      }

      > button {
        align-self: center;
        min-width: 2.5rem;
        min-height: 2.5rem;
        padding: 0.5rem;
      }
    }

    .reminders-container {
      display: flex;
      flex-direction: column;
      gap: 0.75rem;

      .reminder {
        grid-template-columns: 1fr auto;
        grid-template-areas:
          "time actions"
          "title actions"
          "notes notes";
        gap: 0.25rem 0.75rem;
        border: 1px solid var(--color-border);
        border-radius: 0.875rem;
        padding: 0.875rem;
        background: var(--color-card);
        font-size: 1rem;

        .time,
        .title,
        .notes,
        .actions {
          padding: 0;
        }

        .time {
          grid-area: time;
          font-size: 0.875rem;
        }

        .title {
          grid-area: title;
        }

        .notes {
          grid-area: notes;
          color: var(--color-muted-foreground);
        }

        .actions {
          grid-area: actions;
          align-self: center;

          .action {
            width: 2.5rem;
            height: 2.5rem;
          }
        }
      }
    }
  }
</style>
