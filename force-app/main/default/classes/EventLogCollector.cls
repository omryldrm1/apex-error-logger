global class EventLogCollector implements Schedulable {
  @TestVisible static List<EventLogFile> testLogs;

  global void execute(SchedulableContext sc) {
    try {
      List<EventLogFile> logs;
      if (Test.isRunningTest() && testLogs != null) {
        logs = testLogs;
      } else {
        logs = [
          SELECT Id, EventType, LogDate, LogFileLength
          FROM EventLogFile
          WHERE EventType IN ('API','ApexExecution','FlowExecution','ApexUnexpectedException')
          AND LogDate = TODAY
          LIMIT 200
        ];
      }
      List<Error_Log__c> toInsert = new List<Error_Log__c>();
      for (EventLogFile e : logs) {
        toInsert.add(new Error_Log__c(
          Occurred_At__c = e.LogDate,
          Source__c = e.EventType,
          Severity__c = 'Info',
          Message__c = 'EventLogFile: ' + e.EventType + ' size=' + e.LogFileLength + 'B'
        ));
      }
      if (!toInsert.isEmpty()) {
        Database.insert(toInsert, false);
      }
      if (Test.isRunningTest()) {
        testLogs = null;
      }
    } catch (Exception ex) {
      ErrorLogger.Context ctx = new ErrorLogger.Context();
      ctx.source = 'Batch';
      ctx.severity = 'Warning';
      ErrorLogger.log(ex, ctx);
    }
  }
}
