import SwiftUI
import AVKit

struct AboutView: View {

    @State private var player: AVPlayer? = nil

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {

                Text("About")
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 10)

                if let player {
                    VideoPlayer(player: player)
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 10)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.1))
                        .frame(height: 250)
                        .padding(.horizontal, 10)
                }

                Text("Welcome to Bajtlik, your trading application designed to help you make smarter investment decisions. Our platform combines real-time market, and intuitive design to give you a seamless trading experience. Whether you’re a beginner or a seasoned trader.")
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding(16)

                Spacer()
            }
        }
        .onAppear {
            let url = URL(string: "https://cdn.free-stock.video/3172021/counting-finance-paper-currency-money-dollar-currency-wealth-13293-full.mp4")!

            let newPlayer = AVPlayer(url: url)
            newPlayer.isMuted = true
            newPlayer.play()

            self.player = newPlayer
        }
        .onDisappear {
            player?.pause()
        }
    }
}


#Preview {
    AboutView()
}
