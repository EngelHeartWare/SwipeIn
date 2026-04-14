import SwiftUI

struct SettingsView: View {
    // To change the app icon (non-optional String)
    @AppStorage("selectedAppIcon") var selectedAppIcon: String = ""
    @AppStorage("hasSeenTutorial") var hasSeenTutorial: Bool = true
    @AppStorage("hasSeenListTutorial") var hasSeenListTutorial: Bool = true
    @AppStorage("appearanceMode") var appearanceMode: String = "System"
    @AppStorage("selectedLanguage") var selectedLanguage: String = "English"
    @AppStorage("accentColor") private var accentColor: String = "Mint"
    @AppStorage("selectedIcon") private var selectedIcon: String = "AppIcon_mint"

    private let availableAccentColors: [String] = [
        "Red","Orange","Yellow","Green","Blue","Mint","Pink", "Purple" 
    ]
    
    var body: some View {
        List {
                Section(header: Text("Appearance")) {
                    Picker("Appearance", selection: $appearanceMode) {
                        Text("Light").tag("Light")
                        Text("Dark").tag("Dark")
                        Text("System").tag("System")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: appearanceMode) { newValue in
                        updateAppearance(newValue)
                    }
                }

                Section(header: Text("Accent Color")) {
                                    ForEach(availableAccentColors, id: \.self) { colorName in
                                        HStack {
                                            Text(colorName)
                                            Spacer()
                                            Circle()
                                                .fill(Color(colorName))
                                                .frame(width: 24, height: 24)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.primary, lineWidth: accentColor == colorName ? 2 : 0)
                                                )
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            accentColor = colorName
                                            updateAppIcon(to: "AppIcon_\(colorName.lowercased())")
                                        }
                                    }
                                }

                              
                Section(header: Text("Current Icon")) {
                    HStack(spacing: 16) {
                        VStack {
                            Image("AppIcon_\(accentColor.lowercased())_preview")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .environment(\.colorScheme, .light)
                            Text("Light")
                                .font(.caption)
                        }
                        .padding()

                        VStack {
                            Image("AppIcon_\(accentColor.lowercased())_preview")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .environment(\.colorScheme, .dark)
                            Text("Dark")
                                .font(.caption)
                        }
                        .padding()

                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                                
                Section(header: Text("Tutorial")) {
                    Button(action: {
                        resetTutorial()
                    }) {
                        Text("Reset Tutorial")
                    }
                }
            }
        .navigationTitle("Settings")
        .onAppear {
            applyAppearanceMode()
        }
    }

    private func updateAppIcon(to iconName: String) {
            let actualName = iconName == "AppIcon_mint" ? nil : iconName
            UIApplication.shared.setAlternateIconName(actualName) { error in
                if let error = error {
                    #if DEBUG
                    print("Icon change failed: \(error.localizedDescription)")
                    #endif
                } else {
                    selectedIcon = iconName
                    #if DEBUG
                    print("Changed to icon: \(iconName)")
                    #endif
                }
            }
        }
    
    private func updateAppearance(_ mode: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let style: UIUserInterfaceStyle
        switch mode {
        case "Light":
            style = .light
        case "Dark":
            style = .dark
        default:
            style = .unspecified
        }
        for window in windowScene.windows {
            window.overrideUserInterfaceStyle = style
        }
    }

    private func applyAppearanceMode() {
        updateAppearance(appearanceMode)
    }

    private func resetTutorial() {
        hasSeenTutorial = false
        hasSeenListTutorial = false
        #if DEBUG
        print("Tutorial has been reset")
        #endif
    }
    
    private func updateLanguage(_ language: String) {
        // Update the app's language
        // In a real app, you would typically apply localization settings here.
        // For now, we simply print the selected language.

        if language == "English" {
            // Logic to change app language to English
            #if DEBUG
            print("Switching to English")
            #endif
        } else if language == "German" {
            #if DEBUG
            print("Switching to German")
            #endif
            // e.g., update the language in your localization manager or apply custom logic
        }
    }
}
