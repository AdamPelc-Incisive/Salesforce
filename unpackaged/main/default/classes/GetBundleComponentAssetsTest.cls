@isTest
private class GetBundleComponentAssetsTest {

    @TestSetup
    static void setupTestData() {
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        // Bundle product (the parent product a user selected)
        Product2 bundleProduct = new Product2(Name = 'Bundle Product', IsActive = true, Family = 'Scanner');
        insert bundleProduct;

        // Component products — serialized flag lives on Product2.Serialized__c
        Product2 serializedComponent = new Product2(Name = 'Serialized Component', IsActive = true, Family = 'Scanner', Serialized__c = true);
        Product2 unserializedComponent = new Product2(Name = 'Unserialized Component', IsActive = true, Family = 'Accessory', Serialized__c = false);
        Product2 shortComponent = new Product2(Name = 'Short Component', IsActive = true, Family = 'Laptop', Serialized__c = true);
        insert new List<Product2>{ serializedComponent, unserializedComponent, shortComponent };

        // Component settings
        Product_Component_Setting__c serializedSetting = new Product_Component_Setting__c(
            Required_for_Product__c = bundleProduct.Id,
            Product__c = serializedComponent.Id,
            Quantity__c = 2,
            Product_Bundle_Type__c = 'Shipped'
        );
        Product_Component_Setting__c unserializedSetting = new Product_Component_Setting__c(
            Required_for_Product__c = bundleProduct.Id,
            Product__c = unserializedComponent.Id,
            Quantity__c = 1,
            Product_Bundle_Type__c = 'Shipped'
        );
        Product_Component_Setting__c shortSetting = new Product_Component_Setting__c(
            Required_for_Product__c = bundleProduct.Id,
            Product__c = shortComponent.Id,
            Quantity__c = 2,
            Product_Bundle_Type__c = 'Shipped'
        );
        insert new List<Product_Component_Setting__c>{ serializedSetting, unserializedSetting, shortSetting };

        // Assets
        List<Asset> assets = new List<Asset>();
        // 2 inventory assets for serialized component (meets requirement)
        assets.add(new Asset(Name = 'Serialized Inv 1', AccountId = acct.Id, Product2Id = serializedComponent.Id, Status = 'Inventory', SerialNumber = 'SN001'));
        assets.add(new Asset(Name = 'Serialized Inv 2', AccountId = acct.Id, Product2Id = serializedComponent.Id, Status = 'Inventory', SerialNumber = 'SN002'));
        // 1 non-inventory asset (should be ignored)
        assets.add(new Asset(Name = 'Serialized Installed', AccountId = acct.Id, Product2Id = serializedComponent.Id, Status = 'Installed'));
        // 3 unserialized inventory assets (only 1 needed)
        assets.add(new Asset(Name = 'Unserialized Inv 1', AccountId = acct.Id, Product2Id = unserializedComponent.Id, Status = 'Inventory'));
        assets.add(new Asset(Name = 'Unserialized Inv 2', AccountId = acct.Id, Product2Id = unserializedComponent.Id, Status = 'Inventory'));
        assets.add(new Asset(Name = 'Unserialized Inv 3', AccountId = acct.Id, Product2Id = unserializedComponent.Id, Status = 'Inventory'));
        // Only 1 inventory asset for short component (needs 2 — will trigger warning)
        assets.add(new Asset(Name = 'Short Inv 1', AccountId = acct.Id, Product2Id = shortComponent.Id, Status = 'Inventory', SerialNumber = 'SN100'));
        insert assets;
    }

    private static Id getBundleId() {
        return [SELECT Id FROM Product2 WHERE Name = 'Bundle Product' LIMIT 1].Id;
    }

    @isTest
    static void testNoComponentSettings() {
        Product2 orphan = new Product2(Name = 'Orphan Product', IsActive = true);
        insert orphan;

        GetBundleComponentAssets.Request req = new GetBundleComponentAssets.Request();
        req.productId = orphan.Id;

        Test.startTest();
        List<GetBundleComponentAssets.Result> results = GetBundleComponentAssets.getBundleAssets(
            new List<GetBundleComponentAssets.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].isError);
        System.assert(results[0].statusMessage.contains('No bundle components'));
    }

    @isTest
    static void testSerializedAssetsReturnedCorrectly() {
        GetBundleComponentAssets.Request req = new GetBundleComponentAssets.Request();
        req.productId = getBundleId();

        Test.startTest();
        List<GetBundleComponentAssets.Result> results = GetBundleComponentAssets.getBundleAssets(
            new List<GetBundleComponentAssets.Request>{ req }
        );
        Test.stopTest();

        // 2 from serialized component + 1 from short component
        System.assertEquals(3, results[0].serializedAssets.size(), 'Should return 3 serialized inventory assets');
    }

    @isTest
    static void testUnserializedAssetsReturnedCorrectly() {
        GetBundleComponentAssets.Request req = new GetBundleComponentAssets.Request();
        req.productId = getBundleId();

        Test.startTest();
        List<GetBundleComponentAssets.Result> results = GetBundleComponentAssets.getBundleAssets(
            new List<GetBundleComponentAssets.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results[0].unserializedAssets.size(), 'Should return 1 unserialized asset (quantity needed)');
    }

    @isTest
    static void testNonInventoryAssetsExcluded() {
        GetBundleComponentAssets.Request req = new GetBundleComponentAssets.Request();
        req.productId = getBundleId();

        Test.startTest();
        List<GetBundleComponentAssets.Result> results = GetBundleComponentAssets.getBundleAssets(
            new List<GetBundleComponentAssets.Request>{ req }
        );
        Test.stopTest();

        for (Asset a : results[0].serializedAssets) {
            System.assertEquals('Inventory', a.Status, 'All serialized assets should have Inventory status');
        }
        for (Asset a : results[0].unserializedAssets) {
            System.assertEquals('Inventory', a.Status, 'All unserialized assets should have Inventory status');
        }
    }

    @isTest
    static void testIncompleteBundle_IsError() {
        GetBundleComponentAssets.Request req = new GetBundleComponentAssets.Request();
        req.productId = getBundleId();

        Test.startTest();
        List<GetBundleComponentAssets.Result> results = GetBundleComponentAssets.getBundleAssets(
            new List<GetBundleComponentAssets.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].isError, 'Should flag error for incomplete bundle');
        System.assert(results[0].statusMessage.contains('Warning'), 'Message should be a warning');
        System.assert(results[0].statusMessage.contains('Short Component'), 'Message should list the missing item');
    }

    @isTest
    static void testCompleteBundle_Success() {
        Account acct = [SELECT Id FROM Account LIMIT 1];
        Product2 cleanBundle = new Product2(Name = 'Clean Bundle', IsActive = true);
        insert cleanBundle;
        Product2 comp = new Product2(Name = 'Clean Component', IsActive = true, Serialized__c = false);
        insert comp;
        insert new Product_Component_Setting__c(
            Required_for_Product__c = cleanBundle.Id,
            Product__c = comp.Id,
            Product_Bundle_Type__c = 'Shipped',
            Quantity__c = 1
        );
        insert new Asset(Name = 'Clean Inv', AccountId = acct.Id, Product2Id = comp.Id, Status = 'Inventory');

        GetBundleComponentAssets.Request req = new GetBundleComponentAssets.Request();
        req.productId = cleanBundle.Id;

        Test.startTest();
        List<GetBundleComponentAssets.Result> results = GetBundleComponentAssets.getBundleAssets(
            new List<GetBundleComponentAssets.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].isError, 'Should not be error for complete bundle');
        System.assert(results[0].statusMessage.contains('Success'));
        System.assertEquals(1, results[0].unserializedAssets.size());
    }

    @isTest
    static void testUnserializedQuantityGreaterThanOne() {
        Account acct = [SELECT Id FROM Account LIMIT 1];
        Product2 bundle = new Product2(Name = 'Multi Bundle', IsActive = true);
        insert bundle;
        Product2 comp = new Product2(Name = 'Multi Component', IsActive = true, Serialized__c = false);
        insert comp;
        insert new Product_Component_Setting__c(
            Required_for_Product__c = bundle.Id,
            Product__c = comp.Id,
            Product_Bundle_Type__c = 'Shipped',
            Quantity__c = 2
        );
        insert new List<Asset>{
            new Asset(Name = 'Multi Inv 1', AccountId = acct.Id, Product2Id = comp.Id, Status = 'Inventory'),
            new Asset(Name = 'Multi Inv 2', AccountId = acct.Id, Product2Id = comp.Id, Status = 'Inventory'),
            new Asset(Name = 'Multi Inv 3', AccountId = acct.Id, Product2Id = comp.Id, Status = 'Inventory')
        };

        GetBundleComponentAssets.Request req = new GetBundleComponentAssets.Request();
        req.productId = bundle.Id;

        Test.startTest();
        List<GetBundleComponentAssets.Result> results = GetBundleComponentAssets.getBundleAssets(
            new List<GetBundleComponentAssets.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].isError);
        System.assertEquals(2, results[0].unserializedAssets.size(), 'Should return exactly quantityNeeded unserialized assets');
    }

    @isTest
    static void testUnserializedWithNoInventory_IsError() {
        Account acct = [SELECT Id FROM Account LIMIT 1];
        Product2 bundle = new Product2(Name = 'Empty Bundle', IsActive = true);
        insert bundle;
        Product2 comp = new Product2(Name = 'Empty Component', IsActive = true, Serialized__c = false);
        insert comp;
        insert new Product_Component_Setting__c(
            Required_for_Product__c = bundle.Id,
            Product__c = comp.Id,
            Product_Bundle_Type__c = 'Shipped',
            Quantity__c = 1
        );

        GetBundleComponentAssets.Request req = new GetBundleComponentAssets.Request();
        req.productId = bundle.Id;

        Test.startTest();
        List<GetBundleComponentAssets.Result> results = GetBundleComponentAssets.getBundleAssets(
            new List<GetBundleComponentAssets.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].isError);
        System.assert(results[0].statusMessage.contains('short'));
    }

    @isTest
    static void testBundleTypeFilter_ReturnsMatchingOnly() {
        GetBundleComponentAssets.Request req = new GetBundleComponentAssets.Request();
        req.productId = getBundleId();
        req.productBundleType = 'Shipped';

        Test.startTest();
        List<GetBundleComponentAssets.Result> results = GetBundleComponentAssets.getBundleAssets(
            new List<GetBundleComponentAssets.Request>{ req }
        );
        Test.stopTest();

        // All settings are Shipped so should return same as no filter
        System.assertNotEquals(null, results[0].serializedAssets);
    }

    @isTest
    static void testBundleTypeFilter_NoMatch() {
        GetBundleComponentAssets.Request req = new GetBundleComponentAssets.Request();
        req.productId = getBundleId();
        req.productBundleType = 'Received';

        Test.startTest();
        List<GetBundleComponentAssets.Result> results = GetBundleComponentAssets.getBundleAssets(
            new List<GetBundleComponentAssets.Request>{ req }
        );
        Test.stopTest();

        // No settings match 'Received' — not an error, just no bundle components
        System.assertEquals(false, results[0].isError);
        System.assert(results[0].statusMessage.contains('No bundle components'));
    }

    @isTest
    static void testSerializedProductQuantitiesJson() {
        Account acct = [SELECT Id FROM Account LIMIT 1];
        Product2 bundle = new Product2(Name = 'JSON Bundle', IsActive = true);
        insert bundle;
        Product2 comp = new Product2(Name = 'JSON Component', IsActive = true, Serialized__c = true);
        insert comp;
        insert new Product_Component_Setting__c(
            Required_for_Product__c = bundle.Id,
            Product__c = comp.Id,
            Product_Bundle_Type__c = 'Shipped',
            Quantity__c = 3
        );
        insert new List<Asset>{
            new Asset(Name = 'JSON Inv 1', AccountId = acct.Id, Product2Id = comp.Id, Status = 'Inventory', SerialNumber = 'J001'),
            new Asset(Name = 'JSON Inv 2', AccountId = acct.Id, Product2Id = comp.Id, Status = 'Inventory', SerialNumber = 'J002'),
            new Asset(Name = 'JSON Inv 3', AccountId = acct.Id, Product2Id = comp.Id, Status = 'Inventory', SerialNumber = 'J003')
        };

        GetBundleComponentAssets.Request req = new GetBundleComponentAssets.Request();
        req.productId = bundle.Id;

        Test.startTest();
        List<GetBundleComponentAssets.Result> results = GetBundleComponentAssets.getBundleAssets(
            new List<GetBundleComponentAssets.Request>{ req }
        );
        Test.stopTest();

        System.assertNotEquals(null, results[0].serializedProductQuantities, 'JSON string should not be null');
        System.assert(results[0].serializedProductQuantities.contains('"' + comp.Id + '":3'), 'JSON should contain product Id with quantity 3');
    }
}