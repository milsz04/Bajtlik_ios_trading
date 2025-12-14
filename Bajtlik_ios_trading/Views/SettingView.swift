import SwiftUI

struct SettingView: View {

    @EnvironmentObject var stockManager: StockManager

    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @State private var isNotificationMode: Bool = false

    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Settings")
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)

                    Divider()

                    HStack {
                        Text("Dark mode")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .foregroundColor(.primary)

                        Spacer()

                        Toggle("", isOn: $isDarkMode)
                            .labelsHidden()
                            .tint(.green)
                    }

                    Divider()

                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Text("About")
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    NavigationLink(destination: CreditsView()) {
                        HStack {
                            Text("Credits")
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // 🔴 RESET FUNDS
                    Button {
                        showResetAlert = true
                    } label: {
                        HStack {
                            Text("Reset Available Funds")
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(.red)
                        }
                    }

                    Divider()

                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(false)
        }
        .alert("Reset Account", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) {
                stockManager.resetAccount()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset your available funds to $10,000. Your portfolio positions will remain unchanged.")
        }
    }
}

#Preview {
    SettingView()
        .environmentObject(StockManager())
}

