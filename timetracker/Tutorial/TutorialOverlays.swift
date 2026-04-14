import SwiftUI

struct TutorialHomeOverlay: View {
    @Binding var isTutorialVisible: Bool
    
    // State to keep track of the current tutorial step
    @State private var currentStep: Int = 0

    // Define the tutorial steps as an array of strings
    private let tutorialSteps: [String] = [
        "Welcome to Swipe In, the time tracking app!",
        "To start tracking an activity, just swipe right and you are checked in.",
        "To check out, swipe back left - it's that simple!",
        "You can pause the timer by clicking the button while checked in.",
        "Configure your activity with labels for activity and location.",
        "You can view stats about your activities at 'Insights', to see a list of all entries scroll through the list at the bottom",
        "You're all set. Try tracking your first activity!"
    ]
    
    // Define the images corresponding to each step
    private let tutorialImages: [String] = [
        "info.circle",
        "arrowshape.forward",
        "arrowshape.backward",
        "pause.rectangle",
        "rectangle.on.rectangle",
        "lightbulb",
        "checkmark"
    ]
    
    var body: some View {
        ZStack {
            // Semi-transparent background with gray opacity
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
            
            VStack{
                Spacer()
                
                VStack(spacing: 20) {
                    // Image on top of the text box (e.g., a tutorial image)
                    Image(systemName: tutorialImages[currentStep])
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.primary)
                    
                    // Tutorial text
                    Text(tutorialSteps[currentStep])
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil) // Allow the text to span multiple lines
                        .padding([.leading, .trailing], 20) // Add horizontal padding for better alignment
                    
                    // Show "Next" button if not on the last step
                    if currentStep < tutorialSteps.count - 1 {
                        Button(action: {
                            currentStep += 1
                        }) {
                            Text("Next")
                                .fontWeight(.semibold)
                                .foregroundColor(.mint)
                                .padding(.top, 10)
                        }
                    } else {
                        // On the last step, show "Got It!" button
                        Button(action: {
                            isTutorialVisible = false // Dismiss the tutorial
                        }) {
                            Text("Got It!")
                                .fontWeight(.semibold)
                                .foregroundColor(.mint)
                                .padding(.top, 10)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: 350)
                .background(Color(UIColor.systemBackground).opacity(0.95))
                .cornerRadius(20)
                .shadow(radius: 10)
            }
        }
    }
}

struct TutorialHomeOverlay_Previews: PreviewProvider {
    static var previews: some View {
        TutorialHomeOverlay(isTutorialVisible: .constant(true))
    }
}


struct TutorialListOverlay: View {
    @Binding var isListTutorialVisible: Bool
    
    // State to keep track of the current tutorial step
    @State private var currentStep: Int = 0

    // Define the tutorial steps as an array of strings
    private let tutorialSteps: [String] = [
        "Long press an entry to modify it. You can change details and also delete the entry.",
        "With the buttons on the top you can add manual entries and export your list."
        
    ]
    
    // Define the images corresponding to each step
    private let tutorialImages: [String] = [
        "hand.point.up.left",
        "plus"
    ]
    
    var body: some View {
        ZStack {
            // Semi-transparent background with gray opacity
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
            
            VStack{
                Spacer()
                
                VStack(spacing: 20) {
                    // Image on top of the text box (e.g., a tutorial image)
                    Image(systemName: tutorialImages[currentStep])
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.primary)
                    
                    // Tutorial text
                    Text(tutorialSteps[currentStep])
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil) // Allow the text to span multiple lines
                        .padding([.leading, .trailing], 20) // Add horizontal padding for better alignment
                    
                    // Show "Next" button if not on the last step
                    if currentStep < tutorialSteps.count - 1 {
                        Button(action: {
                            currentStep += 1
                        }) {
                            Text("Next")
                                .fontWeight(.semibold)
                                .foregroundColor(.mint)
                                .padding(.top, 10)
                        }
                    } else {
                        // On the last step, show "Got It!" button
                        Button(action: {
                            isListTutorialVisible = false // Dismiss the tutorial
                        }) {
                            Text("Got It!")
                                .fontWeight(.semibold)
                                .foregroundColor(.mint)
                                .padding(.top, 10)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: 350)
                .background(Color(UIColor.systemBackground).opacity(0.95))
                .cornerRadius(20)
                .shadow(radius: 10)
            }
        }
    }
}

struct TutorialListOverlay_Previews: PreviewProvider {
    static var previews: some View {
        TutorialListOverlay(isListTutorialVisible: .constant(true))
    }
}
