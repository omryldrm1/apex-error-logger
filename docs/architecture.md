# Architecture

```mermaid
flowchart TD
    A[Your Code / Flows / Integrations] -->|Exceptions| B(ErrorLogger.log)
    B --> C[RedactionService]
    C --> D[ErrorSignatureFactory]
    D --> E[Buffer + Aggregate]
    E --> F[Transaction Finalizer]
    F -->|small/normal volume| G[(Insert Error_Log__c)]
    F -->|optional high volume| H[LoggingFlushQueueable]
    H --> I[(Insert in chunks)]

    subgraph Storage
      G
      I
    end
```

- Sensitive data is scrubbed before persistence.
- Duplicate suppression groups same errors within a short window using a stable signature.
- Finalizer persists records post-commit; queueable is available for high-volume scenarios.
