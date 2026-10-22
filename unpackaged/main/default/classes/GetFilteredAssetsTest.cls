@isTest
private class GetFilteredAssetsTest {

    @TestSetup
    static void setupTestData() {
        Account corpParent = new Account(Name = 'Corporate Parent');
        insert corpParent;

        Account acct1 = new Account(Name = 'Test Account 1');
        Account acct2 = new Account(Name = 'Test Account 2');
        Account acct3 = new Account(Name = 'Test Account 3', ParentId = corpParent.Id);
        insert new List<Account>{ acct1, acct2, acct3 };

        Product2 scannerProduct = new Product2(Name = 'Test Scanner', Family = 'Scanner', IsActive = true);
        Product2 laptopProduct = new Product2(Name = 'Test Laptop', Family = 'Laptop', IsActive = true);
        Product2 accessoryProduct = new Product2(Name = 'Test Accessory', Family = 'Accessory', IsActive = true);
        insert new List<Product2>{ scannerProduct, laptopProduct, accessoryProduct };

        List<Asset> assets = new List<Asset>();
        assets.add(new Asset(Name = 'Scanner Installed Acct1', AccountId = acct1.Id, Product2Id = scannerProduct.Id, Status = 'Installed'));
        assets.add(new Asset(Name = 'Scanner Obsolete Acct1', AccountId = acct1.Id, Product2Id = scannerProduct.Id, Status = 'Obsolete'));
        assets.add(new Asset(Name = 'Laptop Installed Acct2', AccountId = acct2.Id, Product2Id = laptopProduct.Id, Status = 'Installed'));
        assets.add(new Asset(Name = 'Laptop Obsolete Acct2', AccountId = acct2.Id, Product2Id = laptopProduct.Id, Status = 'Obsolete'));
        assets.add(new Asset(Name = 'Accessory Installed Acct3', AccountId = acct3.Id, Product2Id = accessoryProduct.Id, Status = 'Installed'));
        assets.add(new Asset(Name = 'Accessory Shipped Acct3', AccountId = acct3.Id, Product2Id = accessoryProduct.Id, Status = 'Shipped'));
        assets.add(new Asset(Name = 'Laptop CorpParent Acct3', AccountId = acct3.Id, Product2Id = laptopProduct.Id, Status = 'Installed'));
        insert assets;
    }

    @isTest
    static void testSingleStatus() {
        GetFilteredAssets.Request req = new GetFilteredAssets.Request();
        req.status = 'Installed';

        Test.startTest();
        List<GetFilteredAssets.Result> results = GetFilteredAssets.getAssets(
            new List<GetFilteredAssets.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(4, results[0].assets.size(), 'Should return 4 Installed assets');
    }

    @isTest
    static void testMultipleStatuses() {
        GetFilteredAssets.Request req = new GetFilteredAssets.Request();
        req.status = 'Installed;Obsolete';

        Test.startTest();
        List<GetFilteredAssets.Result> results = GetFilteredAssets.getAssets(
            new List<GetFilteredAssets.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(6, results[0].assets.size(), 'Should return 6 assets with Installed or Obsolete status');
    }

    @isTest
    static void testAccountMatchesAccountId() {
        Account acct1 = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];

        GetFilteredAssets.Request req = new GetFilteredAssets.Request();
        req.accountIdList = new List<Id>{ acct1.Id };

        Test.startTest();
        List<GetFilteredAssets.Result> results = GetFilteredAssets.getAssets(
            new List<GetFilteredAssets.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(2, results[0].assets.size(), 'Should return 2 assets where AccountId matches');
    }

   

    @isTest
    static void testAccountMatchesBothFields() {
        Account acct3 = [SELECT Id FROM Account WHERE Name = 'Test Account 3' LIMIT 1];
        Account corpParent = [SELECT Id FROM Account WHERE Name = 'Corporate Parent' LIMIT 1];

        GetFilteredAssets.Request req = new GetFilteredAssets.Request();
        req.accountIdList = new List<Id>{ corpParent.Id, acct3.Id };

        Test.startTest();
        List<GetFilteredAssets.Result> results = GetFilteredAssets.getAssets(
            new List<GetFilteredAssets.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(3, results[0].assets.size(), 'Should return 3 assets matching AccountId or Corporate_Parent__c');
    }

    @isTest
    static void testSingleProduct() {
        Product2 scanner = [SELECT Id FROM Product2 WHERE Name = 'Test Scanner' LIMIT 1];

        GetFilteredAssets.Request req = new GetFilteredAssets.Request();
        req.productIdList = new List<Id>{ scanner.Id };

        Test.startTest();
        List<GetFilteredAssets.Result> results = GetFilteredAssets.getAssets(
            new List<GetFilteredAssets.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(2, results[0].assets.size(), 'Should return 2 Scanner product assets');
    }

    @isTest
    static void testMultipleProducts() {
        List<Product2> products = [SELECT Id FROM Product2 WHERE Name IN ('Test Scanner', 'Test Laptop') ORDER BY Name];

        GetFilteredAssets.Request req = new GetFilteredAssets.Request();
        req.productIdList = new List<Id>{ products[0].Id, products[1].Id };

        Test.startTest();
        List<GetFilteredAssets.Result> results = GetFilteredAssets.getAssets(
            new List<GetFilteredAssets.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(5, results[0].assets.size(), 'Should return 5 assets across Scanner and Laptop products');
    }

    @isTest
    static void testProductAndProductFamilyTogether() {
        Product2 scanner = [SELECT Id FROM Product2 WHERE Name = 'Test Scanner' LIMIT 1];

        GetFilteredAssets.Request req = new GetFilteredAssets.Request();
        req.productIdList = new List<Id>{ scanner.Id };
        req.productFamily = 'Scanner';

        Test.startTest();
        List<GetFilteredAssets.Result> results = GetFilteredAssets.getAssets(
            new List<GetFilteredAssets.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(2, results[0].assets.size(), 'Should return 2 assets matching both Product and Family');
    }

    @isTest
    static void testSingleProductFamily() {
        GetFilteredAssets.Request req = new GetFilteredAssets.Request();
        req.productFamily = 'Scanner';

        Test.startTest();
        List<GetFilteredAssets.Result> results = GetFilteredAssets.getAssets(
            new List<GetFilteredAssets.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(2, results[0].assets.size(), 'Should return 2 Scanner family assets');
    }

    @isTest
    static void testAllFiltersCombined() {
        Account acct2 = [SELECT Id FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
        Product2 laptop = [SELECT Id FROM Product2 WHERE Name = 'Test Laptop' LIMIT 1];

        GetFilteredAssets.Request req = new GetFilteredAssets.Request();
        req.status = 'Installed';
        req.accountIdList = new List<Id>{ acct2.Id };
        req.productFamily = 'Laptop';
        req.productIdList = new List<Id>{ laptop.Id };

        Test.startTest();
        List<GetFilteredAssets.Result> results = GetFilteredAssets.getAssets(
            new List<GetFilteredAssets.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results[0].assets.size(), 'Should return 1 asset matching all four filters');
        System.assertEquals('Laptop Installed Acct2', results[0].assets[0].Name);
    }

    @isTest
    static void testNoFiltersReturnsAll() {
        GetFilteredAssets.Request req = new GetFilteredAssets.Request();

        Test.startTest();
        List<GetFilteredAssets.Result> results = GetFilteredAssets.getAssets(
            new List<GetFilteredAssets.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(7, results[0].assets.size(), 'Should return all 7 assets when no filters applied');
    }

    @isTest
    static void testNoMatchReturnsEmpty() {
        GetFilteredAssets.Request req = new GetFilteredAssets.Request();
        req.status = 'Purchased';

        Test.startTest();
        List<GetFilteredAssets.Result> results = GetFilteredAssets.getAssets(
            new List<GetFilteredAssets.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(0, results[0].assets.size(), 'Should return empty list for non-matching filter');
    }
}