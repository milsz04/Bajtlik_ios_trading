import SwiftUI

struct SettingView: View {
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @State private var isNotificationMode: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Settings")
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding(.top, 0)
                    
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
                    
                    HStack {
                        Text("Notifications")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        Toggle("", isOn: $isNotificationMode)
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
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(false)
        }
    }
}

#Preview {
    SettingView()
        .environmentObject(StockManager())
}

