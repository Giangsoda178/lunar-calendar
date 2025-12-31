<script lang="ts">
  import { onMount } from "svelte"
  import { SvelteSet } from "svelte/reactivity"

  import CalendarLayout from "@/layouts/CalendarLayout.svelte"
  import LunarCalendarGrid from "@/components/calendar/LunarCalendarGrid.svelte"
  import DateInfoPanel from "@/components/calendar/DateInfoPanel.svelte"
  import { dateToISO, isoToDate } from "@/utils"

  type Reminder = {
    id: number
    user_id: string
    title: string
    start: string
    end?: string | null
    notes?: string | null
    alert_minutes?: number | null
    is_lunar: boolean
    repeat: boolean
    repeat_period?: "daily" | "weekly" | "monthly" | "yearly" | number | null
    created_at?: string
    updated_at?: string
  }

  interface Props {
    reminder_dates: string[]
    today: string
    reminders: Reminder[]
  }

  let { reminder_dates, today, reminders }: Props = $props()

  // Convert array to SvelteSet for O(1) lookup with reactivity
  const reminderDatesSet = $derived(new SvelteSet(reminder_dates))

  // State owned by page
  let selectedISO = $state<string | null>(null)

  onMount(() => {
    if (!selectedISO) selectedISO = today
  })

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
  <div class="flex min-w-0 flex-col gap-6">
    <main class="main-content">
      <LunarCalendarGrid
        initialDate={isoToDate(today)}
        selectedDate={selectedISO}
        onSelect={handleSelect}
        {reminderDatesSet}
      />
      <DateInfoPanel
        {selectedISO}
        {reminders}
        onPrevDay={prevDay}
        onNextDay={nextDay}
      />
    </main>
  </div>
</CalendarLayout>
