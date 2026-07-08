@IsTest
private class PurchaseLineTriggerHandlerTest {

	private static Account createAccount() {
		Account acc = new Account(Name = 'Trigger Test Account');
		insert acc;
		return acc;
	}

	private static Item__c createItem(String name, Decimal price) {
		Item__c item = new Item__c(
				Name = name,
				Description__c = 'Test item',
				Type__c = 'Other',
				Family__c = 'Home',
				Price__c = price,
				AvailableQuantity__c = 10
		);
		insert item;
		return item;
	}

	@IsTest
	static void testTriggerCalculatesTotalsAfterInsert() {
		Account acc = createAccount();
		Item__c item1 = createItem('Item 1', 100);
		Item__c item2 = createItem('Item 2', 50);
		Purchase__c purchase = new Purchase__c(ClientId__c = acc.Id);
		insert purchase;

		Test.startTest();
		insert new List<PurchaseLine__c>{
				new PurchaseLine__c(
						PurchaseId__c = purchase.Id,
						ItemId__c = item1.Id,
						Amount__c = 2,
						UnitCost__c = 100
				),
				new PurchaseLine__c(
						PurchaseId__c = purchase.Id,
						ItemId__c = item2.Id,
						Amount__c = 3,
						UnitCost__c = 50
				)
				};
		Test.stopTest();

		Purchase__c updatedPurchase = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchase.Id];
		System.assertEquals(5, updatedPurchase.TotalItems__c);
		System.assertEquals(350, updatedPurchase.GrandTotal__c);
	}

	@IsTest
	static void testTriggerRecalculatesAfterUpdate() {
		Account acc = createAccount();
		Item__c item = createItem('Item', 100);

		Purchase__c purchase = new Purchase__c(ClientId__c = acc.Id);
		insert purchase;

		PurchaseLine__c line = new PurchaseLine__c(
				PurchaseId__c = purchase.Id,
				ItemId__c = item.Id,
				Amount__c = 2,
				UnitCost__c = 100
		);
		insert line;

		Test.startTest();
		line.Amount__c = 4;
		update line;
		Test.stopTest();

		Purchase__c afterUpdate = [
				SELECT TotalItems__c, GrandTotal__c
				FROM Purchase__c
				WHERE Id = :purchase.Id
		];

		System.assertEquals(4, afterUpdate.TotalItems__c);
		System.assertEquals(400, afterUpdate.GrandTotal__c);
	}

	@IsTest
	static void testTriggerRecalculatesAfterDelete() {
		Account acc = createAccount();
		Item__c item = createItem('Item', 100);

		Purchase__c purchase = new Purchase__c(ClientId__c = acc.Id);
		insert purchase;

		PurchaseLine__c line = new PurchaseLine__c(
				PurchaseId__c = purchase.Id,
				ItemId__c = item.Id,
				Amount__c = 2,
				UnitCost__c = 100
		);
		insert line;

		Test.startTest();
		delete line;
		Test.stopTest();

		Purchase__c afterDelete = [
				SELECT TotalItems__c, GrandTotal__c
				FROM Purchase__c
				WHERE Id = :purchase.Id
		];

		System.assertEquals(0, afterDelete.TotalItems__c);
		System.assertEquals(0, afterDelete.GrandTotal__c);
	}
}