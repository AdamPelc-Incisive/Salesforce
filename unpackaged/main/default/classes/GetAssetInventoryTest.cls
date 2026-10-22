/**
 * @description Test class for GetAssetInventory invocable action.
 *              Covers inventory/ordered counts, zero counts, and mixed statuses.
 */
@isTest
private class GetAssetInventoryTest {

    @TestSetup
    static void setupTestData() {
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        Product2 scanner  = new Product2(Name = 'Scanner', IsActive = true);
        Product2 laptop   = new Product2(Name = 'Laptop', IsActive = true);
        Product2 noAssets = new Product2(Name = 'No Assets Product', IsActive = true);
        insert new List<Product2>{ scanner, laptop, noAssets };

        List<Asset> assets = new List<Asset>();
        // Scanner: 3 Inventory, 2 Ordered
        for (Integer i = 0; i < 3; i++) {
            assets.add(new Asset(Name = 'Scanner', AccountId = acct.Id, Product2Id = scanner.Id, Status = 'Inventory'));
        }
        for (Integer i = 0; i < 2; i++) {
            assets.add(new Asset(Name = 'Scanner', AccountId = acct.Id, Product2Id = scanner.Id, Status = 'Ordered'));
        }
        // Laptop: 0 Inventory, 1 Ordered
        assets.add(new Asset(Name = 'Laptop', AccountId = acct.Id, Product2Id = laptop.Id, Status = 'Ordered'));
        // Scanner: 1 Installed — should never appear in counts
        assets.add(new Asset(Name = 'Scanner', AccountId = acct.Id, Product2Id = scanner.Id, Status = 'Installed'));
        insert assets;
    }

    @isTest
    static void testInventoryAndOrderedCounts() {
        Id scannerId = [SELECT Id FROM Product2 WHERE Name = 'Scanner' LIMIT 1].Id;

        GetAssetInventory.Request req = new GetAssetInventory.Request();
        req.productId = scannerId;

        Test.startTest();
        List<GetAssetInventory.Result> results = GetAssetInventory.getInventory(
            new List<GetAssetInventory.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(3, results[0].inventoryCount, 'Should return 3 Inventory assets');
        System.assertEquals(2, results[0].orderedCount,   'Should return 2 Ordered assets');
        System.assertEquals(5, results[0].totalCount,     'Total should be 5');
    }

    @isTest
    static void testZeroInventoryCount() {
        Id laptopId = [SELECT Id FROM Product2 WHERE Name = 'Laptop' LIMIT 1].Id;

        GetAssetInventory.Request req = new GetAssetInventory.Request();
        req.productId = laptopId;

        Test.startTest();
        List<GetAssetInventory.Result> results = GetAssetInventory.getInventory(
            new List<GetAssetInventory.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(0, results[0].inventoryCount, 'Should return 0 Inventory assets');
        System.assertEquals(1, results[0].orderedCount,   'Should return 1 Ordered asset');
        System.assertEquals(1, results[0].totalCount,     'Total should be 1');
    }

    @isTest
    static void testNoAssetsReturnsZero() {
        Id noAssetsId = [SELECT Id FROM Product2 WHERE Name = 'No Assets Product' LIMIT 1].Id;

        GetAssetInventory.Request req = new GetAssetInventory.Request();
        req.productId = noAssetsId;

        Test.startTest();
        List<GetAssetInventory.Result> results = GetAssetInventory.getInventory(
            new List<GetAssetInventory.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(0, results[0].inventoryCount, 'Should return 0 when no assets exist');
        System.assertEquals(0, results[0].orderedCount,   'Should return 0 when no assets exist');
        System.assertEquals(0, results[0].totalCount,     'Total should be 0');
    }

    @isTest
    static void testNonTrackedStatusesExcluded() {
        // Scanner has an Installed asset — should never appear in any count
        Id scannerId = [SELECT Id FROM Product2 WHERE Name = 'Scanner' LIMIT 1].Id;

        GetAssetInventory.Request req = new GetAssetInventory.Request();
        req.productId = scannerId;

        Test.startTest();
        List<GetAssetInventory.Result> results = GetAssetInventory.getInventory(
            new List<GetAssetInventory.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(5, results[0].totalCount, 'Installed assets should not be included in total');
    }

    @isTest
    static void testOrderedAssetsCollectionReturned() {
        Id scannerId = [SELECT Id FROM Product2 WHERE Name = 'Scanner' LIMIT 1].Id;

        GetAssetInventory.Request req = new GetAssetInventory.Request();
        req.productId = scannerId;

        Test.startTest();
        List<GetAssetInventory.Result> results = GetAssetInventory.getInventory(
            new List<GetAssetInventory.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(2, results[0].orderedAssets.size(), 'Should return 2 Ordered asset records');
        for (Asset a : results[0].orderedAssets) {
            System.assertEquals('Ordered', a.Status, 'All returned assets should have Ordered status');
            System.assertEquals(scannerId, a.Product2Id, 'All returned assets should belong to the queried product');
        }
    }

    @isTest
    static void testOrderedAssetsEmptyWhenNone() {
        Id noAssetsId = [SELECT Id FROM Product2 WHERE Name = 'No Assets Product' LIMIT 1].Id;

        GetAssetInventory.Request req = new GetAssetInventory.Request();
        req.productId = noAssetsId;

        Test.startTest();
        List<GetAssetInventory.Result> results = GetAssetInventory.getInventory(
            new List<GetAssetInventory.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(0, results[0].orderedAssets.size(), 'Ordered assets collection should be empty');
    }
}