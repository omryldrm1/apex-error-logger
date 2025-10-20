@IsTest
private class FlowErrorLoggerTest {

    @IsTest static void logFlowInsertsRecords() {
        FlowErrorLogger.FlowInput input = new FlowErrorLogger.FlowInput();
        input.message = 'Flow failure on screen';
        input.severity = 'Warning';
        input.parentObject = 'Account';

        Test.startTest();
        FlowErrorLogger.logFlow(new List<FlowErrorLogger.FlowInput>{ input });
        Test.stopTest();

        Error_Log__c log = [
            SELECT Source__c, Severity__c, Parent_Object__c, Message__c
            FROM Error_Log__c
            LIMIT 1
        ];
        System.assertEquals('Flow', log.Source__c);
        System.assertEquals('Warning', log.Severity__c);
        System.assertEquals('Account', log.Parent_Object__c);
        System.assert(log.Message__c.contains('Flow failure on screen'));
    }

    @IsTest static void handlesInvalidParentIdGracefully() {
        FlowErrorLogger.FlowInput input = new FlowErrorLogger.FlowInput();
        input.message = 'Invalid id test';
        input.parentRecordId = 'notAnId';

        Test.startTest();
        FlowErrorLogger.logFlow(new List<FlowErrorLogger.FlowInput>{ input });
        Test.stopTest();

        Error_Log__c log = [
            SELECT Parent_Record_Id__c, Severity__c
            FROM Error_Log__c
            LIMIT 1
        ];
        System.assertEquals(null, log.Parent_Record_Id__c, 'Invalid IDs should be ignored');
        System.assertEquals('Error', log.Severity__c, 'Default severity should apply');
    }
}

