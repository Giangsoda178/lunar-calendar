<script lang="ts">
  import { SvelteSet } from "svelte/reactivity"

  import CalendarLayout from "@/layouts/CalendarLayout.svelte"
  import LunarCalendarGrid from "@/components/calendar/LunarCalendarGrid.svelte"
  import DateInfoPanel from "@/components/calendar/DateInfoPanel.svelte"
  import Button from "@/components/ui/Button.svelte"
  import { dateToISO, isoToDate } from "@/utils"
  import { newReminderPath } from "@/routes"
  import type { Reminder, Occurrence } from "@/types/reminder"

  interface Props {
    today: string
    reminders: Reminder[]
    occurrences: Occurrence[]
  }

  let { today, reminders, occurrences }: Props = $props()

  // Build the set of ISO dates that have at least one reminder occurrence.
  // Derived straight from the server-computed `occurrences` array so that
  // repeating reminders show a dot on every firing date, not just `start`.
  const reminderDatesSet = $derived.by(() => {
    return new SvelteSet(occurrences.map((o) => o.date))
  })

  // State owned by page
  let selectedISO = $state<string | null>(today)

  let isSaving = false

  function handleSelect(iso: string | null) {
    selectedISO = iso
  }

  function offsetSelectedBy(days: number) {
    const base = selectedISO ? isoToDate(selectedISO) : isoToDate(today)
    const newDate = new Date(
      base.getFullYear(),
      base.getMonth(),
      base.getDate() + days,
    )
    selectedISO = dateToISO(newDate)
  }

  function prevDay() {
    offsetSelectedBy(-1)
  }

  function nextDay() {
    offsetSelectedBy(1)
  }
</script>

<svelte:head>
  <title>Lunar Calendar</title>
</svelte:head>

<CalendarLayout>
  <div class="flex min-w-0 flex-col gap-4 md:gap-6">
    <main class="main-content relative">
      <DateInfoPanel
        {selectedISO}
        {reminders}
        {occurrences}
        onPrevDay={prevDay}
        onNextDay={nextDay}
      />
      <LunarCalendarGrid
        initialDate={isoToDate(today)}
        selectedDate={selectedISO}
        onSelect={handleSelect}
        {reminderDatesSet}
      />
      <Button
        class="fixed right-4 bottom-[calc(var(--safe-area-bottom)+1rem)] z-20 text-2xl shadow-lg md:absolute md:right-4 md:bottom-4"
        loading={isSaving}
        disabled={isSaving}
        variant="primary"
        size="lg-icon"
        href={newReminderPath()}
        aria-label="Add Reminder"
      >
        +
      </Button>
    </main>
  </div>
</CalendarLayout>
