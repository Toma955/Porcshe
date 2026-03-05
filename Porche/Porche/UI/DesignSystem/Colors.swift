import SwiftUI

enum AppColors {
    static let primary = Color.primary
    static let secondary = Color.secondary
    static let background = Color(.systemBackground)

    /// Glavna narančasta boja za vožnju po noći (island, pozadine).
    static let nightRidingOrange = Color(red: 255/255, green: 92/255, blue: 0/255) // #FF5C00
    /// Naglašena boja u noćnom modu (umjesto zelene: gumb Mod, odabir, itd.).
    static let nightRidingAccent = Color(red: 255/255, green: 75/255, blue: 51/255) // #FF4B33
}
