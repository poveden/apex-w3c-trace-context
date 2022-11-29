# W3C Trace Context helper classes for Salesforce

## Usage

```java
@RestResource(urlMapping='/Account/*')
global with sharing class MyRestResource {

    @HttpPost
    global static String doPost(String name, String phone, String website) {
        // Capture the caller's trace context
        W3CTraceContext ctx = W3CTraceContext.fromRequest(RestContext.request);

        // Use the trace context (e.g. for logging)
        System.debug(loggingLevel.INFO, 'Trace ID: ' + ctx.getTraceParent().getTraceId());
        System.debug(loggingLevel.INFO, 'Parent ID: ' + ctx.getTraceParent().getParentId());

        // Propagate the trace context to external dependencies
        HttpRequest req = new HttpRequest();
        ctx.propagate(req, true);
        req.setEndpoint('http://www.yahoo.com');
        req.setMethod('GET');
    }
}
```

## Resources

- [W3C Trace Context](https://www.w3.org/TR/trace-context/)
