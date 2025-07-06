import SwiftUI
import PDFKit

struct OfflineDocumentView: View {
    let documentPath: String
    var body: some View {
        if let url = Bundle.main.url(forResource: documentPath, withExtension: nil),
           let pdfDoc = PDFDocument(url: url) {
            PDFKitView(document: pdfDoc)
        } else {
            Text("Document not available")
                .foregroundColor(.secondary)
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        return pdfView
    }
    func updateUIView(_ uiView: PDFView, context: Context) {}
}
