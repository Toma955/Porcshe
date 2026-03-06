import AVFoundation

enum WelcomeSoundService {
    private static var welcomePlayer: AVAudioPlayer?

    /// Play welcome sound (e.g. when user enters App from island). Does not check hasPlayed.
    static func playWelcomeSound() {
        if ProcessInfo.processInfo.arguments.contains("--uitesting") { return }
        guard let url = urlForWelcomeSound() else { return }
        DispatchQueue.main.async {
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try session.setActive(true)
            } catch { return }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.volume = 1.0
                welcomePlayer = player
                player.play()
                DispatchQueue.main.asyncAfter(deadline: .now() + max(player.duration + 0.5, 2)) {
                    welcomePlayer = nil
                }
            } catch {}
        }
    }

    static func playWelcomeSoundIfNeeded(hasPlayed: inout Bool) {
        guard !hasPlayed else { return }
        if ProcessInfo.processInfo.arguments.contains("--uitesting") { return }
        hasPlayed = true
        guard let url = urlForWelcomeSound() else { return }
        DispatchQueue.main.async {
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try session.setActive(true)
            } catch {
                return
            }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.volume = 1.0
                welcomePlayer = player
                player.play()
                DispatchQueue.main.asyncAfter(deadline: .now() + max(player.duration + 0.5, 2)) {
                    welcomePlayer = nil
                }
            } catch {
                return
            }
        }
    }

    private static func urlForWelcomeSound() -> URL? {
        let candidates: [(subdir: String?, name: String)] = [
            ("Sounds", "Welcome"),
            ("Resources/Sounds", "Welcome"),
            ("Porche/Resources/Sounds", "Welcome"),
            (nil, "Welcome"),
        ]
        for (subdir, name) in candidates {
            if let url = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: subdir) {
                return url
            }
        }
        if let resourcePath = Bundle.main.resourcePath {
            let fm = FileManager.default
            let subdirs = ["Sounds", "Resources/Sounds", "Porche/Resources/Sounds", ""]
            for sub in subdirs {
                let dir = sub.isEmpty ? resourcePath : (resourcePath as NSString).appendingPathComponent(sub)
                let path = (dir as NSString).appendingPathComponent("Welcome.mp3")
                if fm.fileExists(atPath: path) {
                    return URL(fileURLWithPath: path)
                }
            }
        }
        if let url = Bundle.main.url(forResource: "Welcome", withExtension: "mp3") {
            return url
        }
        return nil
    }
}
