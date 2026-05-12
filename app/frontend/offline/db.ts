import { openDB, type DBSchema, type IDBPDatabase } from "idb"

import type {
  LocalReminder,
  QueuedReminderOperation,
  ReminderIdentifier,
} from "@/offline/types"

const DB_NAME = "moon-calendar-offline"
const DB_VERSION = 1

type ReminderRecord = {
  key: string
  userId: string
  reminderId: ReminderIdentifier
  reminder: LocalReminder
  updatedAt: number
}

type OperationRecord = {
  clientOperationId: string
  userId: string
  operation: QueuedReminderOperation
  createdAt: number
}

type MetadataRecord = {
  key: string
  value: unknown
}

interface OfflineDatabaseSchema extends DBSchema {
  reminders: {
    key: string
    value: ReminderRecord
    indexes: {
      userId: string
      userId_updatedAt: [string, number]
    }
  }
  operations: {
    key: string
    value: OperationRecord
    indexes: {
      userId: string
      userId_createdAt: [string, number]
    }
  }
  metadata: {
    key: string
    value: MetadataRecord
  }
}

let dbPromise: Promise<IDBPDatabase<OfflineDatabaseSchema>> | null = null

function reminderKey(userId: string, reminderId: ReminderIdentifier) {
  return `${userId}:${String(reminderId)}`
}

function metadataKey(key: string, userId?: string) {
  if (!userId) return key
  return `${userId}:${key}`
}

export function openOfflineDatabase() {
  if (dbPromise) return dbPromise

  dbPromise = openDB<OfflineDatabaseSchema>(DB_NAME, DB_VERSION, {
    upgrade(database) {
      if (!database.objectStoreNames.contains("reminders")) {
        const reminders = database.createObjectStore("reminders", { keyPath: "key" })
        reminders.createIndex("userId", "userId", { unique: false })
        reminders.createIndex("userId_updatedAt", ["userId", "updatedAt"], { unique: false })
      }

      if (!database.objectStoreNames.contains("operations")) {
        const operations = database.createObjectStore("operations", {
          keyPath: "clientOperationId",
        })
        operations.createIndex("userId", "userId", { unique: false })
        operations.createIndex("userId_createdAt", ["userId", "createdAt"], {
          unique: false,
        })
      }

      if (!database.objectStoreNames.contains("metadata")) {
        database.createObjectStore("metadata", { keyPath: "key" })
      }
    },
  })

  return dbPromise
}

export async function getRemindersByUser(userId: string) {
  const db = await openOfflineDatabase()
  const records = await db.getAllFromIndex("reminders", "userId", userId)
  return records.map((record) => record.reminder)
}

export async function putReminders(userId: string, reminders: LocalReminder[]) {
  if (reminders.length === 0) return

  const db = await openOfflineDatabase()
  const transaction = db.transaction("reminders", "readwrite")
  const now = Date.now()

  for (const reminder of reminders) {
    const record: ReminderRecord = {
      key: reminderKey(userId, reminder.id),
      userId,
      reminderId: reminder.id,
      reminder,
      updatedAt: now,
    }
    await transaction.store.put(record)
  }

  await transaction.done
}

export async function replaceRemindersForUser(
  userId: string,
  reminders: LocalReminder[],
) {
  const db = await openOfflineDatabase()
  const transaction = db.transaction("reminders", "readwrite")
  const existing = await transaction.store.index("userId").getAllKeys(userId)

  for (const key of existing) {
    await transaction.store.delete(key)
  }

  const now = Date.now()
  for (const reminder of reminders) {
    const record: ReminderRecord = {
      key: reminderKey(userId, reminder.id),
      userId,
      reminderId: reminder.id,
      reminder,
      updatedAt: now,
    }
    await transaction.store.put(record)
  }

  await transaction.done
}

export async function deleteReminder(
  userId: string,
  reminderId: ReminderIdentifier,
) {
  const db = await openOfflineDatabase()
  await db.delete("reminders", reminderKey(userId, reminderId))
}

export async function getOperationsByUser(userId: string) {
  const db = await openOfflineDatabase()
  const records = await db.getAllFromIndex("operations", "userId", userId)
  return records
    .sort((a, b) => a.createdAt - b.createdAt)
    .map((record) => record.operation)
}

export async function putOperation(operation: QueuedReminderOperation) {
  const db = await openOfflineDatabase()
  const record: OperationRecord = {
    clientOperationId: operation.client_operation_id,
    userId: operation.user_id,
    operation,
    createdAt: new Date(operation.created_at).getTime(),
  }
  await db.put("operations", record)
}

export async function deleteOperation(clientOperationId: string) {
  const db = await openOfflineDatabase()
  await db.delete("operations", clientOperationId)
}

export async function clearUserData(userId: string) {
  const db = await openOfflineDatabase()
  const transaction = db.transaction(["reminders", "operations"], "readwrite")

  const reminderKeys = await transaction.objectStore("reminders").index("userId").getAllKeys(userId)
  for (const key of reminderKeys) {
    await transaction.objectStore("reminders").delete(key)
  }

  const operationKeys = await transaction
    .objectStore("operations")
    .index("userId")
    .getAllKeys(userId)
  for (const key of operationKeys) {
    await transaction.objectStore("operations").delete(key)
  }

  await transaction.done
}

export async function setMetadata<T>(key: string, value: T, userId?: string) {
  const db = await openOfflineDatabase()
  await db.put("metadata", {
    key: metadataKey(key, userId),
    value,
  })
}

export async function getMetadata<T>(key: string, userId?: string) {
  const db = await openOfflineDatabase()
  const record = await db.get("metadata", metadataKey(key, userId))
  return (record?.value as T | undefined) ?? null
}
