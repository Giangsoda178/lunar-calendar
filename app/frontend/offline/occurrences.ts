import type { LocalReminder } from "@/offline/types"
import type { Occurrence } from "@/types/reminder"

type OccurrenceRangeInput = {
  reminders: LocalReminder[]
  rangeStart: Date
  rangeEnd: Date
}

export function expandOfflineOccurrences({
  reminders,
  rangeStart,
  rangeEnd,
}: OccurrenceRangeInput): Occurrence[] {
  const start = rangeStart.toISOString().slice(0, 10)
  const end = rangeEnd.toISOString().slice(0, 10)

  return reminders
    .filter(
      (
        reminder,
      ): reminder is LocalReminder & {
        id: number
      } =>
        hasServerReminderId(reminder) &&
        reminder.start >= start &&
        reminder.start <= end &&
        !reminder.deleted_at,
    )
    .map((reminder) => ({
      reminder_id: reminder.id,
      date: reminder.start,
    }))
}

function hasServerReminderId(
  reminder: LocalReminder,
): reminder is LocalReminder & { id: number } {
  return typeof reminder.id === "number"
}
