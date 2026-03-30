import SwiftUI

struct ExamView: View {
    @Environment(PopLexAppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex: Int = 0
    @State private var selectedOption: String?
    @State private var hasAnswered: Bool = false
    @State private var answers: [ExamAnswer] = []
    @State private var score: Int = 0
    @State private var isGenerating: Bool = false
    @State private var errorMessage: String?
    @State private var questions: [ExamQuestion] = []
    @State private var showingResults: Bool = false
    @State private var generationTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            PopLexBackdrop()

            if isGenerating {
                generatingView
            } else if showingResults {
                ExamResultsView(
                    questions: questions,
                    answers: answers,
                    score: score,
                    onRetake: retakeExam,
                    onDismiss: { dismiss() }
                )
            } else if let error = errorMessage {
                errorView(message: error)
            } else if currentIndex < questions.count {
                questionView
            }
        }
        .navigationTitle("真题")
        .popLexNavigationChromeHidden()
        .onAppear {
            generateExam()
        }
        .onDisappear {
            generationTask?.cancel()
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56, weight: .black))
                .foregroundStyle(PopLexTheme.primaryPink.opacity(0.7))

            Text(message)
                .font(.custom("AvenirNext-DemiBold", size: 18))
                .foregroundStyle(PopLexTheme.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                retakeExam()
            } label: {
                Text("重试")
                    .font(.custom("AvenirNext-Bold", size: 16))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
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

            Spacer()
        }
    }

    private var generatingView: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .tint(PopLexTheme.primaryPink)
                .scaleEffect(1.4)

            Text("生成题目中...")
                .font(.custom("AvenirNext-DemiBold", size: 20))
                .foregroundStyle(PopLexTheme.ink)

            Spacer()
        }
    }

    private var questionView: some View {
        VStack(spacing: 0) {
            progressHeader

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if let question = questions[safe: currentIndex] {
                        questionCard(for: question)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 120)
            }
        }
    }

    private var progressHeader: some View {
        PopLexSurface {
            HStack {
                Text("第 \(currentIndex + 1) 题 / 共 \(questions.count) 题")
                    .font(.custom("AvenirNext-DemiBold", size: 15))
                    .foregroundStyle(PopLexTheme.ink.opacity(0.7))

                Spacer()

                Text("正确: \(score)")
                    .font(.custom("AvenirNext-Bold", size: 15))
                    .foregroundStyle(PopLexTheme.primaryBlue)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private func questionCard(for question: ExamQuestion) -> some View {
        PopLexSurface {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("选出与下划线词汇意义最接近的选项")
                        .font(.custom("AvenirNext-Regular", size: 14))
                        .foregroundStyle(PopLexTheme.ink.opacity(0.6))

                    Text(question.word)
                        .font(.custom("AvenirNext-Bold", size: 36))
                        .foregroundStyle(PopLexTheme.primaryPink)
                }

                VStack(spacing: 12) {
                    ForEach(Array(question.options.enumerated()), id: \.offset) { _, option in
                        optionButton(option: option, question: question)
                    }
                }

                if hasAnswered, let selected = selectedOption {
                    explanationSection(
                        selected: selected,
                        correct: question.correctAnswer,
                        explanation: question.explanation
                    )

                    Button {
                        advanceToNext()
                    } label: {
                        Text(currentIndex < questions.count - 1 ? "下一题" : "查看结果")
                            .font(.custom("AvenirNext-Bold", size: 17))
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
                }
            }
        }
    }

    private func optionButton(option: String, question: ExamQuestion) -> some View {
        let isSelected = selectedOption == option
        let isCorrect = option == question.correctAnswer
        let showResult = hasAnswered

        return Button {
            guard !hasAnswered else { return }
            selectOption(option, isCorrect: isCorrect)
        } label: {
            HStack {
                Text(option)
                    .font(.custom("AvenirNext-Medium", size: 17))
                    .foregroundStyle(foregroundColor(for: option, isSelected: isSelected, isCorrect: isCorrect, showResult: showResult))
                    .strikethrough(showResult && isSelected && !isCorrect)

                Spacer()

                if showResult {
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(PopLexTheme.primaryBlue)
                    } else if isSelected {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(PopLexTheme.primaryPink)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(backgroundColor(for: option, isSelected: isSelected, isCorrect: isCorrect, showResult: showResult), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(borderColor(for: option, isSelected: isSelected, isCorrect: isCorrect, showResult: showResult), lineWidth: showResult ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(hasAnswered)
    }

    private func foregroundColor(for option: String, isSelected: Bool, isCorrect: Bool, showResult: Bool) -> Color {
        if showResult {
            if isCorrect { return PopLexTheme.primaryBlue }
            if isSelected && !isCorrect { return PopLexTheme.primaryPink }
        }
        if isSelected { return PopLexTheme.primaryPink }
        return PopLexTheme.ink
    }

    private func backgroundColor(for option: String, isSelected: Bool, isCorrect: Bool, showResult: Bool) -> Color {
        if showResult {
            if isCorrect { return PopLexTheme.primaryBlue.opacity(0.1) }
            if isSelected && !isCorrect { return PopLexTheme.primaryPink.opacity(0.1) }
        }
        if isSelected { return PopLexTheme.primaryPink.opacity(0.08) }
        return .white.opacity(0.6)
    }

    private func borderColor(for option: String, isSelected: Bool, isCorrect: Bool, showResult: Bool) -> Color {
        if showResult {
            if isCorrect { return PopLexTheme.primaryBlue }
            if isSelected && !isCorrect { return PopLexTheme.primaryPink }
        }
        if isSelected { return PopLexTheme.primaryPink.opacity(0.5) }
        return .white.opacity(0.4)
    }

    private func explanationSection(selected: String, correct: String, explanation: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(selected == correct ? "✓ 正确！" : "✗ 不对哦")
                    .font(.custom("AvenirNext-Bold", size: 16))
                    .foregroundStyle(selected == correct ? PopLexTheme.primaryBlue : PopLexTheme.primaryPink)

                if selected != correct {
                    Text("正确答案：\(correct)")
                        .font(.custom("AvenirNext-DemiBold", size: 14))
                        .foregroundStyle(PopLexTheme.primaryBlue)
                }
            }

            Text(explanation)
                .font(.custom("AvenirNext-Regular", size: 15))
                .foregroundStyle(PopLexTheme.ink.opacity(0.78))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (selected == correct ? PopLexTheme.primaryBlue : PopLexTheme.primaryPink).opacity(0.08),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private func selectOption(_ option: String, isCorrect: Bool) {
        selectedOption = option
        hasAnswered = true

        let answer = ExamAnswer(
            questionID: questions[currentIndex].id,
            selectedOption: option,
            isCorrect: isCorrect
        )
        answers.append(answer)
        if isCorrect {
            score += 1
        }

        if !isCorrect {
            model.recordWrongAnswer(
                questionID: questions[currentIndex].id.uuidString,
                word: questions[currentIndex].word,
                userAnswer: option,
                correctAnswer: questions[currentIndex].correctAnswer
            )
        }
    }

    private func advanceToNext() {
        if currentIndex < questions.count - 1 {
            currentIndex += 1
            selectedOption = nil
            hasAnswered = false
        } else {
            showingResults = true
        }
    }

    private func generateExam() {
        guard model.notebook.count >= 3 else {
            errorMessage = "需要在笔记本中至少添加3个单词才能开始真题练习"
            return
        }

        isGenerating = true
        errorMessage = nil

        generationTask?.cancel()
        generationTask = Task {
            let examService = ExamService(credentials: MiniMaxCredentialStore())
            let generatedQuestions = try? await examService.generateExam(
                from: model.notebook,
                questionCount: 5,
                nativeLanguage: model.selectedNativeLanguage,
                targetLanguage: model.selectedTargetLanguage
            )

            guard !Task.isCancelled else { return }

            await MainActor.run {
                if let generatedQuestions, !generatedQuestions.isEmpty {
                    questions = generatedQuestions
                } else {
                    errorMessage = "生成题目失败，请重试"
                }
                isGenerating = false
            }
        }
    }

    private func retakeExam() {
        generationTask?.cancel()
        answers = []
        score = 0
        currentIndex = 0
        selectedOption = nil
        hasAnswered = false
        showingResults = false
        questions = []
        generateExam()
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
