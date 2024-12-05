import SwiftUI

struct SettingsView: View {
    // To change the app icon (non-optional String)
    @AppStorage("selectedAppIcon") var selectedAppIcon: String = ""
    @AppStorage("hasSeenTutorial") var hasSeenTutorial: Bool = true
    @AppStorage("hasSeenListTutorial") var hasSeenListTutorial: Bool = true
    @AppStorage("appearanceMode") var appearanceMode: String = "System"
    @AppStorage("selectedLanguage") var selectedLanguage: String = "English"
    @AppStorage("accentColor") private var accentColor: String = "Mint"

    private let availableAccentColors: [String] = [
        "Red","Orange","Yellow","Green","Blue","Mint","Pink", "Purple" 
    ]
    
    var body: some View {
        NavigationView {
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
                    //ScrollView(.horizontal, showsIndicators: false) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                            ForEach(availableAccentColors, id: \.self) { colorName in
                                Circle()
                                    .fill(Color(colorName))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: accentColor == colorName ? 3 : 0)
                                    )
                                    .onTapGesture {
                                        accentColor = colorName
                                    }
                                    .padding(.horizontal, 4)
                            }
                        }
                        .padding(.vertical, 8)
                    //}
                }

                Section(header: Text("App Icon")) {
                    
                    Button(action: {
                        // Implement language change logic here
                        print("Change App Icon ")
                    }) {
                        AppIconSelectionView()
                    }
                    
                    
                }

                /*Section(header: Text("Language")) {
                    Picker("Language", selection: $selectedLanguage) {
                        Text("English").tag("English")
                        Text("German").tag("German")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedLanguage) { newLanguage in
                        updateLanguage(newLanguage)
                    }
                }*/

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
    }

    private func updateAppearance(_ mode: String) {
        switch mode {
        case "Light":
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .light
        case "Dark":
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .dark
        default:
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .unspecified
        }
    }

    private func applyAppearanceMode() {
        updateAppearance(appearanceMode)
    }

    private func resetTutorial() {
        hasSeenTutorial = false
        hasSeenListTutorial = false
        print("Tutorial has been reset")
    }
    
    private func updateLanguage(_ language: String) {
        // Update the app's language
        // In a real app, you would typically apply localization settings here.
        // For now, we simply print the selected language.

        if language == "English" {
            // Logic to change app language to English
            print("Switching to English")
            // e.g., update the language in your localization manager or apply custom logic
        } else if language == "German" {
            // Logic to change app language to German
            print("Switching to German")
            // e.g., update the language in your localization manager or apply custom logic
        }
    }
}


struct AppIconSelectionView: View {
    @AppStorage("selectedIcon") private var selectedIcon: String = "AppIcon"
    
    let icons = [
        ("AppIcon_red", "Red"),
        ("AppIcon_orange", "Orange"),
        ("AppIcon_yellow", "Yellow"),
        ("AppIcon_green", "Green"),
        ("AppIcon_blue", "Blue"),
        ("AppIcon_mint", "Mint"),
        ("AppIcon_pink", "Pink"),
        ("AppIcon_purple", "Purple")
    ]
    
    let iconPreviews = [
        "AppIcon_red": "AppIcon_red_preview",
        "AppIcon_orange": "AppIcon_orange_preview",
        "AppIcon_yellow": "AppIcon_yellow_preview",
        "AppIcon_green": "AppIcon_green_preview",
        "AppIcon_blue": "AppIcon_blue_preview",
        "AppIcon_mint": "AppIcon_mint_preview",
        "AppIcon_pink": "AppIcon_pink_preview",
        "AppIcon_purple": "AppIcon_purple_preview"
    ]

    var body: some View {
        VStack {
            /*Text("Icon auswählen:")
                .font(.headline)
                .padding()*/

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                ForEach(icons, id: \.0) { icon in
                    Button(action: {
                        updateAppIcon(to: icon.0)
                    }) {
                        VStack {
                            Image(iconPreviews[icon.0] ?? "default_preview")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(selectedIcon == icon.0 ? Color.blue : Color.clear, lineWidth: 3)
                                )

                            /*Text(icon.1)
                                .font(.caption)*/
                        }
                    }
                }
            }
        }
        .padding()
    }

    func updateAppIcon(to iconName: String) {
        UIApplication.shared.setAlternateIconName(iconName == "AppIcon_mint" ? nil : iconName) { error in
            if let error = error {
                print("Error changing icon \(iconName) to : \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    selectedIcon = iconName
                    print("App icon changed to \(iconName)")
                }
            }
        }
    }
    
}
