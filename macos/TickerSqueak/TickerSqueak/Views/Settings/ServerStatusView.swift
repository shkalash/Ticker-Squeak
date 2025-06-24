//
//  ServerStatusView.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/22/25.
//


import SwiftUI

import SwiftUI

struct ServerStatusView: View {
    @ObservedObject var viewModel: TickerSqueakViewModel

    @State private var isButtonDisabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Server Status")
                .font(.headline)

            HStack(spacing: 12) {
                Circle()
                    .fill(viewModel.isServerRunning ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isServerRunning)

                Text(viewModel.isServerRunning ? "Listening on Port : " + String(format: "%d", viewModel.serverPort) : "Stopped")
                    .foregroundColor(.secondary)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isServerRunning)

                Spacer()

                Button {
                    isButtonDisabled = true

                    if viewModel.isServerRunning {
                        viewModel.stopServer()
                    } else {
                        viewModel.startServer()
                    }

                    // Briefly disable to avoid accidental spamming
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isButtonDisabled = false
                    }
                } label: {
                    Label(
                        viewModel.isServerRunning ? "Stop" : "Start",
                        systemImage: viewModel.isServerRunning ? "power.circle" : "figure.run.square.stack"
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .foregroundColor(viewModel.isServerRunning ? .red : .cyan)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(isButtonDisabled)
            }
        }
    }
}

#Preview {
    ServerStatusView(viewModel: TickerSqueakViewModel())
}
