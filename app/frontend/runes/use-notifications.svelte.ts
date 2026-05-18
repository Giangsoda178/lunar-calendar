import { type ToastCategory, toast } from "./toast.svelte"
import { actionCable } from "./use-actioncable.svelte"
import { inertiaPage } from "@/utils"
import { get } from "svelte/store"

export type NotificationType = "info" | "success" | "warning" | "error"

export type Notification = {
  id: string
  type: NotificationType
  title: string
  message: string
  timestamp: string
  read?: boolean
}

/**
 * Notifications manager that integrates with ActionCable.
 * Subscribes to NotificationsChannel and manages notification state.
 *
 * @example
 * const notifications = useNotifications()
 *
 * // Subscribe on mount
 * $effect(() => {
 *   notifications.subscribe()
 *   return () => notifications.unsubscribe()
 * })
 *
 * // Access notifications
 * {#each notifications.items as n}
 *   <NotificationCard {n} />
 * {/each}
 */
class NotificationsStore {
  items = $state<Notification[]>([])
  showToasts = $state(true)
  private subscribed = false
  private subscriptionParams: Record<string, unknown> = {}

  subscribe(): void {
    if (this.subscribed) return

    const userId = this.currentUserId()
    this.subscriptionParams = userId ? { user_id: userId } : {}

    actionCable.subscribe<Notification>(
      "NotificationsChannel",
      this.subscriptionParams,
      {
        received: (notification) => {
          this.items = [notification, ...this.items]

          if (this.showToasts) {
            const category = this.mapTypeToToast(notification.type)
            toast[category](notification.title, {
              description: notification.message,
            })
          }
        },
        connected: () => {
          console.log("[Notifications] Connected to channel")
        },
        disconnected: () => {
          console.log("[Notifications] Disconnected from channel")
        },
      },
    )

    this.subscribed = true
  }

  unsubscribe(): void {
    if (!this.subscribed) return
    actionCable.unsubscribe("NotificationsChannel", this.subscriptionParams)
    this.subscriptionParams = {}
    this.subscribed = false
  }

  private currentUserId(): string | null {
    if (!inertiaPage) return null
    const auth = get(inertiaPage).props.auth as { user?: { id?: string | number } } | undefined
    const userId = auth?.user?.id
    return userId ? String(userId) : null
  }

  private mapTypeToToast(type: NotificationType): ToastCategory {
    const map: Record<NotificationType, ToastCategory> = {
      info: "info",
      success: "success",
      warning: "warning",
      error: "error",
    }
    return map[type]
  }

  markAsRead(id: string): void {
    const notification = this.items.find((n) => n.id === id)
    if (notification) {
      notification.read = true
    }
  }

  markAllAsRead(): void {
    this.items.forEach((n) => (n.read = true))
  }

  clear(): void {
    this.items = []
  }

  get unreadCount(): number {
    return this.items.filter((n) => !n.read).length
  }
}

// Singleton instance
export const notifications = new NotificationsStore()

// Hook-style export
export function useNotifications() {
  return notifications
}
