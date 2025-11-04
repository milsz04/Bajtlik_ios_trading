import SwiftUI

struct HomeView: View {
    @State private var showContentView = false
    @State private var opacity = 1.0
    
    var body: some View {
        ZStack {
            if showContentView {
                ContentView()
                    .transition(.opacity)
            } else {
                ZStack {
                
                    Color(.systemGray6)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "wallet.bifold")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .foregroundColor(.black.opacity(0.85))
                        Spacer()
                        Text("Bajtlik")
                            .font(.system(size: 42, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                        
                        Text("Welcome!")
                            .font(.system(size: 24, weight: .regular, design: .monospaced))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            opacity = 1.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                opacity = 0.0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    showContentView = true
                                }
                            }
                        }
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(StockManager())
}
