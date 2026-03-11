/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-11-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class RAGEngineControllerTest {

    /**
     * Mock HTTP callout — simulates OpenAI's JSON response
     * This prevents real API calls during tests (saves money + speed)
     */
    private class MockOpenAIResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');

            // Fake OpenAI response format
            res.setBody('{"choices":[{"message":{"content":"Dear Customer, thank you for contacting us..."}}]}');
            return res;
        }
    }

    @isTest
    static void testKeywordExtraction() {
        String keywords = KnowledgeSearchHelper.extractKeywords(
            'I cannot reset my password on the login page'
        );
        // 'cannot' is kept, stop words 'I', 'my', 'on', 'the' are filtered
        System.assert(keywords.contains('cannot'), 'Should extract meaningful words');
        System.assert(!keywords.contains(' the '), 'Should remove stop words');
    }

    @isTest
    static void testFullRAGPipeline() {
        // Create a test Case record
        Case testCase = new Case(
            Subject = 'Cannot reset password',
            Description = 'My password reset email is not arriving in inbox'
        );
        insert testCase;
         // Tell Salesforce to use our fake HTTP response
        Test.setMock(HttpCalloutMock.class, new MockOpenAIResponse());

        Test.startTest();
        String result = RAGEngineController.generateCaseResolution(testCase.Id);
        Test.stopTest();

        // Verify we got a reply back
        System.assertNotEquals(null, result, 'Should return AI-generated text');
        System.assert(result.contains('Dear Customer'), 'Should match mock response');
    }
}
