import Foundation

extension ApiServerHandler {
    public func testReceiptOther() {
        let operation = CheckEligibilityTask()
        apiQueue.addOperation(operation)
    }

    public func testReceipt() {
        guard
            let receiptUrl = Bundle.main.appStoreReceiptURL,
            let base64EncodedReceipt = try? Data(contentsOf: receiptUrl).base64EncodedString()
        else {
            print("Failed?")
            return
        }

        var appleRequest = Api_SubscriptionsPurchaseAppleRequest()
        appleRequest.receipt = base64EncodedReceipt

        var request = Api_CheckEligibleRequest()
        request.storeReceipt = .apple(appleRequest)

        let url = ServerHelper.asUrl(ServerConstants.Urls.api() + "subscription/check_eligibility")
        print(url.absoluteString)

        do {
            let data = try request.serializedData()

            guard let request = ServerHelper.createProtoRequest(url: url, data: data) else {
                print("Failed?")
                return
            }

            print("Sending it")

            URLSession.shared.dataTask(with: request) { data, response, error in
                print("Something?")

                guard let responseData = data, error == nil, response?.extractStatusCode() == ServerConstants.HttpConstants.ok else {
                    print("Failed?")

                    return
                }

                do {
                    let resp = try Api_CheckEligibleResponse(serializedData: responseData)
                    print("Yes?")
                } catch {
                    print("uh oh")
                }
            }.resume()
        }
        catch {
            print("uh oh")
        }

    }
}
