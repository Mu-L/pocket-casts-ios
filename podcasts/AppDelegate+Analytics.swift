import PocketCastsServer
import StoreKit

extension AppDelegate: SKRequestDelegate {
    func setupAnalytics() {
        Analytics.register(adapters: [AnalyticsLoggingAdapter(), TracksAdapter()])

        refreshReceipt()
    }

    private func refreshReceipt(){
        let request = SKReceiptRefreshRequest(receiptProperties: nil)
        request.delegate = self
        request.start()
    }

    func requestDidFinish(_ request: SKRequest) {
        isEligibleForIntroductory { meow in
            print(meow)
        }
    }

    func request(_ request: SKRequest, didFailWithError error: Error){
        print("error: \(error.localizedDescription)")
    }

    func isEligibleForIntroductory(callback: @escaping (Bool) -> Void){
        guard let receiptUrl = Bundle.main.appStoreReceiptURL else {
            callback(true)
            return
        }

        guard let receiptData = try? Data(contentsOf: receiptUrl).base64EncodedString() else {
            return
        }

        print("🔵 Check")
        ApiServerHandler.shared.testReceipt()

    }
}
