import SwiftUI

struct FloatingLauncherView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 48, height: 48)

                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .bold))
                    .padding(6)
            }
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.accentColor.gradient)
            )
        }
        .buttonStyle(.plain)
        .help("展开命令口袋")
        .accessibilityLabel("展开命令口袋")
    }
}

