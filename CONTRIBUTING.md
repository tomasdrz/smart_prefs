# Contributing to Smart Prefs

Thank you for your interest in contributing to Smart Prefs! This document provides guidelines and instructions for contributing.

## 🤝 How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:

- A clear, descriptive title
- Steps to reproduce the bug
- Expected behavior
- Actual behavior
- Your environment (Dart/Flutter version, OS, etc.)
- Code samples or error messages if applicable

### Suggesting Features

Feature suggestions are welcome! Please open an issue with:

- A clear description of the feature
- Use cases and benefits
- Possible implementation approach (optional)
- Examples of how it would be used

### Submitting Pull Requests

1. **Fork the repository** and create a new branch from `main`

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**

   - Follow the existing code style
   - Add tests for new functionality
   - Update documentation as needed

3. **Run tests and checks**

   ```bash
   # Run all tests
   flutter test

   # Check code formatting
   dart format .

   # Run static analysis
   flutter analyze
   ```

4. **Commit your changes**

   - Use clear, descriptive commit messages
   - Follow conventional commits format (optional but appreciated):
     - `feat:` for new features
     - `fix:` for bug fixes
     - `docs:` for documentation changes
     - `test:` for test additions/changes
     - `refactor:` for code refactoring

5. **Push to your fork and submit a pull request**

## 📋 Development Guidelines

### Code Style

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` to format your code
- Keep functions small and focused
- Add documentation comments for public APIs
- Use meaningful variable and function names

### Testing

- Write tests for all new features
- Maintain or improve code coverage
- Tests should be clear and well-documented
- Use descriptive test names

### Documentation

- Update README.md for user-facing changes
- Update CHANGELOG.md following [Keep a Changelog](https://keepachangelog.com/)
- Add dartdoc comments for public APIs
- Include code examples in documentation

## 🏗️ Project Structure

```
smart_prefs/
├── lib/
│   ├── smart_prefs.dart      # Main export file
│   └── src/                  # Implementation files
│       ├── pref.dart         # Pref interface and extensions
│       ├── prefs.dart        # Core logic
│       ├── prefs_manager.dart # Initialization
│       ├── remote_prefs.dart  # Remote storage interface
│       ├── prefs_logger.dart  # Logging types
│       └── prefs_callbacks.dart # Callback types
├── test/                     # Unit tests
├── example/                  # Example implementations
└── README.md                 # Main documentation
```

## 🔍 Code Review Process

1. All contributions require review before merging
2. Reviewers will check for:
   - Code quality and style
   - Test coverage
   - Documentation completeness
   - Breaking changes
3. Address review feedback promptly
4. Once approved, a maintainer will merge your PR

## 📝 License

By contributing to Smart Prefs, you agree that your contributions will be licensed under the MIT License.

## ❓ Questions?

If you have questions about contributing, feel free to:

- Open an issue for discussion
- Reach out to the maintainers

## 🙏 Thank You!

Your contributions make Smart Prefs better for everyone. We appreciate your time and effort!

---

**Happy coding!** 🚀
