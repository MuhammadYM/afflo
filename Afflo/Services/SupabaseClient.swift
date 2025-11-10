import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()

    let client: Supabase.SupabaseClient

    private init() {
        // TODO: Load from environment variables or Config
        // For now, using local Supabase instance
        let supabaseURL = URL(string: "http://127.0.0.1:54321")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"

        self.client = Supabase.SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }
}
