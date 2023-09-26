import SwiftUI
import PocketCastsDataModel

struct RatePodcastView: View {
    @ObservedObject var viewModel: RatePodcastViewModel

    @EnvironmentObject var theme: Theme

    init(viewModel: RatePodcastViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                Spacer()
                content
                Spacer()
                Button("Done") {

                }
                .buttonStyle(BasicButtonStyle(textColor: .white, backgroundColor: .black))
            }

            Image("close")
                .renderingMode(.template)
                .foregroundStyle(theme.primaryText01)
                .buttonize {

                }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .applyDefaultThemeOptions()
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.userCanRate {
        case .checking:
            ProgressView()
                .controlSize(.large)
                .foregroundStyle(theme.primaryIcon01)
        case .allowed:
            EmptyView()
        case .disallowed:
            cannotRate
        }
    }

    private var cannotRate: some View {
        Group {
            PodcastCover(podcastUuid: viewModel.podcastUuid, big: true)
                .frame(width: 164, height: 164)
                .padding(.bottom, 40)
            Text(L10n.ratingListenToThisPodcastTitle)
                .font(size: 20, style: .title3, weight: .bold)
                .padding(.bottom, 16)
            Text(L10n.ratingListenToThisPodcastMessage)
                .font(style: .body)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    RatePodcastView(viewModel: RatePodcastViewModel(presented: .constant(true), podcastUuid: Podcast.previewPodcast().uuid))
        .environmentObject(Theme.sharedTheme)
}
