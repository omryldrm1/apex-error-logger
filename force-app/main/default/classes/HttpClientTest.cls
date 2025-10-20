@IsTest
private class HttpClientTest {

    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('200 OK');
            res.setBody('{"result":"ok"}');
            return res;
        }
    }

    private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(503);
            res.setStatus('503 Service Unavailable');
            res.setBody('{"error":"down"}');
            return res;
        }
    }

    private class ExceptionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Timeout reached');
        }
    }

    @IsTest static void sendSuccessDoesNotLog() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://example.com/success');
        req.setMethod('GET');

        Test.startTest();
        HttpResponse res = HttpClient.send(req);
        Test.stopTest();

        System.assertEquals(200, res.getStatusCode());
        System.assertEquals(0, [SELECT COUNT() FROM Error_Log__c], 'Successful responses should not log errors');
    }

    @IsTest static void sendErrorStatusCreatesLog() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://example.com/failure');
        req.setMethod('POST');
        req.setBody('{"payload":true}');

        Test.startTest();
        HttpResponse res = HttpClient.send(req);
        Test.stopTest();

        System.assertEquals(503, res.getStatusCode());
        Error_Log__c log = [
            SELECT Http_Status__c, Endpoint__c, Payload__c, Source__c
            FROM Error_Log__c
            LIMIT 1
        ];
        System.assertEquals(503, log.Http_Status__c);
        System.assertEquals('https://example.com/failure', log.Endpoint__c);
        System.assertEquals('Callout', log.Source__c);
        System.assert(log.Payload__c.contains('REQ:'), 'Payload stores request and response bodies');
    }

    @IsTest static void sendExceptionLogsAndPropagates() {
        Test.setMock(HttpCalloutMock.class, new ExceptionMock());
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://example.com/exception');
        req.setMethod('PATCH');
        req.setBody('ignore');

        Test.startTest();
        Boolean thrown = false;
        try {
            HttpClient.send(req);
        } catch (Exception e) {
            thrown = true;
        }
        Test.stopTest();

        System.assert(thrown, 'Exceptions should propagate to caller');
        Error_Log__c log = [
            SELECT Endpoint__c, Http_Status__c, Source__c
            FROM Error_Log__c
            LIMIT 1
        ];
        System.assertEquals('https://example.com/exception', log.Endpoint__c);
        System.assertEquals(null, log.Http_Status__c);
        System.assertEquals('Callout', log.Source__c);
    }
}

