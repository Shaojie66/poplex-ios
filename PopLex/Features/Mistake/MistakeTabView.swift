import SwiftUI

struct MistakeTabView: View {
    @Environment(PopLexAppModel.self) private var model

    var body: some View {
        NavigationStack {
            Group {
                if model.wrongAnswers.isEmpty {
                    emptyState
                } else {
                    WrongAnswerListView(
                        wrongAnswers: model.wrongAnswers,
                        onRemove: model.removeWrongAnswer,
                        onReLearn: { wrongAnswer in
                            model.queryText = wrongAnswer.word
                            model.selectedTab = .lookup
                        }
                    )
                }
            }
            .navigationTitle("错题")
            .popLexNavigationChromeHidden()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64, weight: .black))
                .foregroundStyle(PopLexTheme.primaryBlue.opacity(0.6))

            VStack(spacing: 10) {
                Text("还没错题，继续保持")
                    .font(.custom("AvenirNext-DemiBold", size: 22))
                    .foregroundStyle(PopLexTheme.ink)

                Text("做几道真题，检验一下学习效果")
                    .font(.custom("AvenirNext-Regular", size: 16))
                    .foregroundStyle(PopLexTheme.ink.opacity(0.72))
                    .multilineTextAlignment(.center)
            }

            Button {
                model.startExam()
            } label: {
                Text("去做真题")
                    .font(.custom("AvenirNext-DemiBold", size: 15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [PopLexTheme.primaryPink, PopLexTheme.primaryBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
            }
            .buttonStyle(.plain)

            if model.notebook.count < 3 {
                Text("需要在笔记本中至少添加3个单词")
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .foregroundStyle(PopLexTheme.ink.opacity(0.52))
            }

            Spacer()
        }
        .padding(.horizontal, 40)
    }
}