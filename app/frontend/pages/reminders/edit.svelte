<script lang="ts">
  import CalendarLayout from "@/layouts/CalendarLayout.svelte"
  import ReminderForm from "./ReminderForm.svelte"
  import { reminderPath } from "@/routes"
  import type { Reminder } from "@/types/reminder"

  interface Props {
    reminder: Reminder
  }

  let { reminder }: Props = $props()
</script>

<svelte:head>
  <title>Edit Reminder</title>
</svelte:head>

<CalendarLayout>
  <h1 class="mb-4 text-xl font-semibold sm:text-2xl">Edit Reminder</h1>
  <ReminderForm
    {reminder}
    action={reminderPath(reminder.id)}
    method="patch"
    submitLabel="Save Changes"
  />
</CalendarLayout>
