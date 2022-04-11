//
//  EditorMainView.swift
//  CiderKit-Editor
//
//  Created by Christophe SAUVEUR on 15/04/2022.
//

import SwiftUI

struct EditorMainView: View {
    var body: some View {
        HStack {
            EditorGameViewRepresentable()
            InspectorView()
                .environmentObject(EditorGameViewRepresentable.gameView!.selectionModel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EditorMainView_Previews: PreviewProvider {
    static var previews: some View {
        EditorMainView()
    }
}
