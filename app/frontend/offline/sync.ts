import type { LocalReminder, QueuedReminderOperation, ReminderSyncResult } from "@/offline/types"

type FlushReminderQueueInput = {
  userId: string
  operations: QueuedReminderOperation[]
}

type FlushReminderQueueOutput = ReminderSyncResult & {
  reminders: LocalReminder[]
}

let inFlightFlush: Promise<FlushReminderQueueOutput> | null = null

export async function flushReminderQueue({
  operations,
}: FlushReminderQueueInput): Promise<FlushReminderQueueOutput> {
  if (inFlightFlush) return inFlightFlush

  inFlightFlush = Promise.resolve({
    applied: operations.map((operation) => operation.client_operation_id),
    failed: [],
    conflicts: [],
    reminders: [],
  })

  try {
    return await inFlightFlush
  } finally {
    inFlightFlush = null
  }
}
