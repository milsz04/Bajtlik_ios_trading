import AVKit
import SwiftUI

struct AboutView: View {
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("About")
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.top, 20)
                VideoPlayer(player: AVPlayer(url: URL(string: "https://youtu.be/IVdyt2pNxn8?si=GgBLTQe97lQsWJV1")!))
                    .frame(height: 250)

                Spacer()
                Text("Welcome to Bajtlik, your trading application designed to help you make smarter investment decisions. Our platform combines real-time market, and intuitive design to give you a seamless trading experience. Whether you’re a beginner or a seasoned trader.")
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(16)
            }
        }
        .padding(0)
    }
}

#Preview {
    AboutView()
        .environmentObject(StockManager())
}
