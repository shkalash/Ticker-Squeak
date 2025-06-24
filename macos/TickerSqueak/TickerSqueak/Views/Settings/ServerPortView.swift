//
//  SettingsView.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/22/25.
//

import SwiftUI

struct ServerPortView: View {
    private let minPort = 1
    private let maxPort = 65535
    
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()
    @ObservedObject var viewModel: TickerSqueakViewModel
    @State private var portText:Int = 1
    var body: some View {
        VStack{
            HStack{
                Text("Server Port:")
                TextField("Port", value: $portText, formatter: formatter)
                .onChange(of: portText){
                    if (portText < minPort || portText > maxPort){
                        portText = viewModel.serverPort
                    }
                }
                .frame(width: 100)
            }
            HStack {
                Button {
                    portText = viewModel.serverPort
                } label: {
                    Label("Revert", systemImage: "arrow.uturn.left")
                }.disabled(portText == viewModel.serverPort)

                Spacer()

                Button {
                    viewModel.setServerPort(portText)
                } label: {
                    Label("Apply", systemImage: "checkmark.circle.fill")
                }.disabled(portText == viewModel.serverPort)
            }
            .frame(width: 240)

        }
        .onAppear(){
            portText = viewModel.serverPort
        }
    }
}
#Preview {
    ServerPortView(viewModel: TickerSqueakViewModel())
}
