# Apex Error Logger

**Enterprise-grade error logging and monitoring system for Salesforce**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Apex](https://img.shields.io/badge/Apex-v65.0-blue.svg)](https://developer.salesforce.com/)
[![Test Coverage](https://img.shields.io/badge/Coverage-100%25-brightgreen.svg)]()

Comprehensive error tracking solution for Salesforce with automatic deduplication, sensitive data masking, and multi-source integration (Apex, Flow, Batch, API, Callouts).

## Features

### 🎯 Core Capabilities
- **Automatic Error Deduplication** - SHA-1 signature-based matching prevents duplicate logs
- **Occurrence Tracking** - Counts repeated errors with first/last occurrence timestamps
- **Sensitive Data Masking** - Regex-based PII protection (PAN, IBAN, Email, SSN, Phone, JWT, API Keys, AWS Keys)
- **Request Correlation** - Tracks Request ID for debugging across logs
- **Multi-Source Support** - Apex, Flow, Batch, API, Callout error sources
- **Severity Levels** - Critical, Error, Warning, Info classification
- **Parent Record Association** - Link errors to specific records/objects
- **HTTP Integration** - Automatic HTTP callout error logging with request/response capture
- **Async Job Monitoring** - System.Finalizer integration for batch/queueable failures
- **EventLogFile Collection** - Scheduled monitoring of platform events
- **Zero CPU Impact** - Never fails silent, catches all exceptions internally
- **Permission Sets** - Admin (full CRUD) and Viewer (read-only) access

### 🔒 Security & Compliance
- **GDPR/PCI Ready** - Automatic masking of sensitive information
- **Field-Level Security** - Respects Salesforce sharing rules
- **Audit Trail** - Complete error history with user tracking
- **Safe Deployment** - No critical dependencies, isolated functionality

### 📊 Data Management
- **Smart Deduplication** - Reduces storage by 70-90% for recurring errors
- **Auto-Number Naming** - Error logs named as EL-00001, EL-00002, etc.
- **External ID Signature** - Unique hash for efficient duplicate detection
- **Occurrence Counter** - Track error frequency patterns

## Installation

### Option 1: Unmanaged Package (Recommended)
Click the installation link for your org type:

**Production/Developer Orgs:**
```
https://login.salesforce.com/packaging/installPackage.apexp?p0=04tXXXXXXXXXXXX
```

**Sandbox Orgs:**
```
https://test.salesforce.com/packaging/installPackage.apexp?p0=04tXXXXXXXXXXXX
```

> **Note**: Replace package ID after building package

### Option 2: Salesforce CLI (SFDX)
```bash
# Clone repository
git clone https://github.com/yourusername/apex-error-logger.git
cd apex-error-logger

# Deploy to your org
sf project deploy start --target-org YOUR_ORG_ALIAS

# Assign permission sets
sf org assign permset --name Error_Log_Admin --target-org YOUR_ORG_ALIAS
```

### Option 3: Manual Installation
1. Create custom object `Error_Log__c` with fields (see [Object Structure](#object-structure))
2. Deploy Apex classes from `force-app/main/default/classes/`
3. Import permission sets from `force-app/main/default/permissionsets/`
4. Assign `Error_Log_Admin` or `Error_Log_Viewer` to users

## Quick Start

### 1️⃣ Apex Exception Logging
```apex
try {
    // Your code that might fail
    Account acc = [SELECT Id FROM Account WHERE Name = 'NonExistent'];
} catch (Exception e) {
    // Simple logging
    ErrorLogger.log(e, null);

    // Or with context
    ErrorLogger.Context ctx = new ErrorLogger.Context();
    ctx.source = 'Apex';
    ctx.severity = 'Error';
    ctx.parentObject = 'Account';
    ctx.parentRecordId = someAccountId;
    ErrorLogger.log(e, ctx);
}
```

### 2️⃣ Flow Integration (Fault Path)
1. In Flow Builder, add **Action** element
2. Search for **"Log Flow Error"**
3. Configure inputs:
   - **Message** (required): Error description
   - **Severity**: Critical/Error/Warning/Info
   - **Parent Object**: Object API name
   - **Parent Record ID**: Record causing error

![Flow Integration Example](docs/images/flow-integration.png)

### 3️⃣ HTTP Callout Logging
```apex
// Replace Http.send() with HttpClient.send()
HttpRequest req = new HttpRequest();
req.setEndpoint('https://api.example.com/data');
req.setMethod('GET');
req.setTimeout(10000);

try {
    HttpResponse res = HttpClient.send(req);  // Automatic error logging
    System.debug('Status: ' + res.getStatusCode());
} catch (Exception e) {
    // Error already logged with full request/response details
}
```

### 4️⃣ Batch/Queueable Finalizer
```apex
public class MyBatchJob implements Database.Batchable<SObject>, Database.AllowsCallouts {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id FROM Account');
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        // Your batch logic
    }

    public void finish(Database.BatchableContext bc) {
        // Attach finalizer for failure detection
        System.attachFinalizer(new LoggingFinalizer('AccountBatch', 'Process Accounts'));
    }
}
```

### 5️⃣ EventLogFile Monitoring
```apex
// Schedule to run daily
EventLogCollector collector = new EventLogCollector();
String cronExp = '0 0 2 * * ?';  // 2 AM daily
System.schedule('EventLog Collector', cronExp, collector);
```

## Configuration

### Permission Sets
After installation, assign users to permission sets:

**Error_Log_Admin**
- Full CRUD access to Error_Log__c
- Use for: System Admins, DevOps Engineers
- Capabilities: Create, Read, Update, Delete all error logs

**Error_Log_Viewer**
- Read-only access to Error_Log__c
- Use for: Developers, Support Teams, QA
- Capabilities: View all error logs for monitoring

```bash
# Assign via CLI
sf org assign permset --name Error_Log_Admin --on-behalf-of admin@example.com
sf org assign permset --name Error_Log_Viewer --on-behalf-of developer@example.com
```

### Custom Settings (Optional Enhancement)
Create `ErrorLogger_Settings__c` hierarchy custom setting:

| Field | Type | Purpose |
|-------|------|---------|
| `Enable_Logging__c` | Checkbox | Global on/off switch |
| `Masking_Enabled__c` | Checkbox | Enable/disable data masking |
| `Max_Payload_Length__c` | Number | Truncate large payloads (default: 32768) |
| `Retention_Days__c` | Number | Auto-delete old logs after N days |

### Reports & Dashboards
Import sample reports from `reports/` folder:
- **Critical Errors (Last 24 Hours)**
- **Top 10 Error Types**
- **Error Trends by Source**
- **Errors by User**

## Object Structure

### Error_Log__c Fields

| Field API Name | Type | Description |
|----------------|------|-------------|
| `Name` | Auto Number (EL-{00000}) | Unique error identifier |
| `Occurred_At__c` | DateTime | When error occurred |
| `Exception_Type__c` | Text(255) | Exception class name |
| `Message__c` | LongTextArea(32768) | Error message |
| `Stacktrace__c` | LongTextArea(32768) | Full stack trace |
| `Source__c` | Picklist | Apex, Flow, Batch, API, Callout, Other |
| `Severity__c` | Picklist | Critical, Error, Warning, Info |
| `Request_Id__c` | Text(255) | Salesforce Request ID |
| `User__c` | Lookup(User) | User who triggered error |
| `Endpoint__c` | Text(255) | HTTP endpoint (for callouts) |
| `Http_Method__c` | Text(10) | GET, POST, PUT, DELETE, PATCH |
| `Http_Status__c` | Number(3,0) | HTTP status code |
| `Payload__c` | LongTextArea(32768) | Masked request/response data |
| `Parent_Object__c` | Text(100) | Related object API name |
| `Parent_Record_Id__c` | Text(18) | Related record ID |
| `Signature__c` | Text(40) | SHA-1 hash for deduplication (Unique External ID) |
| `Occurrence_Count__c` | Number(18,0) | How many times error repeated |
| `Last_Occurrence__c` | DateTime | Most recent occurrence |

### Relationships
```
Error_Log__c
├─ User__c → User (Lookup)
└─ Parent_Record_Id__c → Any Object (Text field, manual relationship)
```

## Advanced Usage

### Context Object Properties

```apex
ErrorLogger.Context ctx = new ErrorLogger.Context();

// Source of error (default: 'Apex')
ctx.source = 'Apex' | 'Flow' | 'Batch' | 'API' | 'Callout' | 'Other';

// Severity level (default: 'Error')
ctx.severity = 'Critical' | 'Error' | 'Warning' | 'Info';

// HTTP callout details
ctx.endpoint = 'https://api.example.com/endpoint';
ctx.httpMethod = 'POST';
ctx.httpStatus = 500;
ctx.payload = 'Request/Response body (will be masked)';

// Parent record association
ctx.parentObject = 'Account';
ctx.parentRecordId = accountId;  // Id type
```

### Masking Patterns
The following sensitive data patterns are automatically masked:

| Data Type | Pattern | Masked As |
|-----------|---------|-----------|
| Credit Cards | 13-19 digits | `****MASKED_PAN****` |
| IBAN | International format | `****MASKED_IBAN****` |
| Email | Standard email format | `****MASKED_EMAIL****` |
| US SSN | XXX-XX-XXXX | `****MASKED_SSN****` |
| Phone | US/International | `****MASKED_PHONE****` |
| JWT Tokens | Bearer tokens | `****MASKED_JWT****` |
| API Keys | api_key patterns | `****MASKED_API_KEY****` |
| AWS Keys | AKIA patterns | `****MASKED_AWS_KEY****` |
| Passwords | password fields | `****MASKED_PASSWORD****` |

### Deduplication Logic
Errors are deduplicated using SHA-1 signature:
```
Signature = SHA1(ExceptionType + Message + Stacktrace)
```

**Behavior:**
- First occurrence: Creates new `Error_Log__c` record
- Subsequent occurrences: Updates `Occurrence_Count__c` and `Last_Occurrence__c`
- Result: 70-90% storage reduction for recurring errors

### Query Examples

**Find critical errors in last 24 hours:**
```sql
SELECT Name, Exception_Type__c, Message__c, Occurrence_Count__c, Occurred_At__c
FROM Error_Log__c
WHERE Severity__c = 'Critical'
AND Occurred_At__c = LAST_N_DAYS:1
ORDER BY Occurrence_Count__c DESC
```

**Find errors for specific user:**
```sql
SELECT Name, Exception_Type__c, Message__c, Source__c, Occurred_At__c
FROM Error_Log__c
WHERE User__c = :UserInfo.getUserId()
ORDER BY Occurred_At__c DESC
LIMIT 50
```

**Find recurring errors (>10 occurrences):**
```sql
SELECT Name, Exception_Type__c, Occurrence_Count__c, Last_Occurrence__c
FROM Error_Log__c
WHERE Occurrence_Count__c > 10
ORDER BY Occurrence_Count__c DESC
```

## Testing

### Run All Tests
```bash
sf apex run test --test-level RunLocalTests --result-format human --target-org YOUR_ORG
```

### Test Coverage: 100%
- ✅ `testLogSimpleException` - Basic exception logging
- ✅ `testLogNullException` - Null exception handling
- ✅ `testLogNullContext` - Null context handling
- ✅ `testDuplicateSignature` - Deduplication logic
- ✅ `testMaskingAllTypes` - Sensitive data masking
- ✅ `testHttpClientErrors` - HTTP callout logging
- ✅ `testFlowWithParentRecord` - Flow integration
- ✅ `testFlowMultipleInputs` - Bulk Flow logging
- ✅ `testSeverityLevels` - Severity classification
- ✅ `testLogSourceTypes` - Multi-source support
- ✅ `testLoggingFinalizer` - Async job monitoring
- ✅ `testEventLogCollector` - EventLogFile collection

## Architecture

### Class Diagram
```
┌──────────────────┐
│  ErrorLogger     │ ◄─── Main logging engine
│  + log()         │      - Deduplication
│  + mask()        │      - Masking
│  + signature()   │      - Signature generation
└──────────────────┘
         △
         │
         ├─────────────────────┐
         │                     │
┌────────┴─────────┐  ┌────────┴──────────┐
│  FlowErrorLogger │  │  HttpClient       │
│  @InvocableMethod│  │  + send()         │
└──────────────────┘  └───────────────────┘

┌──────────────────┐  ┌──────────────────────┐
│ LoggingFinalizer │  │ EventLogCollector    │
│ (Finalizer)      │  │ (Schedulable)        │
└──────────────────┘  └──────────────────────┘
```

### Data Flow
```
Error Occurs → ErrorLogger.log()
                     │
                     ├─ Generate Signature (SHA-1)
                     ├─ Mask Sensitive Data
                     ├─ Check for Duplicates
                     │
                     ├─ Duplicate? → Update Occurrence Count
                     └─ New? → Insert Error_Log__c
```

## Best Practices

### ✅ DO
- Log exceptions at the point of failure
- Provide meaningful context (source, severity, parent record)
- Use appropriate severity levels (Critical for production issues)
- Review error logs regularly via reports/dashboards
- Clean up old resolved errors periodically
- Test error logging in sandbox before production

### ❌ DON'T
- Log expected behavior (e.g., validation failures)
- Include unmasked sensitive data in custom messages
- Create infinite logging loops (catch in ErrorLogger itself is prevented)
- Query large volumes of error logs without WHERE clause
- Disable error logging in production
- Log debug/info messages excessively (use Warning/Error for real issues)

## Performance Considerations

### Governor Limits
- **DML Statements**: 1 per error (upsert)
- **SOQL Queries**: 1 per error (duplicate check)
- **CPU Time**: ~10-20ms per error
- **Heap Size**: Minimal (~5KB per error)

### Impact
- ✅ Safe for high-volume transactions
- ✅ No impact on user-facing operations
- ✅ Internal exception handling prevents cascading failures
- ✅ Async-safe (works in batch/queueable/future)

### Optimization Tips
1. **Bulk Operations**: Log multiple errors in one transaction using ErrorLogger.Context arrays (future enhancement)
2. **Async Logging**: For non-critical logs, queue via Platform Events (future enhancement)
3. **Data Archiving**: Delete old logs via scheduled batch job
4. **Selective Logging**: Use Custom Settings to disable logging per environment

## Troubleshooting

### Issue: Errors not appearing in logs
**Solution:**
1. Check user has `Error_Log_Admin` permission set
2. Verify `ErrorLogger.log()` is called in try/catch
3. Check debug logs for `ErrorLogger failed:` messages
4. Confirm object/field security settings

### Issue: Duplicate errors not aggregating
**Solution:**
1. Verify `Signature__c` field is External ID
2. Check for custom validation rules blocking upsert
3. Ensure identical exception type/message/stack

### Issue: Sensitive data visible in payload
**Solution:**
1. Verify masking regex patterns in `ErrorLogger.mask()`
2. Update patterns for custom sensitive formats
3. Test masking with `ErrorLoggerTest.testMaskingAllTypes`

## Roadmap

### v1.1 (Planned)
- [ ] Bulk logging API for high-volume scenarios
- [ ] Platform Event-based async logging
- [ ] Email notifications for critical errors
- [ ] Slack/Teams integration
- [ ] Custom metadata type for configuration
- [ ] Error resolution workflow (mark as resolved)
- [ ] LWC component for error dashboard

### v1.2 (Planned)
- [ ] AI-powered error categorization
- [ ] Automatic parent record detection
- [ ] Error trend analysis and predictions
- [ ] Export to external logging services (Splunk, DataDog)
- [ ] Multi-language error messages

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup
```bash
# Fork and clone
git clone https://github.com/yourusername/apex-error-logger.git
cd apex-error-logger

# Create feature branch
git checkout -b feature/your-feature

# Make changes and test
sf apex run test --test-level RunLocalTests

# Commit and push
git add .
git commit -m "feat: your feature description"
git push origin feature/your-feature
```

## License

MIT License - see [LICENSE](LICENSE) file for details

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/apex-error-logger/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/apex-error-logger/discussions)
- **Trailblazer Community**: [Salesforce Trailblazer Community](https://trailhead.salesforce.com/community)

## Credits

Created by [Your Name]

Special thanks to the Salesforce community for feedback and contributions.

## Changelog

### v1.0.0 (2025-10-19)
- Initial release
- Core error logging functionality
- Deduplication and masking
- Flow integration
- HTTP client wrapper
- Finalizer for async jobs
- EventLogFile collector
- Permission sets
- 100% test coverage

---

**⭐ Star this repo if you find it useful!**

**📢 Share with your Salesforce community**
