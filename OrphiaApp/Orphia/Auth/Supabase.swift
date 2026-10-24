import Foundation
import Supabase

/// Shared Supabase client. URL and publishable key are read from Info.plist,
/// which gets them from Config/Secrets.xcconfig (gitignored).
/// The publishable key is safe to ship in the app — Row Level Security on each
/// table is what keeps one resident's data private from another.
let supabase: SupabaseClient = {
    guard
        let urlString = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
        let url = URL(string: urlString),
        let key = Bundle.main.object(forInfoDictionaryKey: "SupabasePublishableKey") as? String,
        !key.isEmpty
    else {
        fatalError("Missing Supabase config — copy Config/Secrets.example.xcconfig to Config/Secrets.xcconfig and fill it in.")
    }
    return SupabaseClient(supabaseURL: url, supabaseKey: key)
}()

/// One row of the `profiles` table (see docs/supabase-google-auth-setup.md, Part 4).
struct Profile: Codable {
    let id: UUID
    var firstName: String?
    var birthYear: Int?
    var genres: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case birthYear = "birth_year"
        case genres
    }

    /// Onboarding is done once birth year and at least one genre are saved.
    var isComplete: Bool { birthYear != nil && !genres.isEmpty }
}
