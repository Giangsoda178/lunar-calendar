<script lang="ts">
  import { page, router } from "@inertiajs/svelte"
  import { SvelteSet } from "svelte/reactivity"

  import CalendarLayout from "@/layouts/CalendarLayout.svelte"
  import LunarCalendarGrid from "@/components/calendar/LunarCalendarGrid.svelte"
  import DateInfoPanel from "@/components/calendar/DateInfoPanel.svelte"
  import Button from "@/components/ui/Button.svelte"
  import { expandOfflineOccurrences } from "@/offline/occurrences"
  import { useNetworkStatus } from "@/offline/network.svelte"
  import { useReminderStore } from "@/offline/reminder-store.svelte"
  import { flushReminderQueue } from "@/offline/sync"
  import { dateToISO, isoToDate } from "@/utils"
  import { calendarIndexPath, newReminderPath } from "@/routes"
  import type { Reminder, Occurrence } from "@/types/reminder"

  interface Props {
    today: string
    focused_date: string | null
    reminders: Reminder[]
    occurrences: Occurrence[]
  }

  let { today, focused_date, reminders, occurrences }: Props = $props()
  const network = useNetworkStatus()
  const reminderStore = useReminderStore()

  const currentUserId = $derived.by(() => {
    const auth = $page.props.auth as { user?: { id?: string | number } } | undefined
    const userId = auth?.user?.id
    return userId == null ? null : String(userId)
  })

  let selectedISO = $state<string | null>(null)
  let lastFocusedDate = $state<string | null>(null)
  let seededUserId = $state<string | null>(null)
  let lastSyncedSnapshot = $state<string>("")
  let syncState = $state<"idle" | "syncing" | "failed">("idle")
  const offlineRange = $derived.by(() => {
    const baseDate = selectedISO ? isoToDate(selectedISO) : isoToDate(today)
    return {
      rangeStart: new Date(baseDate.getFullYear(), baseDate.getMonth() - 1, 1),
      rangeEnd: new Date(baseDate.getFullYear(), baseDate.getMonth() + 2, 0),
    }
  })

  let renderedReminders = $derived.by(() => {
    if (
      network.isOnline ||
      !currentUserId ||
      !reminderStore.initialized ||
      reminderStore.userId !== currentUserId
    ) {
      return reminders
    }

    return reminderStore.reminders.filter((reminder) => !reminder.deleted_at) as Reminder[]
  })

  let renderedOccurrences = $derived.by(() => {
    if (
      network.isOnline ||
      !currentUserId ||
      !reminderStore.initialized ||
      reminderStore.userId !== currentUserId
    ) {
      return occurrences
    }

    return expandOfflineOccurrences({
      reminders: reminderStore.reminders,
      rangeStart: offlineRange.rangeStart,
      rangeEnd: offlineRange.rangeEnd,
    })
  })

  const reminderDatesSet = $derived.by(() => {
    return new SvelteSet(renderedOccurrences.map((occurrence) => occurrence.date))
  })

  let isSaving = false

  function handleSelect(iso: string | null) {
    selectedISO = iso
  }

  function handleMonthChange(monthISO: string) {
    if (!network.isOnline) return
    const selectedDay = Number((selectedISO ?? today).slice(8, 10))
    router.get(
      calendarIndexPath(),
      {month: monthISO, day: selectedDay},
      {replace: true, preserveState: true, preserveScroll: true},
    )
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

  const reminderSnapshot = $derived.by(() => {
    return reminders
      .map((reminder) => `${reminder.id}:${reminder.updated_at ?? reminder.start}`)
      .sort()
      .join("|")
  })

  $effect(() => {
    if (selectedISO === null) {
      selectedISO = focused_date ?? today
    }
  })

  $effect(() => {
    if (!focused_date) return
    if (lastFocusedDate === focused_date) return
    lastFocusedDate = focused_date
    selectedISO = focused_date
  })

  $effect(() => {
    if (!focused_date) {
      lastFocusedDate = null
    }
  })

  $effect(() => {
    if (!currentUserId) return
    if (seededUserId === currentUserId) return

    seededUserId = currentUserId
    void reminderStore.initialize(currentUserId, reminders)
  })

  $effect(() => {
    if (!currentUserId || !network.isOnline) return
    const nextSnapshot = `${currentUserId}:${reminderSnapshot}`
    if (lastSyncedSnapshot === nextSnapshot) return

    lastSyncedSnapshot = nextSnapshot
    void reminderStore.replaceFromServer(currentUserId, reminders)
  })

  $effect(() => {
    if (
      !network.isOnline ||
      !currentUserId ||
      !reminderStore.initialized ||
      !reminderStore.hasPendingOperations
    ) {
      return
    }

    syncState = "syncing"
    const operations = [...reminderStore.operations]
    const rangeStart = dateToISO(offlineRange.rangeStart)
    const rangeEnd = dateToISO(offlineRange.rangeEnd)

    void flushReminderQueue({
      userId: currentUserId,
      operations,
      rangeStart,
      rangeEnd,
    })
      .then(async (result) => {
        await Promise.all(result.applied.map((id) => reminderStore.removeOperation(id)))
        if (result.reminders.length > 0) {
          await reminderStore.replaceFromServer(currentUserId, result.reminders)
        }
        syncState = result.failed.length > 0 || result.conflicts.length > 0 ? "failed" : "idle"
      })
      .catch(() => {
        syncState = "failed"
      })
  })
</script>

<svelte:head>
  <title>Lunar Calendar</title>
</svelte:head>

<CalendarLayout>
  <div class="flex min-w-0 flex-col gap-4 md:gap-6">
    <main class="main-content relative">
      <p class="mb-2 text-sm text-muted-foreground">
        {#if !network.isOnline}
          Offline mode
        {:else if syncState === "syncing"}
          Syncing changes...
        {:else if syncState === "failed"}
          Sync failed - retry when online
        {:else if reminderStore.hasPendingOperations}
          Unsynced changes
        {:else}
          Online
        {/if}
      </p>
      <DateInfoPanel
        {selectedISO}
        reminders={renderedReminders}
        occurrences={renderedOccurrences}
        onPrevDay={prevDay}
        onNextDay={nextDay}
      />
      <LunarCalendarGrid
        initialDate={isoToDate(today)}
        selectedDate={selectedISO}
        onSelect={handleSelect}
        onMonthChange={handleMonthChange}
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
