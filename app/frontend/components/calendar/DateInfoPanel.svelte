<script lang="ts">
  import { LunarCalendar } from "@forvn/vn-lunar-calendar"
  import { ChevronLeft, ChevronRight } from "@lucide/svelte"

  import { MONTH_NAMES, isoToDate } from "@/utils"

  interface Props {
    selectedISO: string | null
    onPrevDay: () => void
    onNextDay: () => void
  }

  let { selectedISO, onPrevDay, onNextDay }: Props = $props()

  // Compute lunar calendar data once for selected date
  let selectedLunar = $derived.by(() => {
    if (!selectedISO) return null
    const d = isoToDate(selectedISO)
    return LunarCalendar.fromSolar(
      d.getDate(),
      d.getMonth() + 1,
      d.getFullYear(),
    )
  })

  // Derive display values from single solar computation
  let selectedSolarDate = $derived(selectedISO?.slice(8, 10) ?? null)

  let selectedSolarMonthYear = $derived.by(() => {
    if (!selectedISO) return null
    const monthIndex = Number(selectedISO.slice(5, 7)) - 1
    return `${MONTH_NAMES[monthIndex]} ${selectedISO.slice(0, 4)}`
  })

  let selectedLunarDate = $derived(selectedLunar?.lunarDate.day ?? null)

  let selectedLunarMonthYear = $derived.by(() => {
    if (!selectedLunar) return null
    const { month, year } = selectedLunar.lunarDate
    return `${MONTH_NAMES[month - 1]} ${year}`
  })

  let selectedLunarCanChi = $derived.by(() => {
    if (!selectedLunar) return null
    const { dayCanChi, monthCanChi, yearCanChi } = selectedLunar
    return `Ngày ${dayCanChi} - Tháng ${monthCanChi} - Năm ${yearCanChi}`
  })
</script>

<div class="date-info-container">
  <button class="btn left-btn" onclick={onPrevDay} aria-label="Previous day">
    <ChevronLeft />
  </button>
  <div class="date-info-wrapper">
    <div class="date-info">
      <span class="type">Solar</span>
      <span class="date">{selectedSolarDate ?? ""}</span>
      <span class="month-year">{selectedSolarMonthYear ?? ""}</span>
    </div>
    <div class="date-info">
      <span class="type">Lunar</span>
      <span class="date">{selectedLunarDate ?? ""}</span>
      <span class="month-year">{selectedLunarMonthYear ?? ""}</span>
      <span class="canchi">{selectedLunarCanChi ?? ""}</span>
    </div>
  </div>
  <button class="btn right-btn" onclick={onNextDay} aria-label="Next day">
    <ChevronRight />
  </button>
</div>

<style lang="postcss">
  .date-info-container {
    display: flex;
    justify-content: center;
    align-items: center;
    gap: 8rem;
    margin: 2rem auto;

    .date-info-wrapper {
      display: flex;
      gap: 6rem;

      .date-info {
        display: flex;
        flex-direction: column;
        align-items: center;

        .type {
          font-size: 2rem;
          font-weight: 500;
        }

        .date {
          font-size: 5rem;
          font-weight: 700;
        }

        .month-year {
          font-size: 2rem;
          font-weight: 500;
        }

        .canchi {
          font-size: 1.2rem;
          margin-top: 1rem;
        }
      }
    }
  }
</style>
