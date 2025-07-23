# EnvVarTool

A macOS application for managing environment variables with a clean, native SwiftUI interface.

## Features

- **Visual Environment Management**: Add, edit, and delete environment variables through an intuitive interface
- **Profile Support**: Organize variables into different shell configuration files (.zshrc, .bash_profile, .bashrc, .profile)
- **Import/Export**: Share environment configurations with team members via JSON files
- **Native macOS Experience**: Built with SwiftUI for optimal macOS integration

## Installation

### From Source
1. Clone the repository
2. Open `EnvVarTool.xcodeproj` in Xcode
3. Build and run the project

### Requirements
- macOS 11.0+
- Xcode 12.0+
- Swift 5.3+

## Usage

1. Launch the application from your Applications folder
2. Select a shell configuration file from the sidebar (.zshrc, .bash_profile, .bashrc, .profile)
3. Add new environment variables using the "+" button
4. Edit existing variables by clicking "Edit" next to each variable
5. Use the Import/Export menu (ellipsis button) to:
   - **Export**: Save your environment variables as a JSON file to share with others
   - **Import**: Load environment variables from a JSON file exported by EnvVarTool

## Development

### Project Structure
```
EnvVarTool/
├── EnvVarToolApp.swift          # Main app entry point
├── ContentView.swift           # Primary UI view
├── Models/                     # Data models
├── Views/                      # SwiftUI view components
└── ViewModels/                 # Business logic
```

### Building
```bash
# Open in Xcode
open EnvVarTool.xcodeproj

# Or build from command line
xcodebuild -project EnvVarTool.xcodeproj -scheme EnvVarTool
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Icons from [SF Symbols](https://developer.apple.com/sf-symbols/)

## Support

If you encounter any issues or have questions, please [open an issue](https://github.com/yourusername/EnvVarTool/issues) on GitHub.