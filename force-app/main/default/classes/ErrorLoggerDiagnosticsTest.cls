@IsTest
private class ErrorLoggerDiagnosticsTest {
    @IsTest static void diagnosticsReflectBufferedState() {
        ErrorLogger.clearBufferedState();

        ErrorLogger.Context apexCtx = new ErrorLogger.Context();
        apexCtx.source = 'Apex';

        ErrorLogger.Context apiCtx = new ErrorLogger.Context();
        apiCtx.source = 'API';

        Test.startTest();
        ErrorLogger.log(new DmlException('Diag Apex'), apexCtx);
        ErrorLogger.log(new DmlException('Diag API'), apiCtx);
        Test.stopTest();

        System.assertEquals(2, ErrorLoggerDiagnostics.bufferedRecordCount(), 'Two buffered aggregates expected');
        System.assertEquals(2, ErrorLoggerDiagnostics.bufferedUpdateCount(), 'Both aggregates should be treated as updates');

        Map<String, Integer> bySource = ErrorLoggerDiagnostics.bufferedCountBySource();
        System.assertEquals(2, bySource.size(), 'Sources should include Apex and API');
        System.assertEquals(1, bySource.get('Apex'));
        System.assertEquals(1, bySource.get('API'));

        LoggingFinalizer fin = new LoggingFinalizer('DiagJob', 'Queue');
        fin.execute(null);

        System.assertEquals(0, ErrorLoggerDiagnostics.bufferedRecordCount(), 'Finalizer should clear buffered diagnostics');
    }
}
