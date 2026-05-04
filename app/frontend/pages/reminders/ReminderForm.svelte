<script lang="ts">
  import type { FormComponentSlotProps } from "@inertiajs/core"
  import { Form, page } from "@inertiajs/svelte"
  import { untrack } from "svelte"
  import { LunarCalendar } from "@forvn/vn-lunar-calendar"

  import Field from "@/components/ui/Field.svelte"
  import { addLunarMonthsToLocalDate } from "@/utils/lunar-calendar"
  import Input from "@/components/ui/Input.svelte"
  import Textarea from "@/components/ui/Textarea.svelte"
  import Label from "@/components/ui/Label.svelte"
  import Switch from "@/components/ui/Switch.svelte"
  import Button from "@/components/ui/Button.svelte"
  import type { Reminder } from "@/types/reminder"

  type Method = "post" | "patch"

  interface Props {
    reminder: Reminder
    action: string
    method: Method
    submitLabel: string
  }

  let { reminder, action, method, submitLabel }: Props = $props()

  // Normalize a Rails-serialized datetime (ISO with offset, or undefined) into
  // the `YYYY-MM-DDTHH:MM` shape that `<input type="datetime-local">` requires.
  function toLocalInput(value: string | null | undefined): string {
    if (!value) return ""
    const d = new Date(value)
    if (Number.isNaN(d.getTime())) return ""
    const pad = (n: number) => String(n).padStart(2, "0")
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
  }

  // Extract the date portion ("YYYY-MM-DD") from a Rails datetime so we can
  // seed the <input type="date"> used for `repeat_ends_at`.
  function toDateInput(value: string | null | undefined): string {
    if (!value) return ""
    const d = new Date(value)
    if (Number.isNaN(d.getTime())) return ""
    const pad = (n: number) => String(n).padStart(2, "0")
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
  }

  let errors = $derived($page.props.errors || {})

  // Local UI state for conditional field visibility. The form reads input
  // values from the DOM at submit time — these only drive show/hide and
  // compute-on-change helpers (lunar preview, repeat-ends derivation).
  let alertOn = $state(untrack(() => !!reminder.alert))
  let repeatOn = $state(untrack(() => !!reminder.repeat))
  let isLunar = $state(untrack(() => !!reminder.is_lunar))
  let startValue = $state(untrack(() => toLocalInput(reminder.start)))

  // Controls the three-way "Ends" selector next to Repeat. Seeded from the
  // existing reminder: if `repeat_ends_at` is set we start on "on-date",
  // otherwise "never". We don't try to back-solve "after N occurrences"
  // from an existing datetime (could be lossy for monthly/yearly clamps).
  type EndsMode = "never" | "on-date" | "after-n"
  let endsMode = $state<EndsMode>(
    untrack(() => (reminder.repeat_ends_at ? "on-date" : "never")),
  )
  let endsOnDate = $state(
    untrack(() => toDateInput(reminder.repeat_ends_at ?? null)),
  )
  let endsAfterN = $state(1)
  let repeatPeriod = $state<string>(
    untrack(() => (reminder.repeat_period as string | null) ?? ""),
  )

  // Live lunar preview: whenever start + is_lunar are set, show what lunar
  // date the solar pick would represent. Helps users pick the right solar
  // day when they're thinking in lunar terms. Schema stays solar-only.
  const lunarPreview = $derived.by(() => {
    if (!isLunar || !startValue) return null
    const d = new Date(startValue)
    if (Number.isNaN(d.getTime())) return null
    try {
      const lu = LunarCalendar.fromSolar(
        d.getDate(),
        d.getMonth() + 1,
        d.getFullYear(),
      )
      const ld = lu.lunarDate
      return `Lunar equivalent: ${String(ld.day).padStart(2, "0")}/${String(ld.month).padStart(2, "0")}/${ld.year}${ld.leap ? " (leap)" : ""}`
    } catch {
      return null
    }
  })

  // When the user picks "After N occurrences" we compute the end date
  // client-side rather than adding a second DB column. Advance from `start`
  // by (N - 1) periods of the chosen type. Matches ReminderOccurrences'
  // expansion semantics (solar monthly: Feb-30 -> Feb-28 clamp; lunar monthly:
  // same lunar day, next lunar month).
  function computedEndsAt(): string {
    if (!startValue || endsAfterN < 1 || !repeatPeriod) return ""
    const d = new Date(startValue)
    if (Number.isNaN(d.getTime())) return ""
    const steps = endsAfterN - 1
    if (repeatPeriod === "daily") d.setDate(d.getDate() + steps)
    else if (repeatPeriod === "weekly") d.setDate(d.getDate() + steps * 7)
    else if (repeatPeriod === "monthly") {
      if (isLunar) {
        const next = addLunarMonthsToLocalDate(d, steps)
        d.setTime(next.getTime())
      } else {
        const targetDay = d.getDate()
        d.setMonth(d.getMonth() + steps)
        if (d.getDate() !== targetDay) d.setDate(0)
      }
    } else if (repeatPeriod === "yearly") d.setFullYear(d.getFullYear() + steps)
    const pad = (n: number) => String(n).padStart(2, "0")
    // End-of-day so occurrences on the final day still count.
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T23:59`
  }

  // Final `repeat_ends_at` value that's actually submitted. null for "never",
  // the date input (at end-of-day) for "on-date", computed for "after-n".
  const submittedRepeatEndsAt = $derived.by(() => {
    if (!repeatOn || endsMode === "never") return ""
    if (endsMode === "on-date" && endsOnDate) return `${endsOnDate}T23:59`
    if (endsMode === "after-n") return computedEndsAt()
    return ""
  })
</script>

<Form {action} {method}>
  {#snippet children({ processing }: FormComponentSlotProps)}
    <div class="w-full max-w-2xl space-y-5">
      <Field label="Title*" name="title" error={errors.title}>
        <Input
          name="reminder[title]"
          placeholder="Title of the reminder"
          defaultValue={reminder.title ?? ""}
          required
          invalid={!!errors.title}
        />
      </Field>

      <Field label="Start*" name="start" error={errors.start}>
        <Input
          name="reminder[start]"
          type="datetime-local"
          bind:value={startValue}
          required
          invalid={!!errors.start}
        />
        {#if lunarPreview}
          <p class="text-muted-foreground mt-1 text-sm">{lunarPreview}</p>
        {/if}
      </Field>

      <Field label="End" name="end" error={errors.end}>
        <Input
          name="reminder[end]"
          type="datetime-local"
          defaultValue={toLocalInput(reminder.end)}
          invalid={!!errors.end}
        />
      </Field>

      <Field label="Notes" name="notes" error={errors.notes}>
        <Textarea
          name="reminder[notes]"
          placeholder="Additional details about the reminder"
          rows={3}
          defaultValue={reminder.notes ?? ""}
        />
      </Field>

      <Label class="cursor-pointer items-center gap-3">
        <input type="hidden" name="reminder[alert]" value="0" />
        <Switch name="reminder[alert]" value="1" bind:checked={alertOn} />
        Alert
      </Label>
      {#if alertOn}
        <Field
          label="Minutes in advance"
          name="alert_minutes"
          error={errors.alert_minutes}
        >
          <Input
            name="reminder[alert_minutes]"
            type="number"
            min="0"
            class="w-full sm:w-48"
            defaultValue={reminder.alert_minutes ?? 0}
            invalid={!!errors.alert_minutes}
          />
        </Field>
      {/if}

      <Label class="cursor-pointer items-center gap-3">
        <input type="hidden" name="reminder[repeat]" value="0" />
        <Switch name="reminder[repeat]" value="1" bind:checked={repeatOn} />
        Repeat
      </Label>
      {#if repeatOn}
        <Field
          label="Repeat Period"
          name="repeat_period"
          error={errors.repeat_period}
        >
          <select
            name="reminder[repeat_period]"
            class="w-full sm:w-48"
            aria-invalid={!!errors.repeat_period}
            bind:value={repeatPeriod}
          >
            <option value="" disabled>Select a period</option>
            <option value="daily">Daily</option>
            <option value="weekly">Weekly</option>
            <option value="monthly">Monthly</option>
            <option value="yearly">Yearly</option>
          </select>
        </Field>

        <!-- Three-way ends selector: Never / On date / After N. Whichever
             mode is active, we resolve it to a single datetime and ship
             that via the hidden `reminder[repeat_ends_at]` input below. -->
        <Field label="Ends" name="repeat_ends_at" error={errors.repeat_ends_at}>
          <select class="w-full sm:w-48" bind:value={endsMode}>
            <option value="never">Never</option>
            <option value="on-date">On date</option>
            <option value="after-n">After N occurrences</option>
          </select>
        </Field>
        {#if endsMode === "on-date"}
          <Field label="End date" name="repeat_ends_on">
            <Input type="date" class="w-full sm:w-48" bind:value={endsOnDate} />
          </Field>
        {:else if endsMode === "after-n"}
          <Field label="Number of occurrences" name="repeat_count">
            <Input
              type="number"
              min="1"
              class="w-full sm:w-48"
              bind:value={endsAfterN}
            />
          </Field>
        {/if}
        <input
          type="hidden"
          name="reminder[repeat_ends_at]"
          value={submittedRepeatEndsAt}
        />
      {:else}
        <!-- Explicit empty submission so a previously-set repeat_ends_at
             gets cleared when the user turns repeat off on an edit. -->
        <input type="hidden" name="reminder[repeat_ends_at]" value="" />
      {/if}

      <Label class="cursor-pointer items-center gap-3">
        <input type="hidden" name="reminder[is_lunar]" value="0" />
        <Switch name="reminder[is_lunar]" value="1" bind:checked={isLunar} />
        Lunar calendar
      </Label>

      <div>
        <Button type="submit" disabled={processing} class="w-full sm:w-auto">
          {processing ? "Saving..." : submitLabel}
        </Button>
      </div>
    </div>
  {/snippet}
</Form>
