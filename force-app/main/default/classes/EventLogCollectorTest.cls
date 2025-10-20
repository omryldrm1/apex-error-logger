@IsTest
private class EventLogCollectorTest {

    private static EventLogFile buildEventLog(String eventType, DateTime logDate, Integer length) {
        EventLogFile log = (EventLogFile)Schema.getGlobalDescribe().get('EventLogFile').newSObject(null, true);
        log.put('EventType', eventType);
        log.put('LogDate', logDate);
        log.put('LogFileLength', length);
        return log;
    }

    @IsTest static void insertsLogsWhenRecordsExist() {
        EventLogCollector.testLogs = new List<EventLogFile>{
            buildEventLog('API', System.now(), 2048)
        };

        Test.startTest();
        new EventLogCollector().execute(null);
        Test.stopTest();

        Error_Log__c log = [
            SELECT Source__c, Severity__c, Message__c
            FROM Error_Log__c
            LIMIT 1
        ];
        System.assertEquals('API', log.Source__c);
        System.assertEquals('Info', log.Severity__c);
        System.assert(log.Message__c.contains('EventLogFile: API'), 'Message should include event type');
    }

    @IsTest static void logsCollectorErrorWhenProcessingFails() {
        EventLogCollector.testLogs = new List<EventLogFile>{ null };

        Test.startTest();
        new EventLogCollector().execute(null);
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Source__c, Severity__c, Message__c
            FROM Error_Log__c
            LIMIT 1
        ];
        System.assert(!logs.isEmpty(), 'Error should be logged when collector fails');
        System.assertEquals('Batch', logs[0].Source__c, 'Collector should log via ErrorLogger on failure');
        System.assertEquals('Warning', logs[0].Severity__c);
    }
}
