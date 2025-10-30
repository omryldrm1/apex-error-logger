[![CI](https://github.com/OWNER/REPO/actions/workflows/ci.yml/badge.svg)](.github/workflows/ci.yml)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE) [![Apex](https://img.shields.io/badge/Salesforce-Apex-blue)](#) [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

# Apex Error Logger

> Centralized, governance-safe error logging for Salesforce orgs with duplicate suppression, data redaction, and admin-ready analytics.

## Table of Contents

- [Overview](#overview)
- [Feature Highlights](#feature-highlights)
- [Architecture](#architecture)
- [Installation](#installation)
- [Usage](#usage)
- [Data Model & Security](#data-model--security)
- [Operations & Monitoring](#operations--monitoring)
- [Testing & CI](#testing--ci)
- [Support & Contributions](#support--contributions)
- [License](#license)

## Overview

- **Audience:** Salesforce engineering and architecture teams who need reliable post-commit error capture.
- **Problem solved:** Disparate exception handling, noisy duplicates, and unsafe storage of sensitive payloads.
- **Approach:** Transaction-finalizer + queueable pipeline that buffers, deduplicates, redacts, and persists to `Error_Log__c`.
- **Outcome:** Actionable dashboards, clean audit trail, and a low-friction developer API for Apex, Flow, callouts, and platform events.

## Feature Highlights

- **Unified capture layer** for Apex, Flows, Batch jobs, REST integrations, and callouts (via bundled `HttpClient`).
- **Duplicate suppression** using normalized signatures and occurrence counters within a configurable time window.
- **PII-aware redaction** of emails, phones, PAN/IBAN, tokens, UUIDs, and passwords before persistence.
- **Resilient persistence** leveraging transaction finalizers plus a chunked queueable fallback for high-volume spikes.
- **Admin tooling** with custom application, tab, and permission sets (`Error_Log_Admin`, `Error_Log_Admin_FULL`, `Error_Log_Viewer`).

## Architecture

- Logical flow: exception -> redaction -> signature -> in-memory aggregation -> finalizer/queueable -> `Error_Log__c`.
- See the full sequence diagram in [`docs/architecture.md`](docs/architecture.md).
- Utility Bar support is optional and can be enabled in-app once Salesforce CLI adds registry support for `UtilityBar` metadata.

## Installation

### Prerequisites

- Salesforce CLI (`sf`) v2.0+ and source tracking enabled.
- API version 65.0 or later available in the target org.
- Deploying user with `Modify All Data` (or similar) for metadata deployment.

### Option 1 � Install Unmanaged Package

- Click to install in Production/Developer org:
  - https://login.salesforce.com/packaging/installPackage.apexp?p0=04tg50000000OtZ
- Installing into a Sandbox? Use:
  - https://test.salesforce.com/packaging/installPackage.apexp?p0=04tg50000000OtZ



### Option 2 - Deploy from Source (recommended for evaluation)

```bash
# Authorize an org if needed
sf org login web --alias MyErrorLogOrg

# Push the metadata
sf project deploy start \
  --manifest manifest/package.xml \
  --target-org MyErrorLogOrg \
  --ignore-conflicts \
  --test-level NoTestRun

# Assign full admin rights to your user
sf org assign permset --target-org MyErrorLogOrg --name Error_Log_Admin_FULL
```

### Post-Install Checklist

1. App Launcher → **Error Log** → ensure the **Error Log** tab is visible (restore app defaults if needed).
2. Confirm permission sets are assigned to intended users (`Admin`, `Admin_FULL`, `Viewer`).
3. (Optional) Recreate the Utility Bar via Setup → App Manager → Error Log → Utility Items.
4. Schedule the `EventLogCollector` (if you want daily EventLog ingestion).

## Usage

### Apex

```apex
try {
    // business logic
} catch (Exception ex) {
    ErrorLogger.Context ctx = new ErrorLogger.Context();
    ctx.source = 'Apex';
    ctx.severity = 'Error';
    ErrorLogger.log(ex, ctx);
}
```

### Flow

- Drag the **Log Flow Error** invocable action (`FlowErrorLogger`) and pass message, severity, and optional parent record context.

### Callouts / Integrations

- Wrap callouts with the provided `HttpClient.send(req)` helper. Non-2xx responses and exceptions are logged automatically with request/response payload scrubbing.

### Batch / Platform Events

- Attach `LoggingFinalizer` via `System.attachFinalizer` for post-commit flushes.
- Use `EventLogCollector` (schedulable) to persist selected `EventLogFile` entries as informational logs.

## Data Model & Security

- **Object:** `Error_Log__c` with auto-number name (`EL-{00000}`) and reporting/search enabled.
- **Key fields:** `Severity__c`, `Source__c`, `Signature__c`, `Occurrence_Count__c`, `Last_Occurrence__c`, HTTP context, payload, and parent references.
- **Redaction:** `RedactionService` sanitizes messages, payloads, and stack traces before writing; extend by editing pattern lists or externalizing via CMDT in future.
- **Storage safety:** Long text areas are truncated to governor-safe lengths during finalizer/queueable persistence.

## Operations & Monitoring

- Build dashboards/reports on `Error_Log__c` for trend analysis (Severity by day, most common endpoints, etc.).
- Use the included permission sets to separate admin (CRUD) and viewer (read-only) personas.
- Consider adding Platform Event or Email alerts for `Critical` severity records via Flow/Process Builder.

## Testing & CI

- Run the packaged unit tests:

  ```bash
  sf apex test run --target-org MyErrorLogOrg --wait 60 --result-format human --code-coverage
  ```

- GitHub Actions workflow (`.github/workflows/ci.yml`) performs manifest validation. Set a repository secret `SF_AUTH_URL` to enable authenticated validate-only deploys and Apex tests in CI.

## Support & Contributions

- Issues and feature requests: open a ticket via the **Issues** tab.
- Contributions are welcome—see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines and code style.
- Security concerns: follow the disclosure instructions in [SECURITY.md](.github/SECURITY.md).

## License

- MIT. See [LICENSE](LICENSE) for details.





