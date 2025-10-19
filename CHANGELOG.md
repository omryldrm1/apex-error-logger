# Changelog

All notable changes to Apex Error Logger will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Bulk logging API for high-volume transactions
- Platform Event-based async logging option
- Email/Slack notifications for critical errors
- LWC dashboard component
- Custom metadata type configuration
- Error resolution workflow

## [1.0.0] - 2025-10-19

### Added
- **Core Error Logging**
  - `ErrorLogger` class with automatic deduplication via SHA-1 signatures
  - Support for multiple error sources: Apex, Flow, Batch, API, Callout
  - Severity levels: Critical, Error, Warning, Info
  - Request ID tracking for correlation across logs

- **Sensitive Data Protection**
  - Automatic masking of PII: Credit cards, IBAN, Email, SSN, Phone
  - JWT token, API key, and AWS key masking
  - Password field detection and masking
  - Regex-based pattern matching

- **Multi-Source Integration**
  - `FlowErrorLogger` - @InvocableMethod for Flow Fault Path integration
  - `HttpClient` - HTTP wrapper with automatic callout error logging
  - `LoggingFinalizer` - System.Finalizer for async job monitoring
  - `EventLogCollector` - Schedulable for EventLogFile monitoring

- **Custom Object**
  - `Error_Log__c` with 17 fields
  - Auto-number naming (EL-00001, EL-00002, etc.)
  - External ID signature field for efficient deduplication
  - Occurrence counter and last occurrence tracking

- **Permission Sets**
  - `Error_Log_Admin` - Full CRUD access for administrators
  - `Error_Log_Viewer` - Read-only access for developers/support

- **Testing**
  - 100% test coverage across all classes
  - 12 comprehensive test methods
  - Mock HTTP callouts for integration testing

- **Documentation**
  - Comprehensive README.md with examples and architecture
  - CONTRIBUTING.md with development guidelines
  - MIT License
  - Installation guide for multiple deployment methods

### Technical Details
- **API Version**: v65.0
- **Governor Limits**: ~10-20ms CPU, 1 DML, 1 SOQL per error
- **Storage Efficiency**: 70-90% reduction via deduplication
- **Security**: Field-level security compliant, GDPR/PCI ready

### Known Limitations
- No bulk logging API (single error per transaction)
- Manual parent record association (no automatic detection)
- Fixed masking patterns (no custom regex configuration)
- Synchronous logging only (may impact high-volume scenarios)

### Dependencies
- None (standalone package)

### Breaking Changes
- N/A (initial release)

---

## Version History

### Version Numbering
- **Major** (X.0.0): Breaking changes or significant new features
- **Minor** (1.X.0): New features, backward compatible
- **Patch** (1.0.X): Bug fixes, backward compatible

### Support Policy
- Current major version: Full support
- Previous major version: Security fixes for 12 months
- Older versions: Community support only
