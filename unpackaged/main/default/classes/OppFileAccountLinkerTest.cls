@IsTest
private class OppFileAccountLinkerTest {

    private static Account makeAccount(String name) {
        Account a = new Account(Name = name);
        insert a;
        return a;
    }

    private static Opportunity makeOpp(Account a, String name) {
        Opportunity o = new Opportunity(
            Name = name,
            AccountId = a == null ? null : a.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30)
        );
        insert o;
        return o;
    }

    private static Id makeFileOn(Id parentId, String title) {
        ContentVersion cv = new ContentVersion(
            Title = title,
            PathOnClient = title + '.txt',
            VersionData = Blob.valueOf('test ' + title),
            FirstPublishLocationId = parentId
        );
        insert cv;
        return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
    }

    private static Id makeNoteOn(Id parentId, String title) {
        ContentNote n = new ContentNote(Title = title, Content = Blob.valueOf('<p>' + title + '</p>'));
        insert n;
        insert new ContentDocumentLink(
            ContentDocumentId = n.Id,
            LinkedEntityId = parentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        return n.Id;
    }

    private static Integer linkCount(Id documentId, Id entityId) {
        return [SELECT COUNT() FROM ContentDocumentLink WHERE ContentDocumentId = :documentId AND LinkedEntityId = :entityId];
    }

    @IsTest
    static void linksFileAndNoteToAccountAndIsRepeatable() {
        Account a = makeAccount('Test Practice');
        Opportunity o = makeOpp(a, 'Test Opp');
        Id fileId = makeFileOn(o.Id, 'Agreement');
        Id noteId = makeNoteOn(o.Id, 'Kickoff call');

        Test.startTest();
        OppFileAccountLinker.Result first = OppFileAccountLinker.run();
        OppFileAccountLinker.Result second = OppFileAccountLinker.run();
        Test.stopTest();

        System.assertEquals(1, linkCount(fileId, a.Id), 'file should be linked to the account');
        System.assertEquals(1, linkCount(noteId, a.Id), 'note should be linked to the account');
        System.assertEquals(2, first.linksCreated, 'first run creates the two missing links');
        System.assertEquals(0, second.linksCreated, 'second run creates nothing');
        System.assertEquals(0, first.failures);

        ContentDocumentLink l = [
            SELECT ShareType, Visibility FROM ContentDocumentLink
            WHERE ContentDocumentId = :fileId AND LinkedEntityId = :a.Id
        ];
        System.assertEquals('V', l.ShareType);
        System.assertEquals('AllUsers', l.Visibility);
    }

    @IsTest
    static void skipsNoteWhenAccountAlreadyHasSameTitle() {
        Account a = makeAccount('Test Practice');
        Opportunity o = makeOpp(a, 'Test Opp');
        Id accountNoteId = makeNoteOn(a.Id, 'Same Title');
        Id oppNoteId = makeNoteOn(o.Id, 'same title');

        Test.startTest();
        OppFileAccountLinker.Result r = OppFileAccountLinker.run();
        Test.stopTest();

        System.assertEquals(0, linkCount(oppNoteId, a.Id), 'same-title note is not linked');
        System.assertEquals(1, linkCount(accountNoteId, a.Id));
        System.assertEquals(1, r.sameTitleNotesSkipped);
    }

    @IsTest
    static void untitledNotesAreNeverTitleMatched() {
        Account a = makeAccount('Test Practice');
        Opportunity o = makeOpp(a, 'Test Opp');
        makeNoteOn(a.Id, 'Untitled Note');
        Id oppNoteId = makeNoteOn(o.Id, 'Untitled Note');

        Test.startTest();
        OppFileAccountLinker.Result r = OppFileAccountLinker.run();
        Test.stopTest();

        System.assertEquals(1, linkCount(oppNoteId, a.Id), 'Untitled Note is linked despite the same title');
        System.assertEquals(0, r.sameTitleNotesSkipped);
    }

    @IsTest
    static void ignoresOpportunitiesWithoutAnAccount() {
        Opportunity o = makeOpp(null, 'Orphan Opp');
        makeFileOn(o.Id, 'Loose file');

        Test.startTest();
        OppFileAccountLinker.Result r = OppFileAccountLinker.run();
        Test.stopTest();

        System.assertEquals(0, r.opportunitiesScanned);
        System.assertEquals(0, r.linksCreated);
    }

    @IsTest
    static void schedulesAndRunsNightly() {
        Account a = makeAccount('Test Practice');
        Opportunity o = makeOpp(a, 'Test Opp');
        Id fileId = makeFileOn(o.Id, 'Agreement');

        Test.startTest();
        String jobId = OppFileAccountLinker.scheduleNightly();
        Test.stopTest();

        System.assertNotEquals(null, jobId);
        System.assertEquals(1, [SELECT COUNT() FROM CronTrigger WHERE Id = :jobId]);
        // Test.stopTest() runs the scheduled job once the start time has been reached; run directly to confirm the result.
        OppFileAccountLinker.run();
        System.assertEquals(1, linkCount(fileId, a.Id));
    }
}