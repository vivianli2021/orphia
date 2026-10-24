import Foundation

/// The resident's current age bracket, matching the "Age Bracket" column of
/// design/song-library-by-age-decade.csv. Each bracket maps to a formative
/// listening "Era" (roughly that bracket's teens/twenties) used to curate the
/// bracket's song list — this is the "decade" personalization dimension.
enum AgeBracket: String, CaseIterable {
    case fifties = "50s"
    case sixties = "60s"
    case seventies = "70s"
    case eighties = "80s"
    case nineties = "90s"
    case hundredPlus = "100+"

    /// Computes a resident's current bracket from their birth year. Ages below
    /// 50 (outside the dataset's range — this app targets older adults) clamp
    /// to the youngest bracket rather than failing; ages 100+ clamp to the
    /// oldest. Takes `now` as a parameter (instead of hardcoding a year) so the
    /// bracket stays correct as real time passes.
    static func current(birthYear: Int, now: Date = Date()) -> AgeBracket {
        let currentYear = Calendar.current.component(.year, from: now)
        let age = currentYear - birthYear
        switch age {
        case ..<60: return .fifties
        case 60..<70: return .sixties
        case 70..<80: return .seventies
        case 80..<90: return .eighties
        case 90..<100: return .nineties
        default: return .hundredPlus
        }
    }
}
