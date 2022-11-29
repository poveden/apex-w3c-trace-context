/**
 * @description Represents a W3C Trace Context tracestate HTTP header value.
 * @see W3CTraceContext
 * @see https://www.w3.org/TR/trace-context/#tracestate-header
 */
public with sharing class W3CTraceState implements Iterable<Entry> {
    // Reference: https://www.w3.org/TR/trace-context/#key
    private static final Pattern SIMPLEKEY_PATTERN = Pattern.compile('^[a-z][a-z0-9_\\-*/]{0,255}$');
    private static final Pattern MULTITENANTKEY_PATTERN = Pattern.compile('^[a-z0-9][a-z0-9_\\-*/]{0,240}@[a-z][a-z0-9_\\-*/]{0,13}$');

    // Reference: https://www.w3.org/TR/trace-context/#value
    private static final Pattern VALUE_PATTERN = Pattern.compile('^[ -+\\--<>-~]{1,256}+(?<! )$');

    private static final Integer CHAR_EQUAL = 61;
    private static final Integer CHAR_COMMA = 44;
    private static final Integer CHAR_SPACE = 32;
    private static final Integer CHAR_TAB = 9;
    private static final Integer CHAR_ATSIGN = 64;

    private static final Integer MAX_LIST_MEMBERS = 32;

    private final String traceState;

    /**
     * @description Initializes a new instance of the W3CTraceState class.
     */
    public W3CTraceState() {
        traceState = '';
    }

    private W3CTraceState(String value) {
        this.traceState = value;
    }

    /**
     * @description Gets the value of the provided key.
     * @param key - The key to retrieve the value for.
     * @return The value, or null if the key could not be found.
     */
    public String get(String key) {
        Iterator<Entry> entries = this.iterator();
        while (entries.hasNext()) {
            Entry entry = entries.next();

            if (entry.key == key) {
                return entry.value;
            }
        }

        return null;
    }

    /**
     * @description Creates a new W3CTraceState instance, mutated with the provided entry's key and value.
     * @param key - The key of the entry to mutate.
     * @param value - The value to set for the entry's key. If a null or empty string is used, the entry will be deleted.
     * @return The new, mutated W3CTraceState instance.
     * @throws InvalidParameterValueException if key is invalid and value is not null or empty.
     * @throws InvalidParameterValueException if value is invalid.
     * @see https://www.w3.org/TR/trace-context/#mutating-the-tracestate-field
     */
    public W3CTraceState mutate(String key, String value) {
        return mutate(new Map<String, String> { key => value });
    }

    /**
     * @description Creates a new W3CTraceState instance, mutated with the provided entry's key and value.
     * @param stateUpdates - The set of mutations to apply. Each key/value pair is treated as if {@see mutate(String, String)} were called on each one.
     * @return The new, mutated W3CTraceState instance.
     * @throws InvalidParameterValueException if any key of stateUpdates is invalid and value is not null or empty.
     * @throws InvalidParameterValueException if any value of stateUpdates is invalid.
     * @see https://www.w3.org/TR/trace-context/#mutating-the-tracestate-field
     */
    public W3CTraceState mutate(Map<String, String> stateUpdates) {
        if (stateUpdates == null) {
            throw buildInvalidParamException('stateUpdates', 'stateUpdates cannot be null.');
        }

        List<String> res = new List<String>();

        for (String key : stateUpdates.keySet()) {
            String value = stateUpdates.get(key);
            if (String.isEmpty(value)) {
                continue;
            }

            Entry entry = new Entry(key, value, true);
            res.add(entry.toString());
        }

        Iterator<Entry> entries = new EntryIterator(traceState, true);

        while (entries.hasNext() && res.size() < MAX_LIST_MEMBERS) {
            Entry entry = entries.next();

            if (stateUpdates.containsKey(entry.key)) {
                // Skip the already modified keys.
                continue;
            }

            res.add(entry.toString());
        }

        return new W3CTraceState(String.join(res, ','));
    }

    /**
     * @description Returns an iterator over the entries in this instance.
     * @return The iterator over the entries in this instance.
     */
    public Iterator<Entry> iterator() {
        return new EntryIterator(traceState, false);
    }

    public override String toString() {
        return traceState;
    }

    /**
     * @description Creates a new W3CTraceState instance from the provided string.
     * @param input - The string to create the W3CTraceState instance from.
     * @return The new W3CTraceState instance.
     */
    public static W3CTraceState fromString(String input) {
        return (input != null)
            ? new W3CTraceState(input)
            : new W3CTraceState();
    }

    private static Boolean isValidKey(String key) {
        return key.indexOfChar(CHAR_ATSIGN) == -1
            ? SIMPLEKEY_PATTERN.matcher(key).matches()
            : MULTITENANTKEY_PATTERN.matcher(key).matches();
    }

    private static Boolean isValidValue(String value) {
        return VALUE_PATTERN.matcher(value).matches();
    }

    private static InvalidParameterValueException buildInvalidParamException(String paramName, String message) {
        // Reference: https://salesforce.stackexchange.com/a/219924/15036
        InvalidParameterValueException ex = new InvalidParameterValueException(paramName, null);
        ex.setMessage(message);

        return ex;
    }

    /**
     * @description Represents an entry in a W3C Trace Context tracestate HTTP header value.
     * @see https://www.w3.org/TR/trace-context/#list-members
     */
    public class Entry {
        private final String key;
        private final String value;
        private final Boolean valid;

        private Entry(String key, String value, Boolean enforceValid) {
            if (key == null) {
                throw buildInvalidParamException('key', 'Key cannot be null.');
            }

            Boolean validKey = isValidKey(key);
            if (!validKey && enforceValid) {
                throw buildInvalidParamException('key', 'Key is invalid.');
            }

            Boolean validValue = isValidValue(value);
            if (!validValue && enforceValid) {
                throw buildInvalidParamException('value', 'Value is invalid.');
            }

            this.key = key;
            this.value = value;
            valid = validKey && validValue;
        }

        /**
         * @description Gets the key for this entry.
         * @return The key.
         */
        public String getKey() {
            return key;
        }

        /**
         * @description Gets the value for this entry.
         * @return The value.
         */
        public String getValue() {
            return value;
        }

        /**
         * @description Gets a value indicating whether this entry is valid.
         * @return true if the entry is valid; otherwise, false.
         */
        public Boolean isValid() {
            return valid;
        }

        public override String toString() {
            return key + '=' + value;
        }
    }

    private class EntryIterator implements Iterator<Entry> {
        private final String input;
        private final Boolean doNotLimit;

        private Integer iNext;
        private Entry nextEntry;
        private Integer count;

        private EntryIterator(string input, Boolean doNotLimit) {
            this.input = input;
            this.doNotLimit = doNotLimit;
            iNext = 0;
            count = 0;
            nextEntry = findNext();
        }

        /**
         * @description Gets a value indicating whether the iteration has more elements.
         * @return true if the iteration has more elements; otherwise, false.
         */
        public Boolean hasNext(){
            return nextEntry != null;
        }

        /**
         * @description Gets the next element in the iteration.
         * @return The next element in the iteration.
         * @throws NoSuchElementException if the iteration has no more elements.
         */
        public Entry next() {
            if (!hasNext()) {
                throw new NoSuchElementException('Iterator has no more elements.');
            }

            Entry entry = nextEntry;
            nextEntry = findNext();

            return entry;
        }

        private Entry findNext() {
            while (iNext < input.length() && (doNotLimit || count < MAX_LIST_MEMBERS)) {
                Entry entry = tryParseNext();

                if (entry != null) {
                    count++;
                    return entry;
                }
            }

            return null;
        }

        private Entry tryParseNext() {
            Integer iBegin = iNext;

            Integer iEnd = input.indexOfChar(CHAR_COMMA, iNext);
            if (iEnd == -1) {
                iEnd = input.length();
            }

            iNext = iEnd + 1;

            Integer iEqual = input.indexOfChar(CHAR_EQUAL, iBegin);

            if (iEqual == -1 || iEqual > iEnd) {
                // Invalid entry.
                return null;
            }

            Integer ch = input.charAt(iBegin);
            while (ch == CHAR_SPACE || ch == CHAR_TAB) {
                iBegin++;
                ch = input.charAt(iBegin);
            }

            if (iBegin == iEqual) {
                // Empty key.
                return null;
            }

            ch = input.charAt(iEnd - 1);
            while (ch == CHAR_SPACE || ch == CHAR_TAB) {
                iEnd--;
                ch = input.charAt(iEnd - 1);
            }

            String key = input.substring(iBegin, iEqual);
            String value = input.substring(iEqual + 1, iEnd);

            return new Entry(key, value, false);
        }
    }
}
