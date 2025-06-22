//
//  SettingsView.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/22/25.
//


import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SymbolNotifierViewModel
    @ObservedObject var tvSettingsViewModel: TVSettingsViewModel

    @AppStorage("settingsTabIndex") private var selectedTab: Int = 0


    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            IconTabPicker(selection: $selectedTab, options: [
                ("Server", "dot.radiowaves.left.and.right", 0),
                ("Audio", "speaker.wave.2.fill", 1),
                ("TradingView", "chart.line.uptrend.xyaxis", 2),
            ])
            .padding(.bottom, 8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case 0:
                        ServerPortView(viewModel: viewModel)
                        ServerStatusView(viewModel: viewModel)
                    case 1:
                        ToastSoundPickerView(viewModel: viewModel)
                    case 2:
                        TVSettingsView(viewModel: tvSettingsViewModel)
                    default:
                        EmptyView()
                    }
                }
                .padding()
            }
        }
    }
}
#Preview {
    SettingsView(viewModel: SymbolNotifierViewModel(), tvSettingsViewModel: TVSettingsViewModel())
}
