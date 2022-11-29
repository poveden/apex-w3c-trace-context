@IsTest
public class W3CTraceParentTest {
    private static final Pattern RX_TRACEPARENT = Pattern.compile(
        '^[0-9a-f]{2}-[0-9a-f]{32}-[0-9a-f]{16}-[0-9a-f]{2}$'
    );

    @IsTest
    static void parsesTraceParents() {
        W3CTraceParent tp = W3CTraceParent.TryParse(
            '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01'
        );

        System.Assert.isNotNull(tp);
        System.Assert.areEqual(
            '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01',
            tp.toString()
        );
        System.Assert.areEqual(0, tp.getVersion());
        System.Assert.areEqual(
            '0af7651916cd43dd8448eb211c80319c',
            tp.getTraceId()
        );
        System.Assert.areEqual('b7ad6b7169203331', tp.getParentId());
        System.Assert.isTrue(tp.getSampled());
    }

    @IsTest
    static void createsNewTraceParents() {
        W3CTraceParent tp1 = new W3CTraceParent(true);

        System.Assert.isNotNull(tp1);
        System.Assert.isTrue(RX_TRACEPARENT.matcher(tp1.toString()).matches());

        W3CTraceParent tp2 = W3CTraceParent.tryParse(tp1.toString());

        System.Assert.isNotNull(tp2);
        System.Assert.areEqual(tp2.toString(), tp1.toString());
        System.Assert.areEqual(tp2.getVersion(), tp1.getVersion());
        System.Assert.areEqual(tp2.getTraceId(), tp1.getTraceId());
        System.Assert.areEqual(tp2.getParentId(), tp1.getParentId());
        System.Assert.areEqual(tp2.getSampled(), tp1.getSampled());
    }
    @IsTest
    static void nullTraceParentsAreInvalid() {
        String tp = null;
        System.Assert.isNull(W3CTraceParent.tryParse(tp));
    }

    @IsTest
    static void traceParentsLessThan55CharsAreInvalid() {
        String tp = '00-eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
        System.Assert.isNull(W3CTraceParent.tryParse(tp));
    }

    @IsTest
    static void versionsWithNonLowerCaseHexCharsAreInvalid() {
        String tp = '0F-eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-aaaaaaaaaaaaaaaa-01';
        System.Assert.isNull(W3CTraceParent.tryParse(tp));
    }

    @IsTest
    static void ffVersionNumbersAreInvalid() {
        String tp = 'ff-eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-aaaaaaaaaaaaaaaa-00';
        System.Assert.isNull(W3CTraceParent.tryParse(tp));
    }

    @IsTest
    static void traceParentsWithMissingDash1AreInvalid() {
        String tp = '00 eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-aaaaaaaaaaaaaaaa-00';
        System.Assert.isNull(W3CTraceParent.tryParse(tp));
    }

    @IsTest
    static void traceIdsWithNonLowerCaseHexCharsAreInvalid() {
        String tp = '00-eEeEeEeEeEeEeEeEeEeEeEeEeEeEeEeE-aaaaaaaaaaaaaaaa-00';
        System.Assert.isNull(W3CTraceParent.tryParse(tp));
    }

    @IsTest
    static void zeroedTraceIdsAreInvalid() {
        String tp = '00-00000000000000000000000000000000-aaaaaaaaaaaaaaaa-00';
        System.Assert.isNull(W3CTraceParent.tryParse(tp));
    }

    @IsTest
    static void traceParentsWithMissingDash2AreInvalid() {
        String tp = '0f-eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee aaaaaaaaaaaaaaaa-00';
        System.Assert.isNull(W3CTraceParent.tryParse(tp));
    }

    @IsTest
    static void parentIdsWithNonLowerCaseHexCharsAreInvalid() {
        String tp = '00-eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-aAaAaAaAaAaAaAaA-00';
        System.Assert.isNull(W3CTraceParent.tryParse(tp));
    }

    @IsTest
    static void zeroedParentIdsAreInvalid() {
        String tp = '00-eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-0000000000000000-00';
        System.Assert.isNull(W3CTraceParent.tryParse(tp));
    }

    @IsTest
    static void traceParentsWithMissingDash3AreInvalid() {
        String tp = '00-eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-aaaaaaaaaaaaaaaa 00';
        System.Assert.isNull(W3CTraceParent.tryParse(tp));
    }

    @IsTest
    static void traceFlagsWithNonLowerCaseHexCharsAreInvalid() {
        String tp = '00-eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-aaaaaaaaaaaaaaaa-0F';
        System.Assert.isNull(W3CTraceParent.tryParse(tp));
    }

    @IsTest
    static void traceParentsWithMoreThan55CharsAndADelimitingDashAreValid() {
        String tp = '00-eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-aaaaaaaaaaaaaaaa-00-VALID-FUTURE-CONTENT';
        System.Assert.isNotNull(W3CTraceParent.tryParse(tp));
    }

    @IsTest
    static void traceParentsWithMoreThan55CharsAndNoDelimitingDashAreInvalid() {
        String tp = '00-eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-aaaaaaaaaaaaaaaa-00=INVALID-FUTURE-CONTENT';
        System.Assert.isNull(W3CTraceParent.tryParse(tp));
    }

    @IsTest
    static void mutatesTraceParents() {
        W3CTraceParent tp1 = new W3CTraceParent(true);
        W3CTraceParent tp2 = tp1.mutate(false);

        System.Assert.isNotNull(W3CTraceParent.tryParse(tp2.toString()));

        System.Assert.areEqual(tp1.getVersion(), tp2.getVersion());
        System.Assert.areEqual(tp1.getTraceId(), tp2.getTraceId());
        System.Assert.areNotEqual(tp1.getParentId(), tp2.getParentId());
        System.Assert.areNotEqual(tp1.getSampled(), tp2.getSampled());
    }
}
