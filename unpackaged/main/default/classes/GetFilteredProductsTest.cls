@isTest
private class GetFilteredProductsTest {

    @TestSetup
    static void setupTestData() {
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Scanner A', Family = 'Scanner', ProductCode = 'SCA', IsActive = true));
        products.add(new Product2(Name = 'Scanner B', Family = 'Scanner', IsActive = false));
        products.add(new Product2(Name = 'Laptop A', Family = 'Laptop', ProductCode = 'LPA', IsActive = true));
        products.add(new Product2(Name = 'Laptop B', Family = 'Laptop', IsActive = true));
        products.add(new Product2(Name = 'Accessory A', Family = 'Accessory', IsActive = true));
        products.add(new Product2(Name = 'Consumable A', Family = 'Consumable', IsActive = false));
        insert products;
    }

    @isTest
    static void testDefaultExcludesInactive() {
        GetFilteredProducts.Request req = new GetFilteredProducts.Request();

        Test.startTest();
        List<GetFilteredProducts.Result> results = GetFilteredProducts.getProducts(
            new List<GetFilteredProducts.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(4, results[0].products.size(), 'Should return only 4 active products by default');
    }

    @isTest
    static void testIncludeInactiveReturnsAll() {
        GetFilteredProducts.Request req = new GetFilteredProducts.Request();
        req.includeInactive = true;

        Test.startTest();
        List<GetFilteredProducts.Result> results = GetFilteredProducts.getProducts(
            new List<GetFilteredProducts.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(6, results[0].products.size(), 'Should return all 6 products including inactive');
    }

    @isTest
    static void testIncludeInactiveFalse() {
        GetFilteredProducts.Request req = new GetFilteredProducts.Request();
        req.includeInactive = false;

        Test.startTest();
        List<GetFilteredProducts.Result> results = GetFilteredProducts.getProducts(
            new List<GetFilteredProducts.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(4, results[0].products.size(), 'Should return only 4 active products when explicitly false');
    }

    @isTest
    static void testSingleProductId() {
        Product2 scannerA = [SELECT Id FROM Product2 WHERE Name = 'Scanner A' LIMIT 1];

        GetFilteredProducts.Request req = new GetFilteredProducts.Request();
        req.productIdList = new List<Id>{ scannerA.Id };

        Test.startTest();
        List<GetFilteredProducts.Result> results = GetFilteredProducts.getProducts(
            new List<GetFilteredProducts.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results[0].products.size(), 'Should return 1 product by Id');
        System.assertEquals('Scanner A', results[0].products[0].Name);
    }

    @isTest
    static void testMultipleProductIds() {
        List<Product2> scanners = [SELECT Id FROM Product2 WHERE Family = 'Scanner' ORDER BY Name];

        GetFilteredProducts.Request req = new GetFilteredProducts.Request();
        req.productIdList = new List<Id>{ scanners[0].Id, scanners[1].Id };
        req.includeInactive = true;

        Test.startTest();
        List<GetFilteredProducts.Result> results = GetFilteredProducts.getProducts(
            new List<GetFilteredProducts.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(2, results[0].products.size(), 'Should return 2 products by Id with inactive included');
    }

    @isTest
    static void testSingleProductFamily() {
        GetFilteredProducts.Request req = new GetFilteredProducts.Request();
        req.productFamily = 'Accessory';

        Test.startTest();
        List<GetFilteredProducts.Result> results = GetFilteredProducts.getProducts(
            new List<GetFilteredProducts.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results[0].products.size(), 'Should return 1 Accessory product');
    }

    @isTest
    static void testMultipleProductFamilies() {
        GetFilteredProducts.Request req = new GetFilteredProducts.Request();
        req.productFamily = 'Scanner;Laptop';

        Test.startTest();
        List<GetFilteredProducts.Result> results = GetFilteredProducts.getProducts(
            new List<GetFilteredProducts.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(3, results[0].products.size(), 'Should return 3 active Scanner + Laptop products');
    }

    @isTest
    static void testFamilyFilterRespectsActiveDefault() {
        GetFilteredProducts.Request req = new GetFilteredProducts.Request();
        req.productFamily = 'Scanner';

        Test.startTest();
        List<GetFilteredProducts.Result> results = GetFilteredProducts.getProducts(
            new List<GetFilteredProducts.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results[0].products.size(), 'Should return only 1 active Scanner');
        System.assertEquals('Scanner A', results[0].products[0].Name);
    }

    @isTest
    static void testFamilyFilterWithInactive() {
        GetFilteredProducts.Request req = new GetFilteredProducts.Request();
        req.productFamily = 'Scanner';
        req.includeInactive = true;

        Test.startTest();
        List<GetFilteredProducts.Result> results = GetFilteredProducts.getProducts(
            new List<GetFilteredProducts.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(2, results[0].products.size(), 'Should return both active and inactive Scanners');
    }

    @isTest
    static void testAllFiltersCombined() {
        Product2 scannerA = [SELECT Id FROM Product2 WHERE Name = 'Scanner A' LIMIT 1];

        GetFilteredProducts.Request req = new GetFilteredProducts.Request();
        req.productIdList = new List<Id>{ scannerA.Id };
        req.productFamily = 'Scanner';
        req.includeInactive = false;

        Test.startTest();
        List<GetFilteredProducts.Result> results = GetFilteredProducts.getProducts(
            new List<GetFilteredProducts.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results[0].products.size());
        System.assertEquals('Scanner A', results[0].products[0].Name);
    }

    @isTest
    static void testNoMatchReturnsEmpty() {
        GetFilteredProducts.Request req = new GetFilteredProducts.Request();
        req.productFamily = 'Nonexistent';

        Test.startTest();
        List<GetFilteredProducts.Result> results = GetFilteredProducts.getProducts(
            new List<GetFilteredProducts.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(0, results[0].products.size());
    }
}