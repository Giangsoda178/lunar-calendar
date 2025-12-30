import { dateToISO, isoToDate } from "./lunar-calendar"

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
