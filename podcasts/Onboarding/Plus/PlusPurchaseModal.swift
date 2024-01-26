import SwiftUI
import PocketCastsServer

struct PlusPurchaseModal: View {
    @EnvironmentObject var theme: Theme
    @ObservedObject var coordinator: PlusPurchaseModel

    @State var selectedOption: Constants.IapProducts
    @State var freeTrialDuration: String?

    var pricingInfo: PlusPurchaseModel.PlusPricingInfo {
        coordinator.pricingInfo
    }

    /// Whether or not all products have free trials, in this case we'll show the free trial label
    /// above the products and not inline
    let showGlobalTrial: Bool

    private var products: [PlusPricingInfoModel.PlusProductPricingInfo]

    init(coordinator: PlusPurchaseModel, selectedPrice: Constants.PlanFrequency = .yearly) {
        self.coordinator = coordinator

        self.products = coordinator.pricingInfo.products.filter { coordinator.plan.products.contains($0.identifier) }
        self.showGlobalTrial = products.allSatisfy { $0.offer != nil }

        let firstProduct = products.first
        _selectedOption = State(initialValue: selectedPrice == .yearly ? coordinator.plan.yearly : coordinator.plan.monthly)
        _freeTrialDuration = State(initialValue: firstProduct?.offer?.duration)
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Label(coordinator.plan == .plus ? L10n.plusPurchasePromoTitle : L10n.patronPurchasePromoTitle, for: .title)
                .foregroundColor(Color.textColor)
                .padding(.top, 32)
                .padding(.bottom, pricingInfo.hasFreeTrial ? 15 : 0)

            VStack(spacing: 16) {
                ForEach(products) { product in
                    // Hide any unselected items if we're in the failed state, this saves space for the error message
                    if coordinator.state != .failed || selectedOption == product.identifier {
                        ZStack(alignment: .center) {
                            Button(product.price) {
                                selectedOption = product.identifier
                                freeTrialDuration = product.offer?.duration
                            }
                            .disabled(coordinator.state == .failed)
                            .buttonStyle(PlusGradientStrokeButton(isSelectable: true, plan: coordinator.plan, isSelected: selectedOption == product.identifier))
                            .overlay(
                                ZStack(alignment: .center) {
                                    if let offerDescription = product.offer?.description {
                                        GeometryReader { proxy in
                                            OfferLabel(offerDescription, plan: coordinator.plan, isSelected: selectedOption ==   product.identifier)
                                                .position(x: proxy.size.width * 0.5, y: proxy.frame(in: .local).minY - (proxy.size.height * 0.12))
                                        }
                                    }
                                }
                            )
                        }
                    }
                }

                // Show how long the free trial is if there is one
                if pricingInfo.hasFreeTrial {
                    let label: String = {
                        if let freeTrialDuration {
                            return L10n.pricingTermsAfterTrialLong(freeTrialDuration)
                        }

                        return "\(selectedOption.renewalPrompt)\n\(L10n.plusCancelTerms)"
                    }()

                    Label(label, for: .freeTrialTerms)
                        .foregroundColor(Color.textColor)
                        .lineSpacing(1.2)
                }

                // Show the error message if we're in the failed state
                if coordinator.state == .failed {
                    PlusDivider()

                    Label(L10n.plusPurchaseFailed, for: .error).foregroundColor(.error)
                }

                PlusDivider()

                let isLoading = (coordinator.state == .purchasing)
                Button(subscribeButton) {
                    guard !isLoading else { return }
                    coordinator.purchase(product: selectedOption)
                }.buttonStyle(PlusGradientFilledButtonStyle(isLoading: isLoading, plan: coordinator.plan)).disabled(isLoading)

                TermsView()
            }.padding(.top, 23)
        }
        .frame(maxWidth: Config.maxWidth)
        .padding([.leading, .trailing])        
        .background(Color.backgroundColor.ignoresSafeArea())
    }

    private var subscribeButton: String {
        if coordinator.state == .failed {
            return L10n.tryAgain
        }

        if freeTrialDuration != nil {
            return L10n.freeTrialStartAndSubscribeButton
        }

        return L10n.subscribe
    }

    enum Config {
        static let backgroundColorHex = "#282829"
        static let maxWidth: CGFloat = 600
        static let termsHTML = L10n.purchaseTerms("<a href=\"\(ServerConstants.Urls.privacyPolicy)\">", "</a><br/>", "<a href=\"\(ServerConstants.Urls.termsOfUse)\">", "</a>")
    }
}

// MARK: - Config
private extension Color {
    static let backgroundColor = Color(hex: PlusPurchaseModal.Config.backgroundColorHex)
    static let textColor = Color(hex: "#FFFFFF")
    static let error = AppTheme.color(for: .support05)
}

// MARK: - Views
private struct PlusDivider: View {
    var body: some View {
        Divider().background(Color(hex: "#E4E4E4")).opacity(0.24)
    }
}

private struct TermsView: View {
    var body: some View {
        let purchaseTerms = L10n.purchaseTerms("$", "$", "$", "$").components(separatedBy: "$")

        let privacyPolicy = ServerConstants.Urls.privacyPolicy
        let termsOfUse = ServerConstants.Urls.termsOfUse

        Group {
            Text(purchaseTerms[safe: 0] ?? "") +
            Text(.init("[\(purchaseTerms[safe: 1] ?? "")](\(privacyPolicy))")).underline() +
            Text(purchaseTerms[safe: 2] ?? "") +
            Text(.init("[\(purchaseTerms[safe: 3] ?? "")](\(termsOfUse))")).underline()
        }
        .foregroundColor(.textColor)
        .font(style: .footnote)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct Label: View {
    enum LabelStyle {
        case title
        case freeTrialTerms
        case error
    }

    let text: String
    let labelStyle: LabelStyle

    init(_ text: String, for style: LabelStyle) {
        self.text = text
        self.labelStyle = style
    }

    var body: some View {
        Text(text)
            .fixedSize(horizontal: false, vertical: true)
            .modifier(LabelFont(labelStyle: labelStyle))
            .multilineTextAlignment(.center)
    }

    private struct LabelFont: ViewModifier {
        let labelStyle: LabelStyle

        func body(content: Content) -> some View {
            switch labelStyle {
            case .title:
                return content.font(size: 22, style: .title2, weight: .bold, maxSizeCategory: .extraExtraLarge)
            case .freeTrialTerms:
                return content.font(size: 13, style: .caption, maxSizeCategory: .extraExtraLarge)
            case .error:
                return content.font(style: .subheadline, maxSizeCategory: .extraExtraExtraLarge)
            }
        }
    }
}

// MARK: - Preview
struct PlusPurchaseOptions_Previews: PreviewProvider {
    static var previews: some View {
        PlusPurchaseModal(coordinator: PlusPurchaseModel())
            .setupDefaultEnvironment()
    }
}
