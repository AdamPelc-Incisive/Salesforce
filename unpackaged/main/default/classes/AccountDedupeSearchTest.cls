@isTest
private class AccountDedupeSearchTest {
    @isTest
    static void returnsMatchesForValidTerm() {
        Account a = new Account(Name = 'Smith Family Dental');
        insert a;
        Test.setFixedSearchResults(new List<Id>{ a.Id });

        Test.startTest();
        List<Account> results = AccountDedupeSearch.searchAccounts('Smith');
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected the seeded account back');
        System.assertEquals(a.Id, results[0].Id, 'Wrong account returned');
    }

    @isTest
    static void ignoresShortOrBlankTerms() {
        System.assertEquals(0, AccountDedupeSearch.searchAccounts('a').size(), 'Single char should not search');
        System.assertEquals(0, AccountDedupeSearch.searchAccounts('').size(), 'Blank should not search');
        System.assertEquals(0, AccountDedupeSearch.searchAccounts(null).size(), 'Null should not search');
    }
}