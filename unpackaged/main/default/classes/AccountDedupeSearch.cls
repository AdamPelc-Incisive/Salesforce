public with sharing class AccountDedupeSearch {
    /**
     * Live "search as you type" for the New Account dedupe combobox (Dedupe Option 3).
     * Uses SOSL name matching so partial / fuzzy names surface existing practices
     * before a rep creates a duplicate. Read-only, cacheable.
     */
    @AuraEnabled(cacheable=true)
    public static List<Account> searchAccounts(String searchTerm) {
        List<Account> results = new List<Account>();
        if (String.isBlank(searchTerm) || searchTerm.trim().length() < 2) {
            return results;
        }
        // Escape SOSL reserved characters, then wildcard for partial matches.
        String cleaned = String.escapeSingleQuotes(searchTerm.trim());
        String term = '*' + cleaned + '*';
        List<List<SObject>> searchResults = [
            FIND :term IN NAME FIELDS
            RETURNING Account(
                Id, Name, ShippingCity, ShippingState, Phone, Website,
                Corporate_ID__c, Practice_ID__c, Is_Practice_Account__c,
                Corporate_Parent_Account__r.Name
                ORDER BY Name
                LIMIT 8
            )
        ];
        if (!searchResults.isEmpty()) {
            results = (List<Account>) searchResults[0];
        }
        return results;
    }
}