import { getLunarDate, getSolarDate } from "@forvn/vn-lunar-calendar"

import {
  addLunarMonthsToLocalDate,
  advanceLunarMonthOne,
  dateToISO,
  isoToDate,
} from "./lunar-calendar"

describe("dateToISO", () => {
  it("formats dates with leading zeros", () => {
    expect(dateToISO(new Date(2024, 0, 5))).toBe("2024-01-05")
    expect(dateToISO(new Date(2024, 9, 9))).toBe("2024-10-09")
  })

  it("handles end of year correctly", () => {
    expect(dateToISO(new Date(2024, 11, 31))).toBe("2024-12-31")
  })
})

describe("isoToDate", () => {
  it("standard ISO", () => {
    expect(isoToDate("2024-01-15")).toEqual(new Date(2024, 0, 15))
    expect(isoToDate("2024-12-31")).toEqual(new Date(2024, 11, 31))
  })
  it("handles leap day", () => {
    expect(isoToDate("2024-02-29")).toEqual(new Date(2024, 1, 29))
  })
})

describe("addLunarMonthsToLocalDate", () => {
  it("matches one step of advanceLunarMonthOne + getSolarDate", () => {
    const d = new Date(2025, 2, 15, 10, 0)
    const out = addLunarMonthsToLocalDate(d, 1)
    const lu = getLunarDate(15, 3, 2025)
    expect(lu.year).not.toBe(0)
    const nxt = advanceLunarMonthOne(lu.year, lu.month, lu.day, lu.leap)
    expect(nxt).not.toBeNull()
    const s = getSolarDate(nxt!.day, nxt!.month, nxt!.year, nxt!.leap)
    expect(s.year).not.toBe(0)
    expect(out.getFullYear()).toBe(s.year)
    expect(out.getMonth()).toBe(s.month - 1)
    expect(out.getDate()).toBe(s.day)
  })
})
