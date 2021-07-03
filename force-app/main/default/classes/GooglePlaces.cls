public class GooglePlaces {

    @AuraEnabled
 	public static List<DataTableWrapper> searchPlace (Id account, Decimal longitude, Decimal latitude, Integer radius, String type){

         // Validation to check if type is church. In the future it would be nice to add functionality to take in different types like School.
        GooglePlacesUtility.validateInputs(account, longitude, latitude, radius, type);
        
        Google_API_Key__mdt googleKey = [SELECT Id, Value__c
                                        FROM Google_API_Key__mdt
                                        LIMIT 1];
        String apiKey = (String)googleKey.Value__c;
        List<Account> churchesNeedCSP = new List<Account>();
        Map <String, String> callParameters = new Map<String, String>();
        callParameters.put('apiKey', apiKey);
        callParameters.put('longitude', String.valueOf(longitude));
        callParameters.put('latitude', String.valueOf(latitude));
        callParameters.put('radius', String.valueOf(radius));
        callParameters.put('type', 'church');

        HttpResponse response = GooglePlacesUtility.createApiCall('textsearch', callParameters);
            
        // Deserialize the JSON string into collections of primitive data types.
        Map<Integer, Map<String,Object>> bulkData = GooglePlacesUtility.processResults(response, apiKey); 
        // Create "raw" churches that will be checked for duplicates.           
        List<Account> rawChurches = GooglePlacesDML.createRawChurches(bulkData);
        Map<String, List<Account>> processedChurches = GooglePlacesDupeChecker.checkAccountDupes(rawchurches);

        if (processedChurches.get('Dupes').size() > 0) {churchesNeedCSP = GooglePlacesDupeChecker.checkCSPDupes(processedChurches.get('Dupes'), account);}
            
        // Raw churches will be inserted
        churchesNeedCSP.addAll(GooglePlacesDML.createProcessedChurches(processedChurches.get('Non-dupes')));
        List<Church_School_Partnership__c> csps = GooglePlacesDML.createGoogleGeneratedCSPs(churchesNeedCSP, account);
        return wrapCSPs(csps);
    }

    // Translate CSP data into readable wrappers for LWC component. This allows URLs to be sent in name format
    public static List<DataTableWrapper> wrapCSPs (List<Church_School_Partnership__c> csps) {
        List<DataTableWrapper> wrappers = new List<DataTableWrapper>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> cspIds = new Set<Id>();
        Map<Id, Account> accounts = new Map<Id, Account>();
        
        for (Church_School_Partnership__c csp : csps) {
            accountIds.add(csp.Church_Account__c);
            cspIds.add(csp.Id);
        }

        List<Account> allAccounts = [SELECT Id, Name, Website, Phone, Google_Maps_Listing__c, Number_of_Google_Maps_Ratings__c, Google_Maps_Rating__c FROM Account WHERE Id IN :accountIds];
        // CSP query is required due to formula fields that are required. Recalculate formulas is one way to bypass this, 
        // but this requires security settings for profiles to be re-evaluated for certain fields (Church_Account__c), so this is a bigger project.
        List<Church_School_Partnership__c> partnerships = [SELECT Id, Name, School_Account__c, School_Name__c, 
                                                            Church_Account__c, Church_Name__c, Status__c
                                                            FROM Church_School_Partnership__c 
                                                            WHERE Id IN :cspIds];

        for (Account account : allAccounts) {
            accounts.put(account.Id, account);
        }

        for (Church_School_Partnership__c csp : partnerships) {
            DataTableWrapper wrapper = new DataTableWrapper();
            wrapper.cspUrl = '/' + csp.Id;
            wrapper.cspName = csp.Name;
            wrapper.schoolUrl = '/' + csp.School_Account__c;
            wrapper.schoolName = csp.School_Name__c;
            wrapper.churchUrl = '/' + csp.Church_Account__c;
            wrapper.churchName = csp.Church_Name__c;
            wrapper.status = csp.Status__c;
            wrapper.website = accounts.get(csp.Church_Account__c).Website;
            wrapper.googleMapsListing = accounts.get(csp.Church_Account__c).Google_Maps_Listing__c;
            wrapper.googleMapsRating = accounts.get(csp.Church_Account__c).Google_Maps_Rating__c;
            wrapper.googleMapsRatingAmount = accounts.get(csp.Church_Account__c).Number_of_Google_Maps_Ratings__c;
            wrapper.phone = accounts.get(csp.Church_Account__c).Phone;
            wrappers.add(wrapper);
        }

        return wrappers;
    }

    // Wrapper class for sending data back to LWC component
    public class DataTableWrapper {
        @AuraEnabled
        public String cspUrl {get; set;}
        @AuraEnabled
        public String schoolUrl {get; set;}
        @AuraEnabled
        public String churchUrl {get; set;}
        @AuraEnabled
        public String status {get; set;}
        @AuraEnabled
        public String cspName {get; set;}
        @AuraEnabled
        public String schoolName {get; set;}
        @AuraEnabled
        public String churchName {get; set;}
        @AuraEnabled
        public String website {get; set;}
        @AuraEnabled
        public String googleMapsListing {get; set;}
        @AuraEnabled
        public Double googleMapsRating {get; set;}
        @AuraEnabled
        public Double googleMapsRatingAmount {get; set;}
        @AuraEnabled
        public String phone {get; set;}
        @AuraEnabled
        public Decimal distance {get; set;}
    }
}