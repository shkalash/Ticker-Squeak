//
//  SystemSoundPickerView.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/22/25.
//


import SwiftUI
import AppKit

struct ToastSoundPickerView: View {
    @ObservedObject var viewModel: SymbolNotifierViewModel
    var body: some View {
        VStack(alignment: .leading){
            Text("Toast Message Sound")
            HStack {
                Picker("Toast Sound", selection: $viewModel.toastSound) {
                    ForEach(NSSound.systemSoundNames, id: \.self) { sound in
                        Text(sound).tag(sound)
                    }
                }
                .labelsHidden()
                .frame(width: 200)
                
                Button {
                    NSSound(named: viewModel.toastSound)?.play()
                } label: {
                    Label("Play", systemImage: "play.circle.fill")
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview {
    ToastSoundPickerView(viewModel: SymbolNotifierViewModel())
}
