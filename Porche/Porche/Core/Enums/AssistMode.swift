import Foundation

/// Modovi rada motora e-bikea (8 modova).
enum AssistMode: String, Codable, CaseIterable {
    case off
    case eco
    case tourTrail
    case sport
    case turboBoost
    case customIndividual
    case auto
    case walk

    /// Kratki naziv za UI (gornji trak, gumb).
    var displayTitle: String {
        switch self {
        case .off: return "OFF"
        case .eco: return "ECO"
        case .tourTrail: return "TOUR / TRAIL"
        case .sport: return "SPORT"
        case .turboBoost: return "TURBO / BOOST"
        case .customIndividual: return "CUSTOM / INDIVIDUAL"
        case .auto: return "AUTO"
        case .walk: return "WALK"
        }
    }

    /// Opis moda za prikaz u izboru.
    var description: String {
        switch self {
        case .off: return "Sustav je upaljen, ali motor ne pruža pomoć"
        case .eco: return "Maksimalna učinkovitost i domet"
        case .tourTrail: return "Uravnotežena potpora za svakodnevnu vožnju"
        case .sport: return "Dinamičan odziv za bržu vožnju"
        case .turboBoost: return "Maksimalna snaga motora"
        case .customIndividual: return "Korisnički definirane postavke snage i momenta"
        case .auto: return "Automatska prilagodba potpore terenu"
        case .walk: return "Asistencija pri guranju bicikla uzbrco"
        }
    }
}
