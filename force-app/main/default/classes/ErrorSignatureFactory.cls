/**
 * @description Factory for building normalized error signatures used for duplicate suppression and idempotent logging.
 * The goal is to produce a stable key that groups the "same" error within a time window.
 * Strategy:
 *  - Use exception type (if provided)
 *  - Use top stack frame (first meaningful line)
 *  - Normalize the message: remove volatile tokens (numbers > 3 digits, UUIDs, ISODateTimes, emails, bearer tokens)
 *  - Include context (class/method/flow name) when present
 *
 * NOTES:
 *  - Keep this logic deterministic and cheap (no DML/queries)
 *  - Avoid including variable data (record Ids, timestamps) that prevents grouping
 *
 * SECURITY:
 *  - Do NOT include sensitive values in signature (it's a grouping key, not payload)
 *
 * EXTENSIBILITY:
 *  - You can enrich normalization patterns as needed or make them configurable via CMDT in the future.
 *
 * @author Apex Error Logger Team
 * @since 1.0.0
 */
public with sharing class ErrorSignatureFactory {

    /**
     * @param ex The exception (can be null)
     * @param rawMessage Original human-readable message (can be null)
     * @param context Logical context like ClassName.MethodName or Flow name (can be null)
     * @return A normalized signature key with max length 255
     */
    public static String build(Exception ex, String rawMessage, String context) {
        String exType = ex == null ? 'NoException' : ex.getTypeName();
        String topFrame = getTopStackFrame(ex);
        String msg = normalizeMessage(rawMessage);
        String ctx = normalizeContext(context);

        // Compose signature parts with separators
        String sig = exType + ' | ' + topFrame + ' | ' + msg + ' | ' + ctx;

        // Enforce 255 char limit, keep the start as it carries most info
        return sig.length() > 255 ? sig.substring(0, 255) : sig;
    }

    // Extract first meaningful stack frame line
    private static String getTopStackFrame(Exception ex) {
        if (ex == null) return 'NoStack';
        String st = ex.getStackTraceString();
        if (String.isBlank(st)) return 'NoStack';
        // Split on newline and pick the first non-empty trimmed line
        List<String> lines = st.split('\\n');
        for (String line : lines) {
            String t = line == null ? '' : line.trim();
            if (!String.isBlank(t)) {
                // Avoid including variable line numbers by stripping :<digits>
                t = t.replaceAll('(:\\d+)', ':N');
                return t.length() > 120 ? t.substring(0, 120) : t;
            }
        }
        return 'NoStack';
    }

    // Remove volatile parts from message
    private static String normalizeMessage(String msg) {
        if (String.isBlank(msg)) return 'NoMessage';
        String out = msg;

        // UUID v4
        out = out.replaceAll('\\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}\\b', '{UUID}');
        // ISO datetime
        out = out.replaceAll('\\b\\d{4}-\\d{2}-\\d{2}[T ]\\d{2}:\\d{2}:\\d{2}(?:\\.\\d+)?Z?\\b', '{TIMESTAMP}');
        // Long numeric sequences (>=4 digits)
        out = out.replaceAll('\\b\\d{4,}\\b', '{NUM}');
        // Emails
        out = out.replaceAll('\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\\b', '{EMAIL}');
        // Bearer/Token
        out = out.replaceAll('(?i)Bearer\\s+[A-Za-z0-9._-]+', 'Bearer {TOKEN}');
        out = out.replaceAll('(?i)token\\s*[:=]\\s*[A-Za-z0-9._-]+', 'token={TOKEN}');
        // Strip excess whitespace
        out = out.replaceAll('\\s+', ' ').trim();

        return out.length() > 120 ? out.substring(0, 120) : out;
    }

    private static String normalizeContext(String ctx) {
        if (String.isBlank(ctx)) return 'NoContext';
        String out = ctx.replaceAll('\\s+', ' ').trim();
        return out.length() > 60 ? out.substring(0, 60) : out;
    }
}
