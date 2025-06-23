//
//  SettingsView.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/22/25.
//


import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SymbolNotifierViewModel
    @ObservedObject var tvSettingsViewModel: TVViewModel
    @ObservedObject var oneOptionViewModel : OneOptionViewModel
    @AppStorage("settingsTabIndex") private var selectedTab: Int = 0


    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            IconTabPicker(selection: $selectedTab, options: [
                PickerOption(label: "", imageName: "dot.radiowaves.left.and.right", tag: 0),
                PickerOption(label: "", imageName: "speaker.wave.2.fill", tag: 1),
                PickerOption(label: "", imageName: "tradingview", tag: 2, imageType: .asset),
                PickerOption(label: "", imageName: "oneoption", tag: 3 , imageType: .asset),
            ])
            .padding(.bottom, 8)
            
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case 0:
                        ServerPortView(viewModel: viewModel)
                        ServerStatusView(viewModel: viewModel)
                        Divider()
                            RemovalDelayEditorView(removalDelay: $viewModel.removalDelay)
                    case 1:
                        AlertMessageSettingsView(viewModel: viewModel)
                    case 2:
                        TVSettingsView(viewModel: tvSettingsViewModel)
                    case 3:
                        OneOptionSettingsView(viewModel: oneOptionViewModel)
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
    SettingsView(viewModel: SymbolNotifierViewModel(), tvSettingsViewModel: TVViewModel() , oneOptionViewModel: OneOptionViewModel())
}
