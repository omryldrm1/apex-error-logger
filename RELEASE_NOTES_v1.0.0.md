# v1.0.0 — Apex Error Logger

Initial public release.

## Highlights
- Core error logging engine with context object
- SHA-1 signature deduplication + occurrence tracking
- Sensitive data masking (PAN, IBAN, Email, SSN, Phone, JWT, API/AWS keys)
- Flow invocable action (Log Flow Error)
- HTTP client wrapper with automatic error capture
- Finalizer for Batch/Queueable failures
- EventLogFile collector (schedulable)
- Admin and Viewer permission sets
- 100% local test coverage

## Installation

Unmanaged package (replace with your Package ID after upload):

Production/Developer:
https://login.salesforce.com/packaging/installPackage.apexp?p0=04tXXXXXXXXXXXX

Sandbox:
https://test.salesforce.com/packaging/installPackage.apexp?p0=04tXXXXXXXXXXXX

## Notes
- Requires Salesforce API v65.0+
- See README for setup, samples, and troubleshooting

