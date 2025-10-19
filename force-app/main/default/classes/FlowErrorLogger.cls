public with sharing class FlowErrorLogger {
    public class FlowInput {
        @InvocableVariable(required=true) public String message;
        @InvocableVariable public String severity;
        @InvocableVariable public String parentObject;
        @InvocableVariable public String parentRecordId;
    }

    @InvocableMethod(label='Log Flow Error')
    public static void logFlow(List<FlowInput> inputs) {
        for (FlowInput i : inputs) {
            try {
                CalloutException e = new CalloutException(i.message);
                ErrorLogger.Context ctx = new ErrorLogger.Context();
                ctx.source = 'Flow';
                ctx.severity = String.isNotBlank(i.severity) ? i.severity : 'Error';
                ctx.parentObject = i.parentObject;
                if (String.isNotBlank(i.parentRecordId)) {
                    try {
                        ctx.parentRecordId = (Id)i.parentRecordId;
                    } catch (Exception invalidId) {
                        ctx.parentRecordId = null;
                    }
                }
                ErrorLogger.log(e, ctx);
            } catch (Exception ignore) {
                System.debug(LoggingLevel.ERROR, 'FlowErrorLogger failed: ' + ignore.getMessage());
            }
        }
    }
}
