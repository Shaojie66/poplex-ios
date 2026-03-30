import SwiftUI

struct WrongAnswerListView: View {
    let wrongAnswers: [WrongAnswer]
    let onRemove: (WrongAnswer) -> Void
    let onReLearn: (WrongAnswer) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                ForEach(wrongAnswers) { wrongAnswer in
                    WrongAnswerCard(
                        wrongAnswer: wrongAnswer,
                        onRemove: { onRemove(wrongAnswer) },
                        onReLearn: { onReLearn(wrongAnswer) }
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
    }
}

private struct WrongAnswerCard: View {
    let wrongAnswer: WrongAnswer
    let onRemove: () -> Void
    let onReLearn: () -> Void

    var body: some View {
        PopLexSurface {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    Text(wrongAnswer.word)
                        .font(.custom("AvenirNext-Bold", size: 24))
                        .foregroundStyle(PopLexTheme.ink)

                    Spacer()

                    Button(action: onRemove) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(PopLexTheme.primaryPink, in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("你的答案：")
                            .font(.custom("AvenirNext-DemiBold", size: 14))
                            .foregroundStyle(PopLexTheme.ink.opacity(0.6))

                        Text("\"\(wrongAnswer.userAnswer)\"")
                            .font(.custom("AvenirNext-Regular", size: 14))
                            .foregroundStyle(PopLexTheme.primaryPink)
                            .strikethrough()
                    }

                    HStack(spacing: 6) {
                        Text("正确答案：")
                            .font(.custom("AvenirNext-DemiBold", size: 14))
                            .foregroundStyle(PopLexTheme.ink.opacity(0.6))

                        Text("\"\(wrongAnswer.correctAnswer)\"")
                            .font(.custom("AvenirNext-Regular", size: 14))
                            .foregroundStyle(PopLexTheme.primaryBlue)
                    }
                }

                HStack {
                    Text("错题时间：\(wrongAnswer.recordedAt, style: .date)")
                        .font(.custom("AvenirNext-Regular", size: 13))
                        .foregroundStyle(PopLexTheme.ink.opacity(0.52))

                    Spacer()

                    Button(action: onReLearn) {
                        Text("重新学习")
                            .font(.custom("AvenirNext-DemiBold", size: 14))
                            .foregroundStyle(PopLexTheme.primaryBlue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(PopLexTheme.primaryBlue.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}