/**
 * @description Queueable job that performs batched insert/update of Error_Log__c records.
 * Used as a fallback when post-commit processing should be decoupled or for tests to flush buffers.
 *
 * DESIGN:
 *  - Accepts a prebuilt list of Error_Log__c records to persist (optional).
 *  - If no list is provided, reads from ErrorLogger's in-memory buffer.
 *  - Deduplicates by Signature__c and aggregates occurrence count + last occurrence.
 *  - Performs DML in chunks, runs in USER_MODE.
 */
public with sharing class LoggingFlushQueueable implements Queueable {

    public LoggingFlushQueueable() {
        this(null, false);
    }

    private List<Error_Log__c> logs;
    private Boolean upsertBySignature;

    /**
     * @param logs Records to persist (optional)
     * @param upsertBySignature If true, upsert by Signature__c (not used by default).
     */
    public LoggingFlushQueueable(List<Error_Log__c> logs, Boolean upsertBySignature) {
        this.logs = logs == null ? new List<Error_Log__c>() : logs.deepClone(true, true, true);
        this.upsertBySignature = upsertBySignature == null ? false : upsertBySignature;
    }

    public void execute(QueueableContext qc) {
        // Populate from ErrorLogger buffer if none provided
        if (logs == null) logs = new List<Error_Log__c>();
        if (logs.isEmpty()) {
            try {
                List<Error_Log__c> buf = ErrorLogger.getBufferedRecords();
                if (buf != null) logs.addAll(buf);
            } catch (Exception ignore) {
            }
        }
        if (logs.isEmpty()) return;

        // Truncate oversized long text fields defensively
        for (Error_Log__c r : logs) {
            r.Message__c = truncate(r.Message__c, 131000);
            r.Stacktrace__c = truncate(r.Stacktrace__c, 131000);
            r.Payload__c = truncate(r.Payload__c, 131000);
        }

        // Deduplicate by Signature__c and compute occurrence count + last occurrence
        Map<String, Error_Log__c> baseBySig = new Map<String, Error_Log__c>();
        Map<String, Integer> counts = new Map<String, Integer>();
        Map<String, DateTime> lastAt = new Map<String, DateTime>();
        for (Error_Log__c r : logs) {
            String sig = String.isBlank(r.Signature__c) ? r.Exception_Type__c + '|' + r.Message__c : r.Signature__c;
            if (!baseBySig.containsKey(sig)) {
                Error_Log__c base = r.clone(false, true, false, false);
                base.Occurrence_Count__c = 1;
                base.Last_Occurrence__c = r.Occurred_At__c;
                baseBySig.put(sig, base);
                counts.put(sig, 1);
                lastAt.put(sig, r.Occurred_At__c);
            } else {
                counts.put(sig, counts.get(sig) + 1);
                DateTime prev = lastAt.get(sig);
                DateTime nowt = r.Occurred_At__c;
                if (prev == null || (nowt != null && nowt.getTime() > prev.getTime())) {
                    lastAt.put(sig, nowt);
                }
            }
        }
        List<Error_Log__c> deduped = new List<Error_Log__c>();
        for (String sig : baseBySig.keySet()) {
            Error_Log__c rec = baseBySig.get(sig);
            rec.Occurrence_Count__c = counts.get(sig);
            rec.Last_Occurrence__c = lastAt.get(sig);
            deduped.add(rec);
        }

        // Chunked insert in USER_MODE
        final Integer CHUNK = 150;
        for (Integer i = 0; i < deduped.size(); i += CHUNK) {
            Integer endIndex = Math.min(i + CHUNK, deduped.size());
            List<Error_Log__c> slice = new List<Error_Log__c>();
            for (Integer j = i; j < endIndex; j++) slice.add(deduped[j]);
            Database.SaveResult[] sr = Database.insert(slice, false, AccessLevel.USER_MODE);
            handleResults(sr, slice);
        }
    }

    private static void handleResults(Database.SaveResult[] results, List<Error_Log__c> slice) {
        // Best-effort logging of failures as separate system logs.
        for (Integer idx = 0; idx < results.size(); idx++) {
            Database.SaveResult r = results[idx];
            if (!r.isSuccess()) {
                // Swallow to avoid recursion
                String err = 'Error_Log__c DML failed: ' + joinErrors(r.getErrors());
            }
        }
    }

    private static String joinErrors(Database.Error[] errs) {
        if (errs == null || errs.isEmpty()) return 'Unknown error';
        List<String> msgs = new List<String>();
        for (Database.Error e : errs) {
            msgs.add((e.getStatusCode() == null ? '' : String.valueOf(e.getStatusCode())) + ':' + e.getMessage());
        }
        return String.join(msgs, ' | ');
    }

    private static String truncate(String s, Integer maxLen) {
        if (s == null) return null;
        if (maxLen == null || maxLen <= 0) return s;
        return s.length() > maxLen ? s.substring(0, maxLen) : s;
    }
}

