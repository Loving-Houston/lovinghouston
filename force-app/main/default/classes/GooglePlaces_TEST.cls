@isTest
private with sharing class GooglePlaces_TEST {
    
    @isTest
    static void testValidResponse() {
        Account school = createSchoolAccount(1)[0];
        GoogleMockCallout callout = new GoogleMockCallout('validKey');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, callout);
        List<GooglePlaces.DataTableWrapper> wraps = GooglePlaces.searchPlace(school.Id, 56.1232, 81.123, 20, school.Type);
        Test.stopTest();
        System.debug(wraps);
        System.assert(wraps.size() > 0,
        'Response should contain data table wrappers.');
    }

    @isTest
    static void testInvalidKey() {
        Account school = createSchoolAccount(1)[0];
        GoogleMockCallout callout = new GoogleMockCallout('invalidKey');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, callout);
        try {
            GooglePlaces.searchPlace(school.Id, 56.1232, 81.123, 20, school.Type);
        } catch (Exception e) {
            System.debug('Test Error message: ' + e.getMessage());
            System.assert(e.getMessage() == 'Error with Google Call: Status: REQUEST_DENIED Error Message: The provided API key is invalid.',
            'Google Response should contain error message.');
        }
        Test.stopTest();
    }

    @isTest
    static void testInvalidAddress() {
        Account school = createSchoolAccount(1)[0];
        GoogleMockCallout callout = new GoogleMockCallout('validKey');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, callout);
        try {
            GooglePlaces.searchPlace(school.Id, null, null, 20, school.Type);
        } catch (Exception e) {
            System.debug('Test Error message: ' + e.getMessage());
            System.assert(e.getMessage() == 'Invalid Account Billing Address. Billing Address Country and Zip are missing.',
            'Address error should be thrown.');
        }
        Test.stopTest();
    }

    @isTest
    static void testInvalidType() {
        Account school = createSchoolAccount(1)[0];
        GoogleMockCallout callout = new GoogleMockCallout('validKey');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, callout);
        try {
            GooglePlaces.searchPlace(school.Id, 56.123, 81.123, 20, 'Church');
        } catch (Exception e) {
            System.debug('Test Error message: ' + e.getMessage());
            System.assert(e.getMessage() == 'Invalid Account Type. Type needs to be school.',
            'Invalid Account Type. Type needs to be school.');
        }
        Test.stopTest();
    }

    @isTest
    static void testBadStatusCode() {
        Account school = createSchoolAccount(1)[0];
        GoogleMockCallout callout = new GoogleMockCallout('badStatusCode');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, callout);
        try {
            List<GooglePlaces.DataTableWrapper> wraps = GooglePlaces.searchPlace(school.Id, 56.1232, 81.123, 20, school.Type);
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.assert(e.getMessage() == 'The requested resource does not exist', 'Status codes that are not 200 should throw an exception');
        }
        Test.stopTest();
    }

    @isTest
    static void testDuplicates() {
        Account duplicateChurch = createDuplicateChurchAccount(1)[0];
        Account school = createSchoolAccount(1)[0];
        GoogleMockCallout callout = new GoogleMockCallout('validKey');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, callout);
        List<GooglePlaces.DataTableWrapper> wraps = GooglePlaces.searchPlace(school.Id, 56.1232, 81.123, 20, school.Type);
        Test.stopTest();
        System.assert(wraps.size() > 0, 'Should return data even if dupe is present.');
        System.assert(wraps[0].website == null, 'If duplicate is found, the website will not be updated on the existing Account.');

    }

    @isTest
    static void testBadReturnAddress() {
        Account school = createSchoolAccount(1)[0];
        GoogleMockCallout callout = new GoogleMockCallout('badAddress');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, callout);
        try {
            List<GooglePlaces.DataTableWrapper> wraps = GooglePlaces.searchPlace(school.Id, 56.1232, 81.123, 20, school.Type);
        } catch (Exception e) {
            System.assert(e.getMessage() == 'All addresses for Google listings found are incomplete and therefore could not be used.', 'No churches created if return data is invalid.');
        }
        Test.stopTest();
    }

    @isTest
    static void testNoStreetNumberOnReturnAddress() {
        Account school = createSchoolAccount(1)[0];
        GoogleMockCallout callout = new GoogleMockCallout('noStreetNumber');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, callout);
        List<GooglePlaces.DataTableWrapper> wraps = GooglePlaces.searchPlace(school.Id, 56.1232, 81.123, 20, school.Type);
        Test.stopTest();
        System.debug(wraps);
        System.assert(wraps.size() > 0,
        'Response should contain data table wrappers even if Street number is not in formatted address.');
    }

    @isTest
    static void testExistingCSPs() {
        List<Account> schools = createSchoolAccount(1);
        List<Account> churches = createDuplicateChurchAccount(1);
        createExistingCSP(1, schools, churches);
        GoogleMockCallout callout = new GoogleMockCallout('validKey');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, callout);
        List<GooglePlaces.DataTableWrapper> wraps = GooglePlaces.searchPlace(schools[0].Id, 56.1232, 81.123, 20, schools[0].Type);
        Test.stopTest();
        System.assert(wraps.size() == 0, 'If existing CSP, no new CSP is created.');
    }

    @isTest
    static void testNullType() {
        Account school = createSchoolAccount(1)[0];
        school.Type = null;
        update school;
        GoogleMockCallout callout = new GoogleMockCallout('validKey');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, callout);
        try {
            GooglePlaces.searchPlace(school.Id, 43.1, 12.1, 5, school.Type);
        } catch (Exception e) {
            System.debug('Test error found: ' + e.getMessage());
            System.assert(e.getMessage() == 'Invalid Account Type. Type needs to be school.', 'If type is null, component will alert user about invalid Type.');
        }
    }

    public static List<Account> createSchoolAccount(Integer amount) {
        String schoolRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('School').getRecordTypeId();
        List<Account> schools = new List<Account>();
        Set<Id> schoolId = new Set<Id>();

        for (Integer i = 0; i < amount; i ++) {

            Account school = new Account();
            school.Name = 'Test School ' + i;
            school.RecordTypeId = schoolRT;
            school.Type = 'School';
            school.BillingStreet = '6587 Jaffe Ct';
            school.BillingCity = 'San Deiego';
            school.BillingState = 'CA';
            school.BillingCountry = 'US';
            school.BillingPostalCode = '92119';
            schools.add(school);
        }
        insert schools;
        for (Account school : schools) {
            schoolId.add(school.Id);
        }
        List<Account> queriedSchools = [SELECT Id, BillingLongitude, BillingLatitude, Type FROM Account WHERE Id IN :schoolId];

        return queriedSchools;
    }

    public static List<Account> createDuplicateChurchAccount(Integer amount) {
        String churchRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Church').getRecordTypeId();
        List<Account> churches = new List<Account>();
        Set<Id> churchId = new Set<Id>();

        for (Integer i = 0; i < amount; i ++) {

            Account church = new Account();
            church.Name = 'Del Mar Church ' + i;
            church.RecordTypeId = churchRT;
            church.Type = 'Church';
            church.BillingStreet = '1425 Ocean Avenue';
            church.BillingCity = 'Del Mar';
            church.BillingState = 'CA';
            church.BillingCountry = 'US';
            church.BillingPostalCode = '92014';
            churches.add(church);
        }
        insert churches;
        for (Account church : churches) {
            churchId.add(church.Id);
        }
        List<Account> queriedSchools = [SELECT Id, BillingLongitude, BillingLatitude, Type FROM Account WHERE Id IN :churchId];

        return queriedSchools;
    }

    public static List<Church_School_Partnership__c> createExistingCSP(Integer amount, List<Account> schools, List<Account> churches) {
        List<Church_School_Partnership__c> csps = new List<Church_School_Partnership__c>();

        for (Integer i = 0; i < amount; i ++) {
            Church_School_Partnership__c csp = new Church_School_Partnership__c();
            csp.Church_Account__c = churches[i].Id;
            csp.School_Account__c = schools[i].Id;
            csp.Status__c = 'Google-Generated';
            csps.add(csp);
        }

        insert csps;
        return csps;
    }

    public class GoogleMockCallout implements HttpCalloutMock {
        public String type;

        public GoogleMockCallout(String type) {
            this.type = type;
        }

        public HttpResponse respond (HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setStatus('OK');

            if (request.getEndpoint().contains('textsearch')) {

                if (type.equals('validKey')) { response.setBody(apiCallResponse('textsearch', 'validKey')); }

                if (type.equals('invalidKey')) { response.setBody(apiCallResponse('textsearch', 'invalidKey')); }

                if (type.equals('badAddress')) { response.setBody(apiCallResponse('textsearch', 'badAddress')); }

                if (type.equals('noStreetNumber')) { response.setBody(apiCallResponse('textsearch', 'noStreetNumber')); }

            }
            if (request.getEndpoint().contains('details')) {

                if (type.equals('validKey')) { response.setBody(apiCallResponse('details', 'validKey')); }

                if (type.equals('invalidKey')) { response.setBody(apiCallResponse('textsearch', 'invalidKey')); }

                if (type.equals('badAddress')) { response.setBody(apiCallResponse('details', 'badAddress')); }

                if (type.equals('noStreetNumber')) { response.setBody(apiCallResponse('details', 'noStreetNumber')); }

            }
            if (type.equals('badStatusCode')) { response.setStatusCode(404); response.setStatus('The requested resource does not exist'); }

            return response;
        }
    }

    public static String apiCallResponse(String callType, String testType) {
        String result = '';

        if (callType.equals('textsearch')) {

            if (testType.equals('validKey')) {
                result = '{' +
                '   \"results\" : [' +
                '       {' +
                '           \"formatted_address\" : \"1425 Ocean Avenue, Del Mar, CA 92014\",' +
                '           \"name\" : \"Del Mar Church\",' +
                '           \"place_id\" : \"1425Ocean\",' +
                '           \"rating\" : 5,' +
                '           \"user_ratings_total\" : 20' +
                '       }' +
                '   ],' +
                '   \"status\" : \"OK\"' +
                '}';
            }
            if (testType.equals('invalidKey')) {
                result = '{' +
                '   \"error_message\" : \"The provided API key is invalid.\",' +
                '   \"results\" : [],' +
                '   \"status\" : \"REQUEST_DENIED\"' +
                '}';
            }
            if (testType.equals('noStreetNumber')) {
                result = '{' +
                '   \"results\" : [' +
                '       {' +
                '           \"formatted_address\" : \"Ocean Avenue, Del Mar, CA 92014\",' +
                '           \"name\" : \"Del Mar Church\",' +
                '           \"place_id\" : \"1425Ocean\",' +
                '           \"rating\" : 5,' +
                '           \"user_ratings_total\" : 20' +
                '       }' +
                '   ],' +
                '   \"status\" : \"OK\"' +
                '}';
            }
            if (testType.equals('badAddress')) {
                result = '{' +
                '   \"results\" : [' +
                '       {' +
                '           \"formatted_address\" : \"Del Mar, CA 92014\",' +
                '           \"name\" : \"Del Mar Church\",' +
                '           \"place_id\" : \"1425Ocean\",' +
                '           \"rating\" : 5,' +
                '           \"user_ratings_total\" : 20' +
                '       }' +
                '   ],' +
                '   \"status\" : \"OK\"' +
                '}';
            }
        }
        if (callType.equals('details')) {
            if (testType.equals('validKey')) {
                result = '{' +
                '   \"result\" : {' +
                '       \"address_components\" : [' +
                '           {' +
                '               \"long_name\" : \"1425\",' +
                '               \"short_name\" : \"1425\",' +
                '               \"types\" : [ \"street_number\" ]' +
                '           },' +
                '           {' +
                '               \"long_name\" : \"Ocean Avenue\",' +
                '               \"short_name\" : \"Ocean Ave\",' +
                '               \"types\" : [ \"route\" ]' +
                '           },' +
                '           {' +
                '               \"long_name\" : \"Del Mar\",' +
                '               \"short_name\" : \"Del Mar\",' +
                '               \"types\" : [ \"locality\" ]' +
                '           },' +
                '           {' +
                '               \"long_name\" : \"California\",' +
                '               \"short_name\" : \"CA\",' +
                '               \"types\" : [ \"administrative_area_level_1\" ]' +
                '           },' +
                '           {' +
                '               \"long_name\" : \"United States\",' +
                '               \"short_name\" : \"US\",' +
                '               \"types\" : [ \"country\" ]' +
                '           },' +
                '           {' +
                '               \"long_name\" : \"92014\",' +
                '               \"short_name\" : \"92014\",' +
                '               \"types\" : [ \"postal_code\" ]' +
                '           }' +
                '       ],' +
                '       \"formatted_phone_number\" : \"1234567890\",' +
                '       \"name\" : \"Del Mar Church\",' +
                '       \"website\" : \"delmarchurch\"' +
                '       },' +
                '   \"status\" : \"OK\"' +
                '}';
            }
            if (testType.equals('noStreetNumber')) {
                result = '{' +
                '   \"result\" : {' +
                '       \"address_components\" : [' +
                '           {' +
                '               \"long_name\" : \"Ocean Avenue\",' +
                '               \"short_name\" : \"Ocean Ave\",' +
                '               \"types\" : [ \"route\" ]' +
                '           },' +
                '           {' +
                '               \"long_name\" : \"Del Mar\",' +
                '               \"short_name\" : \"Del Mar\",' +
                '               \"types\" : [ \"locality\" ]' +
                '           },' +
                '           {' +
                '               \"long_name\" : \"California\",' +
                '               \"short_name\" : \"CA\",' +
                '               \"types\" : [ \"administrative_area_level_1\" ]' +
                '           },' +
                '           {' +
                '               \"long_name\" : \"United States\",' +
                '               \"short_name\" : \"US\",' +
                '               \"types\" : [ \"country\" ]' +
                '           },' +
                '           {' +
                '               \"long_name\" : \"92014\",' +
                '               \"short_name\" : \"92014\",' +
                '               \"types\" : [ \"postal_code\" ]' +
                '           }' +
                '       ],' +
                '       \"formatted_phone_number\" : \"1234567890\",' +
                '       \"name\" : \"Del Mar Church\",' +
                '       \"website\" : \"delmarchurch\"' +
                '       },' +
                '   \"status\" : \"OK\"' +
                '}';
            }
            if (testType.equals('badAddress')) {
                result = '{' +
                '   \"result\" : {' +
                '       \"address_components\" : [' +
                '           {' +
                '               \"long_name\" : \"Del Mar\",' +
                '               \"short_name\" : \"Del Mar\",' +
                '               \"types\" : [ \"locality\" ]' +
                '           },' +
                '           {' +
                '               \"long_name\" : \"California\",' +
                '               \"short_name\" : \"CA\",' +
                '               \"types\" : [ \"administrative_area_level_1\" ]' +
                '           },' +
                '           {' +
                '               \"long_name\" : \"United States\",' +
                '               \"short_name\" : \"US\",' +
                '               \"types\" : [ \"country\" ]' +
                '           },' +
                '           {' +
                '               \"long_name\" : \"92014\",' +
                '               \"short_name\" : \"92014\",' +
                '               \"types\" : [ \"postal_code\" ]' +
                '           }' +
                '       ],' +
                '       \"formatted_phone_number\" : \"1234567890\",' +
                '       \"name\" : \"Del Mar Church\",' +
                '       \"website\" : \"delmarchurch\"' +
                '       },' +
                '   \"status\" : \"OK\"' +
                '}';
            }
        }
        return result;
    }
}
