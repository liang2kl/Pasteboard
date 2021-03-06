//
//  IntroView.swift
//  IntroView
//
//  Created by liang2kl on 2021/8/5.
//

import SwiftUI

struct IntroView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Pasteboard")
                .bold()
                .font(.title)
            
            Form {
                Label("INTROVIEW_RECORDED", systemImage: "arrow.triangle.2.circlepath.doc.on.clipboard")
                    .padding(.bottom, 8)
                Label("INTROVIEW_CLICK_COPY", systemImage: "cursorarrow.rays")
                    .padding(.bottom, 8)
                Label("INTROVIEW_RIGHT_CLICK_PIN", systemImage: "cursorarrow.click")
                    .padding(.bottom, 8)
                Label("INTROVIEW_DRAG", systemImage: "cursorarrow.and.square.on.square.dashed")
            }
            .font(.title3)
            
            Button("OK") {
                (NSApp.delegate as? AppDelegate)?.introWindow?.close()
            }
        }
        .frame(minWidth: 350, maxWidth: 400, minHeight: 250, maxHeight: 300)
    }
}

struct IntroView_Previews: PreviewProvider {
    static var previews: some View {
        IntroView()
    }
}
