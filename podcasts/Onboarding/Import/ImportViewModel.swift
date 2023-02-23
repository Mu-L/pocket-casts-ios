import Foundation
import SwiftUI

class ImportViewModel: OnboardingModel {
    var navigationController: UINavigationController?
    let installedApps: [ImportApp]

    var showSubtitle: Bool = true

    init() {
        self.installedApps = supportedApps.filter { $0.isInstalled }
    }

    func didAppear() {
        OnboardingFlow.shared.track(.onboardingImportShown)
    }

    func didDismiss(type: OnboardingDismissType) {
        guard type == .swipe else { return }

        OnboardingFlow.shared.track(.onboardingImportDismissed)
    }

    @objc func dismissTapped() {
        OnboardingFlow.shared.track(.onboardingImportDismissed)
        navigationController?.dismiss(animated: true)
    }

    // MARK: - Import apps
    private let supportedApps: [ImportApp] = [
        .init(id: .applePodcasts, displayName: "Apple Podcasts", steps: L10n.importInstructionsApplePodcastsSteps),
        .init(id: .breaker, displayName: "Breaker", steps: L10n.importInstructionsBreaker),
        .init(id: .castro, displayName: "Castro", steps: L10n.importInstructionsCastro),
        .init(id: .castbox, displayName: "Castbox", steps: L10n.importInstructionsCastbox),
        .init(id: .overcast, displayName: "Overcast", steps: L10n.importInstructionsOvercast),
        .init(id: .other, displayName: "other apps", steps: L10n.importPodcastsDescription),
        .init(id: .opmlFromURL, displayName: "URL", steps: L10n.importOpmlFromUrl)
    ]

    enum ImportAppId: String, AnalyticsDescribable {
        case breaker, castbox = "wazecastbox", overcast, other, opmlFromURL
        case castro = "co.supertop.Castro-2"
        case applePodcasts = "https://pocketcasts.com/import-from-apple-podcasts"

        var analyticsDescription: String {
            switch self {
            case .breaker:
                return "breaker"
            case .castbox:
                return "castbox"
            case .overcast:
                return "overcast"
            case .other:
                return "other"
            case .castro:
                return "castro"
            case .applePodcasts:
                return "apple_podcasts"
            case .opmlFromURL:
                return "opml_from_url"
            }
        }
    }

    struct ImportApp: Identifiable, CustomDebugStringConvertible {
        let id: ImportAppId
        let displayName: String
        let steps: String

        var isInstalled: Bool {
            #if targetEnvironment(simulator)
            return true
            #endif

            // Always installed
            // Note: Even if Apple podcasts has been uninstalled by the user, the system will always report
            // that it's installed.
            if [.other, .applePodcasts].contains(id) {
                return true
            }

            guard let url else {
                return false
            }

            return UIApplication.shared.canOpenURL(url)
        }

        var hideButton: Bool {
            switch id {
            case .other:
                return true
            default:
                return false
            }
        }

        var hasInputText: Bool {
            switch id {
            case .opmlFromURL:
                return true
            default:
                return false
            }
        }

        func openApp() {
            guard let url else { return }

            UIApplication.shared.open(url)
        }

        private var url: URL? {
            if id == .other || id == .opmlFromURL { return nil }

            let string: String
            if id == .applePodcasts {
                string = id.rawValue
            } else {
                string = id.rawValue + "://"
            }

            return URL(string: string)
        }

        var debugDescription: String {
            return "\(displayName): \(isInstalled ? "Yes" : "No")"
        }
    }
}


extension ImportViewModel {
    static func make(in navigationController: UINavigationController? = nil, source: String? = nil, showSubtitle: Bool = true) -> UIViewController {
        let viewModel = ImportViewModel()
        viewModel.showSubtitle = showSubtitle

        let controller = ImportHostingController(rootView: ImportLandingView(viewModel: viewModel).setupDefaultEnvironment())

        let navController = navigationController ?? UINavigationController(rootViewController: controller)
        viewModel.navigationController = navController
        controller.viewModel = viewModel

        if let source {
            OnboardingFlow.shared.updateAnalyticsSource(source)
        }
        return navigationController == nil ? navController : controller
    }
}

// MARK: - Landing View
extension ImportViewModel {
    func didSelect(_ app: ImportApp) {
        guard let navigationController else { return }
        OnboardingFlow.shared.track(.onboardingImportAppSelected, properties: ["app": app.id])

        let controller = UIHostingController(rootView: ImportDetailsView(app: app, viewModel: self).setupDefaultEnvironment())

        navigationController.pushViewController(controller, animated: true)
    }
}


// MARK: - Details
extension ImportViewModel {
    func openApp(_ app: ImportApp) {
        OnboardingFlow.shared.track(.onboardingImportOpenAppTapped, properties: ["app": app.id])

        app.openApp()
    }
}

// MARK: - OPML from URL
extension ImportViewModel {
    func importFromURL(_ url: URL, completion: @escaping ((Bool) -> Void)) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                print("Error downloading data: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
                return
            }

            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent("feed.opml")

            do {
                try data.write(to: fileURL)
                print("File downloaded to: \(fileURL)")
                self.importPodcastsFromOPML(url: fileURL)
            } catch {
                print("Error saving file: \(error.localizedDescription)")
                completion(false)
            }
        }

        task.resume()
    }

    func importPodcastsFromOPML(url: URL) {
        PodcastManager.shared.importPodcastsFromOpml(url)
    }
}
