public with sharing class Describe {
/*-----------------------------------------------------------------------------------------------
  Wrapper class for object and field description data 

      Copyright (c) 2012, Groundwire Consulting, Inc.
      All rights reserved.

      Redistribution and use in source and binary forms, with or without
      modification, are permitted provided that the following conditions are met:

      * Redistributions of source code must retain the above copyright
         notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above copyright
         notice, this list of conditions and the following disclaimer in the
         documentation and/or other materials provided with the distribution.
      * Neither the name of Groundwire Consulting, Inc. nor the names of
         its contributors may be used to endorse or promote products derived
         from this software without specific prior written permission.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
      "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
      LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
      FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
      COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
      INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
      BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
      LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
      CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
      LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
      ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
      POSSIBILITY OF SUCH DAMAGE.
*/
/*******************************************************************************************************
* @author Evan Callahan
* @date 01/01/2010
* @description This class allows easy access to object and field description information from within other classes.
*
* It is called statically, and therefore will supply the same information to all calls made from
* within one transaction, or set of trigger calls. This is beneficial because this info should
* be the same for all calls in a transaction, and by calling it statically we reduce the calls
* that are made, making the total transaction more efficient.
*/
	
	// throw custom exceptions when a bogus object or field is provided. 
	public class SchemaDescribeException extends Exception {}
	
	//maps to hold the describe info
	private static Map<String, Schema.SObjectType> gd;
	private static Map<String, Schema.DescribeSObjectResult> objectDescribes = new Map<String, Schema.DescribeSObjectResult>();
	private static Map<String, Map<String, Schema.SObjectField>> fieldTokens = new Map<String,Map<String, Schema.SObjectField>>();
	private static Map<String, Map<String, Schema.DescribeFieldResult>> fieldDescribes = new Map<String,Map<String, Schema.DescribeFieldResult>>();
		
	/*******************************************
	* Gets describe maps for a new object
	********************************************/
	static void fillMapsForObject(string objectName) {
		// get the object map the first time
		if (gd==null) gd = Schema.getGlobalDescribe();
		
		// get the object description
		if (gd.containsKey(objectName)) {
			
			if (!objectDescribes.containsKey(objectName))
				objectDescribes.put(objectName, gd.get(objectName).getDescribe());
		} else {
			throw new SchemaDescribeException('Invalid object name \'' + objectName + '\'');
		}
	}

	/*******************************************
	* Gets a field map for a new object/field pair
	********************************************/
	static void fillFieldMapsForObject(string objectName, string fieldName) {
		// get the object map the first time
		fillMapsForObject(objectName);
		
		// get the field description
		if (!fieldTokens.containsKey(objectName)) {
			fieldTokens.put(objectName, objectDescribes.get(objectName).fields.getMap());
			fieldDescribes.put(objectName, new Map<String, Schema.DescribeFieldResult>());
		}
		if (!fieldDescribes.get(objectName).containsKey(fieldName)) {
			if (fieldTokens.get(objectName).containsKey(fieldName)) {
				Schema.DescribeFieldResult dfr = fieldTokens.get(objectName).get(fieldName).getDescribe(); 
				fieldDescribes.get(objectName).put(fieldName, dfr);
			} else {
				throw new SchemaDescribeException('Invalid field name \'' + fieldName + '\'');			
			}
		}
	}
	
	/*******************************************
	* Gets all field maps for a new object
	********************************************/
	static void fillFieldMapsForObject(string objectName) {
		// get the object map the first time
		fillMapsForObject(objectName);
		
		// get the field description
		if (!fieldTokens.containsKey(objectName)) {
			fieldTokens.put(objectName, objectDescribes.get(objectName).fields.getMap());
			fieldDescribes.put(objectName, new Map<String, Schema.DescribeFieldResult>());
		}
		
		//Map<String, Schema.SObjectField> fieldsMap = objectDescribes.get(objectName).fields.getMap();
		if (fieldTokens.get(objectName).size() != fieldDescribes.get(objectName).size()) {
			for ( string fieldName : fieldTokens.get(objectName).keyset()) {
				if (!fieldDescribes.get(objectName).containsKey(fieldName)) {
					Schema.DescribeFieldResult dfr = fieldTokens.get(objectName).get(fieldName).getDescribe(); 
					fieldDescribes.get(objectName).put(fieldName, dfr);
				}
			}
		}
	}

	/*******************************************************************************************************
	* @description Returns new object of given type.
	* @param objectName the name of the object to create
	* @return the new SObject
	*/ 	
	public static SObject getPrototypeObject(String objectName) {
		// make sure we have this object's schema mapped
		if (!objectDescribes.containsKey(objectName)) 
			fillMapsForObject(objectName);
		
		return gd.get(objectName).newSObject();
	}	

	/*******************************************************************************************************
	* @description Returns object friendly name.
	* @param objectName the name of the object to lookup 
	* @return the Label of the object
	*/ 	
	public static string getObjectLabel(String objectName) {
		// make sure we have this object's schema mapped
		if (!objectDescribes.containsKey(objectName)) 
			fillMapsForObject(objectName);
		
		return objectDescribes.get(objectName).getLabel();
		
	}	

	/*******************************************************************************************************
	* @description Returns plural object friendly name.
	* @param objectName the name of the object to lookup 
	* @return the Label of the object
	*/ 	
	public static string getObjectLabelPlural(String objectName) {
		// make sure we have this object's schema mapped
		if (!objectDescribes.containsKey(objectName)) 
			fillMapsForObject(objectName);
		
		return objectDescribes.get(objectName).getLabelPlural();
		
	}	

	/*******************************************************************************************************
	* @description Returns object describe data.
	* @param objectName the name of the object to lookup 
	* @return Schema.DescribeSObjectResult of the object
	*/ 	
	public static Schema.DescribeSObjectResult getObjectDescribe(String objectName) {
		// make sure we have this object's schema mapped
		if (!objectDescribes.containsKey(objectName)) 
			fillMapsForObject(objectName);
		
		return objectDescribes.get(objectName);
	}	

	/*******************************************************************************************************
	* @description Compares Id to verify object type
	* @param salesforceId of the object
	* @param objectName 
	* @return true if the Id is for the given object type, false otherwise.
	*/ 	
	public static boolean isObjectIdThisType(Id salesforceId, String objectName) {
		// make sure we have this object's schema mapped
		if (!objectDescribes.containsKey(objectName)) 
			fillMapsForObject(objectName);
		
		// now grab the requested id prefix
		boolean ret = false;
		if (salesforceId != null) {
			string prefix = objectDescribes.get(objectName).getKeyPrefix();
			if (prefix != null) 
				ret = ((string)(salesforceId)).startsWith(prefix);
		}
		return ret;
	}	
	
	/*******************************************************************************************************
	* @description Returns all field describe data
	* @param objectName the name of the object to look up
	* @return Map<String, Schema.DescribeFieldResult> a map of object names to describe file results.
	*/ 	
	public static Map<String, Schema.DescribeFieldResult> getAllFieldsDescribe(String objectName) {

		// make sure we have this field's schema mapped
		fillFieldMapsForObject(objectName);
		
		Map<String, Schema.DescribeFieldResult> fieldMap = fieldDescribes.get(objectName);
		return fieldMap;
	}

	/*******************************************************************************************************
	* @description Returns all field names for an object
	* @param objectName the name of the object to look up
	* @return Set<String> 
	*/ 	
	public static Set<String> getAllFieldNames(String objectName) {

		// make sure we have this field's schema mapped
		fillFieldMapsForObject(objectName);
		
		return fieldDescribes.get(objectName).keyset();
		
	}

	/*******************************************************************************************************
	* @description Gives field type name - ID, STRING, TEXTAREA, DATE, DATETIME, BOOLEAN, REFERENCE, 
	* PICKLIST, MULTIPICKLIST, CURRENCY, DOUBLE, INTEGER, PERCENT, PHONE, EMAIL
	* @param objectName the name of the object to look up
	* @param fieldName the name of the field to look up
	* @return string the name of the of the field's type
	*/ 	
	public static string getFieldType(String objectName, String fieldName) {
		// make sure we have this field's schema mapped
		if (!fieldDescribes.containsKey(objectName) || !fieldDescribes.get(objectName).containsKey(fieldName)) 
			fillFieldMapsForObject(objectName, fieldName);
		
		Schema.DescribeFieldResult dfr = fieldDescribes.get(objectName).get(fieldName);
		return dfr.getType().name();
	}	

	/*******************************************************************************************************
	* @description Returns field describe data 
	* @param objectName the name of the object to look up
	* @param fieldName the name of the field to look up
	* @return Schema.DescribeFieldResult the describe field result for the given field
	*/ 
	public static Schema.DescribeFieldResult getFieldDescribe(String objectName, String fieldName) {
		// make sure we have this field's schema mapped
		fieldName = fieldName.toLowerCase();
		if (!fieldDescribes.containsKey(objectName) || !fieldDescribes.get(objectName).containsKey(fieldName)) 
			fillFieldMapsForObject(objectName, fieldName);
		
		Schema.DescribeFieldResult dfr = fieldDescribes.get(objectName).get(fieldName);
		return dfr;
	}

	/*******************************************************************************************************
	* @description Gives field friendly name 
	* @param objectName the name of the object to look up
	* @param fieldName the name of the field to look up
	* @return string the label of the field
	*/ 
	public static string getFieldLabel(String objectName, String fieldName) {
		// make sure we have this field's schema mapped
		fieldName = fieldName.toLowerCase();
		if (!fieldDescribes.containsKey(objectName) || !fieldDescribes.get(objectName).containsKey(fieldName)) 
			fillFieldMapsForObject(objectName, fieldName);
		
		Schema.DescribeFieldResult dfr = fieldDescribes.get(objectName).get(fieldName);
		return dfr.getLabel();
	}		

	/*******************************************************************************************************
	* @description Gives member statuses for a campaign 
	* @param cid Id of the campaign to look up
	* @return List of status names 
	*/ 
	public static list<string> getCampaignMemberStatuses(id cid) {
		list<string> memberStatuses = new list<string>();
		
		for (campaignMemberStatus cm : [select Label from CampaignMemberStatus 
			where campaignId =: cid order by SortOrder]) { 
			
			memberStatuses.add(cm.Label);
		}
		
		return (memberStatuses.isEmpty() ? null : memberStatuses);
	}

	// TEST
	static testmethod void testDescribe() {
		
		string s;
		
		Schema.DescribeSObjectResult res = Describe.getObjectDescribe('Contact');		
		system.assertEquals(res.getName(), 'Contact');
		s = Describe.getObjectLabel('Contact');
		system.assertEquals (s, res.getLabel());

		account a = new account(name='Test');
		insert a;
		system.assert(isObjectIdThisType(a.id, 'Account'));
		
		s = Describe.getFieldLabel('Account', 'LastModifiedDate');
		integer calls = limits.getfieldsdescribes();
		
		Schema.DescribeFieldResult fr = Describe.getFieldDescribe('Account', 'CreatedDate');		
		s = Describe.getFieldLabel('Account', 'CreatedDate');
		system.assertEquals (s, fr.getLabel());

		Map<String, Schema.DescribeFieldResult> afd = getAllFieldsDescribe('Account');
		system.assertEquals ('BillingCity', afd.get('billingcity').getName());
		afd = getAllFieldsDescribe('Account');

		SObject acctObj = getPrototypeObject('Account');
		// should be able to cast to account
		account acct = (account)(acctObj);

		// another call should not use another describe
		system.assertEquals(limits.getfieldsdescribes(), calls);
		
		s = Describe.getFieldType('Account', 'CreatedDate');
		system.assertEquals('DATETIME', s);
		
		try {
			s = Describe.getObjectLabel('sdlkfjsdlkfjsldkfjlsdkfj');
		} catch (exception e) {
			system.assertEquals('Invalid object name \'sdlkfjsdlkfjsldkfjlsdkfj\'', e.getMessage());
		} 
		try {
			s = Describe.getFieldLabel('Opportunity', 'sdlkfjsdlkfjsldkfjlsdkfj');
		} catch (exception e) {
			system.assertEquals('Invalid field name \'sdlkfjsdlkfjsldkfjlsdkfj\'', e.getMessage());
		} 
	}		
}