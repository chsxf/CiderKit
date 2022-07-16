//
//  EditorMainView.swift
//  CiderKit-Editor
//
//  Created by Christophe SAUVEUR on 15/04/2022.
//

import SwiftUI

struct EditorMainView: View {
    
    private var gameView: EditorGameView
    
    init(gameView: EditorGameView) {
        self.gameView = gameView
    }
    
    var body: some View {
        HStack {
            EditorGameViewRepresentable(gameView: gameView)
            InspectorView()
                .environmentObject(gameView.selectionModel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
