import SwiftUI

/// Sign Up step 3 of 3. Single-column list of large cards (not a dense icon grid) —
/// the biggest mis-tap risk for users with tremor or low dexterity is small adjacent
/// targets. Selection is capped at 4; once reached, unselected cards dim and further
/// taps are ignored until one is deselected.
struct SignUpGenresView: View {
    @Binding var path: [Route]
    @EnvironmentObject var appState: AppState

    private var count: Int { appState.selectedGenres.count }
    private var atMax: Bool { count >= AppState.maxGenres }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Step 3 of 3")
                    .foregroundColor(AppColors.muted)
                Text("Pick your favorite music")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.ink)
                Text(atMax ? "Maximum of 4 selected" : "Choose up to 4 (\(count) selected)")
                    .foregroundColor(AppColors.muted)
                    .padding(.bottom, 8)

                ForEach(Genre.allCases) { genre in
                    genreCard(genre)
                }

                Button("Finish") {
                    path.append(.home)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 10)
            }
            .padding(20)
        }
        .background(AppColors.bg)
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func genreCard(_ genre: Genre) -> some View {
        let isSelected = appState.selectedGenres.contains(genre)
        let dimmed = atMax && !isSelected
        return Button {
            appState.toggleGenre(genre)
        } label: {
            HStack {
                Text(genre.rawValue)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.ink)
                Spacer()
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? AppColors.primary : AppColors.border, lineWidth: 2)
                        .background(Circle().fill(isSelected ? AppColors.primary : Color.clear))
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(16)
            .background(isSelected ? AppColors.selectedCardBg : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? AppColors.primary : AppColors.border, lineWidth: 2)
            )
            .cornerRadius(14)
            .opacity(dimmed ? 0.45 : 1)
        }
    }
}
