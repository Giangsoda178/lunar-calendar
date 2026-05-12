import type { Reminder } from "@/types/reminder"

export type ReminderSyncStatus =
  | "synced"
  | "pending_create"
  | "pending_update"
  | "pending_delete"
  | "failed"
  | "conflicted"

export type ReminderIdentifier = Reminder["id"] | string

export type ReminderValidationErrors = Record<string, string[]>

export type LocalReminder = Omit<Reminder, "id"> & {
  id: ReminderIdentifier
  local_id?: string | null
  sync_status: ReminderSyncStatus
  base_updated_at?: string | null
  deleted_at?: string | null
  sync_errors?: ReminderValidationErrors | null
}

export type ReminderMutationAttributes = Omit<Reminder, "id" | "user_id" | "created_at" | "updated_at">

export type ReminderOperationType = "create" | "update" | "delete"

export type QueuedReminderOperation = {
  client_operation_id: string
  user_id: string
  operation: ReminderOperationType
  client_record_id?: string | null
  server_id?: Reminder["id"] | null
  base_updated_at?: string | null
  attributes?: Partial<ReminderMutationAttributes>
  created_at: string
}

export type ReminderSyncFailure = {
  client_operation_id: string
  reason: "validation" | "conflict" | "unauthorized" | "not_found" | "network" | "unknown"
  errors?: ReminderValidationErrors
}

export type ReminderSyncResult = {
  applied: string[]
  failed: ReminderSyncFailure[]
  conflicts: string[]
}
