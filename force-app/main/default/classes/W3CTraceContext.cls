/**
 * @description Represents a W3C Trace Context.
 * @see https://www.w3.org/TR/trace-context/
 *
 * @example
 *
 * // Capture the caller's trace context
 * W3CTraceContext ctx = W3CTraceContext.fromRequest(RestContext.request);
 *
 * // Use the trace context (e.g. for logging)
 * System.debug(
 *     loggingLevel.INFO,
 *     'Trace ID: ' + ctx.getTraceParent().getTraceId()
 * );
 *
 * // Propagate the trace context to external dependencies
 * HttpRequest req = new HttpRequest();
 * ctx.propagate(req, true);
 */
public with sharing class W3CTraceContext {
    private static final String TRACEPARENT_HEADER = 'traceparent';
    private static final String TRACESTATE_HEADER = 'tracestate';

    private final W3CTraceParent traceParent;
    private final W3CTraceState traceState;

    private W3CTraceContext(W3CTraceParent traceParent, W3CTraceState traceState) {
        this.traceParent = traceParent;
        this.traceState = traceState;
    }

    /**
     * @description Gets the traceparent HTTP header value of this context.
     * @return The W3CTraceParent instance.
     * @see W3CTraceParent
     */
    public W3CTraceParent getTraceParent() {
        return traceParent;
    }

    /**
     * @description Gets the tracestate HTTP header value of this context.
     * @return The W3CTraceState instance.
     * @see W3CTraceState
     */
    public W3CTraceState getTraceState() {
        return traceState;
    }

    /**
     * @description Creates a new W3CTraceContext instance that represents the current request. Use this when no inbound request is available.
     * @return The new W3CTraceContext instance.
     * @see https://www.w3.org/TR/trace-context/#processing-model
     */
    public static W3CTraceContext create() {
        return new W3CTraceContext(
            new W3CTraceParent(false),
            new W3CTraceState()
        );
    }

    /**
     * @description Creates a W3CTraceContext instance that represents the provided inbound request.
     * @param inbound - The inbound request.
     * @return The W3CTraceContext instance.
     * @throws InvalidParameterValueException if inbound is null.
     * @see https://www.w3.org/TR/trace-context/#processing-model
     */
    public static W3CTraceContext fromRequest(RestRequest inbound) {
        if (inbound == null) {
            throw buildInvalidParamException('inbound', 'Inbound request cannot be null.');
        }

        String tpValue = inbound.headers.get(TRACEPARENT_HEADER);
        W3CTraceParent tp = W3CTraceParent.tryParse(tpValue);

        if (tp == null) {
            return create();
        }

        String tsStr = inbound.headers.get(TRACESTATE_HEADER);
        W3CTraceState ts = W3CTraceState.fromString(tsStr);

        return new W3CTraceContext(tp, ts);
    }

    /**
     * @description Passes the inbound request's trace context, if any, to the outbound request.
     * @param inbound - The inbound request.
     * @param outbound - The outbound request.
     * @throws InvalidParameterValueException if inbound is null.
     * @throws InvalidParameterValueException if outbound is null.
     * @see https://www.w3.org/TR/trace-context/#processing-model
     *
     * @example
     *
     * HttpRequest req = new HttpRequest();
     * W3CTraceContext.passThrough(RestContext.request, req);
     */
    public static void passThrough(RestRequest inbound, HttpRequest outbound) {
        if (inbound == null) {
            throw buildInvalidParamException('inbound', 'Inbound request cannot be null.');
        }

        if (outbound == null) {
            throw buildInvalidParamException('outbound', 'Outbound request cannot be null.');
        }

        String tpValue = inbound.headers.get(TRACEPARENT_HEADER);
        if (String.isEmpty(tpValue)) {
            return;
        }

        outbound.setHeader(TRACEPARENT_HEADER, tpValue);

        String tsValue = inbound.headers.get(TRACESTATE_HEADER);
        if (String.isEmpty(tsValue)) {
            return;
        }

        outbound.setHeader(TRACESTATE_HEADER, tsValue);
    }

    /**
     * @description Propagates the trace context to the provided outbound request.
     * @param outbound - The outbound request.
     * @param sampled - Whether the caller may have recorded trace data.
     * @see https://www.w3.org/TR/trace-context/#processing-model
     */
    public void propagate(HttpRequest outbound, Boolean sampled) {
        propagate(outbound, sampled, null);
    }

    /**
     * @description Propagates the trace context to the provided outbound request with the additional trace state.
     * @param outbound - The outbound request.
     * @param sampled - Whether the caller may have recorded trace data.
     * @param stateUpdates - An optional map of trace state key/value updates. See {@see W3CTraceState.mutate(Map<String, String>)} for more details.
     * @see https://www.w3.org/TR/trace-context/#processing-model
     */
    public void propagate(HttpRequest outbound, Boolean sampled, Map<String, String> stateUpdates) {
        if (outbound == null) {
            throw buildInvalidParamException('outbound', 'Outbound request cannot be null.');
        }

        W3CTraceParent tp = traceParent.mutate(sampled);
        W3CTraceState ts = traceState;

        if (stateUpdates != null) {
            ts = ts.mutate(stateUpdates);
        }

        outbound.setHeader(TRACEPARENT_HEADER, tp.toString());

        String tsValue = ts.toString();
        if (!String.isEmpty(tsValue)) {
            outbound.setHeader(TRACESTATE_HEADER, tsValue);
        }
    }

    private static InvalidParameterValueException buildInvalidParamException(String paramName, String message) {
        // Reference: https://salesforce.stackexchange.com/a/219924/15036
        InvalidParameterValueException ex = new InvalidParameterValueException(paramName, null);
        ex.setMessage(message);

        return ex;
    }
}
