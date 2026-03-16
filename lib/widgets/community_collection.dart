import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rosario/models/pattern.dart';
import 'package:rosario/screens/edit.dart';
import 'package:rosario/widgets/pattern_filter.dart';
import 'package:rosario/services/user_prefs_service.dart';
import 'package:rosario/screens/settings.dart';

class CommunityCollection extends StatefulWidget {
  const CommunityCollection({super.key});

  @override
  State<CommunityCollection> createState() => _CommunityCollectionState();
}

class _CommunityCollectionState extends State<CommunityCollection> {
  static const int MAX_PATTERNS =
      5; // For testing, limit free users to 5 patterns

  List<BeadsPattern> items = [];
  Map<String, String> patternIdToUserName = {}; // Map pattern ID to user name
  Map<String, String> patternIdToImageUrl = {}; // Map pattern ID to image URL
  String? selectedFilter;
  bool isLoading = true;
  String? errorMessage;
  bool isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
    _fetchCommunityPatterns();
  }

  Future<void> _checkSubscriptionStatus() async {
    final subscribed = await UserPrefsService.isSubscribed();
    setState(() {
      isSubscribed = subscribed;
    });
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
    List<BeadsPattern> filtered = selectedFilter == null
        ? items
        : items
            .where((pattern) => pattern.patternId == selectedFilter)
            .toList();

    // Limit patterns for free users
    if (!isSubscribed && filtered.length > MAX_PATTERNS) {
      return filtered.take(MAX_PATTERNS).toList();
    }

    return filtered;
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
    final allFilteredItems = selectedFilter == null
        ? items
        : items
            .where((pattern) => pattern.patternId == selectedFilter)
            .toList();
    final showSubscribeButton =
        !isSubscribed && allFilteredItems.length > MAX_PATTERNS;

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
                : Builder(
                    builder: (context) {
                      final width = MediaQuery.of(context).size.width;
                      final isMediumOrLarger = width >= 600;
                      final crossAxisCount = isMediumOrLarger ? 3 : 2;
                      final childAspectRatio = isMediumOrLarger ? 0.8 : 0.9;
                      return GridView.count(
                        childAspectRatio: childAspectRatio,
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        children: filteredItems.map((pattern) {
                          final userName = pattern.id != null &&
                                  patternIdToUserName.containsKey(pattern.id!)
                              ? patternIdToUserName[pattern.id!]!
                              : 'Unknown';
                          final imageUrl = pattern.id != null &&
                                  patternIdToImageUrl.containsKey(pattern.id!)
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
                            onTap: () => Navigator.of(context).pushNamed(
                                EditPatternScreen.routeName,
                                arguments: item),
                            child: Card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 8.0, left: 4, right: 4),
                                      child: imageUrl != null
                                          ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.contain,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Container(
                                                  width: double.infinity,
                                                  color: Colors.grey[300],
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      value: loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  width: double.infinity,
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.image,
                                                    size: 60,
                                                    color: Colors.grey,
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              width: double.infinity,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.image,
                                                size: 60,
                                                color: Colors.grey,
                                              ),
                                            ),
                                    ),
                                  ),
                                  Container(
                                    height: 56,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 6.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          item.name ?? item.patternId,
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                        if (userName.isNotEmpty &&
                                            userName != 'Unknown')
                                          Text(
                                            'from $userName',
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .primaryColor
                                                    .withOpacity(0.7),
                                                fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
          ),
        ),

        // Subscribe button for free users (below the list)
        if (showSubscribeButton)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Theme.of(context).primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Showing ${filteredItems.length} of ${allFilteredItems.length} patterns',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.of(context)
                            .pushNamed(SettingsScreen.routeName);
                        // Refresh subscription status when returning from settings
                        _checkSubscriptionStatus();
                      },
                      icon: const Icon(Icons.card_membership),
                      label: const Text('Subscribe to show more'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Note about sharing patterns (at the very bottom)
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
          child: Card(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Share your own patterns with the Community! It will be checked and shown for everyone!',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
