@isTest
private class GetFilteredPendingDevicesTest {

    @TestSetup
    static void setupTestData() {
        // Accounts
        Account practiceAcct1 = new Account(Name = 'Practice Account 1');
        Account practiceAcct2 = new Account(Name = 'Practice Account 2');
        Account corpAcct = new Account(Name = 'Corporate Account');
        insert new List<Account>{ practiceAcct1, practiceAcct2, corpAcct };

        // Onboarding records (master-detail to Account, Name is auto-number)
        Onboarding__c onb1 = new Onboarding__c(Account__c = practiceAcct1.Id);
        Onboarding__c onb2 = new Onboarding__c(Account__c = practiceAcct2.Id);
        insert new List<Onboarding__c>{ onb1, onb2 };

        // Products
        Product2 scannerProduct = new Product2(Name = 'Test Scanner', Family = 'Scanner', IsActive = true);
        Product2 laptopProduct = new Product2(Name = 'Test Laptop', Family = 'Laptop', IsActive = true);
        Product2 accessoryProduct = new Product2(Name = 'Test Accessory', Family = 'Accessory', IsActive = true);
        insert new List<Product2>{ scannerProduct, laptopProduct, accessoryProduct };

        // Pricebook Entries
        Id stdPbId = Test.getStandardPricebookId();
        PricebookEntry pbeScanner = new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = scannerProduct.Id, UnitPrice = 100, IsActive = true);
        PricebookEntry pbeLaptop = new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = laptopProduct.Id, UnitPrice = 500, IsActive = true);
        PricebookEntry pbeAccessory = new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = accessoryProduct.Id, UnitPrice = 25, IsActive = true);
        insert new List<PricebookEntry>{ pbeScanner, pbeLaptop, pbeAccessory };

        // Opportunities
        Opportunity opp1 = new Opportunity(Name = 'Opp 1', AccountId = practiceAcct1.Id, StageName = 'Qualification', CloseDate = Date.today());
        Opportunity opp2 = new Opportunity(Name = 'Opp 2', AccountId = practiceAcct2.Id, StageName = 'Qualification', CloseDate = Date.today());
        insert new List<Opportunity>{ opp1, opp2 };

        // Opportunity Line Items
        OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = opp1.Id, PricebookEntryId = pbeScanner.Id, Quantity = 1, UnitPrice = 100);
        OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId = opp1.Id, PricebookEntryId = pbeLaptop.Id, Quantity = 1, UnitPrice = 500);
        OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId = opp2.Id, PricebookEntryId = pbeLaptop.Id, Quantity = 1, UnitPrice = 500);
        OpportunityLineItem oli4 = new OpportunityLineItem(OpportunityId = opp2.Id, PricebookEntryId = pbeAccessory.Id, Quantity = 1, UnitPrice = 25);
        insert new List<OpportunityLineItem>{ oli1, oli2, oli3, oli4 };

        // Pending Devices (requires Onboarding__c master-detail)
        List<Pending_Device__c> devices = new List<Pending_Device__c>();
        devices.add(new Pending_Device__c(Name = 'PD Scanner Pract1', Practice_Account__c = practiceAcct1.Id, Corporate_Account__c = corpAcct.Id, Opportunity_Product__c = oli1.Id, Onboarding__c = onb1.Id, Status__c = 'Ordered'));
        devices.add(new Pending_Device__c(Name = 'PD Laptop Pract1', Practice_Account__c = practiceAcct1.Id, Corporate_Account__c = corpAcct.Id, Opportunity_Product__c = oli2.Id, Onboarding__c = onb1.Id, Status__c = 'Ordered'));
        devices.add(new Pending_Device__c(Name = 'PD Laptop Pract2', Practice_Account__c = practiceAcct2.Id, Corporate_Account__c = corpAcct.Id, Opportunity_Product__c = oli3.Id, Onboarding__c = onb2.Id, Status__c = 'Ordered'));
        devices.add(new Pending_Device__c(Name = 'PD Accessory Pract2', Practice_Account__c = practiceAcct2.Id, Opportunity_Product__c = oli4.Id, Onboarding__c = onb2.Id, Status__c = 'Assigned'));
        insert devices;
    }

    @isTest
    static void testSinglePracticeAccount() {
        Account pract1 = [SELECT Id FROM Account WHERE Name = 'Practice Account 1' LIMIT 1];

        GetFilteredPendingDevices.Request req = new GetFilteredPendingDevices.Request();
        req.accountIdList = new List<Id>{ pract1.Id };

        Test.startTest();
        List<GetFilteredPendingDevices.Result> results = GetFilteredPendingDevices.getPendingDevices(
            new List<GetFilteredPendingDevices.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(2, results[0].pendingDevices.size(), 'Should return 2 devices for Practice Account 1');
    }

    @isTest
    static void testCorporateAccountMatch() {
        Account corpAcct = [SELECT Id FROM Account WHERE Name = 'Corporate Account' LIMIT 1];

        GetFilteredPendingDevices.Request req = new GetFilteredPendingDevices.Request();
        req.accountIdList = new List<Id>{ corpAcct.Id };

        Test.startTest();
        List<GetFilteredPendingDevices.Result> results = GetFilteredPendingDevices.getPendingDevices(
            new List<GetFilteredPendingDevices.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(3, results[0].pendingDevices.size(), 'Should return 3 devices where Corporate Account matches');
    }

    @isTest
    static void testAccountMatchesBothFields() {
        Account pract2 = [SELECT Id FROM Account WHERE Name = 'Practice Account 2' LIMIT 1];
        Account corpAcct = [SELECT Id FROM Account WHERE Name = 'Corporate Account' LIMIT 1];

        GetFilteredPendingDevices.Request req = new GetFilteredPendingDevices.Request();
        req.accountIdList = new List<Id>{ pract2.Id, corpAcct.Id };

        Test.startTest();
        List<GetFilteredPendingDevices.Result> results = GetFilteredPendingDevices.getPendingDevices(
            new List<GetFilteredPendingDevices.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(3, results[0].pendingDevices.size(), 'Should return 3 Ordered devices matching Practice or Corporate Account');
    }

    @isTest
    static void testSingleProductId() {
        Product2 scanner = [SELECT Id FROM Product2 WHERE Name = 'Test Scanner' LIMIT 1];

        GetFilteredPendingDevices.Request req = new GetFilteredPendingDevices.Request();
        req.productIdList = new List<Id>{ scanner.Id };

        Test.startTest();
        List<GetFilteredPendingDevices.Result> results = GetFilteredPendingDevices.getPendingDevices(
            new List<GetFilteredPendingDevices.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results[0].pendingDevices.size(), 'Should return 1 device with Scanner product');
        System.assertEquals('PD Scanner Pract1', results[0].pendingDevices[0].Name);
    }

    @isTest
    static void testMultipleProductIds() {
        List<Product2> products = [SELECT Id FROM Product2 WHERE Name IN ('Test Scanner', 'Test Laptop') ORDER BY Name];

        GetFilteredPendingDevices.Request req = new GetFilteredPendingDevices.Request();
        req.productIdList = new List<Id>{ products[0].Id, products[1].Id };

        Test.startTest();
        List<GetFilteredPendingDevices.Result> results = GetFilteredPendingDevices.getPendingDevices(
            new List<GetFilteredPendingDevices.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(3, results[0].pendingDevices.size(), 'Should return 3 devices for Scanner + Laptop products');
    }

    @isTest
    static void testSingleProductFamily() {
        GetFilteredPendingDevices.Request req = new GetFilteredPendingDevices.Request();
        req.productFamily = 'Laptop';

        Test.startTest();
        List<GetFilteredPendingDevices.Result> results = GetFilteredPendingDevices.getPendingDevices(
            new List<GetFilteredPendingDevices.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(2, results[0].pendingDevices.size(), 'Should return 2 Laptop family devices');
    }

    @isTest
    static void testMultipleProductFamilies() {
        GetFilteredPendingDevices.Request req = new GetFilteredPendingDevices.Request();
        req.productFamily = 'Scanner;Accessory';

        Test.startTest();
        List<GetFilteredPendingDevices.Result> results = GetFilteredPendingDevices.getPendingDevices(
            new List<GetFilteredPendingDevices.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results[0].pendingDevices.size(), 'Should return 1 Ordered device for Scanner + Accessory families');
    }

    @isTest
    static void testAllFiltersCombined() {
        Account pract1 = [SELECT Id FROM Account WHERE Name = 'Practice Account 1' LIMIT 1];
        Product2 laptop = [SELECT Id FROM Product2 WHERE Name = 'Test Laptop' LIMIT 1];

        GetFilteredPendingDevices.Request req = new GetFilteredPendingDevices.Request();
        req.accountIdList = new List<Id>{ pract1.Id };
        req.productIdList = new List<Id>{ laptop.Id };
        req.productFamily = 'Laptop';

        Test.startTest();
        List<GetFilteredPendingDevices.Result> results = GetFilteredPendingDevices.getPendingDevices(
            new List<GetFilteredPendingDevices.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results[0].pendingDevices.size(), 'Should return 1 device matching all three filters');
        System.assertEquals('PD Laptop Pract1', results[0].pendingDevices[0].Name);
    }

    @isTest
    static void testNoFiltersReturnsAll() {
        GetFilteredPendingDevices.Request req = new GetFilteredPendingDevices.Request();

        Test.startTest();
        List<GetFilteredPendingDevices.Result> results = GetFilteredPendingDevices.getPendingDevices(
            new List<GetFilteredPendingDevices.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(3, results[0].pendingDevices.size(), 'Should return 3 Ordered devices when no other filters applied');
    }

    @isTest
    static void testNoMatchReturnsEmpty() {
        GetFilteredPendingDevices.Request req = new GetFilteredPendingDevices.Request();
        req.productFamily = 'Nonexistent';

        Test.startTest();
        List<GetFilteredPendingDevices.Result> results = GetFilteredPendingDevices.getPendingDevices(
            new List<GetFilteredPendingDevices.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(0, results[0].pendingDevices.size(), 'Should return empty list for non-matching filter');
    }
}