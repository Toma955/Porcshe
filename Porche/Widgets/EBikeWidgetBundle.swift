import WidgetKit
import SwiftUI

struct EBikeWidgetBundle: WidgetBundle {
    var body: some Widget {
        LiveActivityWidget()
        LockScreenWidget()
    }
}
