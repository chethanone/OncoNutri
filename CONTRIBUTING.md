# Contributing to OncoNutri+

Thank you for your interest in contributing to OncoNutri+! This document provides guidelines for contributing to the project.

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help maintain a positive environment
- Report unacceptable behavior

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in Issues
2. Create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if applicable
   - Environment details (OS, versions, etc.)

### Suggesting Features

1. Check if the feature has been suggested
2. Create a new issue with:
   - Clear use case
   - Expected behavior
   - Why it would be valuable
   - Possible implementation approach

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **Make your changes**
   - Follow existing code style
   - Write clear commit messages
   - Add tests if applicable
   - Update documentation

4. **Test your changes**
   ```bash
   # Backend tests
   cd backend/node_server && npm test
   
   # Frontend tests
   cd frontend && flutter test
   
   # ML service tests
   cd backend/fastapi_ml && pytest
   ```

5. **Commit your changes**
   ```bash
   git commit -m "feat: add amazing feature"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/amazing-feature
   ```

7. **Open a Pull Request**
   - Describe what changed and why
   - Reference related issues
   - Ensure all checks pass

## Coding Standards

### Flutter/Dart
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable names
- Add comments for complex logic
- Format code: `flutter format .`

### Node.js
- Follow [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript)
- Use async/await over callbacks
- Handle errors properly
- Use ESLint: `npm run lint`

### Python
- Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/)
- Use type hints where appropriate
- Write docstrings for functions
- Format code: `black .`

### SQL
- Use lowercase for keywords
- Indent properly
- Add comments for complex queries
- Use meaningful table/column names

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new feature
fix: fix bug
docs: update documentation
style: format code
refactor: refactor code
test: add tests
chore: update dependencies
```

## Project Structure

```
OncoNutri+/
├── frontend/           # Flutter mobile app
├── backend/
│   ├── node_server/    # Node.js API
│   ├── fastapi_ml/     # Python ML service
│   └── database/       # PostgreSQL schemas
└── docs/              # Documentation
```

## Development Workflow

1. Pick an issue or create one
2. Discuss approach if needed
3. Implement changes
4. Write tests
5. Update documentation
6. Submit PR
7. Address review feedback
8. Merge when approved

## Testing Guidelines

- Write unit tests for new features
- Maintain or improve code coverage
- Test edge cases
- Verify backwards compatibility
- Test on multiple devices/platforms

## Documentation

- Update README files
- Add JSDoc/Dartdoc comments
- Update API documentation
- Include usage examples
- Keep CHANGELOG.md updated

## Questions?

- Open a discussion on GitHub
- Join our community chat
- Email: contribute@onconutri.com

## Recognition

Contributors will be acknowledged in:
- CONTRIBUTORS.md file
- Release notes
- Project documentation

Thank you for contributing to OncoNutri+! 🎉
