# Contributing to Xtreme XA-vI ROM

First off, thank you for considering contributing to Xtreme XA-vI ROM! It's people like you that make this custom ROM a great tool for the Realme C63 community.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Submission Guidelines](#submission-guidelines)
- [Style Guidelines](#style-guidelines)
- [Community](#community)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## Getting Started

Before you begin:
- Make sure you have read the [README.md](README.md)
- Check out the [Development Guide](docs/DEVELOPMENT.md)
- Familiarize yourself with the project structure
- Read through existing issues and pull requests

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

**Bug Report Template:**
- **Device Information**: Realme C63 model, current ROM version
- **Description**: Clear and concise description of the bug
- **Steps to Reproduce**: Detailed steps to reproduce the behavior
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Logs**: Relevant log files or screenshots
- **Additional Context**: Any other relevant information

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear Title**: A descriptive title for the enhancement
- **Detailed Description**: Explain the feature and why it would be useful
- **Use Cases**: Provide examples of how the feature would be used
- **Alternatives**: Describe alternatives you've considered
- **Additional Context**: Screenshots, mockups, or references

### Pull Requests

We actively welcome your pull requests:

1. Fork the repo and create your branch from `main`
2. Make your changes following our style guidelines
3. Test your changes thoroughly
4. Update documentation as needed
5. Ensure your code passes all checks
6. Submit your pull request

## Development Setup

### Prerequisites

- Git installed on your machine
- Basic understanding of Android development (for ROM contributions)
- A Realme C63 device for testing (recommended)
- ADB and Fastboot tools installed

### Setting Up Your Development Environment

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR_USERNAME/Realme-C63.git
   cd Realme-C63
   ```

2. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
   
   Branch naming conventions:
   - `feature/` - New features
   - `bugfix/` - Bug fixes
   - `docs/` - Documentation changes
   - `refactor/` - Code refactoring
   - `test/` - Test additions or modifications

3. **Make Your Changes**
   - Write clear, concise code
   - Follow existing code style
   - Add comments for complex logic
   - Update documentation as needed

4. **Test Your Changes**
   ```bash
   # Run any existing tests
   # Test on actual device if possible
   ```

5. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "feat: Add descriptive commit message"
   ```

## Submission Guidelines

### Commit Message Format

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(bootloader): Add support for new unlock method
fix(installer): Resolve fastboot connection issue
docs(readme): Update installation instructions
```

### Pull Request Process

1. **Update Documentation**: Ensure all documentation is updated to reflect your changes
2. **Follow Code Style**: Your code should match the existing style
3. **Write Tests**: Add tests for new features when applicable
4. **One Feature Per PR**: Keep pull requests focused on a single feature or fix
5. **Describe Your Changes**: Provide a clear description of what your PR does
6. **Link Related Issues**: Reference any related issues in your PR description
7. **Be Responsive**: Be prepared to respond to feedback and make changes

### Pull Request Template

When submitting a PR, include:

```markdown
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Code refactoring

## Testing
How has this been tested?

## Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code where necessary
- [ ] I have updated the documentation
- [ ] My changes generate no new warnings
- [ ] I have tested my changes on a Realme C63 device
```

## Style Guidelines

### Code Style

- **Indentation**: Use consistent indentation (2 or 4 spaces, no tabs)
- **Naming**: Use descriptive variable and function names
- **Comments**: Add comments for complex logic, but write self-documenting code
- **Line Length**: Keep lines under 100 characters when possible
- **Functions**: Keep functions focused and reasonably sized

### Bash Script Guidelines

- Use `#!/bin/bash` shebang
- Enable strict mode: `set -euo pipefail`
- Use meaningful variable names in UPPER_CASE for constants
- Add comments to explain complex sections
- Quote variables to prevent word splitting
- Use functions for reusable code

### Documentation Style

- Use clear, concise language
- Include code examples where appropriate
- Keep formatting consistent with existing docs
- Update table of contents when adding sections
- Use proper Markdown syntax

## Community

### Getting Help

- **GitHub Issues**: For bug reports and feature requests
- **Discussions**: For questions and general discussion
- **Documentation**: Check the docs/ directory for guides

### Recognition

Contributors who make significant contributions will be recognized in:
- The project README
- Release notes
- The CONTRIBUTORS file (if applicable)

## Questions?

Don't hesitate to ask questions! You can:
- Open an issue with the `question` label
- Start a discussion on GitHub
- Contact the project maintainers

---

Thank you for contributing to Xtreme XA-vI ROM! Your efforts help make this project better for the entire Realme C63 community.

**Copyright © 2026 Elektronikx-Center-Matte by Alexander Mathey**
