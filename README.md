[![CI](https://github.com/OWNER/REPO/actions/workflows/ci.yml/badge.svg)](.github/workflows/ci.yml)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE) [![Apex](https://img.shields.io/badge/Salesforce-Apex-blue)](#) [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

# Error Log Application

A comprehensive error logging solution for Salesforce applications that captures, aggregates, and securely stores error information.

## Overview

The Error Log application provides centralized error tracking for Salesforce orgs, with features for duplicate suppression, data redaction, and detailed error analysis.

## Key Features

### 1. Error Capture
- Captures exceptions from multiple sources (Apex, Flow, Batch, API, Callouts)
- Rich contextual information including endpoints, HTTP methods, and payloads
- Automatic request ID generation for traceability

### 2. Duplicate Suppression
- Groups similar errors within a 15-minute window
- Uses stable signatures to identify duplicate errors
- Maintains occurrence counts and last occurrence timestamps

### 3. Data Security
- Comprehensive redaction of sensitive information:
  - Email addresses
  - Phone numbers
  - Credit card numbers
  - Authentication tokens
  - UUIDs and timestamps
- Configurable masking patterns

### 4. Flexible Architecture
- Transaction finalizer pattern for reliable post-commit processing
- Bulk-safe DML operations respecting governor limits
- Queueable fallback for high-volume scenarios
- Support for multiple error sources and contexts

## Components

### Custom Objects
- **Error_Log__c**: Main object storing error information

### Apex Classes
- **ErrorLogger**: Main logging entry point with aggregation
- **ErrorSignatureFactory**: Generates stable error signatures
- **RedactionService**: Removes sensitive data from logs
- **LoggingFinalizer**: Processes aggregated records after transaction
- **LoggingFlushQueueable**: Batch processing fallback
- **FlowErrorLogger**: Specialized flow error logging
- **EventLogCollector**: Collects platform event logs

### Permission Sets
- **Error_Log_Admin**: Full access to error logs
- **Error_Log_Viewer**: Read-only access to error logs

## Installation

1. Deploy the package to your Salesforce org
2. Assign the appropriate permission sets to users
3. Configure any custom settings as needed

## Usage

### Basic Logging
```apex
try {
    // Your code here
} catch (Exception e) {
    ErrorLogger.log(e, new ErrorLogger.Context() {
        source = 'Apex',
        severity = 'Error'
    });
}
```

### Flow Integration
Use the `FlowErrorLogger` invocable method in your flows to log flow errors.

## Security

All sensitive data is automatically redacted before storage:
- Personal Identifiable Information (PII)
- Financial information (credit cards, IBAN)
- Authentication credentials
- Internal identifiers and tokens

## Performance

- Optimized for bulk operations
- Respects Salesforce governor limits
- Uses efficient aggregation algorithms
- Minimal impact on transaction performance

## Administration

Administrators can:
- View all error logs with full details
- Analyze error trends and patterns
- Monitor system health and stability
- Configure alerting and reporting

## Support

For issues or feature requests, please submit a GitHub issue in the repository.

## Quick Start

- Deploy:
  - `sf project deploy start --manifest manifest/package.xml --target-org <alias>`
- Assign permission set to see the tab:
  - `sf org assign permset --target-org <alias> --name Error_Log_Admin_FULL`
- Open the app:
  - App Launcher → Error Log → Error Log tab

Notes:
- Utility Bar is optional and excluded from source deploy due to current CLI registry limits. You can add it in Setup → App Manager later if desired.
- The CustomTab `Error_Log__c` is included and wired into the app.
\n## Architecture\n\nSee docs/architecture.md for the flow diagram.\n

