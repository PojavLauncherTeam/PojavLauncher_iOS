import SwiftUI

extension NavigationView {
    @ViewBuilder
    func switchNavigationViewStyle(if flag: Bool) -> some View {
        if flag {
            self.navigationViewStyle(DoubleColumnNavigationViewStyle())
        } else {
            self.navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
