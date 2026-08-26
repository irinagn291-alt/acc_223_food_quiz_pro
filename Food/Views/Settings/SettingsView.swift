import SwiftUI

struct SettingsView: View {
    @State private var showContact = false

    var body: some View {
        NavigationStack {
            List {
                Button {
                    showContact = true
                } label: {
                    Label("Contact Us", systemImage: "envelope")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showContact) {
                ContactWebSheet()
            }
        }
    }
}
