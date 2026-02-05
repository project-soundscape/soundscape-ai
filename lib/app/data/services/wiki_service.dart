import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

class WikiService extends GetConnect {
  late Box _cacheBox;

  Future<WikiService> init() async {
    _cacheBox = await Hive.openBox('wiki_cache');
    return this;
  }

  Future<Map<String, dynamic>?> getBirdInfo(String scientificName, {String languageCode = 'en'}) async {
    // Clean the species name: Extract only the scientific name part
    // Format can be: "Fringilla coelebs_Зяблик" or "Fringilla coelebs" or "Common Name" or "Common Name (ID: User)"
    String cleanedName = scientificName.trim();
    
    // Remove content in parentheses (e.g., user tags)
    cleanedName = cleanedName.replaceAll(RegExp(r'\(.*?\)'), '').trim();
    
    // If contains underscore, take only the part before it (scientific name)
    if (cleanedName.contains('_')) {
      cleanedName = cleanedName.split('_').first.trim();
    }
    
    // Replace spaces with underscores for Wikipedia URL
    final pageTitle = cleanedName.replaceAll(' ', '_');
    final cacheKey = "${languageCode}_$pageTitle";
    
    // 1. Check Local Cache
    if (_cacheBox.containsKey(cacheKey)) {
      final cachedData = _cacheBox.get(cacheKey);
      if (cachedData != null) {
        return Map<String, dynamic>.from(cachedData);
      }
    }

    // 2. Fetch Remote
    final url = 'https://$languageCode.wikipedia.org/api/rest_v1/page/summary/$pageTitle';

    try {
      final response = await get(
        url,
        headers: {'User-Agent': 'SoundScape/1.0 (soundscape@example.com)'},
      );
      
      if (response.status.hasError) {
        print('WikiService: Error ${response.statusCode} fetching $scientificName');
        return null;
      }

      if (response.body == null) return null;

      if (response.body['type'] == 'disambiguation') {
         return null; 
      }

      final data = {
        'title': response.body['title'],
        'description': response.body['extract'],
        'imageUrl': response.body['thumbnail']?['source'],
        'originalImageUrl': response.body['originalimage']?['source'],
        'pageUrl': response.body['content_urls']?['desktop']?['page'],
      };

      // 3. Save to Cache
      await _cacheBox.put(cacheKey, data);

      return data;
    } catch (e) {
      print('WikiService Exception: $e');
      return null;
    }
  }

  Future<String?> getBirdImage(String scientificName) async {
    final info = await getBirdInfo(scientificName);
    return info?['imageUrl'];
  }
}
