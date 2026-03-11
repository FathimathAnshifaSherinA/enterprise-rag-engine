/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-11-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class RAGEngineController {

    @AuraEnabled(cacheable=false)
    public static String generateCaseResolution(Id caseId) {

        Case currentCase = [
            SELECT Id, Subject, Description, Contact.Name
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        String keywords = KnowledgeSearchHelper.extractKeywords(
            currentCase.Description
        );

        List<KnowledgeSearchHelper.ArticleResult> articles =
            KnowledgeSearchHelper.findArticles(keywords);

        String ragPrompt = buildRAGPrompt(currentCase, articles);

        return callOpenAI(ragPrompt);
    }

    private static String buildRAGPrompt(
        Case c,
        List<KnowledgeSearchHelper.ArticleResult> articles
    ) {
        String prompt = 'You are a helpful customer support agent.\n'
            + 'Use ONLY the Knowledge Articles below to write your reply.\n'
            + 'Do NOT use any outside knowledge.\n\n'
            + '=== CUSTOMER CASE ===\n'
            + 'Customer: ' + c.Contact?.Name + '\n'
            + 'Subject: ' + c.Subject + '\n'
            + 'Description: ' + c.Description + '\n\n'
            + '=== KNOWLEDGE ARTICLES ===\n';

        Integer i = 1;
        for (KnowledgeSearchHelper.ArticleResult art : articles) {
            prompt += 'Article ' + i + ': ' + art.title + '\n'
                   + 'Summary: ' + art.summary + '\n'
                   + 'Solution: ' + art.answer + '\n\n';
            i++;
        }

        prompt += '=== YOUR TASK ===\n'
               + 'Write a professional empathetic email reply to the customer.\n'
               + 'Start with Dear [customer name] and end with a helpful closing.';

        return prompt;
    }

    private static String callOpenAI(String prompt) {
        Map<String, Object> textPart = new Map<String, Object>{
            'text' => prompt
        };

        Map<String, Object> content = new Map<String, Object>{
            'parts' => new List<Object>{ textPart }
        };

        Map<String, Object> requestBody = new Map<String, Object>{
            'contents' => new List<Object>{ content }
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=YOUR_GEMINI_API_KEY_HERE');
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('POST');
        req.setBody(JSON.serialize(requestBody));
        req.setTimeout(30000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> candidates = (List<Object>) responseMap.get('candidates');
            Map<String, Object> candidate = (Map<String, Object>) candidates[0];
            Map<String, Object> contentMap = (Map<String, Object>) candidate.get('content');
            List<Object> parts = (List<Object>) contentMap.get('parts');
            Map<String, Object> part = (Map<String, Object>) parts[0];
            return (String) part.get('text');
        } else {
            throw new AuraHandledException(
                'Gemini call failed: ' + res.getStatus() + ' ' + res.getBody()
            );
        }
    }
    @AuraEnabled
    public static void sendCaseEmail(Id caseId, String emailBody) {
        // Get case details
        Case currentCase = [
            SELECT Id, Subject, ContactEmail, Contact.Email, Contact.Name
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
    
        // Get email address from Case contact or contact email field
        String toAddress = currentCase.Contact?.Email != null
            ? currentCase.Contact.Email
            : currentCase.ContactEmail;
    
        if (String.isBlank(toAddress)) {
            throw new AuraHandledException(
                'No email address found on this Case. Please add a contact email first.'
            );
        }
    
        // Build the email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ toAddress });
        email.setSubject('Re: ' + currentCase.Subject);
        email.setPlainTextBody(emailBody);
        email.setWhatId(caseId); // Links email to the Case record
    
        // Send it
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    }
}