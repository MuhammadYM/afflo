import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()

    let client: Supabase.SupabaseClient

    private init() {
        // Load configuration from Config.plist
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path) as? [String: Any],
              let urlString = config["SUPABASE_URL"] as? String,
              let key = config["SUPABASE_ANON_KEY"] as? String,
              let url = URL(string: urlString) else {
            fatalError("Config.plist not found or invalid. Copy Config.plist.example to Config.plist and fill in your values.")
        }

        let useLocal = config["USE_LOCAL"] as? Bool ?? false

        let supabaseURL: URL
        let supabaseKey: String

        if useLocal {
            supabaseURL = URL(string: "http://127.0.0.1:54321")!
            supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
            print("🔧 Using LOCAL Supabase: \(supabaseURL)")
        } else {
            supabaseURL = url
            supabaseKey = key
            print("☁️ Using PRODUCTION Supabase: \(supabaseURL)")
        }

        self.client = Supabase.SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }
}
