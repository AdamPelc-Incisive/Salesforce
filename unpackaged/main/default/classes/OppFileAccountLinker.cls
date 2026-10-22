/**
 * Nightly sweep that shares every file and note on an Opportunity with that Opportunity's Account.
 *
 * Reads the ContentDocumentLink rows on the opportunities (not the files themselves), so it does not
 * depend on who owns a file. Anything already linked to the account is skipped. A note is also skipped
 * when the account already has a note with the same title ("Untitled Note" is never title-matched).
 * Safe to run any number of times: it only ever adds missing links.
 *
 * Run by hand:      OppFileAccountLinker.run();
 * Schedule nightly: OppFileAccountLinker.scheduleNightly();   (4:00 AM in the scheduling user's time zone)
 */
public without sharing class OppFileAccountLinker implements Schedulable {

    public static final String UNTITLED_NOTE = 'Untitled Note';
    public static final String NOTE_FILE_TYPE = 'SNOTE';
    private static final Integer CHUNK = 500;

    public class Result {
        public Integer opportunitiesScanned = 0;
        public Integer linksOnOpportunities = 0;
        public Integer linksCreated = 0;
        public Integer sameTitleNotesSkipped = 0;
        public Integer failures = 0;
        public List<String> failureMessages = new List<String>();
        public override String toString() {
            return 'opportunities=' + opportunitiesScanned + ', opportunityLinks=' + linksOnOpportunities
                + ', created=' + linksCreated + ', sameTitleNotesSkipped=' + sameTitleNotesSkipped
                + ', failures=' + failures;
        }
    }

    public void execute(SchedulableContext sc) {
        Result r = run();
        System.debug(LoggingLevel.INFO, 'OppFileAccountLinker ' + r);
    }

    public static String scheduleNightly() {
        return System.schedule('OppFileAccountLinker nightly', '0 0 4 * * ?', new OppFileAccountLinker());
    }

    public static Result run() {
        Result res = new Result();

        // 1. Opportunities that have an account
        Map<Id, Id> accountByOpp = new Map<Id, Id>();
        for (Opportunity o : [SELECT Id, AccountId FROM Opportunity WHERE AccountId != null]) {
            accountByOpp.put(o.Id, o.AccountId);
        }
        res.opportunitiesScanned = accountByOpp.size();
        if (accountByOpp.isEmpty()) {
            return res;
        }

        // 2. Files and notes linked to those opportunities
        List<ContentDocumentLink> oppLinks = new List<ContentDocumentLink>();
        List<Id> oppIds = new List<Id>(accountByOpp.keySet());
        for (Integer i = 0; i < oppIds.size(); i += CHUNK) {
            List<Id> chunk = slice(oppIds, i);
            oppLinks.addAll([
                SELECT ContentDocumentId, LinkedEntityId, ContentDocument.Title, ContentDocument.FileType
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :chunk
            ]);
        }
        res.linksOnOpportunities = oppLinks.size();

        // 3. What the accounts already have: document keys and note titles
        Set<Id> accountIds = new Set<Id>(accountByOpp.values());
        Set<String> existingKeys = new Set<String>();
        Map<Id, Set<String>> noteTitlesByAccount = new Map<Id, Set<String>>();
        List<Id> accountList = new List<Id>(accountIds);
        for (Integer i = 0; i < accountList.size(); i += CHUNK) {
            List<Id> chunk = slice(accountList, i);
            for (ContentDocumentLink l : [
                SELECT ContentDocumentId, LinkedEntityId, ContentDocument.Title, ContentDocument.FileType
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :chunk
            ]) {
                existingKeys.add(key(l.ContentDocumentId, l.LinkedEntityId));
                if (l.ContentDocument.FileType == NOTE_FILE_TYPE) {
                    addTitle(noteTitlesByAccount, l.LinkedEntityId, l.ContentDocument.Title);
                }
            }
        }

        // 4. Work out the missing links
        List<ContentDocumentLink> toInsert = new List<ContentDocumentLink>();
        for (ContentDocumentLink l : oppLinks) {
            Id accountId = accountByOpp.get(l.LinkedEntityId);
            if (accountId == null || existingKeys.contains(key(l.ContentDocumentId, accountId))) {
                continue;
            }
            Boolean isNote = l.ContentDocument.FileType == NOTE_FILE_TYPE;
            String title = l.ContentDocument.Title;
            if (isNote && isMatchableTitle(title) && hasTitle(noteTitlesByAccount, accountId, title)) {
                res.sameTitleNotesSkipped++;
                continue;
            }
            toInsert.add(new ContentDocumentLink(
                ContentDocumentId = l.ContentDocumentId,
                LinkedEntityId = accountId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
            existingKeys.add(key(l.ContentDocumentId, accountId));
            if (isNote) {
                addTitle(noteTitlesByAccount, accountId, title);
            }
        }

        // 5. Create them. One failure does not stop the rest.
        if (!toInsert.isEmpty()) {
            List<Database.SaveResult> saved = Database.insert(toInsert, false);
            for (Integer i = 0; i < saved.size(); i++) {
                if (saved[i].isSuccess()) {
                    res.linksCreated++;
                } else {
                    res.failures++;
                    if (res.failureMessages.size() < 20) {
                        res.failureMessages.add(toInsert[i].ContentDocumentId + ' -> ' + toInsert[i].LinkedEntityId
                            + ': ' + saved[i].getErrors()[0].getMessage());
                    }
                }
            }
        }
        if (res.failures > 0) {
            System.debug(LoggingLevel.ERROR, 'OppFileAccountLinker failures: ' + res.failureMessages);
        }
        return res;
    }

    private static List<Id> slice(List<Id> ids, Integer start) {
        List<Id> part = new List<Id>();
        for (Integer i = start; i < Math.min(start + CHUNK, ids.size()); i++) {
            part.add(ids[i]);
        }
        return part;
    }

    private static String key(Id documentId, Id entityId) {
        return String.valueOf(documentId).left(15) + '|' + String.valueOf(entityId).left(15);
    }

    private static Boolean isMatchableTitle(String title) {
        return String.isNotBlank(title) && title.trim().toLowerCase() != UNTITLED_NOTE.toLowerCase();
    }

    private static void addTitle(Map<Id, Set<String>> titles, Id accountId, String title) {
        if (!isMatchableTitle(title)) {
            return;
        }
        if (!titles.containsKey(accountId)) {
            titles.put(accountId, new Set<String>());
        }
        titles.get(accountId).add(title.trim().toLowerCase());
    }

    private static Boolean hasTitle(Map<Id, Set<String>> titles, Id accountId, String title) {
        return titles.containsKey(accountId) && titles.get(accountId).contains(title.trim().toLowerCase());
    }
}