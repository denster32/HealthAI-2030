import Foundation
import Combine

@available(iOS 17.0, *)
@available(macOS 14.0, *)
class SkillDownloader: ObservableObject {
    @Published var downloadProgress: Double = 0.0
    @Published var isDownloading = false
    private var downloadTask: URLSessionDownloadTask?
    private var cancellables = Set<AnyCancellable>()

    func downloadSkill(from url: URL, to destination: URL) -> AnyPublisher<URL, Error> {
        isDownloading = true
        downloadProgress = 0.0

        let subject = PassthroughSubject<URL, Error>()

        downloadTask = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            guard let self = self else { return }
            self.isDownloading = false

            if let error = error {
                subject.send(completion: .failure(error))
                return
            }

            guard let tempURL = tempURL else {
                subject.send(completion: .failure(URLError(.badServerResponse)))
                return
            }

            do {
                try FileManager.default.moveItem(at: tempURL, to: destination)
                subject.send(destination)
                subject.send(completion: .finished)
            } catch {
                subject.send(completion: .failure(error))
            }
        }
        
        downloadTask?.publisher(for: \.progress.fractionCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.downloadProgress = progress
            }
            .store(in: &cancellables)

        downloadTask?.resume()

        return subject.eraseToAnyPublisher()
    }

    func cancelDownload() {
        downloadTask?.cancel()
        isDownloading = false
    }
}
