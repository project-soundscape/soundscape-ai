import 'package:get/get.dart';

class WikiService extends GetConnect {
  static final Map<String, String?> _imageCache = {};

  Future<Map<String, dynamic>?> getBirdInfo(String scientificName) async {
    // Clean and encode the scientific name for the URL
    // Wikipedia expects spaces to be underscores for the page title in REST API, 
    // or just properly encoded.
    final pageTitle = scientificName.trim().replaceAll(' ', '_');
    final url = 'https://en.wikipedia.org/api/rest_v1/page/summary/$pageTitle';

    try {
      final response = await get(url);
      
      if (response.status.hasError) {
        print('WikiService: Error ${response.statusCode} fetching $scientificName');
        return null;
      }

      if (response.body == null) return null;

      // Check if it's a disambiguation page or not found
      if (response.body['type'] == 'disambiguation') {
         return null; 
      }

      final imageUrl = response.body['thumbnail']?['source'];
      if (imageUrl != null) {
        _imageCache[scientificName] = imageUrl;
      }

      return {
        'title': response.body['title'],
        'description': response.body['extract'],
        'imageUrl': imageUrl,
        'originalImageUrl': response.body['originalimage']?['source'],
        'pageUrl': response.body['content_urls']?['desktop']?['page'],
      };
    } catch (e) {
      print('WikiService Exception: $e');
      return null;
    }
  }

  Future<String?> getBirdImage(String scientificName) async {
    if (_imageCache.containsKey(scientificName)) {
      return _imageCache[scientificName];
    }
    
    // We can just call getBirdInfo, it caches the image as a side effect
    final info = await getBirdInfo(scientificName);
    return info?['imageUrl'];
  }
}
