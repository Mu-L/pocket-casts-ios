import PocketCastsServer
import UIKit

class UpgradeRequiredViewController: PCViewController {
    @IBOutlet var upgradeButton: ThemeableRoundedButton! {
        didSet {
            upgradeButton.setTitle(L10n.plusMarketingUpgradeButton, for: .normal)
        }
    }

    @IBOutlet var featureInfoView: PlusFeaturesView!
    @IBOutlet var logoImageView: ThemeableImageView! {
        didSet {
            logoImageView.imageNameFunc = AppTheme.pcPlusLogoVerticalImageName
        }
    }
    
    @IBOutlet var verticalLogo: UIImageView! {
        didSet {
            verticalLogo.image = Theme.isDarkTheme() ? UIImage(named: "verticalLogoDark") : UIImage(named: "verticalLogo")
        }
    }
    
    @IBOutlet var infoLabel: ThemeableLabel! {
        didSet {
            infoLabel.style = .primaryText01
            infoLabel.text = L10n.plusRequiredFeature
        }
    }
    
    @IBOutlet var priceLabel: ThemeableLabel! {
        didSet {
            priceLabel.style = .primaryText02
        }
    }
    
    @IBOutlet var noThanksButton: ThemeableRoundedButton! {
        didSet {
            noThanksButton.shouldFill = false
            noThanksButton.setTitle(L10n.settingsGeneralNoThanks, for: .normal)
        }
    }

    let source: PlusUpgradeViewSource
    weak var upgradeRootViewController: UIViewController?
    
    @IBOutlet var noPaymentLabel: ThemeableLabel!

    init(upgradeRootViewController: UIViewController, source: PlusUpgradeViewSource) {
        self.upgradeRootViewController = upgradeRootViewController
        self.source = source

        super.init(nibName: "UpgradeRequiredViewController", bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "" // L10n.pocketCastsPlus
        
        NotificationCenter.default.addObserver(self, selector: #selector(iapProductsUpdated), name: ServerNotifications.iapProductsUpdated, object: nil)

        upgradePriceLabel()
        
        let closeButton = UIBarButtonItem(image: UIImage(named: "cancel"), style: .done, target: self, action: #selector(doneCicked))
        closeButton.accessibilityLabel = L10n.accessibilityCloseDialog
        navigationItem.leftBarButtonItem = closeButton
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")

        AnalyticsHelper.plusUpgradeViewed(source: source)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        AppTheme.popupStatusBarStyle()
    }
    
    @IBOutlet var learnMoreButton: ThemeableRoundedButton! {
        didSet {
            learnMoreButton.textStyle = .primaryInteractive01
            learnMoreButton.buttonStyle = .primaryUi01
            learnMoreButton.setTitle(L10n.plusMarketingLearnMoreButton, for: .normal)
        }
    }
    
    @IBAction func learnMoreClicked(_ sender: Any) {
        NavigationManager.sharedManager.navigateTo(NavigationManager.showPlusMarketingPageKey, data: nil)
    }
    
    @IBAction func doneCicked(_ sender: Any) {
        AnalyticsHelper.plusUpgradeDismissed(source: source)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func upgradeClicked(_ sender: Any) {
        AnalyticsHelper.plusUpgradeConfirmed(source: source)

        dismiss(animated: true, completion: { [weak self] in
            guard let self = self else { return }

            let presentingController = self.upgradeRootViewController

            guard let offer = IapHelper.shared.introductoryPromo else {
                if SyncManager.isUserLoggedIn() {
                    let newSubscription = NewSubscription(isNewAccount: false, iap_identifier: "")
                    presentingController?.present(SJUIUtils.popupNavController(for: TermsViewController(newSubscription: newSubscription), navStyle: .primaryUi01), animated: true)
                }
                else {
                    presentingController?.present(SJUIUtils.popupNavController(for: ProfileIntroViewController()), animated: true)
                }
                return
            }

            NavigationManager.sharedManager.navigateTo(NavigationManager.showPromotionPageKey, data: [NavigationManager.promotionInfoKey: offer.code as Any])
        })
    }
    
    @objc func iapProductsUpdated() {
        upgradePriceLabel()
    }
    
    // MARK: - Orientation
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}

private extension UpgradeRequiredViewController {
    func checkIntroPromoCode() {
        guard let offer = IapHelper.shared.introductoryPromo else {
            noPaymentLabel.isHidden = true
            return
        }

        infoLabel.text = "Try Pocket Casts Plus free for \(offer.days) days"
        noPaymentLabel.text = "No Payment Required"
        upgradeButton.setTitle("Start Free Trial", for: .normal)
        noPaymentLabel.isHidden = false
    }

    func updateInfoLabel() {
        guard let trial = IapHelper.shared.getFreeTrialDays(.yearly) else {
            checkIntroPromoCode()
            return
        }

        infoLabel.text = "Try Pocket Casts Plus free for \(trial) days"
        upgradeButton.setTitle("Start Free Trial", for: .normal)
        noPaymentLabel.isHidden = false
    }

    func upgradePriceLabel() {
        updateInfoLabel()

        let monthlyPrice = IapHelper.shared.getPriceForIdentifier(identifier: Constants.IapProducts.monthly.rawValue)
        let yearlyPrice = IapHelper.shared.getPriceForIdentifier(identifier: Constants.IapProducts.yearly.rawValue)

        guard !monthlyPrice.isEmpty, !yearlyPrice.isEmpty else {
            return
        }

//        let priceText = L10n.settingsPlusPricingFormat(monthlyPrice, yearlyPrice)
//        priceLabel.text = priceText
        
    }
}
