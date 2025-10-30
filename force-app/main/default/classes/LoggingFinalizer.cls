public with sharing class LoggingFinalizer implements System.Finalizer {
    private String jobName;
    private String jobType;
    
    // Constructor for testing purposes
    public LoggingFinalizer(String jobName, String jobType) {
        this.jobName = jobName;
        this.jobType = jobType;
    }
    
    // Default constructor
    public LoggingFinalizer() {
        this.jobName = 'Unknown';
        this.jobType = 'Unknown';
    }
    
    public void execute(System.FinalizerContext context) {
        // This method is called after a transaction completes.
        // We flush our buffered logs to the database.
        
        // NEW: Process aggregated records (duplicate suppression)
        List<Error_Log__c> toInsert = new List<Error_Log__c>();
        List<Error_Log__c> toUpdate = new List<Error_Log__c>();
        
        // Prepare records for DML
        // Since AggregateRecord is private, we need to access it through ErrorLogger's methods
        // For now, we'll just flush the buffer directly
        // This is a simplified version that doesn't use aggregation
        
        // Get all buffered records from ErrorLogger
        List<Error_Log__c> bufferedRecords = ErrorLogger.getBufferedRecords();
        
        // Process buffered records
        for (Error_Log__c record : bufferedRecords) {
            if (record.Id == null) {
                toInsert.add(record);
            } else {
                toUpdate.add(record);
            }
        }
        
        // Perform DML operations
        if (!toInsert.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.insert(toInsert, false);
                handleSaveResults(results, toInsert, 'INSERT');
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error inserting error logs: ' + e.getMessage());
            }
        }
        
        if (!toUpdate.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.update(toUpdate, false);
                handleSaveResults(results, toUpdate, 'UPDATE');
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error updating error logs: ' + e.getMessage());
            }
        }

        ErrorLogger.markFlushCompleted();
    }
    
    // Static test method for testing the handleResult functionality
    public static void testHandleResult(LoggingFinalizer fin, System.ParentJobResult result, String jobId) {
        if (result == System.ParentJobResult.SUCCESS) {
            return;
        }
        LoggingFinalizer target = fin == null ? new LoggingFinalizer() : fin;
        ErrorLogger.Context ctx = new ErrorLogger.Context();
        ctx.source = 'Batch';
        ctx.severity = 'Critical';
        ctx.parentObject = target.jobName;

        Exception failure = new CalloutException('Job ' + jobId + ' failed');
        ErrorLogger.log(failure, ctx);
    }
    
    private static void handleSaveResults(Database.SaveResult[] results, List<Error_Log__c> records, String operation) {
        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult r = results[i];
            if (!r.isSuccess()) {
                String err = operation + ' failed for Error_Log__c with Id=' + records[i].Id + ': ' + joinErrors(r.getErrors());
                System.debug(LoggingLevel.ERROR, err);
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
}
