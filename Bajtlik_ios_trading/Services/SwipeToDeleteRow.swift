//import SwiftUI
//
//struct SwipeToDeleteRow<Content: View>: View {
//    let content: () -> Content
//    let onDelete: () -> Void
//    var cornerRadius: CGFloat = 16
//
//    @GestureState private var dragOffset: CGFloat = 0
//    @State private var permanentOffset: CGFloat = 0
//
//    private let maxReveal: CGFloat = 80
//
//    private var totalOffset: CGFloat {
//        permanentOffset + dragOffset
//    }
//
//    private var clampedOffset: CGFloat {
//        min(0, max(-maxReveal, totalOffset))
//    }
//
//    private var revealProgress: CGFloat {
//        guard maxReveal > 0 else { return 0 }
//        return min(1, max(0, -clampedOffset / maxReveal))
//    }
//
//    var body: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
//                .fill(Color.red)
//                .opacity(revealProgress)
//
//            HStack {
//                Spacer()
//                Button(action: onDelete) {
//                    Image(systemName: "trash")
//                        .font(.system(size: 20, weight: .bold))
//                        .foregroundColor(.white)
//                }
//                .padding(.trailing, 16)
//            }
//            .opacity(revealProgress)
//
//            content()
//                .offset(x: clampedOffset)
//                .gesture(
//                    DragGesture()
//                        .updating($dragOffset) { value, state, _ in
//                            let translation = value.translation.width
//                            state = translation < 0 ? translation : 0
//                        }
//                        .onEnded { value in
//                            let final = permanentOffset + value.translation.width
//                            permanentOffset = final < -maxReveal * 0.5 ? -maxReveal : 0
//                        }
//                )
//                .animation(
//                    .spring(response: 0.25, dampingFraction: 0.9),
//                    value: permanentOffset
//                )
//        }
//        .mask(
//            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
//        )
//        .contentShape(Rectangle())
//    }
//}
