//
//  SystemSoundPickerView.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/22/25.
//


import SwiftUI
import AppKit

struct AlertMessageSettingsView: View {
    @ObservedObject var viewModel: SymbolNotifierViewModel
    var body: some View {
        VStack(alignment: .leading , spacing: 12){
            HStack{
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Alert Sound")
            }
            HStack {
                Picker("Alert Sound", selection: $viewModel.alertSound) {
                    ForEach(NSSound.bundledSoundNames, id: \.self) { sound in
                        Text(sound).tag(sound)
                    }
                }
                .labelsHidden()
                .frame(width: 200)
                
                Button {
                    NSSound(named: viewModel.alertSound)?.play()
                } label: {
                    Label("Play", systemImage: "play.circle.fill")
                }
                .buttonStyle(.bordered)
            }
            HStack{
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.yellow)
                Text("High Priority Sound")
            }
            
            HStack {
                Picker("High Priority Sound", selection: $viewModel.highPriorityAlertSound) {
                    ForEach(NSSound.bundledSoundNames, id: \.self) { sound in
                        Text(sound).tag(sound)
                    }
                }
                .labelsHidden()
                .frame(width: 200)
                
                Button {
                    NSSound(named: viewModel.highPriorityAlertSound)?.play()
                } label: {
                    Label("Play", systemImage: "play.circle.fill")
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview {
    AlertMessageSettingsView(viewModel: SymbolNotifierViewModel())
}
