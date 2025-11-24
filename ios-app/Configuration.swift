import Foundation

struct Configuration {
    // MARK: - Base URL Configuration

    /// Base URL for the Rails server
    /// - Simulator: Use "http://localhost:3000"
    /// - Physical device: Use "http://YOUR_MAC_IP:3000" (find with: ifconfig | grep "inet ")
    static let baseURL = URL(string: "http://localhost:3000")!

    /// Alternative: Automatically detect if running on simulator or device
    /// Uncomment this and comment out the line above if you want automatic detection
    // static var baseURL: URL {
    //     #if targetEnvironment(simulator)
    //         return URL(string: "http://localhost:3000")!
    //     #else
    //         // Replace with your Mac's IP address
    //         return URL(string: "http://192.168.1.100:3000")!
    //     #endif
    // }

    // MARK: - App Settings

    /// App name displayed in navigation
    static let appName = "RAG Mobile"

    /// User agent string sent with requests
    static let userAgent = "RAG Mobile iOS - Turbo Native"
}
