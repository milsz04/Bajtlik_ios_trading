import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Image(systemName: "wallet.bifold")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .foregroundColor(.black.opacity(0.85))
                        .padding(.top, 60)
                    
                    Text("BAJTLIK")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.black.opacity(0.75))
                    
                    NavigationLink(destination: ContentView()) {
                        Text("Start")
                            .font(.system(size: 24, weight: .regular, design: .monospaced))
                            .padding(.horizontal, 50)
                            .padding(.vertical, 15)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                            )
                            .foregroundColor(.black.opacity(0.8))
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

#Preview {
    HomeView()
}
