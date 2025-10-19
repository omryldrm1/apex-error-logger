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
        if (ctx.getResult() != System.ParentJobResult.SUCCESS) {
            String errMsg = 'Async job failed [' + jobType + '] JobId: ' + ctx.getAsyncApexJobId();
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
}
