public with sharing class ItemController {
	@AuraEnabled(cacheable=true)
	public static List<Item__c> getItems(String type, String family, String searchTerm) {
		String searchPattern = '%' + String.escapeSingleQuotes(String.isBlank(searchTerm) ? '' : searchTerm.trim()) + '%';
		String query = 'SELECT Id, Name, Description__c, Type__c, Family__c, Image__c, Price__c, AvailableQuantity__c FROM Item__c WHERE AvailableQuantity__c > 0';

		if (!String.isBlank(type)) {
			query += ' AND Type__c = :type';
		}
		if (!String.isBlank(family)) {
			query += ' AND Family__c = :family';
		}
		if (!String.isBlank(searchTerm)) {
			query += ' AND (Name LIKE :searchPattern OR Description__c LIKE :searchPattern)';
		}
		// in alphabetical order
		query += ' ORDER BY Name ASC';
		return Database.query(query);
	}

	@AuraEnabled(cacheable=true)
	public static Account getAccountInfo(Id accountId) {
		if (accountId == null) {
			return null;
		}
		return [SELECT Id, Name, AccountNumber, Industry FROM Account WHERE Id = :accountId LIMIT 1];
	}
}