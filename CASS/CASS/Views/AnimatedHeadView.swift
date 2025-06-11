import SwiftUI

struct AnimatedHeadView: View {
    @Binding var isSpeaking: Bool
    
    // Animation properties
    @State private var mouthOffset: CGFloat = 0
    @State private var eyeBlinkLeft: Bool = false
    @State private var eyeBlinkRight: Bool = false
    @State private var jawOffset: CGFloat = 0
    
    let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()
    let blinkTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let centerX = width / 2
            let centerY = height / 2
            
            ZStack {
                // Hair
                Group {
                    // Main hair volume
                    Path { path in
                        // Top of hair with side part
                        path.move(to: CGPoint(x: centerX - 75, y: centerY - 85))
                        // Left side of part
                        path.addCurve(
                            to: CGPoint(x: centerX - 15, y: centerY - 90),
                            control1: CGPoint(x: centerX - 55, y: centerY - 95),
                            control2: CGPoint(x: centerX - 35, y: centerY - 95)
                        )
                        // Part line
                        path.addCurve(
                            to: CGPoint(x: centerX + 5, y: centerY - 85),
                            control1: CGPoint(x: centerX - 10, y: centerY - 90),
                            control2: CGPoint(x: centerX, y: centerY - 85)
                        )
                        // Right side of hair
                        path.addCurve(
                            to: CGPoint(x: centerX + 75, y: centerY - 80),
                            control1: CGPoint(x: centerX + 35, y: centerY - 95),
                            control2: CGPoint(x: centerX + 65, y: centerY - 90)
                        )
                        // Right side
                        path.addCurve(
                            to: CGPoint(x: centerX + 80, y: centerY - 20),
                            control1: CGPoint(x: centerX + 85, y: centerY - 65),
                            control2: CGPoint(x: centerX + 85, y: centerY - 45)
                        )
                        // Left side
                        path.addLine(to: CGPoint(x: centerX - 80, y: centerY - 20))
                        path.addCurve(
                            to: CGPoint(x: centerX - 75, y: centerY - 85),
                            control1: CGPoint(x: centerX - 85, y: centerY - 45),
                            control2: CGPoint(x: centerX - 85, y: centerY - 65)
                        )
                    }
                    .fill(Color(red: 0.15, green: 0.1, blue: 0.05))
                    
                    // Hair highlights
                    Group {
                        // Main part line highlight
                        Path { path in
                            path.move(to: CGPoint(x: centerX - 15, y: centerY - 90))
                            path.addCurve(
                                to: CGPoint(x: centerX + 5, y: centerY - 40),
                                control1: CGPoint(x: centerX - 10, y: centerY - 70),
                                control2: CGPoint(x: centerX, y: centerY - 55)
                            )
                        }
                        .stroke(Color(red: 0.25, green: 0.2, blue: 0.15), lineWidth: 2)
                        
                        // Volume highlights
                        Path { path in
                            path.move(to: CGPoint(x: centerX + 5, y: centerY - 85))
                            path.addCurve(
                                to: CGPoint(x: centerX + 60, y: centerY - 80),
                                control1: CGPoint(x: centerX + 25, y: centerY - 90),
                                control2: CGPoint(x: centerX + 45, y: centerY - 85)
                            )
                        }
                        .stroke(Color(red: 0.25, green: 0.2, blue: 0.15), lineWidth: 3)
                    }
                    
                    // Hair strands
                    Group {
                        // Left side strands
                        ForEach(0..<3) { i in
                            Path { path in
                                let x = centerX - 60 + CGFloat(i * 20)
                                path.move(to: CGPoint(x: x, y: centerY - 80))
                                path.addCurve(
                                    to: CGPoint(x: x - 5, y: centerY - 30),
                                    control1: CGPoint(x: x - 10, y: centerY - 60),
                                    control2: CGPoint(x: x - 15, y: centerY - 45)
                                )
                            }
                            .stroke(Color(red: 0.2, green: 0.15, blue: 0.1), lineWidth: 1)
                        }
                        
                        // Right side strands
                        ForEach(0..<4) { i in
                            Path { path in
                                let x = centerX + 10 + CGFloat(i * 20)
                                path.move(to: CGPoint(x: x, y: centerY - 80))
                                path.addCurve(
                                    to: CGPoint(x: x + 10, y: centerY - 30),
                                    control1: CGPoint(x: x + 5, y: centerY - 60),
                                    control2: CGPoint(x: x + 15, y: centerY - 45)
                                )
                            }
                            .stroke(Color(red: 0.2, green: 0.15, blue: 0.1), lineWidth: 1)
                        }
                    }
                }

                // Face shape
                Path { path in
                    // Forehead
                    path.move(to: CGPoint(x: centerX - 60, y: centerY - 70))
                    path.addCurve(
                        to: CGPoint(x: centerX + 60, y: centerY - 70),
                        control1: CGPoint(x: centerX - 30, y: centerY - 75),
                        control2: CGPoint(x: centerX + 30, y: centerY - 75)
                    )
                    // Right cheek
                    path.addCurve(
                        to: CGPoint(x: centerX + 65, y: centerY + 30),
                        control1: CGPoint(x: centerX + 70, y: centerY - 40),
                        control2: CGPoint(x: centerX + 70, y: centerY)
                    )
                    // Jaw
                    path.addCurve(
                        to: CGPoint(x: centerX, y: centerY + 70 + jawOffset),
                        control1: CGPoint(x: centerX + 65, y: centerY + 60),
                        control2: CGPoint(x: centerX + 30, y: centerY + 70)
                    )
                    // Left jaw
                    path.addCurve(
                        to: CGPoint(x: centerX - 65, y: centerY + 30),
                        control1: CGPoint(x: centerX - 30, y: centerY + 70),
                        control2: CGPoint(x: centerX - 65, y: centerY + 60)
                    )
                    // Left cheek
                    path.addCurve(
                        to: CGPoint(x: centerX - 60, y: centerY - 70),
                        control1: CGPoint(x: centerX - 70, y: centerY),
                        control2: CGPoint(x: centerX - 70, y: centerY - 40)
                    )
                }
                .fill(Color(red: 0.95, green: 0.85, blue: 0.75))

                // Facial features group
                Group {
                    // Eyes background shading
                    Path { path in
                        path.addRoundedRect(
                            in: CGRect(
                                x: centerX - 50,
                                y: centerY - 45,
                                width: 100,
                                height: 25
                            ),
                            cornerSize: CGSize(width: 12, height: 12)
                        )
                    }
                    .fill(Color(red: 0.93, green: 0.83, blue: 0.73))

                    // Left eye
                    Group {
                        // Eye socket
                        Path { path in
                            path.addEllipse(in: CGRect(x: centerX - 40, y: centerY - 42, width: 30, height: 18))
                        }
                        .fill(Color(red: 0.9, green: 0.8, blue: 0.7))

                        // Eye white
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 28, height: eyeBlinkLeft ? 1 : 16)
                            .position(x: centerX - 25, y: centerY - 33)
                            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)

                        if !eyeBlinkLeft {
                            // Iris
                            Circle()
                                .fill(Color(red: 0.3, green: 0.5, blue: 0.8))
                                .frame(width: 12, height: 12)
                                .position(x: centerX - 25, y: centerY - 33)

                            // Pupil
                            Circle()
                                .fill(Color.black)
                                .frame(width: 6, height: 6)
                                .position(x: centerX - 25, y: centerY - 33)

                            // Eye highlights
                            Circle()
                                .fill(Color.white)
                                .frame(width: 4, height: 4)
                                .position(x: centerX - 23, y: centerY - 35)
                        }
                    }

                    // Right eye
                    Group {
                        // Eye socket
                        Path { path in
                            path.addEllipse(in: CGRect(x: centerX + 10, y: centerY - 42, width: 30, height: 18))
                        }
                        .fill(Color(red: 0.9, green: 0.8, blue: 0.7))

                        // Eye white
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 28, height: eyeBlinkRight ? 1 : 16)
                            .position(x: centerX + 25, y: centerY - 33)
                            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)

                        if !eyeBlinkRight {
                            // Iris
                            Circle()
                                .fill(Color(red: 0.3, green: 0.5, blue: 0.8))
                                .frame(width: 12, height: 12)
                                .position(x: centerX + 25, y: centerY - 33)

                            // Pupil
                            Circle()
                                .fill(Color.black)
                                .frame(width: 6, height: 6)
                                .position(x: centerX + 25, y: centerY - 33)

                            // Eye highlights
                            Circle()
                                .fill(Color.white)
                                .frame(width: 4, height: 4)
                                .position(x: centerX + 27, y: centerY - 35)
                        }
                    }

                    // Nose
                    Group {
                        // Bridge and main shape
                        Path { path in
                            // Bridge start
                            path.move(to: CGPoint(x: centerX - 2, y: centerY - 35))
                            // Bridge curve
                            path.addCurve(
                                to: CGPoint(x: centerX + 8, y: centerY - 5),
                                control1: CGPoint(x: centerX + 1, y: centerY - 25),
                                control2: CGPoint(x: centerX + 6, y: centerY - 15)
                            )
                            // Tip and ball
                            path.addCurve(
                                to: CGPoint(x: centerX, y: centerY + 8),
                                control1: CGPoint(x: centerX + 10, y: centerY + 2),
                                control2: CGPoint(x: centerX + 5, y: centerY + 8)
                            )
                            // Left side of tip
                            path.addCurve(
                                to: CGPoint(x: centerX - 8, y: centerY - 5),
                                control1: CGPoint(x: centerX - 5, y: centerY + 8),
                                control2: CGPoint(x: centerX - 10, y: centerY + 2)
                            )
                            // Connect back to bridge
                            path.addCurve(
                                to: CGPoint(x: centerX - 2, y: centerY - 35),
                                control1: CGPoint(x: centerX - 6, y: centerY - 15),
                                control2: CGPoint(x: centerX - 4, y: centerY - 25)
                            )
                        }
                        .fill(Color(red: 0.92, green: 0.82, blue: 0.72))
                        
                        // Nose highlights
                        Group {
                            // Bridge highlight
                            Path { path in
                                path.move(to: CGPoint(x: centerX - 1, y: centerY - 30))
                                path.addCurve(
                                    to: CGPoint(x: centerX + 2, y: centerY - 15),
                                    control1: CGPoint(x: centerX, y: centerY - 25),
                                    control2: CGPoint(x: centerX + 1, y: centerY - 20)
                                )
                            }
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            
                            // Side shadow
                            Path { path in
                                path.move(to: CGPoint(x: centerX + 6, y: centerY - 10))
                                path.addCurve(
                                    to: CGPoint(x: centerX + 4, y: centerY + 5),
                                    control1: CGPoint(x: centerX + 8, y: centerY - 5),
                                    control2: CGPoint(x: centerX + 7, y: centerY)
                                )
                            }
                            .stroke(Color.black.opacity(0.1), lineWidth: 2)
                        }
                    }

                    // Nostrils
                    Group {
                        // Left nostril
                        Path { path in
                            path.move(to: CGPoint(x: centerX - 6, y: centerY + 5))
                            path.addCurve(
                                to: CGPoint(x: centerX - 2, y: centerY + 7),
                                control1: CGPoint(x: centerX - 5, y: centerY + 7),
                                control2: CGPoint(x: centerX - 3, y: centerY + 7)
                            )
                        }
                        .stroke(Color.black.opacity(0.4), lineWidth: 2)
                        
                        // Right nostril
                        Path { path in
                            path.move(to: CGPoint(x: centerX + 2, y: centerY + 7))
                            path.addCurve(
                                to: CGPoint(x: centerX + 6, y: centerY + 5),
                                control1: CGPoint(x: centerX + 3, y: centerY + 7),
                                control2: CGPoint(x: centerX + 5, y: centerY + 7)
                            )
                        }
                        .stroke(Color.black.opacity(0.4), lineWidth: 2)
                    }

                    // Mouth region
                    Group {
                        // Mouth background and structure
                        Path { path in
                            path.addRoundedRect(
                                in: CGRect(
                                    x: centerX - 22,
                                    y: centerY + 20,
                                    width: 44,
                                    height: 18
                                ),
                                cornerSize: CGSize(width: 10, height: 10)
                            )
                        }
                        .fill(Color(red: 0.92, green: 0.82, blue: 0.72))

                        // Lips
                        Group {
                            // Upper lip
                            Path { path in
                                // Left curve
                                path.move(to: CGPoint(x: centerX - 15, y: centerY + 28))
                                path.addCurve(
                                    to: CGPoint(x: centerX, y: centerY + 27),
                                    control1: CGPoint(x: centerX - 10, y: centerY + 28),
                                    control2: CGPoint(x: centerX - 5, y: centerY + 27)
                                )
                                // Right curve
                                path.addCurve(
                                    to: CGPoint(x: centerX + 15, y: centerY + 28),
                                    control1: CGPoint(x: centerX + 5, y: centerY + 27),
                                    control2: CGPoint(x: centerX + 10, y: centerY + 28)
                                )
                            }
                            .stroke(Color(red: 0.8, green: 0.4, blue: 0.4), lineWidth: 1.5)
                            
                            // Lower lip
                            Path { path in
                                path.move(to: CGPoint(x: centerX - 15, y: centerY + 28))
                                path.addQuadCurve(
                                    to: CGPoint(x: centerX + 15, y: centerY + 28),
                                    control: CGPoint(x: centerX, y: centerY + 28 + (isSpeaking ? mouthOffset : 0))
                                )
                            }
                            .stroke(Color(red: 0.8, green: 0.4, blue: 0.4), lineWidth: 2)
                        }
                        
                        // Lip highlights and details
                        Group {
                            // Upper lip shadow
                            Path { path in
                                path.move(to: CGPoint(x: centerX - 12, y: centerY + 27))
                                path.addQuadCurve(
                                    to: CGPoint(x: centerX + 12, y: centerY + 27),
                                    control: CGPoint(x: centerX, y: centerY + 26)
                                )
                            }
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            
                            // Lower lip highlight
                            Path { path in
                                path.move(to: CGPoint(x: centerX - 10, y: centerY + 29))
                                path.addQuadCurve(
                                    to: CGPoint(x: centerX + 10, y: centerY + 29),
                                    control: CGPoint(x: centerX, y: centerY + 30 + (isSpeaking ? mouthOffset * 0.5 : 0))
                                )
                            }
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        }
                    }

                    // Eyebrows
                    Group {
                        // Left eyebrow
                        Path { path in
                            path.move(to: CGPoint(x: centerX - 40, y: centerY - 55))
                            path.addQuadCurve(
                                to: CGPoint(x: centerX - 15, y: centerY - 55),
                                control: CGPoint(x: centerX - 27, y: centerY - 58)
                            )
                        }
                        .stroke(Color(red: 0.2, green: 0.15, blue: 0.1), lineWidth: 3)

                        // Right eyebrow
                        Path { path in
                            path.move(to: CGPoint(x: centerX + 15, y: centerY - 55))
                            path.addQuadCurve(
                                to: CGPoint(x: centerX + 40, y: centerY - 55),
                                control: CGPoint(x: centerX + 27, y: centerY - 58)
                            )
                        }
                        .stroke(Color(red: 0.2, green: 0.15, blue: 0.1), lineWidth: 3)
                    }
                }
            }
        }
        .frame(width: 200, height: 250)
        .onReceive(timer) { _ in
            if isSpeaking {
                withAnimation(.easeInOut(duration: 0.15)) {
                    mouthOffset = CGFloat.random(in: 2...8)
                    jawOffset = CGFloat.random(in: 1...3)
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    mouthOffset = 0
                    jawOffset = 0
                }
            }
        }
        .onReceive(blinkTimer) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                eyeBlinkLeft = true
                eyeBlinkRight = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    eyeBlinkLeft = false
                    eyeBlinkRight = false
                }
            }
        }
    }
}