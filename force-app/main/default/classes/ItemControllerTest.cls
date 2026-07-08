@IsTest
private class ItemControllerTest {

	private class UnsplashMock implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest req) {
			HttpResponse res = new HttpResponse();
			res.setStatusCode(200);
			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"results":[{"urls":{"regular":"https://images.unsplash.com/test-image.jpg"}}]}');
			return res;
		}
	}

	private static Account createAccount() {
		Account acc = new Account(Name = 'Test account', AccountNumber = 'ACC-001', Industry = 'Construction');
		insert acc;
		return acc;
	}

	private static Item__c createItem(String name, String typeValue, String familyValue, Decimal price, Decimal quantity) {
		Item__c item = new Item__c(
				Name = name,
				Description__c = 'Test description',
				Type__c = typeValue,
				Family__c = familyValue,
				Price__c = price,
				AvailableQuantity__c = quantity
		);
		insert item;
		return item;
	}

	@IsTest
	static void testGetItemsWithFiltersAndSearch() {
		createItem('Laptop', 'Electronics', 'Office', 1000, 5);
		createItem('Chair', 'Furniture', 'Office', 100, 3);
		createItem('Hidden Item', 'Furniture', 'Home', 50, 0);
		Test.startTest();
		List<Item__c> result = ItemController.getItems('Electronics', 'Office', 'lap');
		Test.stopTest();
		System.assertEquals(1, result.size());
		System.assertEquals('Laptop', result[0].Name);
	}

	@IsTest
	static void testGetAccountInfo() {
		Account acc = createAccount();
		Test.startTest();
		Account result = ItemController.getAccountInfo(acc.Id);
		Test.stopTest();

		System.assertEquals(acc.Id, result.Id);
		System.assertEquals('Test account', result.Name);
		System.assertEquals('ACC-001', result.AccountNumber);
	}

	@IsTest
	static void testCheckoutCartCreatesPurchaseAndLines() {
		Account acc = createAccount();
		Item__c item = createItem('Apple', 'Other', 'Home', 10, 5);
		ItemController.CartItemDTO dto = new ItemController.CartItemDTO();
		dto.itemId = item.Id;
		dto.quantity = 2;

		Test.startTest();
		Id purchaseId = ItemController.checkoutCart(acc.Id, new List<ItemController.CartItemDTO>{ dto });
		Test.stopTest();

		Purchase__c purchase = [SELECT Id, ClientId__c, TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchaseId];
		System.assertEquals(acc.Id, purchase.ClientId__c);
		System.assertEquals(2, purchase.TotalItems__c);
		System.assertEquals(20, purchase.GrandTotal__c);

		PurchaseLine__c line = [
				SELECT Id, PurchaseId__c, ItemId__c, Amount__c, UnitCost__c
				FROM PurchaseLine__c
				WHERE PurchaseId__c = :purchaseId
				LIMIT 1
		];

		System.assertEquals(item.Id, line.ItemId__c);
		System.assertEquals(2, line.Amount__c);
		System.assertEquals(10, line.UnitCost__c);

		Item__c updatedItem = [SELECT AvailableQuantity__c FROM Item__c WHERE Id = :item.Id];
		System.assertEquals(3, updatedItem.AvailableQuantity__c);
	}

	@IsTest
	static void testCheckoutCartNotEnoughQuantity() {
		Account acc = createAccount();
		Item__c item = createItem('Apple', 'Other', 'Home', 10, 1);
		ItemController.CartItemDTO dto = new ItemController.CartItemDTO();
		dto.itemId = item.Id;
		dto.quantity = 2;

		Test.startTest();
		try {
			ItemController.checkoutCart(acc.Id, new List<ItemController.CartItemDTO>{ dto });
			System.assert(false, 'Exception should have been thrown.');
		} catch (AuraHandledException e) {
			System.assert(true);
		}
		Test.stopTest();
	}

	@IsTest
	static void testSearchImage() {
		Test.setMock(HttpCalloutMock.class, new UnsplashMock());
		Test.startTest();
		String imageUrl = ItemController.searchImage('apple');
		Test.stopTest();
		System.assertEquals('https://images.unsplash.com/test-image.jpg', imageUrl);
	}

	@IsTest
	static void testIsCurrentUserManager() {
		User currentUser = [SELECT Id, IsManager__c FROM User WHERE Id = :UserInfo.getUserId()];
		currentUser.IsManager__c = true;
		update currentUser;
		Test.startTest();
		Boolean result = ItemController.isCurrentUserManager();
		Test.stopTest();
		System.assertEquals(true, result);
	}
}