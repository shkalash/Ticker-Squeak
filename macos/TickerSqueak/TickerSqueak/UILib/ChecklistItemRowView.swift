//
//  to.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 7/4/25.
//


import SwiftUI

/// A view that renders a single row for any type of checklist item.
/// It takes a generic ViewModel that conforms to the base protocol to get bindings and perform actions.
struct ChecklistItemRowView: View {
    let item: ChecklistItem
    let viewModel: any ChecklistViewModelProtocol
    
    // For the Trade Idea context, which is optional
    var tradeIdea: TradeIdea? = nil
   
    var body: some View {
        
        // The switch handles the rendering for each item type.
        switch item.type {
            case .checkbox(let text):
                
                Toggle(isOn: viewModel.binding(for: item.id).isChecked) {
                    Text(text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
                .toggleStyle(.checkbox)
                .padding(.vertical, 4)
                
            case .textInput(let prompt):
                VStack(alignment: .leading, spacing: 6) {
                    Text(prompt).font(.callout).foregroundColor(.secondary)
                    ScrollFriendlyTextEditor(text: viewModel.binding(for: item.id).userText)
                        .font(.body)
                        .frame(minHeight: 80)
                        .padding(4)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.5)))
                }
                .padding(.vertical, 4)
                .padding(.trailing, 40)
                
            case .image(let caption):
                VStack(alignment: .leading, spacing: 6) {
                    Text(caption).font(.callout).foregroundColor(.secondary)
                    // We determine the correct context to pass to the image well.
                    if let context = imageContext {
                        MultiImageWellView(
                            imageFileNames: viewModel.binding(for: item.id).imageFileNames,
                            context: context,
                            onPaste: { images in
                                Task { await viewModel.savePastedImages(images, forItemID: item.id) }
                            },
                            onDelete: { filename in
                                viewModel.deletePastedImage(filename: filename, forItemID: item.id)
                            }
                        )
                    } else {
                        Text("Context not available for images.").font(.caption).foregroundColor(.red)
                    }
                }
                .padding(.vertical, 4)
                
            case .picker(let prompt, let options):
                Picker(
                    prompt,
                    selection: viewModel.binding(for: item.id).selectedOption
                ) {
                    Text("Select...").tag(String?.none)
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(String?(option))
                    }
                }
                .pickerStyle(.menu)
                .padding(.vertical, 4)
                
            case .dynamicPicker(let prompt, let optionsKey):
                let options = viewModel.options(for: optionsKey)
                Picker(prompt, selection: viewModel.binding(for: item.id).selectedOption) {
                    Text("Select...").tag(String?.none)
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(String?(option))
                    }
                }
                .pickerStyle(.menu)
                .padding(.vertical, 4)
        
        }
    }
    
    /// A helper to determine the correct image context.
    private var imageContext: ChecklistContext? {
        if let idea = tradeIdea {
            return .tradeIdea(id: idea.id)
        } else if let preMarketViewModel = viewModel as? PreMarketChecklistViewModel, let date = preMarketViewModel.checklistDate {
            return .preMarket(date: date)
        }
        return nil
    }
}
