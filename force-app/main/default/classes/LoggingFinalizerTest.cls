@IsTest
private class LoggingFinalizerTest {

    private static System.ParentJobResult successResult() {
        for (System.ParentJobResult value : System.ParentJobResult.values()) {
            if (String.valueOf(value) == 'SUCCESS') {
                return value;
            }
        }
        System.assert(false, 'SUCCESS result not available');
        return null;
    }

    private static System.ParentJobResult nonSuccessResult() {
        for (System.ParentJobResult value : System.ParentJobResult.values()) {
            if (String.valueOf(value) != 'SUCCESS') {
                return value;
            }
        }
        System.assert(false, 'Non-success result not available');
        return null;
    }

    @IsTest static void doesNotLogWhenJobSucceeds() {
        LoggingFinalizer fin = new LoggingFinalizer('BatchJob', 'Nightly sync');
        LoggingFinalizer.testHandleResult(fin, successResult(), '707000000000AAA');

        System.assertEquals(0, [SELECT COUNT() FROM Error_Log__c], 'Successful jobs should not generate logs');
    }

    @IsTest static void logsFailureWithContext() {
        LoggingFinalizer fin = new LoggingFinalizer('BatchJob', 'Nightly sync');

        Test.startTest();
        LoggingFinalizer.testHandleResult(fin, nonSuccessResult(), '707000000000AAA');
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Severity__c, Source__c, Parent_Object__c, Message__c
            FROM Error_Log__c
            LIMIT 1
        ];
        System.assert(!logs.isEmpty(), 'Failure should create an error log');
        System.assertEquals('Critical', logs[0].Severity__c);
        System.assertEquals('Batch', logs[0].Source__c);
        System.assertEquals('BatchJob', logs[0].Parent_Object__c);
        System.assert(logs[0].Message__c.contains('707000000000AAA'), 'Log message should include job id');
    }

    @IsTest static void defaultConstructorUsesUnknownType() {
        LoggingFinalizer fin = new LoggingFinalizer();

        Test.startTest();
        LoggingFinalizer.testHandleResult(fin, nonSuccessResult(), '707000000000AAA');
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Parent_Object__c
            FROM Error_Log__c
            LIMIT 1
        ];
        System.assert(!logs.isEmpty(), 'Failure should create log for default constructor');
        System.assertEquals('Unknown', logs[0].Parent_Object__c, 'Default constructor sets job type to Unknown');
    }
}
