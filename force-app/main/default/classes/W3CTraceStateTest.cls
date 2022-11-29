@IsTest
public class W3CTraceStateTest {
    @IsTest
    static void createsTraceStates() {
        W3CTraceState ts = new W3CTraceState();

        System.Assert.areEqual('', ts.toString());
    }

    @IsTest
    static void createsFromString() {
        W3CTraceState ts = W3CTraceState.fromString('key1=value1, INVALID!KEY = invalid?value , INVALID_ENTRY, =no-key-here, empty-key=, key2=value2, some-tenant@some-system-id=Some value');

        System.Assert.areEqual('key1=value1, INVALID!KEY = invalid?value , INVALID_ENTRY, =no-key-here, empty-key=, key2=value2, some-tenant@some-system-id=Some value', ts.toString());
    }

    @IsTest
    static void createsFromANullString() {
        W3CTraceState ts = W3CTraceState.fromString(null);

        System.Assert.areEqual('', ts.toString());
    }

    @IsTest
    static void getsStateValues() {
        W3CTraceState ts = W3CTraceState.fromString('key1=value1, INVALID!KEY = invalid?value , INVALID_ENTRY, =no-key-here, empty-key=, key2=value2, some-tenant@some-system-id=Some value');

        System.Assert.areEqual('value1', ts.get('key1'));
        System.Assert.areEqual('value2', ts.get('key2'));
        System.Assert.areEqual(' invalid?value', ts.get('INVALID!KEY '));
        System.Assert.isNull(ts.get('nonexisting-key'));
        System.Assert.areEqual('', ts.get('empty-key'));
        System.Assert.areEqual('Some value', ts.get('some-tenant@some-system-id'));
    }

    @IsTest
    static void iteratesOverStateValues() {
        W3CTraceState ts = W3CTraceState.fromString('key1=value1, INVALID!KEY = invalid?value , INVALID_ENTRY, =no-key-here, empty-key=, key2=value2, some-tenant@some-system-id=Some value');

        List<W3CTraceState.Entry> entries = getAllEntries(ts);

        System.Assert.areEqual(5, entries.size());

        W3CTraceState.Entry entry = entries.get(0);
        System.Assert.areEqual('key1', entry.getKey());
        System.Assert.areEqual('value1', entry.getValue());
        System.Assert.isTrue(entry.isValid());
        System.Assert.areEqual('key1=value1', entry.toString());

        entry = entries.get(1);
        System.Assert.areEqual('INVALID!KEY ', entry.getKey());
        System.Assert.areEqual(' invalid?value', entry.getValue());
        System.Assert.isFalse(entry.isValid());
        System.Assert.areEqual('INVALID!KEY = invalid?value', entry.toString());

        entry = entries.get(2);
        System.Assert.areEqual('empty-key', entry.getKey());
        System.Assert.areEqual('', entry.getValue());
        System.Assert.isFalse(entry.isValid());
        System.Assert.areEqual('empty-key=', entry.toString());

        entry = entries.get(3);
        System.Assert.areEqual('key2', entry.getKey());
        System.Assert.areEqual('value2', entry.getValue());
        System.Assert.isTrue(entry.isValid());
        System.Assert.areEqual('key2=value2', entry.toString());

        entry = entries.get(4);
        System.Assert.areEqual('some-tenant@some-system-id', entry.getKey());
        System.Assert.areEqual('Some value', entry.getValue());
        System.Assert.isTrue(entry.isValid());
        System.Assert.areEqual('some-tenant@some-system-id=Some value', entry.toString());
    }

    @IsTest
    static void throwsWhenOverruningIterator() {
        W3CTraceState ts = W3CTraceState.fromString('key1=value1,key2=value2');

        Iterator<W3CTraceState.Entry> iter = ts.iterator();

        System.Assert.isTrue(iter.hasNext());
        System.Assert.isNotNull(iter.next());

        System.Assert.isTrue(iter.hasNext());
        System.Assert.isNotNull(iter.next());

        System.Assert.isFalse(iter.hasNext());
        try {
            iter.next();
            System.Assert.fail('An exception should have been thrown.');
        } catch (NoSuchElementException ex) {
            System.Assert.areEqual('Iterator has no more elements.', ex.getMessage());
        }
    }

    @IsTest
    static void mutatesTraceStates() {
        W3CTraceState ts1 = W3CTraceState.fromString('key1=value1, INVALID!KEY = invalid?value , INVALID_ENTRY, =no-key-here, empty-key=, key2=value2, some-tenant@some-system-id=Some value');
        W3CTraceState ts2 = ts1.mutate('key2', 'NEW VALUE');

        System.Assert.areEqual('key2=NEW VALUE,key1=value1,INVALID!KEY = invalid?value,empty-key=,some-tenant@some-system-id=Some value', ts2.toString());
    }

    @IsTest
    static void mutatesTraceStatesFromIterable() {
        W3CTraceState ts1 = W3CTraceState.fromString('key1=value1, INVALID!KEY = invalid?value , INVALID_ENTRY, =no-key-here, empty-key=, key2=value2, some-tenant@some-system-id=Some value');

        Map<String, String> entries = new Map<String, String>();
        entries.put('key2', 'NEW VALUE');
        entries.put('key3', 'New value');

        W3CTraceState ts2 = ts1.mutate(entries);

        System.Assert.areEqual('key2=NEW VALUE,key3=New value,key1=value1,INVALID!KEY = invalid?value,empty-key=,some-tenant@some-system-id=Some value', ts2.toString());
    }

    @IsTest
    static void mutateThrowsWithANullKey() {
        W3CTraceState ts = W3CTraceState.fromString('key1=value1,key2=value2');

        try {
            ts.mutate(null, 'New value');
            System.Assert.fail('An exception should have been thrown.');
        } catch (InvalidParameterValueException ex) {
            System.Assert.areEqual('Key cannot be null.', ex.getMessage());
        }
    }

    @IsTest
    static void mutateThrowsWithANullMap() {
        W3CTraceState ts = W3CTraceState.fromString('key1=value1,key2=value2');

        try {
            ts.mutate(null);
            System.Assert.fail('An exception should have been thrown.');
        } catch (InvalidParameterValueException ex) {
            System.Assert.areEqual('stateUpdates cannot be null.', ex.getMessage());
        }
    }

    @IsTest
    static void mutateCanDeleteEntriesWithInvalidKeys() {
        W3CTraceState ts1 = W3CTraceState.fromString('key1=value1,INVALID!KEY=invalid?value,key2=value2');
        W3CTraceState ts2 = ts1.mutate('INVALID!KEY', null);

        System.Assert.areEqual('key1=value1,key2=value2', ts2.toString());
    }

    @IsTest
    static void mutateThrowsWhenUpdatingWithInvalidKeys() {
        W3CTraceState ts = W3CTraceState.fromString('key1=value1,INVALID!KEY=invalid?value,key2=value2');

        try {
            ts.mutate('INVALID!KEY', 'valid-value');
            System.Assert.fail('An exception should have been thrown.');
        } catch (InvalidParameterValueException ex) {
            System.Assert.areEqual('Key is invalid.', ex.getMessage());
        }
    }

    @IsTest
    static void mutateThrowsWhenUpdatingWithInvalidValues() {
        W3CTraceState ts = W3CTraceState.fromString('key1=value1,key2=value2');

        try {
            ts.mutate('key1', 'INVALID=VALUE');
            System.Assert.fail('An exception should have been thrown.');
        } catch (InvalidParameterValueException ex) {
            System.Assert.areEqual('Value is invalid.', ex.getMessage());
        }
    }

    @IsTest
    static void getSeeksOnlyFirst32Entries() {
        W3CTraceState ts = W3CTraceState.fromString('k01=v01,k02=v02,k03=v03,k04=v04,k05=v05,k06=v06,k07=v07,k08=v08,k09=v09,k10=v10,k11=v11,k12=v12,k13=v13,k14=v14,k15=v15,k16=v16,k17=v17,k18=v18,k19=v19,k20=v20,k21=v21,k22=v22,k23=v23,k24=v24,k25=v25,k26=v26,k27=v27,k28=v28,k29=v29,k30=v30,k31=v31,k32=v32,k33=v33');

        System.Assert.areEqual('v01', ts.get('k01'));
        System.Assert.isNull(ts.get('k33'));
    }

    @IsTest
    static void iteratorReturnsOnlyFirst32Entries() {
        W3CTraceState ts = W3CTraceState.fromString('k01=v01,k02=v02,k03=v03,k04=v04,k05=v05,k06=v06,k07=v07,k08=v08,k09=v09,k10=v10,k11=v11,k12=v12,k13=v13,k14=v14,k15=v15,k16=v16,k17=v17,k18=v18,k19=v19,k20=v20,k21=v21,k22=v22,k23=v23,k24=v24,k25=v25,k26=v26,k27=v27,k28=v28,k29=v29,k30=v30,k31=v31,k32=v32,k33=v33');

        List<W3CTraceState.Entry> entries = getAllEntries(ts);

        System.Assert.areEqual(32, entries.size());
        System.Assert.areEqual('v01', entries.get(0).getValue());
        System.Assert.areEqual('v32', entries.get(31).getValue());
    }

    @IsTest
    static void mutateOnlyKeepsFirst32EntriesOnInsert() {
        W3CTraceState ts1 = W3CTraceState.fromString('k01=v01,k02=v02,k03=v03,k04=v04,k05=v05,k06=v06,k07=v07,k08=v08,k09=v09,k10=v10,k11=v11,k12=v12,k13=v13,k14=v14,k15=v15,k16=v16,k17=v17,k18=v18,k19=v19,k20=v20,k21=v21,k22=v22,k23=v23,k24=v24,k25=v25,k26=v26,k27=v27,k28=v28,k29=v29,k30=v30,k31=v31,k32=v32,k33=v33');
        W3CTraceState ts2 = ts1.mutate('k99', 'New value');

        List<W3CTraceState.Entry> entries = getAllEntries(ts2);

        System.Assert.areEqual(32, entries.size());
        System.Assert.areEqual('New value', entries.get(0).getValue());
        System.Assert.areEqual('v31', entries.get(31).getValue());
    }

    @IsTest
    static void mutateOnlyKeepsFirst32EntriesOnUpdate() {
        W3CTraceState ts1 = W3CTraceState.fromString('k01=v01,k02=v02,k03=v03,k04=v04,k05=v05,k06=v06,k07=v07,k08=v08,k09=v09,k10=v10,k11=v11,k12=v12,k13=v13,k14=v14,k15=v15,k16=v16,k17=v17,k18=v18,k19=v19,k20=v20,k21=v21,k22=v22,k23=v23,k24=v24,k25=v25,k26=v26,k27=v27,k28=v28,k29=v29,k30=v30,k31=v31,k32=v32,k33=v33');
        W3CTraceState ts2 = ts1.mutate('k10', 'New value');

        List<W3CTraceState.Entry> entries = getAllEntries(ts2);

        System.Assert.areEqual(32, entries.size());
        System.Assert.areEqual('New value', entries.get(0).getValue());
        System.Assert.areEqual('v32', entries.get(31).getValue());
    }

    @IsTest
    static void mutateOnlyKeepsFirst32EntriesOnDelete() {
        W3CTraceState ts1 = W3CTraceState.fromString('k01=v01,k02=v02,k03=v03,k04=v04,k05=v05,k06=v06,k07=v07,k08=v08,k09=v09,k10=v10,k11=v11,k12=v12,k13=v13,k14=v14,k15=v15,k16=v16,k17=v17,k18=v18,k19=v19,k20=v20,k21=v21,k22=v22,k23=v23,k24=v24,k25=v25,k26=v26,k27=v27,k28=v28,k29=v29,k30=v30,k31=v31,k32=v32,k33=v33');
        W3CTraceState ts2 = ts1.mutate('k10', null);

        List<W3CTraceState.Entry> entries = getAllEntries(ts2);

        System.Assert.areEqual(32, entries.size());
        System.Assert.areEqual('v01', entries.get(0).getValue());
        System.Assert.areEqual('v33', entries.get(31).getValue());
    }

    private static List<W3CTraceState.Entry> getAllEntries(W3CTraceState traceState) {
        List<W3CTraceState.Entry> entries = new List<W3CTraceState.Entry>();

        Iterator<W3CTraceState.Entry> iter = traceState.iterator();
        while (iter.hasNext()) {
            entries.add(iter.next());
        }

        return entries;
    }
}
