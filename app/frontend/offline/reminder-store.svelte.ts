import type { Reminder } from "@/types/reminder"
import {
  clearUserData,
  deleteOperation,
  deleteReminder,
  getMetadata,
  getOperationsByUser,
  getRemindersByUser,
  putOperation,
  putReminders,
  replaceRemindersForUser,
  setMetadata,
} from "@/offline/db"
import type { LocalReminder, QueuedReminderOperation } from "@/offline/types"

type ReminderStoreState = {
  userId: string | null
  reminders: LocalReminder[]
  operations: QueuedReminderOperation[]
  initialized: boolean
  loading: boolean
}

const state = $state<ReminderStoreState>({
  userId: null,
  reminders: [],
  operations: [],
  initialized: false,
  loading: false,
})

function asLocalReminder(reminder: Reminder): LocalReminder {
  return {
    ...reminder,
    sync_status: "synced",
    base_updated_at: reminder.updated_at ?? null,
    local_id: null,
    deleted_at: null,
    sync_errors: null,
  }
}

function mergeById(existing: LocalReminder[], next: LocalReminder[]) {
  const map = new Map(existing.map((item) => [String(item.id), item]))
  for (const reminder of next) {
    map.set(String(reminder.id), reminder)
  }
  return Array.from(map.values())
}

async function reloadFromStorage(userId: string) {
  const [reminders, operations] = await Promise.all([
    getRemindersByUser(userId),
    getOperationsByUser(userId),
  ])
  state.reminders = reminders
  state.operations = operations
}

export function useReminderStore() {
  const initialize = async (userId: string, serverReminders: Reminder[] = []) => {
    if (!userId) return
    if (state.userId === userId && state.initialized) return

    state.loading = true
    const previousUserId = state.userId
    state.userId = userId

    if (previousUserId && previousUserId !== userId) {
      await clearUserData(previousUserId)
    }

    await reloadFromStorage(userId)

    const activeUserId = await getMetadata<string>("active_user_id")
    if (activeUserId && activeUserId !== userId) {
      await clearUserData(activeUserId)
    }

    if (serverReminders.length > 0) {
      const normalized = serverReminders.map(asLocalReminder)
      state.reminders = mergeById(state.reminders, normalized)
      await putReminders(userId, normalized)
      await setMetadata("last_server_seed_at", new Date().toISOString(), userId)
    }

    await setMetadata("active_user_id", userId)
    state.initialized = true
    state.loading = false
  }

  const replaceFromServer = async (userId: string, reminders: Reminder[]) => {
    if (!userId) return
    const normalized = reminders.map(asLocalReminder)
    state.reminders = normalized
    await replaceRemindersForUser(userId, normalized)
    await setMetadata("last_server_sync_at", new Date().toISOString(), userId)
  }

  const upsertLocalReminder = async (reminder: LocalReminder) => {
    if (!state.userId) return
    state.reminders = mergeById(state.reminders, [reminder])
    await putReminders(state.userId, [reminder])
  }

  const removeLocalReminder = async (reminderId: number | string) => {
    if (!state.userId) return
    state.reminders = state.reminders.filter((item) => String(item.id) !== String(reminderId))
    await deleteReminder(state.userId, reminderId)
  }

  const enqueueOperation = async (operation: QueuedReminderOperation) => {
    state.operations = [...state.operations, operation].sort((a, b) =>
      a.created_at.localeCompare(b.created_at),
    )
    await putOperation(operation)
  }

  const removeOperation = async (clientOperationId: string) => {
    state.operations = state.operations.filter(
      (operation) => operation.client_operation_id !== clientOperationId,
    )
    await deleteOperation(clientOperationId)
  }

  const switchUser = async (nextUserId: string) => {
    if (state.userId === nextUserId) return
    if (state.userId && state.userId !== nextUserId) {
      await clearUserData(state.userId)
    }
    state.userId = nextUserId
    await reloadFromStorage(nextUserId)
    await setMetadata("active_user_id", nextUserId)
    state.initialized = true
  }

  const clearCurrentUser = async () => {
    if (!state.userId) return
    const userId = state.userId
    await clearUserData(userId)
    await setMetadata("active_user_id", null)
    state.userId = null
    state.reminders = []
    state.operations = []
    state.initialized = false
  }

  return {
    get userId() {
      return state.userId
    },
    get reminders() {
      return state.reminders
    },
    get operations() {
      return state.operations
    },
    get hasPendingOperations() {
      return state.operations.length > 0
    },
    get initialized() {
      return state.initialized
    },
    get loading() {
      return state.loading
    },
    initialize,
    switchUser,
    replaceFromServer,
    upsertLocalReminder,
    removeLocalReminder,
    enqueueOperation,
    removeOperation,
    clearCurrentUser,
  }
}
