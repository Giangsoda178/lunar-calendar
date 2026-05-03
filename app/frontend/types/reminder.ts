export type RepeatPeriod = "daily" | "weekly" | "monthly" | "yearly"

export type Reminder = {
  id: number
  user_id: string
  title: string
  start: string
  end: string
  notes?: string | null
  alert: boolean
  alert_minutes?: number | null
  is_lunar: boolean
  repeat: boolean
  repeat_period?: RepeatPeriod | number | null
  repeat_ends_at?: string | null
  created_at?: string
  updated_at?: string
}

export type Occurrence = {
  reminder_id: number
  date: string
}
