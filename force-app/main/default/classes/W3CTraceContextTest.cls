@IsTest
public class W3CTraceContextTest {
    @IsTest
    static void createsTraceContexts() {
        W3CTraceContext tc = W3CTraceContext.create();

        System.Assert.areEqual(55, tc.getTraceParent().toString().length());
        System.Assert.areEqual(0, tc.getTraceState().toString().length());
    }

    @IsTest
    static void createsTraceContextFromRequestsWithTraceContextHeaders() {
        RestRequest req = new RestRequest();
        req.headers.put('traceparent', '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01');
        req.headers.put('tracestate', 'key1=value1,key2=value2');

        W3CTraceContext tc = W3CTraceContext.fromRequest(req);

        System.Assert.areEqual(0, tc.getTraceParent().getVersion());
        System.Assert.areEqual('0af7651916cd43dd8448eb211c80319c', tc.getTraceParent().getTraceId());
        System.Assert.areEqual('b7ad6b7169203331', tc.getTraceParent().getParentId());
        System.Assert.isTrue(tc.getTraceParent().getSampled());

        System.Assert.areEqual('key1=value1,key2=value2', tc.getTraceState().toString());
    }

    @IsTest
    static void createThrowsWhenInboundIsNull() {
        try {
            W3CTraceContext.fromRequest(null);
            System.Assert.fail('An exception should have been thrown.');
        } catch (InvalidParameterValueException ex) {
            System.Assert.areEqual('Inbound request cannot be null.', ex.getMessage());
        }
    }

    @IsTest
    static void createRestartsTheTraceIfTheTraceparentIsMissingOrInvalid() {
        RestRequest req = new RestRequest();
        req.headers.put('traceparent', 'INVALID-tracePARENT-value');
        req.headers.put('tracestate', 'key1=value1,key2=value2');

        W3CTraceContext tc = W3CTraceContext.fromRequest(req);

        System.Assert.areEqual(55, tc.getTraceParent().toString().length());
        System.Assert.areEqual(0, tc.getTraceState().toString().length());
    }

    @IsTest
    static void passThroughProjectsUnalteredHeaders() {
        RestRequest inbound = new RestRequest();
        inbound.headers.put('traceparent', 'INVALID-tracePARENT-value');
        inbound.headers.put('tracestate', 'INVALID-traceSTATE-value');

        HttpRequest outbound = new HttpRequest();
        W3CTraceContext.passThrough(inbound, outbound);

        System.Assert.areEqual('INVALID-tracePARENT-value', outbound.getHeader('traceparent'));
        System.Assert.areEqual('INVALID-traceSTATE-value', outbound.getHeader('tracestate'));
    }

    @IsTest
    static void passThroughProjectsNoHeadersIfTraceparentIsMissing() {
        RestRequest inbound = new RestRequest();
        inbound.headers.put('tracestate', 'key1=value1,key2=value2');

        HttpRequest outbound = new HttpRequest();
        W3CTraceContext.passThrough(inbound, outbound);

        System.Assert.isNull(outbound.getHeader('traceparent'));
        System.Assert.isNull(outbound.getHeader('tracestate'));
    }

    @IsTest
    static void passThroughProjectsTraceParentEvenIfTracestateIsMissing() {
        RestRequest inbound = new RestRequest();
        inbound.headers.put('traceparent', '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01');

        HttpRequest outbound = new HttpRequest();
        W3CTraceContext.passThrough(inbound, outbound);

        System.Assert.areEqual('00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01', outbound.getHeader('traceparent'));
        System.Assert.isNull(outbound.getHeader('tracestate'));
    }

    @IsTest
    static void passThroughThrowsWhenInboundIsNull() {
        try {
            W3CTraceContext.passThrough(null, new HttpRequest());
            System.Assert.fail('An exception should have been thrown.');
        } catch (InvalidParameterValueException ex) {
            System.Assert.areEqual('Inbound request cannot be null.', ex.getMessage());
        }
    }

    @IsTest
    static void passThroughThrowsWhenOutboundIsNull() {
        try {
            W3CTraceContext.passThrough(new RestRequest(), null);
            System.Assert.fail('An exception should have been thrown.');
        } catch (InvalidParameterValueException ex) {
            System.Assert.areEqual('Outbound request cannot be null.', ex.getMessage());
        }
    }

    @IsTest
    static void propagatesTraceToOutboundRequests() {
        RestRequest req = new RestRequest();
        req.headers.put('traceparent', '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-00');
        req.headers.put('tracestate', 'key1=value1,key2=value2');

        W3CTraceContext tc = W3CTraceContext.fromRequest(req);

        HttpRequest outbound = new HttpRequest();
        tc.propagate(outbound, true);

        String[] tcOut = outbound.getHeader('traceparent') .split('-');

        System.Assert.areEqual('00', tcOut[0]);
        System.Assert.areEqual('0af7651916cd43dd8448eb211c80319c', tcOut[1]);
        System.Assert.areNotEqual('b7ad6b7169203331', tcOut[2]);
        System.Assert.areEqual(16, tcOut[2].length());
        System.Assert.areEqual('01', tcOut[3]);

        System.Assert.areEqual('key1=value1,key2=value2', outbound.getHeader('tracestate'));
    }

    @IsTest
    static void propagatesTraceWithStateChangesToOutboundRequests() {
        RestRequest req = new RestRequest();
        req.headers.put('traceparent', '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-00');
        req.headers.put('tracestate', 'key1=value1,key2=value2');

        W3CTraceContext tc = W3CTraceContext.fromRequest(req);

        HttpRequest outbound = new HttpRequest();
        tc.propagate(outbound, true, new Map<String, String> { 'key1' => 'NEW VALUE', 'key3' => 'VALUE3' });

        String[] tcOut = outbound.getHeader('traceparent') .split('-');

        System.Assert.areEqual('00', tcOut[0]);
        System.Assert.areEqual('0af7651916cd43dd8448eb211c80319c', tcOut[1]);
        System.Assert.areNotEqual('b7ad6b7169203331', tcOut[2]);
        System.Assert.areEqual(16, tcOut[2].length());
        System.Assert.areEqual('01', tcOut[3]);

        System.Assert.areEqual('key1=NEW VALUE,key3=VALUE3,key2=value2', outbound.getHeader('tracestate'));
    }

    @IsTest
    static void propagateThrowsWhenOutboundIsNull() {
        W3CTraceContext tc = W3CTraceContext.create();

        try {
            tc.propagate(null, true);
            System.Assert.fail('An exception should have been thrown.');
        } catch (InvalidParameterValueException ex) {
            System.Assert.areEqual('Outbound request cannot be null.', ex.getMessage());
        }
    }
}
