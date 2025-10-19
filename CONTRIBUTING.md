# Contributing to Apex Error Logger

First off, thank you for considering contributing to Apex Error Logger! It's people like you that make this project a valuable resource for the Salesforce community.

## Code of Conduct

This project and everyone participating in it is governed by respect, professionalism, and collaboration. By participating, you are expected to uphold this standard.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include as many details as possible:

**Bug Report Template:**
```markdown
## Environment
- Salesforce Edition: [e.g., Enterprise, Developer]
- API Version: [e.g., v65.0]
- Package Version: [e.g., 1.0.0]

## Steps to Reproduce
1. Go to '...'
2. Execute '....'
3. See error

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened.

## Error Details
- Exception Type: [e.g., NullPointerException]
- Error Message: [Full error message]
- Stack Trace: [If available]

## Screenshots
If applicable, add screenshots.

## Additional Context
Any other context about the problem.
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

**Enhancement Template:**
```markdown
## Problem Statement
Describe the problem you're trying to solve.

## Proposed Solution
Describe your proposed solution in detail.

## Alternatives Considered
What alternative solutions did you consider?

## Additional Context
Any other context, screenshots, or examples.
```

### Pull Requests

#### Development Workflow

1. **Fork the Repository**
   ```bash
   # Fork via GitHub UI, then clone
   git clone https://github.com/YOUR_USERNAME/apex-error-logger.git
   cd apex-error-logger
   ```

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or for bug fixes
   git checkout -b fix/bug-description
   ```

3. **Set Up Development Environment**
   ```bash
   # Authorize your scratch org or developer org
   sf org login web --alias devorg

   # Deploy to your org
   sf project deploy start --target-org devorg

   # Assign permission set
   sf org assign permset --name Error_Log_Admin --target-org devorg
   ```

4. **Make Your Changes**
   - Write clean, readable code
   - Follow existing code style and patterns
   - Add or update tests as needed
   - Update documentation (README, inline comments)

5. **Test Your Changes**
   ```bash
   # Run all tests
   sf apex run test --test-level RunLocalTests --target-org devorg --result-format human

   # Ensure 100% pass rate
   # Check code coverage remains at 100%
   ```

6. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

   **Commit Message Format:**
   - `feat:` New feature
   - `fix:` Bug fix
   - `docs:` Documentation changes
   - `test:` Adding/updating tests
   - `refactor:` Code refactoring
   - `perf:` Performance improvements
   - `chore:` Maintenance tasks

7. **Push and Create Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```

   Then create a Pull Request via GitHub UI with:
   - Clear title describing the change
   - Detailed description of what and why
   - Link to related issues (if any)
   - Screenshots (if UI changes)

#### Pull Request Checklist

Before submitting your PR, ensure:

- [ ] Code follows project style and patterns
- [ ] All tests pass (100% pass rate required)
- [ ] Test coverage remains at 100%
- [ ] Documentation updated (README, inline comments)
- [ ] Commit messages follow convention
- [ ] No unnecessary files added (check .gitignore)
- [ ] PR description clearly explains changes
- [ ] Related issues linked

## Code Style Guidelines

### Apex Code Style

```apex
// ✅ GOOD: Clear naming, proper spacing
public class ErrorLogger {
    public static void log(Exception e, Context ctx) {
        if (e == null) {
            return;
        }

        try {
            Error_Log__c record = buildErrorRecord(e, ctx);
            upsertAggregate(record);
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'ErrorLogger failed: ' + ex.getMessage());
        }
    }
}

// ❌ BAD: Poor naming, no spacing
public class EL {
    public static void l(Exception e,Context c){
        if(e==null)return;
        try{Error_Log__c r=new Error_Log__c();
        insert r;}catch(Exception ex){}
    }
}
```

**Standards:**
- Class names: PascalCase (`ErrorLogger`, `HttpClient`)
- Method names: camelCase (`log`, `buildErrorRecord`)
- Constants: UPPER_SNAKE_CASE (`MAX_RETRIES`, `DEFAULT_TIMEOUT`)
- Variables: camelCase (`errorRecord`, `requestId`)
- Indentation: 4 spaces (no tabs)
- Line length: Max 120 characters
- Braces: Same line for opening, new line for closing

### Documentation Style

```apex
/**
 * @description Logs exceptions with context and automatic deduplication
 * @param e The exception to log (required)
 * @param ctx Additional context information (optional)
 * @example
 * try {
 *     riskyOperation();
 * } catch (Exception e) {
 *     ErrorLogger.Context ctx = new ErrorLogger.Context();
 *     ctx.severity = 'Critical';
 *     ErrorLogger.log(e, ctx);
 * }
 */
public static void log(Exception e, Context ctx) {
    // Implementation
}
```

### Test Class Standards

```apex
@IsTest
private class ErrorLoggerTest {
    @IsTest
    static void testLogSimpleException() {
        // Arrange
        Exception testException = new NullPointerException('Test error');

        // Act
        Test.startTest();
        ErrorLogger.log(testException, null);
        Test.stopTest();

        // Assert
        List<Error_Log__c> logs = [SELECT Id, Exception_Type__c FROM Error_Log__c];
        System.assertEquals(1, logs.size(), 'Should create one log');
        System.assertEquals('NullPointerException', logs[0].Exception_Type__c);
    }
}
```

**Test Requirements:**
- Every public method must have test coverage
- Use Arrange-Act-Assert pattern
- Descriptive test method names (`testLogSimpleException`, not `test1`)
- Test positive cases, negative cases, and edge cases
- Use `System.assertEquals()` with descriptive failure messages
- Mock external services (HTTP callouts, etc.)

## Project Structure

```
apex-error-logger/
├── .github/
│   └── workflows/           # CI/CD workflows (future)
├── docs/
│   └── images/              # Documentation images
├── force-app/
│   └── main/
│       └── default/
│           ├── classes/     # Apex classes and tests
│           ├── objects/     # Custom objects
│           ├── permissionsets/  # Permission sets
│           └── tabs/        # Custom tabs (if any)
├── scripts/
│   └── apex/                # Anonymous Apex scripts
├── .gitignore
├── CHANGELOG.md
├── CONTRIBUTING.md          # This file
├── LICENSE
├── README.md
└── sfdx-project.json
```

## Adding New Features

### Feature Development Checklist

When adding a new feature:

1. **Planning**
   - [ ] Create GitHub issue describing the feature
   - [ ] Discuss approach with maintainers (for major features)
   - [ ] Design API/interface (if applicable)

2. **Implementation**
   - [ ] Create feature branch
   - [ ] Implement core functionality
   - [ ] Add error handling
   - [ ] Update ErrorLogger if needed

3. **Testing**
   - [ ] Write unit tests (100% coverage required)
   - [ ] Test in scratch org/sandbox
   - [ ] Test edge cases and error scenarios
   - [ ] Verify existing functionality unaffected

4. **Documentation**
   - [ ] Update README.md with usage examples
   - [ ] Add inline code documentation
   - [ ] Update CHANGELOG.md
   - [ ] Add to roadmap (if long-term feature)

5. **Review**
   - [ ] Self-review code changes
   - [ ] Ensure style guidelines followed
   - [ ] Create pull request
   - [ ] Address review feedback

## Testing Requirements

### Unit Tests
- **Coverage**: 100% of all methods
- **Assertions**: Every test must have meaningful assertions
- **Independence**: Tests must not depend on each other
- **Data**: Create test data within test methods (no @TestSetup unless needed)

### Integration Tests
For features interacting with external systems:
- Use `Test.setMock()` for HTTP callouts
- Test success and failure scenarios
- Verify error logging in failure cases

### Example Test Structure
```apex
@IsTest
private class YourFeatureTest {
    @IsTest
    static void testSuccessScenario() {
        // Arrange: Set up test data and mocks

        // Act: Execute the feature
        Test.startTest();
        YourFeature.execute();
        Test.stopTest();

        // Assert: Verify expected behavior
        System.assertEquals(expected, actual, 'Failure message');
    }

    @IsTest
    static void testErrorScenario() {
        // Arrange

        // Act
        Test.startTest();
        try {
            YourFeature.executeWithError();
            System.assert(false, 'Should throw exception');
        } catch (Exception e) {
            // Expected exception
        }
        Test.stopTest();

        // Assert: Verify error was logged
        List<Error_Log__c> logs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(1, logs.size(), 'Should log error');
    }
}
```

## Documentation Guidelines

### README.md Updates
- Keep examples up to date
- Add new features to feature list
- Update installation instructions if needed
- Maintain table of contents accuracy

### Code Comments
```apex
// ✅ GOOD: Explains WHY, not WHAT
// Use SHA-1 for backward compatibility with existing signatures
String signature = Crypto.generateDigest('SHA-1', data);

// ❌ BAD: States the obvious
// Generate SHA-1 hash
String signature = Crypto.generateDigest('SHA-1', data);
```

### Change Log Format
```markdown
## [1.1.0] - 2025-02-15

### Added
- New feature X with Y capability
- Support for Z integration

### Changed
- Improved performance of deduplication by 30%
- Updated masking patterns for new PII formats

### Fixed
- Bug #123: Error when payload exceeds 32KB
- Bug #124: Null pointer in Flow integration

### Deprecated
- Old API method (will be removed in v2.0)
```

## Release Process

(For maintainers)

1. Update version in `sfdx-project.json`
2. Update `CHANGELOG.md` with release notes
3. Create GitHub release with tag (v1.1.0)
4. Build and publish unmanaged package
5. Update README.md with new package installation URL
6. Announce in Salesforce community forums

## Getting Help

- **Questions**: Open a GitHub Discussion
- **Bugs**: Create a GitHub Issue with bug template
- **Feature Requests**: Create a GitHub Issue with enhancement template
- **General**: Post in Trailblazer Community with tag `apex-error-logger`

## Recognition

Contributors will be recognized in:
- GitHub contributors list
- README.md credits section
- Release notes for significant contributions

Thank you for contributing to Apex Error Logger! 🚀
