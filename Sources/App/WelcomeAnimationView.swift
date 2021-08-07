//------------------------------------------------------------------------
// Author: The SwiftUI Lab
// Post: Advanced SwiftUI Animations - Part 4
// Link: https://swiftui-lab.com/swiftui-animations-part4 (TimelineView)

import SwiftUI

@available(macOS 12.0, iOS 15.0, *)
struct WelcomeAnimationView: View {
    var body: some View {
        VStack {
            ZStack {
                AnimatedEmoji(keyframes: leftKF)
                AnimatedEmoji(keyframes: rightKF)
            }
            //.frame(width: 500)
            //.clipped()
            //.frame(width: 500, height: 300, alignment: .bottom)
            //.clipped()
        }
    }
}


@available(macOS 12.0, iOS 15.0, *)
struct OffsetsTimelineSchedule: TimelineSchedule {
    let timeOffsets: [TimeInterval]

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> Entries {
        Entries(last: startDate, offsets: timeOffsets)
    }

    struct Entries: Sequence, IteratorProtocol {
        var last: Date
        let offsets: [TimeInterval]

        var idx: Int = -1

        mutating func next() -> Date? {
            idx += 1

            if idx >= offsets.count { return nil }

            last = last.addingTimeInterval(offsets[idx])

            return last
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
extension TimelineSchedule where Self == OffsetsTimelineSchedule {
    static func offsets(_ timeOffsets: [TimeInterval]) -> OffsetsTimelineSchedule {
            .init(timeOffsets: timeOffsets)
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct AnimatedEmoji: View {
    let keyframes: [KeyFrame]

    var body: some View {
        let offsets = Array(keyframes.map { $0.offset }.dropFirst())

        TimelineView(.offsets(offsets)) { timeline in
            Emoji(date: timeline.date, keyframes: keyframes)
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct Emoji: View {
    let date: Date
    let keyframes: [KeyFrame]
    @State var idx: Int = 0
    @State var kf: KeyFrame? = nil

    var body: some View {
        Text((kf ?? keyframes[0]).e)
            .font(.system(size: 100.0))
            .modifier(Effects(keyframe: kf ?? keyframes[0]))
            .onChange(of: date) { _ in advanceKeyFrame() }
            .onAppear { advanceKeyFrame()}
    }

    func advanceKeyFrame() {
        idx = min(idx + 1, keyframes.count - 1)

        withAnimation(keyframes[idx].animation) {
            kf = keyframes[idx]
        }
    }

    struct Effects: ViewModifier {
        let keyframe: KeyFrame

        func body(content: Content) -> some View {
            content
                .scaleEffect(keyframe.s)
                .overlay(alignment: .bottomLeading) {
                    if let t = keyframe.b {
                        Bubble(text: t)
                    }
                }
                .rotationEffect(Angle(degrees: keyframe.a))
                .offset(x: keyframe.x, y: keyframe.y)
                .opacity(keyframe.o)
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct Bubble: View {
    let text: Text

    var body: some View {
        text
            .foregroundColor(.black)
            .padding(.vertical, 5)
            .padding(.horizontal, 15)
            .background(BubbleShape())
            .fixedSize()
            .font(.custom("Bradley Hand", size: 22))
            .offset(x: 100, y: -100)
            .multilineTextAlignment(.center)
    }

    struct BubbleShape: Shape {
        func path(in rect: CGRect) -> Path {
            // Bubble
            var path = RoundedRectangle(cornerRadius: 15.0).path(in: rect)

            // Tail
            path.move(to: CGPoint(x: 10, y: rect.maxY))
            path.addLine(to: CGPoint(x: 20.0, y: rect.maxY))
            path .addLine(to: CGPoint(x: -10, y: rect.maxY + 10.0))
            path.closeSubpath()

            return path
        }
    }

}

struct KeyFrame {
    // time offset
    let offset: TimeInterval

    // opacity
    var o: Double = 1.0

    // emoji face
    let e: String

    // rotation angle
    let a: Double

    // x, y offsets
    let x: CGFloat
    let y: CGFloat

    // bubble text, nil for no bubble
    var b: Text? = nil

    // scale
    var s: CGSize = CGSize(width: 1.0, height: 1.0)

    // animation kind
    let animationKind: KeyFrameAnimation

    var animation: Animation? {
        switch animationKind {
        case .none: return nil
        case .linear: return .linear(duration: offset)
        case .easeIn: return .easeIn(duration: offset)
        case .easeOut: return .easeOut(duration: offset)
        case .easeInOut: return .easeInOut(duration: offset)
        }
    }

    enum KeyFrameAnimation {
        case none
        case linear
        case easeOut
        case easeIn
        case easeInOut
    }
}

let l_text_1 = Text("Hi there!\nLooking for Apps?")
let l_text_2 = Text("Do you know where\nyou can get them?")
let l_text_3 = Text("It's the App Fair!")
let l_text_4 = Text("It's Free.\nIt's Fair.\nAnd all are welcome\nat appfair.net!")

let leftKF = [
    // Start off-screen
    KeyFrame(offset: 0.0, e: "😃", a: 0, x: -320, y: -62, animationKind: .none),

    // Peek
    KeyFrame(offset: 1.2, e: "😃", a: 45, x: -220, y: -22, animationKind: .easeOut),

    // Blink twice
    KeyFrame(offset: 0.1, e: "😀", a: 45, x: -220, y: -22, animationKind: .easeOut),
    KeyFrame(offset: 0.1, e: "😃", a: 45, x: -220, y: -22, animationKind: .easeOut),
    KeyFrame(offset: 0.1, e: "😀", a: 45, x: -220, y: -22, animationKind: .easeOut),
    KeyFrame(offset: 0.8, e: "😃", a: 45, x: -220, y: -22, animationKind: .easeOut),

    // Hide
    KeyFrame(offset: 0.2, e: "😃", a: 0,  x: -320, y: -22, animationKind: .easeOut),

    // Re-appear and blink once
    KeyFrame(offset: 0.8, e: "😃", a: 360, x: -150, y: -22, animationKind: .easeOut),
    KeyFrame(offset: 0.1, e: "😀", a: 360, x: -150, y: -22, animationKind: .easeOut),
    KeyFrame(offset: 0.1, e: "😃", a: 360, x: -150, y: -22, animationKind: .easeOut),

    // Say "Hi there"
    KeyFrame(offset: 0.2, e: "😃", a: 360, x: -150, y: -22, b: l_text_1, animationKind: .easeIn),
    KeyFrame(offset: 2.2, e: "😃", a: 360, x: -150, y: -22, b: l_text_1, animationKind: .none),
    KeyFrame(offset: 0.1, e: "😃", a: 360, x: -150, y: -22, animationKind: .none),

    // Blink once
    KeyFrame(offset: 0.1, e: "😀", a: 360, x: -150, y: -22, animationKind: .easeOut),
    KeyFrame(offset: 0.2, e: "😃", a: 360, x: -150, y: -22, animationKind: .easeOut),

    // Say "would you like to learn how I move around?"
    KeyFrame(offset: 0.2, e: "😃", a: 360, x: -150, y: -22, b: l_text_2, animationKind: .easeIn),
    KeyFrame(offset: 3.0, e: "😃", a: 360, x: -150, y: -22, b: l_text_2, animationKind: .none),
    KeyFrame(offset: 0.1, e: "😃", a: 360, x: -150, y: -22, animationKind: .easeOut),

    // Blink once
    KeyFrame(offset: 0.2, e: "😃", a: 360, x: -150, y: -22, animationKind: .easeOut),
    KeyFrame(offset: 0.1, e: "😀", a: 360, x: -150, y: -22, animationKind: .easeOut),
    KeyFrame(offset: 0.2, e: "😃", a: 360, x: -150, y: -22, animationKind: .easeOut),

    // Get hit and roll eyes
    KeyFrame(offset: 0.2, e: "🙂", a: 330, x: -170, y: -22, animationKind: .easeOut),
    KeyFrame(offset: 0.2, e: "🙄", a: 360, x: -150, y: -22, animationKind: .easeOut),
    KeyFrame(offset: 1.7, e: "🙄", a: 360, x: -150, y: -22, animationKind: .none),

    // Get angry and strike back
    KeyFrame(offset: 0.5, e: "😠", a: 360, x: -150, y: -22, animationKind: .none),
    KeyFrame(offset: 1.0, e: "😡", a: 360, x: -150, y: -22, animationKind: .none),
    KeyFrame(offset: 0.3, e: "😡", a: 300, x: -170, y: -22, animationKind: .easeInOut),
    KeyFrame(offset: 0.3, e: "😡", a: 720, x:    0, y: -22, animationKind: .easeInOut),
    KeyFrame(offset: 0.1, e: "😠", a: 720, x:    0, y: -22, animationKind: .none),
    KeyFrame(offset: 0.1, e: "🙂", a: 720, x:    0, y: -22, animationKind: .none),

    // Smile again and blink
    KeyFrame(offset: 0.1, e: "😀", a: 720, x:    0, y: -22, animationKind: .none),
    KeyFrame(offset: 0.3, e: "😃", a: 720, x:    0, y: -22, animationKind: .none),
    KeyFrame(offset: 0.1, e: "😀", a: 720, x:    0, y: -22, animationKind: .none),
    KeyFrame(offset: 0.3, e: "😃", a: 720, x:    0, y: -22, animationKind: .none),

    // Say "come visit and I'll show you!" (and blink)
    KeyFrame(offset: 0.2, e: "😃", a: 720, x:    0, y: -22, b: l_text_3, animationKind: .linear),
    KeyFrame(offset: 0.1, e: "😀", a: 720, x:    0, y: -22, b: l_text_3, animationKind: .none),
    KeyFrame(offset: 0.1, e: "😃", a: 720, x:    0, y: -22, b: l_text_3, animationKind: .none),
    KeyFrame(offset: 0.1, e: "😀", a: 720, x:    0, y: -22, b: l_text_3, animationKind: .none),
    KeyFrame(offset: 2.0, e: "😃", a: 720, x:    0, y: -22, b: l_text_3, animationKind: .none),

    // Blink
    KeyFrame(offset: 0.1, e: "😃", a: 720, x:    0, y: -22, animationKind: .none),
    KeyFrame(offset: 0.1, e: "😀", a: 720, x:    0, y: -22, animationKind: .none),
    KeyFrame(offset: 0.1, e: "😃", a: 720, x:    0, y: -22, animationKind: .none),

    // Say closing words
    KeyFrame(offset: 0.2, e: "😃", a: 720, x:    0, y: -22, b: l_text_4, animationKind: .linear),
    KeyFrame(offset: 3.2, e: "😃", a: 720, x:    0, y: -22, b: l_text_4, animationKind: .none),

    // Blink
    KeyFrame(offset: 0.3, e: "😃", a: 720, x:    0, y: -22, animationKind: .none),
    KeyFrame(offset: 0.1, e: "😀", a: 720, x:    0, y: -22, animationKind: .none),
    KeyFrame(offset: 0.2, e: "😍", a: 720, x:    0, y: -22, animationKind: .none),

    // Fade out
    KeyFrame(offset: 0.8, o: 0.0, e: "😍", a: 720, x:    0, y: -22, animationKind: .easeInOut),

]

let r_text_1 = Text("Buy them at an App Store!")
let r_text_2 = Text("They don't cost much!")

let rightKF = [
    // Start off screen
    KeyFrame(offset: 0.0, e: "🧐", a: 0, x: 300, y: -22, animationKind: .none),

    // Wait off-screen for the other emoji to do its thing
    KeyFrame(offset: 9.5, e: "🧐", a: 0, x: 300, y: -22, animationKind: .none),

    // Hit the other guy
    KeyFrame(offset: 0.6, e: "🧐", a: -720, x: -53, y: -22, animationKind: .linear),

    // Blink
    KeyFrame(offset: 0.1, e: "😀", a: -720, x: -53, y: -22, animationKind: .linear),
    KeyFrame(offset: 0.1, e: "🧐", a: -720, x: -53, y: -22, animationKind: .linear),

    // Bounce three times and say "I know, I know, I know!"
    KeyFrame(offset: 0.1, e: "🧐", a: -720, x: -53, y: -2, b: r_text_1, s: CGSize(width: 1, height: 0.5), animationKind: .easeIn),
    KeyFrame(offset: 0.1, e: "🧐", a: -720, x: -53, y: -22, b: r_text_1, s: CGSize(width: 1, height: 0.5), animationKind: .easeOut),
    KeyFrame(offset: 0.1, e: "🧐", a: -720, x: -53, y: -44, b: r_text_1, animationKind: .easeOut),
    KeyFrame(offset: 0.1, e: "🧐", a: -720, x: -53, y: -22, b: r_text_1, animationKind: .linear),
    KeyFrame(offset: 0.1, e: "🧐", a: -720, x: -53, y: -2, b: r_text_1, s: CGSize(width: 1, height: 0.5), animationKind: .easeIn),
    KeyFrame(offset: 0.1, e: "🧐", a: -720, x: -53, y: -22, b: r_text_1, s: CGSize(width: 1, height: 0.5), animationKind: .easeOut),
    KeyFrame(offset: 0.1, e: "🧐", a: -720, x: -53, y: -44, b: r_text_1, animationKind: .easeOut),
    KeyFrame(offset: 0.1, e: "🧐", a: -720, x: -53, y: -22, b: r_text_1, animationKind: .linear),
    KeyFrame(offset: 0.1, e: "🧐", a: -720, x: -53, y: -2, b: r_text_1, s: CGSize(width: 1, height: 0.5), animationKind: .easeIn),
    KeyFrame(offset: 0.1, e: "🧐", a: -720, x: -53, y: -22, b: r_text_1, s: CGSize(width: 1, height: 0.5), animationKind: .easeOut),
    KeyFrame(offset: 0.1, e: "🧐", a: -720, x: -53, y: -44, b: r_text_1, animationKind: .easeOut),
    KeyFrame(offset: 0.1, e: "🧐", a: -720, x: -53, y: -22, b: r_text_1, animationKind: .linear),
    KeyFrame(offset: 0.4, e: "🧐", a: -720, x: -53, y: -22, b: r_text_1, animationKind: .none),
    KeyFrame(offset: 0.4, e: "🧐", a: -720, x: -53, y: -22, animationKind: .none),

    // Say: "It's super easy!"
    KeyFrame(offset: 0.1, e: "🧐", a: -720, x: -53, y: -22, b: r_text_2, animationKind: .linear),
    KeyFrame(offset: 1.7, e: "🧐", a: -720, x: -53, y: -22, b: r_text_2, animationKind: .none),

    // Get pushed off screen with dizzy eyes face
    KeyFrame(offset: 0.4, e: "😵‍💫", a: -720, x: 300, y: -22, animationKind: .linear),
]
