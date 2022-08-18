import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf
import Foundation

class CheckEligibilityTask: ApiBaseTask {
    // try authenticated request?
    override func apiTokenAcquired(token: String) {
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

        let url = ServerConstants.Urls.api() + "subscription/check_eligibility"
        print(url)

        do {
            let data = try request.serializedData()

            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            print("Sending it")

            guard let responseData = response, httpStatus == ServerConstants.HttpConstants.ok else {
                print("Failed?")
                return
            }

            do {
                let resp = try Api_CheckEligibleResponse(serializedData: responseData)

                print("Yes?")
            } catch {
                print("uih oh")
            }
        }
        catch {
            print("uh oh")
        }
    }
}
