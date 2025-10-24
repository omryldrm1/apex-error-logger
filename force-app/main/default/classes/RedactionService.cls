/**
 * @description Service that removes sensitive data (PII/Secrets) from strings prior to logging.
 * Scope includes common patterns like emails, credit cards, IBAN, phone numbers, UUIDs, bearer tokens, and authorization headers.
 * Keep this lightweight and deterministic (no DML/SOQL).
 *
 * EXTENSIBILITY:
 *  - Patterns can be externalized to Custom Metadata Types in a future iteration.
 *
 * SECURITY:
 *  - This must be applied to Message, Payload and optionally Stacktrace before persistence.
 *
 * @author Apex Error Logger Team
 * @since 1.0.0
 */
public with sharing class RedactionService {

    // Replacement markers
    private static final String EMAIL_MASK = '{EMAIL}';
    private static final String PHONE_MASK = '{PHONE}';
    private static final String IBAN_MASK = '{IBAN}';
    private static final String CC_MASK = '{CARD}';
    private static final String UUID_MASK = '{UUID}';
    private static final String TOKEN_MASK = '{TOKEN}';
    private static final String AUTH_MASK = '{AUTH}';

    /**
     * @description Scrubs a message text from sensitive data.
     */
    public static String scrubMessage(String input) {
        return scrubGeneric(input, true);
    }

    /**
     * @description Scrubs a payload text (JSON/XML/plain) from sensitive data.
     */
    public static String scrubPayload(String input) {
        return scrubGeneric(input, true);
    }

    /**
     * @description Scrubs a stacktrace text; usually less sensitive but may include tokens.
     */
    public static String scrubStacktrace(String input) {
        return scrubGeneric(input, false);
    }

    // Core redaction pipeline
    private static String scrubGeneric(String input, Boolean aggressive) {
        if (String.isBlank(input)) return input;
        String out = input;

        // Emails
        out = out.replaceAll('\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\\b', EMAIL_MASK);

        // Phone numbers (very permissive): sequences of digits with optional separators
        out = out.replaceAll('(?:(?:\\+\\d{1,3}[\\s-]?)?(?:\\(\\d{1,4}\\)[\\s-]?)?\\d[\\d\\s-]{6,}\\d)', PHONE_MASK);

        // IBAN (generic pattern; country-specific vary)
        out = out.replaceAll('\\b[A-Z]{2}\\d{2}[A-Z0-9]{1,30}\\b', IBAN_MASK);

        // Credit cards (simple Luhn-friendly patterns). We avoid Luhn calc for performance.
        out = out.replaceAll('\\b(?:\\d[ -]*?){13,19}\\b', CC_MASK);

        // UUID v4
        out = out.replaceAll('\\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}\\b', UUID_MASK);

        // Authorization: Bearer or Basic headers
        out = out.replaceAll('(?i)Authorization\\s*:\\s*Bearer\\s+[A-Za-z0-9._-]+', 'Authorization: Bearer ' + TOKEN_MASK);
        out = out.replaceAll('(?i)Authorization\\s*:\\s*Basic\\s+[A-Za-z0-9+/=]+', 'Authorization: Basic ' + AUTH_MASK);

        // Generic token/key style: key=xxxx or "token":"xxxx"
        // token[:=]"value" or token=value (allow optional quotes)
        out = out.replaceAll('(?i)token\\s*[:=]\\s*["\\\']?[A-Za-z0-9._-]+["\\\']?', 'token=' + TOKEN_MASK);
        // api_key / secret / password assignments; avoid backreference ($1) because Apex replaceAll doesn't support replacement group refs
        out = out.replaceAll('(?i)(api[_-]?key|secret|password)\\s*[:=]\\s*["\\\']?[^"\\\'\\s]+["\\\']?', '$REDACTED=' + TOKEN_MASK);

        if (aggressive) {
            // Reduce repeated whitespace and common JSON spacing noise
            out = out.replaceAll('\\s+', ' ').trim();
        }
        return out;
    }
}
