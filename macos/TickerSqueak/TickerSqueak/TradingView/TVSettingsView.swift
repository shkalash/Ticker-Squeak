import SwiftUI

struct TVSettingsView: View {
    @ObservedObject var viewModel: TVViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack{
                Text("TradingView Integration")
                    .font(.headline)
                
                Image(systemName: viewModel.hasAccessToAccessibilityAPI ? "checkmark.shield" : "exclamationmark.shield")
                    .foregroundColor(viewModel.hasAccessToAccessibilityAPI ? Color.green : Color.red).padding(.horizontal , 4)
                
                Button(action: {
                    viewModel.requestAccess()
                }) {
                    Image(systemName: "arrow.clockwise")
                }.buttonStyle(.plain)
                
            }
            Toggle("Enable TradingView Automation", isOn: $viewModel.settings.useTradingView)
            Divider()
            Group {
                Toggle("Switch Tab", isOn: $viewModel.settings.changeTab)
                    .disabled(!viewModel.settings.useTradingView)

                HStack {
                    Text("Modifier Key")
                    Picker("", selection: $viewModel.settings.tabModifier) {
                        ForEach(TVSettingsData.ModifierKey.allCases) { modifier in
                            Text(modifier.displayName).tag(modifier)
                        }
                    }
                    .frame(width: 130)
                }
                .disabled(!viewModel.settings.useTradingView || !viewModel.settings.changeTab)
                
                HStack {
                    Text("Tab Number")
                    Picker("", selection: $viewModel.settings.tabNumber) {
                        ForEach(0..<10) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                    .frame(width: 80)
                }
                .disabled(!viewModel.settings.useTradingView || !viewModel.settings.changeTab)
            }

            Divider()

            Text("Delays (seconds)")
                .font(.headline)

            Group {
                delayField("Before Tab Change", value: $viewModel.settings.delayBeforeTab)
                delayField("Before Typing", value: $viewModel.settings.delayBeforeTyping)
                delayField("Between Characters", value: $viewModel.settings.delayBetweenCharacters , step: 0.01)
            }
            .disabled(!viewModel.settings.useTradingView)

            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    func delayField(
        _ label: String,
        value: Binding<TimeInterval>,
        step: TimeInterval = 0.05
    ) -> some View {
        HStack {
            Text(label)
            Spacer()
            Stepper(value: value, in: 0...5, step: step) {
                TextField("", value: value, format: .number.precision(.fractionLength(2)))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 60)
            }
        }
    }
}

#Preview {
    TVSettingsView(viewModel: TVViewModel())
}
