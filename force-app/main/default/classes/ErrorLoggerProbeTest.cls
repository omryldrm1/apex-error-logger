@IsTest
private class ErrorLoggerProbeTest {
    @IsTest static void simulateEventFailure() {
        EventLogCollector.testLogs = new List<EventLogFile>{ null };
        ErrorLogger.testInsertCount = 0;
        ErrorLogger.testUpdateCount = 0;
        Test.startTest();
        new EventLogCollector().execute(null);
        Test.stopTest();
        Integer totalDml = ErrorLogger.testInsertCount + ErrorLogger.testUpdateCount;
        System.assertEquals(1, totalDml, 'Exactly one DML operation should occur. insert=' + ErrorLogger.testInsertCount + ' update=' + ErrorLogger.testUpdateCount + ' lastError=' + ErrorLogger.lastErrorMessage);
        System.assert(ErrorLogger.testInsertCount == 1 || ErrorLogger.testUpdateCount == 1, 'Insert or update should run. lastError=' + ErrorLogger.lastErrorMessage);
        Integer cnt = [SELECT COUNT() FROM Error_Log__c];
        System.assertEquals(1, cnt, 'count');
    }
}
