# Apex Error Logger

Enterprise-grade error logging for Salesforce (Apex, Flow, Batch, API, Callouts) with deduplication and sensitive data masking.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Apex](https://img.shields.io/badge/Apex-v65.0-blue.svg)](https://developer.salesforce.com/)

## What You Get
- Deduplicated errors (SHA‑1 signature) with occurrence counts
- PII masking (PAN, IBAN, Email, SSN, Phone, JWT, API/AWS keys)
- Multi‑source support (Apex, Flow, Batch, API, Callout)
- HTTP wrapper with automatic error capture
- Batch/Queueable finalizer logging
- EventLogFile collector (schedulable)
- Permission sets: `Error_Log_Admin`, `Error_Log_Viewer`

## Install

Option A — Unmanaged Package (recommended)
- Production/Developer: `https://login.salesforce.com/packaging/installPackage.apexp?p0=04tg50000000OiH`
- Sandbox: `https://test.salesforce.com/packaging/installPackage.apexp?p0=04tg50000000OiH`

Option B — Salesforce CLI
```bash
git clone https://github.com/omryldrm1/apex-error-logger.git
cd apex-error-logger
sf project deploy start --target-org YOUR_ORG
sf org assign permset --name Error_Log_Admin --target-org YOUR_ORG
```

Managed Package (Coming Soon)
- A namespaced 2GP build will be published. Follow this repo for updates.

## Quick Start

Log an exception in Apex
```apex
try {
    // your code
} catch (Exception e) {
    ErrorLogger.log(e, null);
}
```

Add context
```apex
ErrorLogger.Context ctx = new ErrorLogger.Context();
ctx.source = 'Apex';
ctx.severity = 'Error';
ctx.parentObject = 'Account';
ctx.parentRecordId = someAccountId;
ErrorLogger.log(new DmlException('Oops'), ctx);
```

Flow fault path
1) Add Action → Log Flow Error
2) Set Message, optional Severity/Parent fields

HTTP callouts
```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('https://api.example.com/data');
req.setMethod('GET');
HttpResponse res = HttpClient.send(req); // logs 3xx/4xx/5xx
```

## Troubleshooting
- No logs? Ensure permission set assigned and `ErrorLogger.log()` is called.
- Duplicates not aggregating? Verify `Signature__c` is External ID.
- Sensitive data visible? Review masking rules in `ErrorLogger.mask()`.

## Packaging
- Unmanaged: see `docs/PACKAGING.md`.
- Managed (2GP): Coming soon.

## License
MIT — see `LICENSE`.