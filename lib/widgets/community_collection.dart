import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rosario/models/pattern.dart';
import 'package:rosario/screens/edit.dart';
import 'package:rosario/widgets/pattern_filter.dart';

class CommunityCollection extends StatefulWidget {
  const CommunityCollection({super.key});

  @override
  State<CommunityCollection> createState() => _CommunityCollectionState();
}

class _CommunityCollectionState extends State<CommunityCollection> {
  List<BeadsPattern> items = [];
  Map<String, String> patternIdToUserName = {}; // Map pattern ID to user name
  Map<String, String> patternIdToImageUrl = {}; // Map pattern ID to image URL
  String? selectedFilter;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCommunityPatterns();
  }

  Future<void> _fetchCommunityPatterns() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final uri = Uri.parse('https://rosario-api.vercel.app/api/patterns');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<BeadsPattern> patterns = [];
        final Map<String, String> idToUserName = {};
        final Map<String, String> idToImageUrl = {};

        for (var item in data) {
          try {
            // Parse the pattern JSON string
            final patternJson = jsonDecode(item['pattern'] as String);
            final pattern = _parsePatternFromJson(patternJson);
            
            // Use the API item's id (top-level id from response)
            final itemId = item['id'] as String? ?? pattern.id ?? '';
            final userName = item['userName'] as String? ?? 'Unknown';
            final imageUrl = item['image'] as String?;
            
            // Ensure pattern has the API item's id for mapping
            if (itemId.isNotEmpty) {
              pattern.id = itemId;
              idToUserName[itemId] = userName;
              if (imageUrl != null && imageUrl.isNotEmpty) {
                idToImageUrl[itemId] = imageUrl;
              }
            } else if (pattern.id != null) {
              idToUserName[pattern.id!] = userName;
              if (imageUrl != null && imageUrl.isNotEmpty) {
                idToImageUrl[pattern.id!] = imageUrl;
              }
            }
            
            patterns.add(pattern);
          } catch (e) {
            // Skip invalid patterns
            continue;
          }
        }

        setState(() {
          items = patterns;
          patternIdToUserName = idToUserName;
          patternIdToImageUrl = idToImageUrl;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load patterns: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading patterns: $e';
      });
    }
  }

  BeadsPattern _parsePatternFromJson(Map<String, dynamic> json) {
    // Parse matrix
    List<List<Color?>> matrix = [];
    final matrixData = json['matrix'] as List<dynamic>;

    for (var rowData in matrixData) {
      final row = (rowData as List<dynamic>)
          .map((e) => e == null ? null : Color(int.parse(e.toString())))
          .toList();
      matrix.add(row);
    }

    // Parse colors
    List<Color> colors = [];
    final colorsData = json['colors'] as List<dynamic>;
    for (var colorData in colorsData) {
      colors.add(Color(int.parse(colorData.toString())));
    }

    // Create pattern
    return BeadsPattern(
      name: json['name'] as String?,
      id: json['id'] as String?,
      patternId: json['patternId'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      matrix: matrix,
      colors: colors,
      rowsPattern: json['rowsPattern'] as Map<String, dynamic>?,
      columnsPattern: json['columnsPattern'] as Map<String, dynamic>?,
    );
  }

  // Get filtered patterns based on selected filter
  List<BeadsPattern> getFilteredPatterns() {
    if (selectedFilter == null) {
      return items;
    }
    return items.where((pattern) => pattern.patternId == selectedFilter).toList();
  }

  // Get unique pattern types from current collection
  List<String> getAvailablePatternTypes() {
    return items
        .map((pattern) => pattern.patternId)
        .where((id) => id != null)
        .cast<String>()
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchCommunityPatterns,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredItems = getFilteredPatterns();
    final availablePatternTypes = getAvailablePatternTypes();

    return Column(
      children: [
        // Filter dropdown
        if (availablePatternTypes.isNotEmpty)
          PatternFilter(
            selectedFilter: selectedFilter,
            onFilterChanged: (String? newValue) {
              setState(() {
                selectedFilter = newValue;
              });
            },
            availablePatterns: availablePatternTypes,
          ),

        // Patterns grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: filteredItems.isEmpty
                ? const Center(
                    child: Text(
                      'No patterns found',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : GridView.count(
                    childAspectRatio: 0.9,
                    crossAxisCount: 2,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    children: filteredItems.map((pattern) {
                      final userName = pattern.id != null && patternIdToUserName.containsKey(pattern.id!)
                          ? patternIdToUserName[pattern.id!]!
                          : 'Unknown';
                      final imageUrl = pattern.id != null && patternIdToImageUrl.containsKey(pattern.id!)
                          ? patternIdToImageUrl[pattern.id!]
                          : null;

                      BeadsPattern item = BeadsPattern(
                          width: pattern.width,
                          height: pattern.height,
                          patternId: pattern.patternId,
                          matrix: [...pattern.matrix!],
                          name: pattern.name,
                          colors: pattern.colors,
                          xdelta: pattern.xdelta,
                          ydelta: pattern.ydelta,
                          id: pattern.id);

                      return InkWell(
                        onTap: () => Navigator.of(context)
                            .pushNamed(EditPatternScreen.routeName, arguments: item),
                        child: Card(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: imageUrl != null
                                    ? Container(
                                        width: double.infinity,
                                        height: 120,
                                        alignment: Alignment.center,
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.contain,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              height: 120,
                                              width: double.infinity,
                                              color: Colors.grey[300],
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                          loadingProgress.expectedTotalBytes!
                                                      : null,
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            // If image fails to load, show a placeholder
                                            return Container(
                                              height: 120,
                                              width: double.infinity,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.image,
                                                size: 60,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : Container(
                                        height: 120,
                                        width: double.infinity,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image,
                                          size: 60,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.name ?? item.patternId,
                                      style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    if (userName.isNotEmpty && userName != 'Unknown')
                                      Text(
                                        'from $userName',
                                        style: TextStyle(
                                            color: Theme.of(context).primaryColor.withOpacity(0.7),
                                            fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }
}

