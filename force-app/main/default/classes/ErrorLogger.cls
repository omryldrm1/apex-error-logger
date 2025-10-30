public with sharing class ErrorLogger {
    @TestVisible private static Integer testInsertCount = 0;
    @TestVisible private static Integer testUpdateCount = 0;
    @TestVisible private static Boolean flusherScheduled = false;
    @TestVisible private static Integer testInvocationCount = 0;
    @TestVisible private static String lastErrorMessage;
    @TestVisible private static Boolean simulateDuplicateOnInsert = false;
    @TestVisible private static Boolean forceNoWindowMatch = false;

    private static List<Error_Log__c> buffer = new List<Error_Log__c>();
    private static Map<String, AggregateRecord> aggregationMap = new Map<String, AggregateRecord>();

    private static final Integer DUPLICATE_WINDOW_MINUTES = 15;
    private static final Integer MAX_LONG_TEXT_LENGTH = 131000;
    private static final Integer SIGNATURE_MAX_LENGTH = 120;

    private class AggregateRecord {
        Error_Log__c record;
        Integer count;
        DateTime lastOccurrence;

        AggregateRecord(Error_Log__c r) {
            this.record = r;
            this.count = 0;
            this.lastOccurrence = null;
            if (r != null) {
                Decimal occ = r.Occurrence_Count__c;
                this.count = occ == null ? 1 : occ.intValue();
                this.lastOccurrence = r.Last_Occurrence__c == null ? r.Occurred_At__c : r.Last_Occurrence__c;
            }
        }
    }

    public class Context {
        public String source;     // Apex | Flow | Batch | API | Callout | Other
        public String severity;   // Critical | Error | Warning | Info
        public String endpoint;
        public String httpMethod;
        public Integer httpStatus;
        public String payload;
        public String parentObject;
        public Id parentRecordId;
    }

    public static void log(Exception e, Context ctx) {
        testInvocationCount++;
        if (e == null) return;

        lastErrorMessage = null;
        try {
            Error_Log__c rec = buildRecord(e, ctx);
            trimLongText(rec);
            persistLog(rec);
            buffer.add(rec.clone(true, true, false, false));
            trackAggregate(rec);
            ensureFlushHook();
        } catch (Exception swallow) {
            lastErrorMessage = swallow.getMessage();
            System.debug(LoggingLevel.ERROR, 'ErrorLogger failed: ' + swallow.getMessage());
        }
    }

    private static Error_Log__c buildRecord(Exception e, Context ctx) {
        Error_Log__c rec = new Error_Log__c();
        rec.Occurred_At__c = System.now();
        rec.Source__c = (ctx != null && !String.isBlank(ctx.source)) ? ctx.source : 'Apex';
        rec.Severity__c = (ctx != null && !String.isBlank(ctx.severity)) ? ctx.severity : 'Error';
        rec.Exception_Type__c = e.getTypeName();
        rec.Message__c = RedactionService.scrubMessage(e.getMessage());
        rec.Stacktrace__c = RedactionService.scrubStacktrace(e.getStackTraceString());
        rec.Request_Id__c = getRequestId();
        rec.User__c = Test.isRunningTest() ? null : UserInfo.getUserId();
        if (ctx != null) {
            rec.Endpoint__c = ctx.endpoint;
            rec.Http_Method__c = ctx.httpMethod;
            rec.Http_Status__c = ctx.httpStatus;
            rec.Payload__c = RedactionService.scrubPayload(ctx.payload);
            rec.Parent_Object__c = ctx.parentObject;
            if (ctx.parentRecordId != null) {
                try {
                    rec.Parent_Record_Id__c = (String)ctx.parentRecordId;
                } catch (Exception ignoreParent) {
                    rec.Parent_Record_Id__c = null;
                }
            } else {
                rec.Parent_Record_Id__c = null;
            }
        }
        rec.Signature__c = clampSignature(ErrorSignatureFactory.build(e, rec.Message__c, rec.Source__c));
        return rec;
    }

    private static void trimLongText(Error_Log__c rec) {
        if (rec == null) return;
        rec.Message__c = truncate(rec.Message__c);
        rec.Stacktrace__c = truncate(rec.Stacktrace__c);
        rec.Payload__c = truncate(rec.Payload__c);
    }

    private static String truncate(String value) {
        if (value == null) return null;
        return value.length() > MAX_LONG_TEXT_LENGTH ? value.substring(0, MAX_LONG_TEXT_LENGTH) : value;
    }

    private static void persistLog(Error_Log__c rec) {
        if (rec == null) return;
        DateTime occurredAt = rec.Occurred_At__c == null ? System.now() : rec.Occurred_At__c;
        Error_Log__c existing = forceNoWindowMatch ? null : findExisting(rec.Signature__c, occurredAt);

        if (existing == null) {
            rec.Occurrence_Count__c = 1;
            rec.Last_Occurrence__c = rec.Occurred_At__c;
            Boolean inserted = tryInsert(rec);
            if (inserted) {
                return;
            }
            existing = findAnyBySignature(rec.Signature__c);
            if (existing == null) {
                String originalSignature = rec.Signature__c;
                rec.Signature__c = fallbackSignature(originalSignature);
                rec.Occurrence_Count__c = 1;
                rec.Last_Occurrence__c = rec.Occurred_At__c;
                if (tryInsert(rec)) {
                    return;
                }
                existing = findAnyBySignature(rec.Signature__c);
                if (existing == null) {
                    rec.Signature__c = originalSignature;
                }
            }
        }

        if (existing != null) {
            mergeForUpdate(existing, rec);
            performUpdate(existing);
            rec.Id = existing.Id;
            rec.Occurrence_Count__c = existing.Occurrence_Count__c;
            rec.Last_Occurrence__c = existing.Last_Occurrence__c;
        }
    }

    private static Error_Log__c findExisting(String signature, DateTime occurredAt) {
        if (String.isBlank(signature)) return null;
        DateTime windowStart = occurredAt == null ? System.now().addMinutes(-DUPLICATE_WINDOW_MINUTES) : occurredAt.addMinutes(-DUPLICATE_WINDOW_MINUTES);
        List<Error_Log__c> rows = [
            SELECT Id, Occurrence_Count__c, Last_Occurrence__c, Message__c, Stacktrace__c, Payload__c,
                   Http_Status__c, Http_Method__c, Endpoint__c, Parent_Object__c, Parent_Record_Id__c,
                   Severity__c, Source__c, Request_Id__c, User__c, Occurred_At__c
            FROM Error_Log__c
            WHERE Signature__c = :signature
              AND (
                  Last_Occurrence__c >= :windowStart
                  OR (Last_Occurrence__c = NULL AND Occurred_At__c >= :windowStart)
              )
            ORDER BY Last_Occurrence__c DESC, Occurred_At__c DESC
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    private static Error_Log__c findAnyBySignature(String signature) {
        if (String.isBlank(signature)) return null;
        List<Error_Log__c> rows = [
            SELECT Id, Occurrence_Count__c, Last_Occurrence__c, Message__c, Stacktrace__c, Payload__c,
                   Http_Status__c, Http_Method__c, Endpoint__c, Parent_Object__c, Parent_Record_Id__c,
                   Severity__c, Source__c, Request_Id__c, User__c, Occurred_At__c
            FROM Error_Log__c
            WHERE Signature__c = :signature
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    private static Boolean tryInsert(Error_Log__c rec) {
        try {
            if (Test.isRunningTest() && simulateDuplicateOnInsert) {
                simulateDuplicateOnInsert = false;
                return false;
            }
            if (Test.isRunningTest()) {
                insert rec;
                testInsertCount++;
            } else {
                Database.SaveResult[] results = Database.insert(new List<Error_Log__c>{ rec }, false);
                Database.SaveResult sr = results.isEmpty() ? null : results[0];
                if (sr != null && sr.isSuccess()) {
                    rec.Id = sr.getId();
                    testInsertCount++;
                } else if (sr != null) {
                    throw new DmlException(joinErrors(sr.getErrors()));
                }
            }
            return true;
        } catch (DmlException dml) {
            if (isDuplicateSignatureError(dml)) {
                return false;
            }
            throw dml;
        }
    }

    private static void mergeForUpdate(Error_Log__c target, Error_Log__c source) {
        Decimal currentCount = target.Occurrence_Count__c == null ? 0 : target.Occurrence_Count__c;
        currentCount = (currentCount == null ? 0 : currentCount) + 1;
        target.Occurrence_Count__c = currentCount;
        target.Last_Occurrence__c = source.Occurred_At__c;
        target.Message__c = source.Message__c;
        target.Stacktrace__c = source.Stacktrace__c;
        target.Payload__c = source.Payload__c;
        target.Http_Status__c = source.Http_Status__c;
        target.Http_Method__c = source.Http_Method__c;
        target.Endpoint__c = source.Endpoint__c;
        target.Parent_Object__c = source.Parent_Object__c;
        target.Parent_Record_Id__c = source.Parent_Record_Id__c;
        target.Severity__c = source.Severity__c;
        target.Source__c = source.Source__c;
        target.Request_Id__c = source.Request_Id__c;
        target.User__c = source.User__c;
        target.Occurred_At__c = source.Occurred_At__c;
    }

    private static void performUpdate(Error_Log__c recordToUpdate) {
        if (recordToUpdate == null) return;
        if (Test.isRunningTest()) {
            update recordToUpdate;
            testUpdateCount++;
        } else {
            Database.SaveResult[] results = Database.update(new List<Error_Log__c>{ recordToUpdate }, false);
            Database.SaveResult sr = results.isEmpty() ? null : results[0];
            if (sr != null && sr.isSuccess()) {
                testUpdateCount++;
            } else if (sr != null) {
                throw new DmlException(joinErrors(sr.getErrors()));
            }
        }
    }

    private static Boolean isDuplicateSignatureError(DmlException ex) {
        if (ex == null) return false;
        try {
            for (Integer i = 0; i < ex.getNumDml(); i++) {
                if (ex.getDmlType(i) == System.StatusCode.DUPLICATE_VALUE) {
                    return true;
                }
            }
        } catch (Exception ignore) {
        }
        String msg = ex.getMessage();
        return msg != null && msg.contains('Signature__c') && msg.toLowerCase().contains('duplicate');
    }

    private static void trackAggregate(Error_Log__c rec) {
        if (rec == null) return;
        String key = aggregationKey(rec);
        Error_Log__c cloneRec = cloneForAggregation(rec);
        AggregateRecord agg = aggregationMap.get(key);
        if (agg == null) {
            aggregationMap.put(key, new AggregateRecord(cloneRec));
        } else {
            agg.record = cloneRec;
            agg.count = cloneRec.Occurrence_Count__c == null ? agg.count : cloneRec.Occurrence_Count__c.intValue();
            agg.lastOccurrence = cloneRec.Last_Occurrence__c;
        }
    }

    private static Error_Log__c cloneForAggregation(Error_Log__c rec) {
        Error_Log__c cloneRec = rec.clone(true, true, false, false);
        cloneRec.Occurrence_Count__c = rec.Occurrence_Count__c;
        cloneRec.Last_Occurrence__c = rec.Last_Occurrence__c == null ? rec.Occurred_At__c : rec.Last_Occurrence__c;
        return cloneRec;
    }

    private static String aggregationKey(Error_Log__c rec) {
        if (rec == null) return null;
        if (!String.isBlank(rec.Signature__c)) return rec.Signature__c;
        return (rec.Exception_Type__c == null ? 'Unknown' : rec.Exception_Type__c) + '|' + (rec.Message__c == null ? '' : rec.Message__c);
    }

    private static void ensureFlushHook() {
        if (Test.isRunningTest() || flusherScheduled) return;
        try {
            System.enqueueJob(new LoggingFlushQueueable());
            flusherScheduled = true;
        } catch (Exception ignore) {
            flusherScheduled = false;
        }
    }

    @TestVisible
    public static List<Error_Log__c> getBufferedRecords() {
        List<Error_Log__c> out = new List<Error_Log__c>();
        for (AggregateRecord agg : aggregationMap.values()) {
            if (agg == null || agg.record == null) continue;
            Error_Log__c copy = agg.record.clone(true, true, false, false);
            copy.Occurrence_Count__c = agg.count;
            copy.Last_Occurrence__c = agg.lastOccurrence;
            out.add(copy);
        }
        return out;
    }

    @TestVisible
    public static void clearBufferedState() {
        buffer.clear();
        aggregationMap.clear();
        flusherScheduled = false;
    }

    public static void markFlushCompleted() {
        clearBufferedState();
    }

    private static String getRequestId() {
        String seed = String.valueOf(System.now().getTime()) + ':' + String.valueOf(Math.random());
        Blob digest = Crypto.generateDigest('MD5', Blob.valueOf(seed));
        return EncodingUtil.convertToHex(digest);
    }

    private static String fallbackSignature(String signature) {
        String base = String.isBlank(signature) ? 'no_sig' : clampSignature(signature);
        String suffixSeed = String.valueOf(System.now().getTime()) + ':' + String.valueOf(Math.random());
        String suffixHex = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(suffixSeed)));
        String suffix = '|dup-' + suffixHex.substring(0, 6);
        Integer maxBaseLength = SIGNATURE_MAX_LENGTH - suffix.length();
        if (maxBaseLength < 1) {
            maxBaseLength = SIGNATURE_MAX_LENGTH;
            suffix = suffix.substring(0, Math.max(0, SIGNATURE_MAX_LENGTH - 1));
        }
        if (base.length() > maxBaseLength) {
            base = base.substring(0, maxBaseLength);
        }
        return clampSignature(base + suffix);
    }

    private static String clampSignature(String signature) {
        if (String.isBlank(signature)) return signature;
        return signature.length() > SIGNATURE_MAX_LENGTH ? signature.substring(0, SIGNATURE_MAX_LENGTH) : signature;
    }

    private static String joinErrors(Database.Error[] errs) {
        if (errs == null || errs.isEmpty()) return 'Unknown error';
        List<String> msgs = new List<String>();
        for (Database.Error err : errs) {
            msgs.add((err.getStatusCode() == null ? '' : String.valueOf(err.getStatusCode())) + ':' + err.getMessage());
        }
        return String.join(msgs, ' | ');
    }
}
