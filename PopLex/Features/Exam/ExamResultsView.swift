import SwiftUI

struct ExamResultsView: View {
    let questions: [ExamQuestion]
    let answers: [ExamAnswer]
    let score: Int
    let onRetake: () -> Void
    let onDismiss: () -> Void

    private var wrongAnswers: [(question: ExamQuestion, answer: ExamAnswer)] {
        var result: [(question: ExamQuestion, answer: ExamAnswer)] = []
        for answer in answers where !answer.isCorrect {
            if let question = questions.first(where: { $0.id == answer.questionID }) {
                result.append((question, answer))
            }
        }
        return result
    }

    private var scorePercentage: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(score) / Double(questions.count)
    }

    private var scoreMessage: String {
        if scorePercentage >= 0.8 {
            return "太棒了！"
        } else if scorePercentage >= 0.6 {
            return "不错的开始！"
        } else if scorePercentage >= 0.4 {
            return "继续加油！"
        } else {
            return "别灰心，多练习！"
        }
    }

    private var scoreColor: Color {
        if scorePercentage >= 0.8 {
            return PopLexTheme.primaryBlue
        } else if scorePercentage >= 0.6 {
            return PopLexTheme.primaryOrange
        } else {
            return PopLexTheme.primaryPink
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                scoreCard

                if !wrongAnswers.isEmpty {
                    wrongAnswersSection
                }

                actionButtons
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
    }

    private var scoreCard: some View {
        PopLexSurface {
            VStack(spacing: 20) {
                Text(scoreMessage)
                    .font(.custom("AvenirNext-Bold", size: 28))
                    .foregroundStyle(PopLexTheme.ink)

                ZStack {
                    Circle()
                        .stroke(scoreColor.opacity(0.15), lineWidth: 14)
                        .frame(width: 140, height: 140)

                    Circle()
                        .trim(from: 0, to: scorePercentage)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 4) {
                        Text("\(score)/\(questions.count)")
                            .font(.custom("AvenirNext-Bold", size: 36))
                            .foregroundStyle(PopLexTheme.ink)

                        Text("正确率")
                            .font(.custom("AvenirNext-Regular", size: 14))
                            .foregroundStyle(PopLexTheme.ink.opacity(0.6))
                    }
                }

                HStack(spacing: 32) {
                    statItem(value: "\(score)", label: "答对", color: PopLexTheme.primaryBlue)
                    statItem(value: "\(questions.count - score)", label: "答错", color: PopLexTheme.primaryPink)
                    statItem(value: "\(questions.count)", label: "总题数", color: PopLexTheme.ink.opacity(0.5))
                }
            }
        }
    }

    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.custom("AvenirNext-Bold", size: 24))
                .foregroundStyle(color)

            Text(label)
                .font(.custom("AvenirNext-Regular", size: 13))
                .foregroundStyle(PopLexTheme.ink.opacity(0.6))
        }
    }

    private var wrongAnswersSection: some View {
        PopLexSurface {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("错题复习")
                        .font(.custom("AvenirNext-Bold", size: 22))
                        .foregroundStyle(PopLexTheme.ink)

                    Spacer()

                    Text("\(wrongAnswers.count) 题")
                        .font(.custom("AvenirNext-DemiBold", size: 14))
                        .foregroundStyle(PopLexTheme.primaryPink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(PopLexTheme.primaryPink.opacity(0.12), in: Capsule())
                }

                ForEach(wrongAnswers, id: \.question.id) { item in
                    wrongAnswerRow(question: item.question, answer: item.answer)
                }
            }
        }
    }

    private func wrongAnswerRow(question: ExamQuestion, answer: ExamAnswer) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(question.word)
                    .font(.custom("AvenirNext-Bold", size: 18))
                    .foregroundStyle(PopLexTheme.ink)

                Spacer()

                Text("正确答案：\(question.correctAnswer)")
                    .font(.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundStyle(PopLexTheme.primaryBlue)
            }

            HStack(spacing: 6) {
                Text("你的答案：")
                    .font(.custom("AvenirNext-DemiBold", size: 13))
                    .foregroundStyle(PopLexTheme.ink.opacity(0.6))

                Text("\"\(answer.selectedOption)\"")
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .foregroundStyle(PopLexTheme.primaryPink)
                    .strikethrough()
            }

            Text(question.explanation)
                .font(.custom("AvenirNext-Regular", size: 14))
                .foregroundStyle(PopLexTheme.ink.opacity(0.75))
        }
        .padding(16)
        .background(
            PopLexTheme.primaryPink.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private var actionButtons: some View {
        VStack(spacing: 14) {
            Button {
                onRetake()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.clockwise")
                    Text("再做一次")
                        .font(.custom("AvenirNext-Bold", size: 17))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [PopLexTheme.primaryPink, PopLexTheme.primaryBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                )
            }
            .buttonStyle(.plain)

            Button {
                onDismiss()
            } label: {
                Text("返回笔记本")
                    .font(.custom("AvenirNext-DemiBold", size: 16))
                    .foregroundStyle(PopLexTheme.ink.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(PopLexTheme.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}
