/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-11-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class KnowledgeSearchHelper {

    public class ArticleResult {
        public String title;
        public String summary;
        public String answer;

        public ArticleResult(String t, String s, String a) {
            this.title = t;
            this.summary = s;
            this.answer = a;
        }
    }

    public static String extractKeywords(String caseDescription) {
        Set<String> stopWords = new Set<String>{
            'the','a','an','is','it','my','i',
            'not','can','to','and','or','in','am'
        };

        List<String> words = caseDescription.toLowerCase().split('\\s+');
        List<String> keywords = new List<String>();

        for (String word : words) {
            if (!stopWords.contains(word) && word.length() > 3) {
                keywords.add(word);
                if (keywords.size() == 3) break;
            }
        }

        return String.join(keywords, ' ');
    }

    public static List<ArticleResult> findArticles(String keywords) {
        List<ArticleResult> results = new List<ArticleResult>();

        try {
            String searchQuery = 'FIND \''
                + String.escapeSingleQuotes(keywords)
                + '\' IN ALL FIELDS RETURNING Knowledge__kav('
                + 'Id, Title, Summary, Answer__c '
                + 'WHERE PublishStatus = \'Online\' '
                + 'AND Language = \'en_US\' LIMIT 3)';

            List<List<SObject>> searchResult = search.query(searchQuery);

            if (!searchResult.isEmpty() && !searchResult[0].isEmpty()) {
                for (SObject obj : searchResult[0]) {
                    // Use .get() instead of direct field access
                    // This avoids Invalid type compile errors
                    String title   = (String) obj.get('Title');
                    String summary = (String) obj.get('Summary');
                    String answer  = (String) obj.get('Answer__c');

                    results.add(new ArticleResult(title, summary, answer));
                }
            }

        } catch (Exception e) {
            System.debug('Knowledge search error: ' + e.getMessage());
        }

        return results;
    }
}