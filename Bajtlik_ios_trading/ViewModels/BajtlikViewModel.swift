import SwiftUI
import SwiftData
import Foundation
import Combine

final class BajtlikViewModel: ObservableObject {
    
    @Published var bajtlikVal = 12400.02
    @Published var balance = 1100.09
    
    @Published var shares = 1
}


