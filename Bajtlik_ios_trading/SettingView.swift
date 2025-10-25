import SwiftUI

struct SettingView: View {
    @State private var isLightMode: Bool = false
    @State private var isNotificationMode: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Settings")
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.top, 20)
                    
                    Divider()
                    
                    HStack {
                        Text("Light mode")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                        
                        Spacer()
                        Toggle("", isOn: $isLightMode)
                            .labelsHidden()
                            .tint(.green)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Notifications")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                        
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
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray.opacity(0.8))
                        }
                    }
                    
                    Divider()
                    
                
                    NavigationLink(destination: CreditsView()) {
                        HStack {
                            Text("Credits")
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray.opacity(0.8))
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
}
