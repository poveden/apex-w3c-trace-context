/**
 * @description Represents a W3C Trace Context traceparent HTTP header value.
 * @see W3CTraceContext
 * @see https://www.w3.org/TR/trace-context/#traceparent-header
 */
public with sharing class W3CTraceParent {
    private static final Integer SUPPORTED_VERSION = 0;

    private static final Pattern V0_PATTERN = Pattern.compile('^([0-9a-f]{2})-([0-9a-f]{32})-([0-9a-f]{16})-([0-9a-f]{2})(?:$|-)');

    private static final Integer TRACEID_LENGTH = 32;
    private static final Integer PARENTID_LENGTH = 16;

    private static final Integer SAMPLED_FLAG = 1;

    private static final String INVALID_VERSION = 'ff';
    private static final String INVALID_TRACEID = '00000000000000000000000000000000';
    private static final String INVALID_PARENTID = '0000000000000000';

    private static final String HEX_CHARS = '0123456789abcdef';

    private final String traceId;
    private final String parentId;
    private final Boolean sampled;

    /**
     * @description Initializes a new instance of the W3CTraceParent class with the provided sampled flag.
     * @param sampled - Whether the caller may have recorded trace data.
     */
    public W3CTraceParent(Boolean sampled) {
        this(
            getRandomNonZeroHexString(TRACEID_LENGTH),
            getRandomNonZeroHexString(PARENTID_LENGTH),
            sampled
        );
    }

    private W3CTraceParent(String traceId, String parentId, Boolean sampled) {
        this.traceId = traceId;
        this.parentId = parentId;
        this.sampled = sampled;
    }

    /**
     * @description Gets the version of the trace context.
     * @return The version of the trace context.
     * @see https://www.w3.org/TR/trace-context/#version
     */
    public Integer getVersion() {
        return SUPPORTED_VERSION;
    }

    /**
     * @description Gets the ID of the whole trace forest.
     * @return The trace ID.
     * @see https://www.w3.org/TR/trace-context/#trace-id
     */
    public String getTraceId() {
        return traceId;
    }

    /**
     * @description Gets the ID of this request as known by the caller.
     * @return The parent ID.
     * @see https://www.w3.org/TR/trace-context/#parent-id
     */
    public String getParentId() {
        return parentId;
    }

    /**
     * @description Gets a value indicating whether the caller may have recorded trace data.
     * @return true if the caller may have recorded trace data; false otherwise.
     * @see https://www.w3.org/TR/trace-context/#sampled-flag
     */
    public Boolean getSampled() {
        return sampled;
    }

    /**
     * @description Creates a new W3CTraceParent instance, mutated with a new parent ID and the provided sampled flag.
     * @param sampled - A value indicating whether the caller may be recording trace data.
     * @return The new, mutated W3CTraceParent instance.
     * @see https://www.w3.org/TR/trace-context/#mutating-the-traceparent-field
     */
    public W3CTraceParent mutate(Boolean sampled) {
        return new W3CTraceParent(
            traceId,
            getRandomNonZeroHexString(PARENTID_LENGTH),
            sampled
        );
    }

    public override String toString() {
        String[] elems = new String[] {
            getHexByte(SUPPORTED_VERSION),
            traceId,
            parentId,
            getHexByte(sampled ? SAMPLED_FLAG : 0)
        };

        return String.join(elems, '-');
    }

    /**
     * @description Tries to parse a traceparent HTTP header value.
     * @param input - The string to parse.
     * @return If input is a valid traceparent, a new W3CTraceParent instance will be returned; otherwise, null.
     */
    public static W3CTraceParent tryParse(String input) {
        if (input == null) {
            return null;
        }

        Matcher m = V0_PATTERN.matcher(input);
        if (!m.find()) {
            return null;
        }

        String version = m.group(1);
        if (version == INVALID_VERSION) {
            return null;
        }

        String traceId = m.group(2);
        if (traceId == INVALID_TRACEID) {
            return null;
        }

        String parentId = m.group(3);
        if (parentId == INVALID_PARENTID) {
            return null;
        }

        String traceFlags = m.group(4);
        Boolean sampled = (getByteFromHexString(traceFlags, 0) & SAMPLED_FLAG) == SAMPLED_FLAG;

        return new W3CTraceParent(traceId, parentId, sampled);
    }

    private static String getRandomNonZeroHexString(Integer hexChars) {
        Integer[] buf = new Integer[hexChars];

        Boolean nonZero = false;
        do {
            Integer rnd;
            Integer j = 0;
            for (Integer i = 0; i < hexChars; i += 2) {
                if (j == 0) {
                    rnd = Crypto.getRandomInteger();
                    j = 4;
                }

                Integer byteValue = rnd & 255;
                rnd >>>= 8;
                j--;

                setHexChars(buf, i, byteValue);
                nonZero = nonZero | (byteValue != 0);
            }
        } while (!nonZero);

        return String.fromCharArray(buf);
    }

    private static Integer getByteFromHexString(String hexString, Integer index) {
        Integer hi = HEX_CHARS.indexOfChar(hexString.charAt(index));
        Integer lo = HEX_CHARS.indexOfChar(hexString.charAt(index + 1));

        return (hi << 4) | lo;
    }

    private static void setHexChars(Integer[] buf, Integer index, Integer byteValue) {
        Integer hi = (byteValue >> 4) & 15;
        Integer lo = byteValue & 15;

        buf[index] = HEX_CHARS.charAt(hi);
        buf[index + 1] = HEX_CHARS.charAt(lo);
    }

    private static String getHexByte(Integer byteValue) {
        Integer[] buf = new Integer[2];
        setHexChars(buf, 0, byteValue);
        return String.fromCharArray(buf);
    }
}
