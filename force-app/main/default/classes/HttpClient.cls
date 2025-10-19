public with sharing class HttpClient {
    public static HttpResponse send(HttpRequest req) {
        Http h = new Http();
        String reqBody = req.getBody();
        try {
            HttpResponse res = h.send(req);
            if (res.getStatusCode() >= 300) {
                CalloutException ex = new CalloutException('HTTP ' + res.getStatus());
                ErrorLogger.Context ctx = new ErrorLogger.Context();
                ctx.source = 'Callout';
                ctx.endpoint = req.getEndpoint();
                ctx.httpMethod = req.getMethod();
                ctx.httpStatus = res.getStatusCode();
                ctx.payload = 'REQ: ' + (reqBody != null ? reqBody : '') + ' | RES: ' + res.getBody();
                ErrorLogger.log(ex, ctx);
            }
            return res;
        } catch (Exception e) {
            ErrorLogger.Context ctx = new ErrorLogger.Context();
            ctx.source = 'Callout';
            ctx.endpoint = req.getEndpoint();
            ctx.httpMethod = req.getMethod();
            ctx.payload = 'REQ: ' + (reqBody != null ? reqBody : '');
            ErrorLogger.log(e, ctx);
            throw e;
        }
    }
}
