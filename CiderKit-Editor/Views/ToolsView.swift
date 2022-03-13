//
//  ToolsView.swift
//  CiderKit
//
//  Created by Christophe SAUVEUR on 13/03/2022.
//

import SwiftUI

struct ToolData: Identifiable {
    let name: String
    let action: (ToolsView) -> Void
    var id: String { name }
}

protocol ToolsDelegate {
    
    func increaseElevation(area: MapArea?)
    func decreaseElevation(area: MapArea?)
    
}

struct ToolsView: View {
    @EnvironmentObject var selectionModel: SelectionModel
    
    var delegate: ToolsDelegate?
    
    let items = [
        ToolData(name: "arrow_up", action: { $0.delegate?.increaseElevation(area: $0.selectionModel.selectedArea!) } ),
        ToolData(name: "arrow_down", action: { $0.delegate?.decreaseElevation(area: $0.selectionModel.selectedArea!) })
    ]
    
    let columns = [
        GridItem(.fixed(32)),
        GridItem(.fixed(32))
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 5) {
            ForEach(items) { item in
                let button = Button(action: { item.action(self) }) {
                    Image(item.name)
                }
                .frame(width: 32, height: 32)
                .buttonStyle(.borderless)
                if selectionModel.selectedArea == nil {
                    button
                        .disabled(true)
                        .opacity(0.25)
                }
                else {
                    button
                }
            }
        }
        .padding(5)
        .frame(height: 400, alignment: .topLeading)
    }
}

struct ToolsView_Previews: PreviewProvider {
    static var previews: some View {
        ToolsView()
    }
}
