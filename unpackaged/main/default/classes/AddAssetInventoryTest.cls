/**
 * @description Test class for AddAssetInventory invocable action.
 *              Covers bundle mode, single product mode, status handling,
 *              bundle type filtering, error paths, and trigger integration.
 */
@isTest
private class AddAssetInventoryTest {

    @TestSetup
    static void setupTestData() {
        Account acct = new Account(Name = 'Test Warehouse');
        insert acct;

        // Main bundle product
        Product2 bundle = new Product2(Name = 'Scanner Bundle', IsActive = true, Family = 'Scanner');
        insert bundle;

        // Component products
        Product2 powerCord = new Product2(Name = 'Power Cord', IsActive = true, Family = 'Accessory');
        Product2 battery   = new Product2(Name = 'Battery', IsActive = true, Family = 'Accessory');
        insert new List<Product2>{ powerCord, battery };

        // Component settings — Received type
        insert new List<Product_Component_Setting__c>{
            new Product_Component_Setting__c(
                Required_for_Product__c = bundle.Id,
                Product__c = powerCord.Id,
                Quantity__c = 1,
                Product_Bundle_Type__c = 'Received'
            ),
            new Product_Component_Setting__c(
                Required_for_Product__c = bundle.Id,
                Product__c = battery.Id,
                Quantity__c = 2,
                Product_Bundle_Type__c = 'Received'
            )
        };

        // Also insert a Shipped-type setting — should be ignored by default
        insert new Product_Component_Setting__c(
            Required_for_Product__c = bundle.Id,
            Product__c = powerCord.Id,
            Quantity__c = 99,
            Product_Bundle_Type__c = 'Shipped'
        );
    }

    private static Id getBundleId() {
        return [SELECT Id FROM Product2 WHERE Name = 'Scanner Bundle' LIMIT 1].Id;
    }

    private static Id getAccountId() {
        return [SELECT Id FROM Account WHERE Name = 'Test Warehouse' LIMIT 1].Id;
    }

    // ── Bundle mode: quantity of 1 ───────────────────────────────────────────

    @isTest
    static void testQuantityOne_CreatesCorrectAssets() {
        AddAssetInventory.Request req = new AddAssetInventory.Request();
        req.productId = getBundleId();
        req.accountId = getAccountId();
        req.quantity  = 1;

        Test.startTest();
        List<AddAssetInventory.Result> results = AddAssetInventory.receiveBundles(
            new List<AddAssetInventory.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].isError, 'Should not be an error');
        // 1 Scanner + 1 Power Cord + 2 Batteries = 4 assets
        System.assertEquals(4, results[0].createdAssets.size(), 'Should create 4 total assets for qty 1');
        for (Asset a : [SELECT Status FROM Asset]) {
            System.assertEquals('Inventory', a.Status, 'Default status should be Inventory');
        }
    }

    // ── Bundle mode: quantity multiplier ─────────────────────────────────────

    @isTest
    static void testQuantityTwo_MultipliesCorrectly() {
        AddAssetInventory.Request req = new AddAssetInventory.Request();
        req.productId = getBundleId();
        req.accountId = getAccountId();
        req.quantity  = 2;

        Test.startTest();
        List<AddAssetInventory.Result> results = AddAssetInventory.receiveBundles(
            new List<AddAssetInventory.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].isError, 'Should not be an error');
        // 2 Scanners + 2 Power Cords + 4 Batteries = 8 assets
        System.assertEquals(8, results[0].createdAssets.size(), 'Should create 8 total assets for qty 2');
    }

    // ── Bundle mode: correct product breakdown ────────────────────────────────

    @isTest
    static void testCorrectProductBreakdown() {
        Id bundleId  = getBundleId();
        Id accountId = getAccountId();
        Id cordId    = [SELECT Id FROM Product2 WHERE Name = 'Power Cord' LIMIT 1].Id;
        Id batteryId = [SELECT Id FROM Product2 WHERE Name = 'Battery' LIMIT 1].Id;

        AddAssetInventory.Request req = new AddAssetInventory.Request();
        req.productId = bundleId;
        req.accountId = accountId;
        req.quantity  = 2;

        Test.startTest();
        AddAssetInventory.receiveBundles(new List<AddAssetInventory.Request>{ req });
        Test.stopTest();

        Map<Id, Integer> countByProduct = new Map<Id, Integer>();
        for (AggregateResult ar : [SELECT Product2Id, COUNT(Id) cnt FROM Asset GROUP BY Product2Id]) {
            countByProduct.put((Id) ar.get('Product2Id'), (Integer) ar.get('cnt'));
        }

        System.assertEquals(2, countByProduct.get(bundleId),  '2 x Scanner Bundle');
        System.assertEquals(2, countByProduct.get(cordId),    '2 x Power Cord (qty 1 * 2)');
        System.assertEquals(4, countByProduct.get(batteryId), '4 x Battery (qty 2 * 2)');
    }

    // ── Single product mode ───────────────────────────────────────────────────

    @isTest
    static void testSingleProduct_CreatesMainProductOnly() {
        AddAssetInventory.Request req = new AddAssetInventory.Request();
        req.productId     = getBundleId();
        req.accountId     = getAccountId();
        req.quantity      = 3;
        req.singleProduct = true;

        Test.startTest();
        List<AddAssetInventory.Result> results = AddAssetInventory.receiveBundles(
            new List<AddAssetInventory.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].isError, 'Should not be an error');
        System.assertEquals(3, results[0].createdAssets.size(), 'Should create only 3 assets — no components');
        for (Asset a : [SELECT Product2Id FROM Asset]) {
            System.assertEquals(getBundleId(), a.Product2Id, 'All assets should be the main product only');
        }
    }

    @isTest
    static void testSingleProduct_NonBundledProduct() {
        // A plain product with no component settings at all — singleProduct = true should work fine
        Product2 standalone = new Product2(Name = 'Standalone Laptop', IsActive = true);
        insert standalone;

        AddAssetInventory.Request req = new AddAssetInventory.Request();
        req.productId     = standalone.Id;
        req.accountId     = getAccountId();
        req.quantity      = 2;
        req.singleProduct = true;

        Test.startTest();
        List<AddAssetInventory.Result> results = AddAssetInventory.receiveBundles(
            new List<AddAssetInventory.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].isError, 'Should succeed for standalone product');
        System.assertEquals(2, results[0].createdAssets.size(), 'Should create 2 assets');
    }

    @isTest
    static void testSingleProduct_IgnoresComponentSettings() {
        // Even if component settings exist, singleProduct = true should skip them
        AddAssetInventory.Request req = new AddAssetInventory.Request();
        req.productId     = getBundleId();
        req.accountId     = getAccountId();
        req.quantity      = 1;
        req.singleProduct = true;

        Test.startTest();
        AddAssetInventory.receiveBundles(new List<AddAssetInventory.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Asset], 'Component settings should be ignored in single product mode');
    }

    // ── Custom status ─────────────────────────────────────────────────────────

    @isTest
    static void testOrderedStatus() {
        AddAssetInventory.Request req = new AddAssetInventory.Request();
        req.productId = getBundleId();
        req.accountId = getAccountId();
        req.quantity  = 1;
        req.status    = 'Ordered';

        Test.startTest();
        AddAssetInventory.receiveBundles(new List<AddAssetInventory.Request>{ req });
        Test.stopTest();

        for (Asset a : [SELECT Status FROM Asset]) {
            System.assertEquals('Ordered', a.Status, 'All assets should have Ordered status');
        }
    }

    // ── Shipped-type settings excluded by default ─────────────────────────────

    @isTest
    static void testShippedTypeSettingsIgnoredByDefault() {
        AddAssetInventory.Request req = new AddAssetInventory.Request();
        req.productId = getBundleId();
        req.accountId = getAccountId();
        req.quantity  = 1;

        Test.startTest();
        AddAssetInventory.receiveBundles(new List<AddAssetInventory.Request>{ req });
        Test.stopTest();

        System.assertEquals(4, [SELECT COUNT() FROM Asset], 'Shipped-type settings should be excluded by default');
    }

    // ── Explicit bundleType overrides default ─────────────────────────────────

    @isTest
    static void testExplicitBundleTypeShipped() {
        AddAssetInventory.Request req = new AddAssetInventory.Request();
        req.productId  = getBundleId();
        req.accountId  = getAccountId();
        req.quantity   = 1;
        req.bundleType = 'Shipped';

        Test.startTest();
        List<AddAssetInventory.Result> results = AddAssetInventory.receiveBundles(
            new List<AddAssetInventory.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(false, results[0].isError, 'Should succeed with explicit Shipped bundle type');
        // 1 bundle + 99 power cords = 100 assets
        System.assertEquals(100, results[0].createdAssets.size(), 'Should use Shipped-type component settings');
    }

    // ── Error: unknown bundleType ─────────────────────────────────────────────

    @isTest
    static void testUnknownBundleTypeReturnsError() {
        AddAssetInventory.Request req = new AddAssetInventory.Request();
        req.productId  = getBundleId();
        req.accountId  = getAccountId();
        req.quantity   = 1;
        req.bundleType = 'Nonexistent';

        Test.startTest();
        List<AddAssetInventory.Result> results = AddAssetInventory.receiveBundles(
            new List<AddAssetInventory.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].isError, 'Should error when no settings match the bundle type');
        System.assert(results[0].statusMessage.contains('Nonexistent'), 'Error should include the bundle type value');
        System.assert(results[0].statusMessage.contains('Single Product'), 'Error should hint at single product mode');
    }

    // ── AccountId stamped on all assets ──────────────────────────────────────

    @isTest
    static void testAccountIdStampedOnAllAssets() {
        Id accountId = getAccountId();

        AddAssetInventory.Request req = new AddAssetInventory.Request();
        req.productId = getBundleId();
        req.accountId = accountId;
        req.quantity  = 1;

        Test.startTest();
        AddAssetInventory.receiveBundles(new List<AddAssetInventory.Request>{ req });
        Test.stopTest();

        for (Asset a : [SELECT AccountId FROM Asset]) {
            System.assertEquals(accountId, a.AccountId, 'All assets should be assigned to the input account');
        }
    }

    // ── Returns created assets in result ─────────────────────────────────────

    @isTest
    static void testCreatedAssetsReturnedInResult() {
        AddAssetInventory.Request req = new AddAssetInventory.Request();
        req.productId = getBundleId();
        req.accountId = getAccountId();
        req.quantity  = 1;

        Test.startTest();
        List<AddAssetInventory.Result> results = AddAssetInventory.receiveBundles(
            new List<AddAssetInventory.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(4, results[0].createdAssets.size(), 'Result should contain all created assets');
        for (Asset a : results[0].createdAssets) {
            System.assertNotEquals(null, a.Id, 'Returned assets should have Ids');
        }
    }

    // ── Error: invalid quantity ───────────────────────────────────────────────

    @isTest
    static void testZeroQuantityReturnsError() {
        AddAssetInventory.Request req = new AddAssetInventory.Request();
        req.productId = getBundleId();
        req.accountId = getAccountId();
        req.quantity  = 0;

        Test.startTest();
        List<AddAssetInventory.Result> results = AddAssetInventory.receiveBundles(
            new List<AddAssetInventory.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].isError, 'Zero quantity should be an error');
        System.assertEquals(0, [SELECT COUNT() FROM Asset], 'No assets should be created');
    }

    // ── Error: no Received-type settings in bundle mode ───────────────────────

    @isTest
    static void testNoReceivedSettingsReturnsError() {
        Product2 orphan = new Product2(Name = 'Orphan Bundle', IsActive = true);
        insert orphan;

        AddAssetInventory.Request req = new AddAssetInventory.Request();
        req.productId = orphan.Id;
        req.accountId = getAccountId();
        req.quantity  = 1;

        Test.startTest();
        List<AddAssetInventory.Result> results = AddAssetInventory.receiveBundles(
            new List<AddAssetInventory.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].isError, 'Should error when no Received settings found');
        System.assert(results[0].statusMessage.contains('No Received-type'), 'Message should explain the missing settings');
    }

    // ── Trigger fires: deployable count updates ───────────────────────────────

    @isTest
    static void testTriggerFiresOnCreatedAssets() {
        Account acct = [SELECT Id FROM Account LIMIT 1];

        Product2 triggerBundle = new Product2(Name = 'Trigger Test Bundle', IsActive = true);
        insert triggerBundle;

        Product2 comp = new Product2(Name = 'Trigger Component', IsActive = true, Serialized__c = false);
        insert comp;

        insert new Product_Component_Setting__c(
            Required_for_Product__c = triggerBundle.Id,
            Product__c = comp.Id,
            Quantity__c = 1,
            Product_Bundle_Type__c = 'Received'
        );

        AddAssetInventory.Request req = new AddAssetInventory.Request();
        req.productId = triggerBundle.Id;
        req.accountId = acct.Id;
        req.quantity  = 1;

        Test.startTest();
        AddAssetInventory.receiveBundles(new List<AddAssetInventory.Request>{ req });
        Test.stopTest();

        Product2 result = [SELECT Deployable_Bundles_In_Stock__c FROM Product2 WHERE Name = 'Trigger Test Bundle' LIMIT 1];
        System.assertEquals(1, result.Deployable_Bundles_In_Stock__c,
            'Deployable count should update via trigger after receiving inventory');
    }
}