public class LoggingFinalizer implements System.Finalizer {
    private String jobType;
    private String jobContext;

    public LoggingFinalizer() {
        this('Unknown', null);
    }

    public LoggingFinalizer(String jobType, String jobContext) {
        this.jobType = jobType;
        this.jobContext = jobContext;
    }

    public void execute(System.FinalizerContext ctx) {
        handleResult(ctx.getResult(), ctx.getAsyncApexJobId());
    }

    @TestVisible
    void handleResult(System.ParentJobResult result, String asyncJobId) {
        if (result != System.ParentJobResult.SUCCESS) {
            String errMsg = 'Async job failed [' + jobType + '] JobId: ' + asyncJobId;
            if (String.isNotBlank(jobContext)) {
                errMsg += ' | Context: ' + jobContext;
            }
            CalloutException e = new CalloutException(errMsg);
            ErrorLogger.Context ec = new ErrorLogger.Context();
            ec.source = 'Batch';
            ec.severity = 'Critical';
            ec.parentObject = jobType;
            ErrorLogger.log(e, ec);
        }
    }

    @TestVisible
    static void testHandleResult(LoggingFinalizer fin, System.ParentJobResult result, String asyncJobId) {
        fin.handleResult(result, asyncJobId);
    }
}
