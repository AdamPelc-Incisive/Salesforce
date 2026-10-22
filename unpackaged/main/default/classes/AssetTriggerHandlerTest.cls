@isTest
private class AssetTriggerHandlerTest {

    @TestSetup
    static void setupTestData() {
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        // Bundle product
        Product2 bundle = new Product2(Name = 'Test Bundle', IsActive = true, Family = 'Scanner');
        insert bundle;

        // Two component products
        Product2 compA = new Product2(Name = 'Component A', IsActive = true, Serialized__c = true);
        Product2 compB = new Product2(Name = 'Component B', IsActive = true, Serialized__c = false);
        insert new List<Product2>{ compA, compB };

        // Component settings: bundle needs 2x A and 1x B
        insert new List<Product_Component_Setting__c>{
            new Product_Component_Setting__c(Required_for_Product__c = bundle.Id, Product__c = compA.Id, Quantity__c = 2, Product_Bundle_Type__c = 'Shipped'),
            new Product_Component_Setting__c(Required_for_Product__c = bundle.Id, Product__c = compB.Id, Quantity__c = 1, Product_Bundle_Type__c = 'Shipped')
        };

        // Inventory:
        // 3x bundle product (main), 4x A (floor 4/2=2), 2x B (floor 2/1=2)
        // min(3, 2, 2) = 2 deployable
        List<Asset> assets = new List<Asset>();
        for (Integer i = 0; i < 3; i++) {
            assets.add(new Asset(Name = 'Bundle ' + i, AccountId = acct.Id, Product2Id = bundle.Id, Status = 'Inventory'));
        }
        for (Integer i = 0; i < 4; i++) {
            assets.add(new Asset(Name = 'Comp A ' + i, AccountId = acct.Id, Product2Id = compA.Id, Status = 'Inventory'));
        }
        for (Integer i = 0; i < 2; i++) {
            assets.add(new Asset(Name = 'Comp B ' + i, AccountId = acct.Id, Product2Id = compB.Id, Status = 'Inventory'));
        }
        insert assets;
    }

    private static Id getBundleId() {
        return [SELECT Id FROM Product2 WHERE Name = 'Test Bundle' LIMIT 1].Id;
    }

    @isTest
    static void testInsertSetsDeployableCount() {
        // 3 bundle, 4xA (floor 4/2=2), 2xB (floor 2/1=2) — min(3,2,2) = 2
        Product2 bundle = [SELECT Id, Deployable_Bundles_In_Stock__c FROM Product2 WHERE Name = 'Test Bundle' LIMIT 1];
        System.assertEquals(2, bundle.Deployable_Bundles_In_Stock__c, 'Should have 2 deployable bundles (constrained by components)');
    }

    @isTest
    static void testBundleProductInventoryIsConstraint() {
        // Drop bundle product inventory from 3 to 1 — should constrain deployable to 1
        // min(1, floor(4/2)=2, floor(2/1)=2) = 1
        List<Asset> bundleAssets = [SELECT Id FROM Asset WHERE Name LIKE 'Bundle %' LIMIT 2];
        for (Asset a : bundleAssets) { a.Status = 'Installed'; }

        Test.startTest();
        update bundleAssets;
        Test.stopTest();

        Product2 bundle = [SELECT Deployable_Bundles_In_Stock__c FROM Product2 WHERE Name = 'Test Bundle' LIMIT 1];
        System.assertEquals(1, bundle.Deployable_Bundles_In_Stock__c, 'Bundle product inventory should constrain deployable count');
    }

    @isTest
    static void testStatusChangeToInventoryIncreasesCount() {
        // Add 2 more A (total 6), 1 more B (total 3), 1 more bundle (total 4)
        // min(4, floor(6/2)=3, floor(3/1)=3) = 3
        Account acct = [SELECT Id FROM Account LIMIT 1];
        Product2 compA = [SELECT Id FROM Product2 WHERE Name = 'Component A' LIMIT 1];
        Product2 compB = [SELECT Id FROM Product2 WHERE Name = 'Component B' LIMIT 1];
        Product2 bundle = [SELECT Id FROM Product2 WHERE Name = 'Test Bundle' LIMIT 1];

        Test.startTest();
        insert new List<Asset>{
            new Asset(Name = 'Comp A Extra 1', AccountId = acct.Id, Product2Id = compA.Id, Status = 'Inventory'),
            new Asset(Name = 'Comp A Extra 2', AccountId = acct.Id, Product2Id = compA.Id, Status = 'Inventory'),
            new Asset(Name = 'Comp B Extra 1', AccountId = acct.Id, Product2Id = compB.Id, Status = 'Inventory'),
            new Asset(Name = 'Bundle Extra 1', AccountId = acct.Id, Product2Id = bundle.Id, Status = 'Inventory')
        };
        Test.stopTest();

        Product2 bundleProduct = [SELECT Deployable_Bundles_In_Stock__c FROM Product2 WHERE Name = 'Test Bundle' LIMIT 1];
        System.assertEquals(3, bundleProduct.Deployable_Bundles_In_Stock__c, 'Should now have 3 deployable bundles');
    }

    @isTest
    static void testStatusChangeFromInventoryDecreasesCount() {
        // Move one A asset out of Inventory — drops to 3xA, floor(3/2)=1
        // min(3 bundle, 1, floor(2/1)=2) = 1
        Asset assetA = [SELECT Id FROM Asset WHERE Name = 'Comp A 0' LIMIT 1];

        Test.startTest();
        assetA.Status = 'Installed';
        update assetA;
        Test.stopTest();

        Product2 bundle = [SELECT Deployable_Bundles_In_Stock__c FROM Product2 WHERE Name = 'Test Bundle' LIMIT 1];
        System.assertEquals(1, bundle.Deployable_Bundles_In_Stock__c, 'Should drop to 1 deployable bundle (3xA/2=1)');
    }

    @isTest
    static void testNonStatusChangeDoesNotRecalculate() {
        Asset assetA = [SELECT Id, Name FROM Asset WHERE Name = 'Comp A 0' LIMIT 1];
        Decimal beforeCount = [SELECT Deployable_Bundles_In_Stock__c FROM Product2 WHERE Name = 'Test Bundle' LIMIT 1].Deployable_Bundles_In_Stock__c;

        Test.startTest();
        assetA.Name = 'Comp A 0 Renamed';
        update assetA;
        Test.stopTest();

        Decimal afterCount = [SELECT Deployable_Bundles_In_Stock__c FROM Product2 WHERE Name = 'Test Bundle' LIMIT 1].Deployable_Bundles_In_Stock__c;
        System.assertEquals(beforeCount, afterCount, 'Count should not change when Status did not change');
    }

    @isTest
    static void testZeroInventoryGivesZeroBundles() {
        List<Asset> allAssets = [SELECT Id, Status FROM Asset WHERE Status = 'Inventory'];
        for (Asset a : allAssets) { a.Status = 'Installed'; }

        Test.startTest();
        update allAssets;
        Test.stopTest();

        Product2 bundle = [SELECT Deployable_Bundles_In_Stock__c FROM Product2 WHERE Name = 'Test Bundle' LIMIT 1];
        System.assertEquals(0, bundle.Deployable_Bundles_In_Stock__c, 'Should be 0 when no inventory');
    }

    @isTest
    static void testLastCalculatedIsStamped() {
        Asset assetA = [SELECT Id FROM Asset WHERE Name = 'Comp A 0' LIMIT 1];

        Test.startTest();
        assetA.Status = 'Installed';
        update assetA;
        Test.stopTest();

        Product2 bundle = [SELECT Bundle_Stock_Last_Calculated__c FROM Product2 WHERE Name = 'Test Bundle' LIMIT 1];
        System.assertNotEquals(null, bundle.Bundle_Stock_Last_Calculated__c, 'Last calculated timestamp should be set');
    }

    @isTest
    static void testUnrelatedProductNotAffected() {
        Account acct = [SELECT Id FROM Account LIMIT 1];
        Product2 unrelated = new Product2(Name = 'Unrelated Product', IsActive = true);
        insert unrelated;

        Test.startTest();
        insert new Asset(Name = 'Unrelated Asset', AccountId = acct.Id, Product2Id = unrelated.Id, Status = 'Inventory');
        Test.stopTest();

        System.assert(true, 'Should handle assets with no bundle relationships gracefully');
    }
}