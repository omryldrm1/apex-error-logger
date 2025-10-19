public with sharing class ErrorLogger {
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
        if (e == null) return;
        try {
            Error_Log__c rec = new Error_Log__c();
            rec.Occurred_At__c    = System.now();
            rec.Source__c         = (ctx!=null && !String.isBlank(ctx.source))   ? ctx.source   : 'Apex';
            rec.Severity__c       = (ctx!=null && !String.isBlank(ctx.severity)) ? ctx.severity : 'Error';
            rec.Exception_Type__c = e.getTypeName();
            rec.Message__c        = e.getMessage();
            rec.Stacktrace__c     = e.getStackTraceString();
            rec.Request_Id__c     = getRequestId();
            rec.User__c           = UserInfo.getUserId();
            if (ctx != null) {
                rec.Endpoint__c         = ctx.endpoint;
                rec.Http_Method__c      = ctx.httpMethod;
                rec.Http_Status__c      = ctx.httpStatus;
                rec.Payload__c          = mask(ctx.payload);
                rec.Parent_Object__c    = ctx.parentObject;
                rec.Parent_Record_Id__c = ctx.parentRecordId == null ? null : (String)ctx.parentRecordId;
            }
            rec.Signature__c = signature(rec.Exception_Type__c, rec.Message__c, rec.Stacktrace__c);
            upsertAggregate(rec);
        } catch (DmlException dmlEx) {
            System.debug(LoggingLevel.ERROR, 'ErrorLogger DML failed: ' + dmlEx.getMessage());
        } catch (Exception swallow) {
            System.debug(LoggingLevel.ERROR, 'ErrorLogger failed: ' + swallow.getMessage());
        }
    }

    private static String signature(String typeName, String message, String stack) {
        String top = topFrame(stack);
        String basis = ((typeName==null?'':typeName) + '|' + top + '|' + left(message,200)).toLowerCase();
        Blob b = Crypto.generateDigest('SHA1', Blob.valueOf(basis));
        return EncodingUtil.convertToHex(b);
    }

    private static String topFrame(String stack) {
        if (String.isBlank(stack)) return 'noframe';
        List<String> lines = stack.split('\n');
        return lines.isEmpty() ? 'noframe' : lines[0];
    }

    private static String left(String s, Integer n) {
        return s==null ? null : s.substring(0, Math.min(n, s.length()));
    }

    private static String mask(String body) {
        if (String.isBlank(body)) return body;
        String out = body;

        // Credit cards (13-19 digits)
        out = out.replaceAll('\\b\\d{13,19}\\b', '****MASKED_PAN****');

        // IBAN (international format)
        out = out.replaceAll('\\b[A-Z]{2}\\d{2}[A-Z0-9]{10,30}\\b', '****MASKED_IBAN****');

        // Email addresses
        out = out.replaceAll('[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}', '****MASKED_EMAIL****');

        // US SSN
        out = out.replaceAll('\\b\\d{3}-\\d{2}-\\d{4}\\b', '****MASKED_SSN****');
        out = out.replaceAll('\\b\\d{9}\\b', '****MASKED_SSN****');

        // Phone numbers
        out = out.replaceAll('\\+?\\d{1,3}[\\s.-]?\\(?\\d{3}\\)?[\\s.-]?\\d{3}[\\s.-]?\\d{4}', '****MASKED_PHONE****');

        // Bearer tokens
        out = out.replaceAll('Bearer\\s+[A-Za-z0-9\\-._~+/]+=*', 'Bearer ****MASKED_TOKEN****');

        // JWT tokens
        out = out.replaceAll('\\beyJ[A-Za-z0-9_-]+\\.eyJ[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\b', '****MASKED_JWT****');

        // API keys
        out = out.replaceAll('(api[_-]?key|apikey|api[_-]?token)[\'"]?\\s*[:=]\\s*[\'"]?([A-Za-z0-9]{32,64})', '$1=****MASKED_APIKEY****');

        // AWS Keys
        out = out.replaceAll('\\b(AKIA|ASIA)[A-Z0-9]{16}\\b', '****MASKED_AWS_KEY****');

        // Password fields
        out = out.replaceAll('(password|passwd|pwd)[\'"]?\\s*[:=]\\s*[\'"]?([^\'",\\s}]+)', '$1=****MASKED_PASSWORD****');

        return out;
    }

    private static String getRequestId() {
        if (Test.isRunningTest()) {
            return 'TEST-' + String.valueOf(System.currentTimeMillis());
        }
        try {
            return Request.getCurrent().getRequestId();
        } catch (Exception e) {
            return 'UNKNOWN-' + String.valueOf(System.now().getTime());
        }
    }

    private static void upsertAggregate(Error_Log__c rec) {
        List<Error_Log__c> exist = [
            SELECT Id, Occurrence_Count__c
            FROM Error_Log__c
            WHERE Signature__c = :rec.Signature__c
            LIMIT 1
        ];
        if (!exist.isEmpty()) {
            Error_Log__c cur = exist[0];
            cur.Occurrence_Count__c = (cur.Occurrence_Count__c==null ? 1 : cur.Occurrence_Count__c + 1);
            cur.Last_Occurrence__c = System.now();
            update cur;
        } else {
            rec.Occurrence_Count__c = 1;
            rec.Last_Occurrence__c = System.now();
            insert rec;
        }
    }
}