import type {
  QueuedReminderOperation,
  ReminderSyncFailure,
  ReminderSyncResult,
} from "@/offline/types"
import type { Occurrence, Reminder } from "@/types/reminder"

type FlushReminderQueueInput = {
  userId: string
  operations: QueuedReminderOperation[]
  rangeStart?: string
  rangeEnd?: string
  month?: string
}

type FlushReminderQueueOutput = ReminderSyncResult & {
  reminders: Reminder[]
  occurrences: Occurrence[]
  window?: { range_start: string; range_end: string }
}

let inFlightFlush: Promise<FlushReminderQueueOutput> | null = null

type SyncApiResponse = {
  applied?: Array<{ client_operation_id: string }>
  failed?: Array<{ client_operation_id: string; reason?: string; errors?: Record<string, string[]> }>
  conflicts?: Array<{ client_operation_id: string }>
  reminders?: Reminder[]
  occurrences?: Occurrence[]
  window?: { range_start: string; range_end: string }
}

function csrfToken() {
  return (
    document
      .querySelector('meta[name="csrf-token"]')
      ?.getAttribute("content") ?? ""
  )
}

function normalizeFailureReason(reason?: string): ReminderSyncFailure["reason"] {
  if (reason === "validation") return "validation"
  if (reason === "not_found") return "not_found"
  if (reason === "unauthorized") return "unauthorized"
  if (reason === "conflict") return "conflict"
  return "unknown"
}

export async function flushReminderQueue({
  userId,
  operations,
  rangeStart,
  rangeEnd,
  month,
}: FlushReminderQueueInput): Promise<FlushReminderQueueOutput> {
  if (inFlightFlush) return inFlightFlush
  if (operations.length === 0) {
    return {
      applied: [],
      failed: [],
      conflicts: [],
      reminders: [],
      occurrences: [],
    }
  }

  inFlightFlush = (async () => {
    const response = await fetch("/reminders/sync", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-CSRF-Token": csrfToken(),
      },
      credentials: "same-origin",
      body: JSON.stringify({
        user_id: userId,
        operations,
        range_start: rangeStart,
        range_end: rangeEnd,
        month,
      }),
    })

    if (!response.ok) {
      throw new Error(`Sync request failed with status ${response.status}`)
    }

    const payload = (await response.json()) as SyncApiResponse

    return {
      applied: (payload.applied ?? []).map((item) => item.client_operation_id),
      failed: (payload.failed ?? []).map((item) => ({
        client_operation_id: item.client_operation_id,
        reason: normalizeFailureReason(item.reason),
        errors: item.errors,
      })),
      conflicts: (payload.conflicts ?? []).map((item) => item.client_operation_id),
      reminders: payload.reminders ?? [],
      occurrences: payload.occurrences ?? [],
      window: payload.window,
    }
  })()

  try {
    return await inFlightFlush
  } finally {
    inFlightFlush = null
  }
}
