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
                    .foregroundColor(.primary)
                    .padding(10)
                HStack{
                    VideoPlayer(player: AVPlayer(url: URL(string: "https://file-examples.com/storage/fe30cc5437690901c9c4eea/2017/04/file_example_MP4_480_1_5MG.mp4")!))
                        .frame(height: 250)
                        .padding(10)
                }
                Text("Welcome to Bajtlik, your trading application designed to help you make smarter investment decisions. Our platform combines real-time market, and intuitive design to give you a seamless trading experience. Whether you’re a beginner or a seasoned trader.")
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding(16)
                Spacer()
            }
        }
        .padding(0)
    }
}

#Preview {
    AboutView()
        .environmentObject(StockManager())
}

