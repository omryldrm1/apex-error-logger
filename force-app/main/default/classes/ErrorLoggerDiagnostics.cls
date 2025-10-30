public with sharing class ErrorLoggerDiagnostics {
    public static Integer bufferedRecordCount() {
        return ErrorLogger.getBufferedRecords().size();
    }

    public static Integer bufferedUpdateCount() {
        Integer updates = 0;
        for (Error_Log__c rec : ErrorLogger.getBufferedRecords()) {
            if (rec != null && rec.Id != null) {
                updates++;
            }
        }
        return updates;
    }

    public static Map<String, Integer> bufferedCountBySource() {
        Map<String, Integer> counts = new Map<String, Integer>();
        for (Error_Log__c rec : ErrorLogger.getBufferedRecords()) {
            if (rec == null) continue;
            String src = String.isBlank(rec.Source__c) ? 'Unknown' : rec.Source__c;
            Integer running = counts.containsKey(src) ? counts.get(src) : 0;
            counts.put(src, running + 1);
        }
        return counts;
    }
}
