
import SwiftUI

@available(iOS 17.0, *)
struct GenerativeHealthCoachView: View {
    @EnvironmentObject var coach: GenerativeHealthCoach

    @State private var query: String = ""
    @State private var conversation: [(question: String, answer: String)] = []
    @State private var isThinking: Bool = false

    var body: some View {
        VStack {
            Text("Generative Health Coach")
                .font(.largeTitle)
                .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    ForEach(conversation, id: \.question) { turn in
                        Text("You: \(turn.question)")
                            .font(.headline)
                        Text("Coach: \(turn.answer)")
                            .padding(.bottom, 10)
                    }
                }
                .padding()
            }

            if isThinking {
                ProgressView()
                    .padding()
            }

            HStack {
                TextField("Ask a health question...", text: $query)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading)

                Button(action: askQuestion) {
                    Text("Send")
                }
                .padding(.trailing)
                .disabled(query.isEmpty || isThinking)
            }
            .padding()
        }
        .navigationTitle("AI Coach")
    }

    private func askQuestion() {
        let userQuestion = query
        query = ""
        isThinking = true

        Task {
            do {
                let answer = try await coach.answerQuery(query: userQuestion)
                conversation.append((question: userQuestion, answer: answer))
            } catch {
                conversation.append((question: userQuestion, answer: "Sorry, I had trouble getting a response. Please try again."))
            }
            isThinking = false
        }
    }
}
