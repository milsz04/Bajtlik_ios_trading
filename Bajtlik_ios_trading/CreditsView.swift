import SwiftUI

struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                Text("Credits")
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    
                    Spacer()
                }
                .padding(.top, 20)
                
                Divider()
                
                Group {
                    HStack {
                        Text("Design & Concept\nTeam Bajtlik")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                        Spacer()
                    }
                    Divider()
                    HStack {
                        Text("Development\nMilosz Szynka\nKatarzyna Michalska\nJakub Piskorowski")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                    }
                    Divider()
                    HStack {
                        Text("Icons\nApple design resources")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                    }
                    Divider()
                    HStack {
                        Text("Fonts\nOverpass mono")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                    }
                    Divider()
                    HStack {
                        Text("Data providers\nApple design resources")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                    }
                    Divider()
                    HStack {
                        Text("App Name Origin\nBajtlik means wallet in Silesian Dialect")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack{
                        Spacer()
                        Text("Version 1.0.0 @ 2025 Bajtlik")
                            .font(.system(size: 12, weight: .ultraLight))
                        Spacer()
                    }
                }
            }
            .padding()
        }
        .navigationBarHidden(false)
    }
}

#Preview {
    CreditsView()
        .environmentObject(StockManager())
}
