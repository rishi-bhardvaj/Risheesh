import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

class ApasDsaProblem {
  final int id;
  final String title;
  final String slug;
  final String difficulty;
  final String topic;
  final String url;
  final String? description;
  final String? solution;
  final List<String> companyTags;

  const ApasDsaProblem({
    required this.id,
    required this.title,
    required this.slug,
    required this.difficulty,
    required this.topic,
    required this.url,
    this.description,
    this.solution,
    this.companyTags = const [],
  });
}

class ApasDsaService {
  final AppDatabase db;
  static const _uuid = Uuid();

  ApasDsaService({required this.db});

  /// Fetches summary of problems from LeetCode GraphQL API with pagination or falls back to offline curated seed
  Future<List<ApasDsaProblem>> fetchApasProblems({
    int targetCount = 500,
    String? category,
    String? difficulty,
    String? tag,
  }) async {
    final allProblems = <ApasDsaProblem>[];
    try {
      final uri = Uri.parse('https://leetcode.com/graphql');
      final pageCount = (targetCount / 100).ceil().clamp(1, 5);

      final futures = List.generate(pageCount, (pageIdx) async {
        final skip = pageIdx * 100;
        final body = jsonEncode({
          "query": "query problemsetQuestionList(\$categorySlug: String, \$limit: Int, \$skip: Int, \$filters: QuestionListFilterInput) { problemsetQuestionList: questionList(categorySlug: \$categorySlug limit: \$limit skip: \$skip filters: \$filters) { total: totalNum questions: data { acRate difficulty frontendQuestionId: questionFrontendId title titleSlug topicTags { name slug } } } }",
          "variables": {
            "categorySlug": category ?? "",
            "skip": skip,
            "limit": 100,
            "filters": {}
          }
        });

        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
          body: body,
        ).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final questionsData = data['data']['problemsetQuestionList']['questions'] as List<dynamic>? ?? [];
          return questionsData.map((item) {
            final idStr = item['frontendQuestionId']?.toString() ?? '0';
            final id = int.tryParse(idStr) ?? 0;
            final title = item['title']?.toString() ?? 'Problem #$id';
            final diff = _normalizeDifficulty(item['difficulty']?.toString());
            final slug = item['titleSlug']?.toString() ?? 'problem-$id';

            final tags = (item['topicTags'] as List<dynamic>?)?.map((t) => t['name']?.toString() ?? '').where((t) => t.isNotEmpty).toList() ?? [];
            final topic = _normalizeTopic(tags.isNotEmpty ? tags.first : '');

            return ApasDsaProblem(
              id: id,
              title: '$idStr. $title',
              slug: slug,
              difficulty: diff,
              topic: topic,
              url: 'https://leetcode.com/problems/$slug/',
              companyTags: tags,
            );
          }).toList();
        }
        return <ApasDsaProblem>[];
      });

      final results = await Future.wait(futures);
      for (final r in results) {
        allProblems.addAll(r);
      }

      if (allProblems.isNotEmpty) {
        return allProblems;
      }
    } catch (e) {
      debugPrint('ApasDsaService: LeetCode GraphQL fetch failed or timed out: $e. Using offline curated bank.');
    }

    return _getCuratedApasSeedBank();
  }

  /// Syncs APAS problems directly into local Drift DSA tracker
  Future<int> syncProblemsToDatabase({int limit = 500}) async {
    final apasProblems = await fetchApasProblems(targetCount: limit);
    int addedCount = 0;

    final existing = await db.getAllDSAProblems();
    final existingTitles = existing.map((p) => p.title.toLowerCase().trim()).toSet();

    for (final prob in apasProblems.take(limit)) {
      if (existingTitles.contains(prob.title.toLowerCase().trim())) {
        continue;
      }

      final companion = DSAProblemsCompanion(
        id: drift.Value(_uuid.v4()),
        title: drift.Value(prob.title),
        platform: const drift.Value('LeetCode'),
        url: drift.Value(prob.url),
        topic: drift.Value(prob.topic),
        difficulty: drift.Value(prob.difficulty),
        status: const drift.Value('TODO'),
        attempts: const drift.Value(0),
        solution: drift.Value(prob.solution),
        notes: drift.Value(prob.companyTags.isNotEmpty
            ? 'Top Companies: ${prob.companyTags.join(', ')}'
            : null),
        createdAt: drift.Value(DateTime.now()),
        updatedAt: drift.Value(DateTime.now()),
      );

      await db.insertDSAProblem(companion);
      addedCount++;
    }

    return addedCount;
  }

  static String _normalizeDifficulty(String? diff) {
    if (diff == null) return 'MEDIUM';
    final lower = diff.toLowerCase();
    if (lower.contains('easy') || lower == '1') return 'EASY';
    if (lower.contains('hard') || lower == '3') return 'HARD';
    return 'MEDIUM';
  }

  static String _normalizeTopic(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('array') || lower.contains('matrix') || lower.contains('hash')) return 'Arrays & Hashing';
    if (lower.contains('two pointer')) return 'Two Pointers';
    if (lower.contains('stack') || lower.contains('queue')) return 'Stack';
    if (lower.contains('binary search') || lower.contains('search')) return 'Binary Search';
    if (lower.contains('sliding')) return 'Sliding Window';
    if (lower.contains('linked')) return 'Linked List';
    if (lower.contains('tree') || lower.contains('bst')) return 'Trees';
    if (lower.contains('heap') || lower.contains('priority')) return 'Heap / Priority Queue';
    if (lower.contains('backtrack')) return 'Backtracking';
    if (lower.contains('graph') || lower.contains('bfs') || lower.contains('dfs') || lower.contains('topological')) return 'Graphs';
    if (lower.contains('dp') || lower.contains('dynamic')) return 'Dynamic Programming';
    if (lower.contains('greedy')) return 'Greedy';
    if (lower.contains('interval')) return 'Intervals';
    if (lower.contains('math') || lower.contains('bit')) return 'Math & Bit Manipulation';
    if (lower.contains('trie')) return 'Trie';
    return 'Arrays & Hashing';
  }

  /// High-yield LeetCode Curated Problem Bank
  List<ApasDsaProblem> _getCuratedApasSeedBank() {
    return const [
      // Arrays & Hashing (10)
      ApasDsaProblem(
        id: 1, title: '1. Two Sum', slug: 'two-sum', difficulty: 'EASY', topic: 'Arrays & Hashing', url: 'https://leetcode.com/problems/two-sum/',
        companyTags: ['Amazon', 'Google', 'Meta', 'Apple', 'Microsoft'], solution: '// Hash Map Approach',
      ),
      ApasDsaProblem(
        id: 217, title: '217. Contains Duplicate', slug: 'contains-duplicate', difficulty: 'EASY', topic: 'Arrays & Hashing', url: 'https://leetcode.com/problems/contains-duplicate/',
        solution: '// HashSet approach',
      ),
      ApasDsaProblem(
        id: 242, title: '242. Valid Anagram', slug: 'valid-anagram', difficulty: 'EASY', topic: 'Arrays & Hashing', url: 'https://leetcode.com/problems/valid-anagram/',
        solution: '// Frequency array approach',
      ),
      ApasDsaProblem(
        id: 49, title: '49. Group Anagrams', slug: 'group-anagrams', difficulty: 'MEDIUM', topic: 'Arrays & Hashing', url: 'https://leetcode.com/problems/group-anagrams/',
        solution: '// HashMap with sorted string keys',
      ),
      ApasDsaProblem(
        id: 347, title: '347. Top K Frequent Elements', slug: 'top-k-frequent-elements', difficulty: 'MEDIUM', topic: 'Arrays & Hashing', url: 'https://leetcode.com/problems/top-k-frequent-elements/',
        solution: '// Bucket sort or PriorityQueue',
      ),
      ApasDsaProblem(
        id: 238, title: '238. Product of Array Except Self', slug: 'product-of-array-except-self', difficulty: 'MEDIUM', topic: 'Arrays & Hashing', url: 'https://leetcode.com/problems/product-of-array-except-self/',
        solution: '// Prefix and Postfix arrays',
      ),
      ApasDsaProblem(
        id: 36, title: '36. Valid Sudoku', slug: 'valid-sudoku', difficulty: 'MEDIUM', topic: 'Arrays & Hashing', url: 'https://leetcode.com/problems/valid-sudoku/',
        solution: '// HashSets for rows, cols, squares',
      ),
      ApasDsaProblem(
        id: 128, title: '128. Longest Consecutive Sequence', slug: 'longest-consecutive-sequence', difficulty: 'MEDIUM', topic: 'Arrays & Hashing', url: 'https://leetcode.com/problems/longest-consecutive-sequence/',
        solution: '// HashSet, check n-1',
      ),
      ApasDsaProblem(
        id: 271, title: '271. Encode and Decode Strings', slug: 'encode-and-decode-strings', difficulty: 'MEDIUM', topic: 'Arrays & Hashing', url: 'https://leetcode.com/problems/encode-and-decode-strings/',
        solution: '// Length + delimiter',
      ),
      ApasDsaProblem(
        id: 14, title: '14. Longest Common Prefix', slug: 'longest-common-prefix', difficulty: 'EASY', topic: 'Arrays & Hashing', url: 'https://leetcode.com/problems/longest-common-prefix/',
        solution: '// Vertical scanning',
      ),

      // Two Pointers (5)
      ApasDsaProblem(
        id: 125, title: '125. Valid Palindrome', slug: 'valid-palindrome', difficulty: 'EASY', topic: 'Two Pointers', url: 'https://leetcode.com/problems/valid-palindrome/',
        solution: '// Two pointers from ends',
      ),
      ApasDsaProblem(
        id: 167, title: '167. Two Sum II', slug: 'two-sum-ii-input-array-is-sorted', difficulty: 'MEDIUM', topic: 'Two Pointers', url: 'https://leetcode.com/problems/two-sum-ii-input-array-is-sorted/',
        solution: '// Two pointers left and right',
      ),
      ApasDsaProblem(
        id: 15, title: '15. 3Sum', slug: '3sum', difficulty: 'MEDIUM', topic: 'Two Pointers', url: 'https://leetcode.com/problems/3sum/',
        solution: '// Sort + Two pointers',
      ),
      ApasDsaProblem(
        id: 11, title: '11. Container With Most Water', slug: 'container-with-most-water', difficulty: 'MEDIUM', topic: 'Two Pointers', url: 'https://leetcode.com/problems/container-with-most-water/',
        solution: '// Two pointers, move smaller height',
      ),
      ApasDsaProblem(
        id: 42, title: '42. Trapping Rain Water', slug: 'trapping-rain-water', difficulty: 'HARD', topic: 'Two Pointers', url: 'https://leetcode.com/problems/trapping-rain-water/',
        solution: '// Two Pointers with max left and max right',
      ),

      // Sliding Window (5)
      ApasDsaProblem(
        id: 121, title: '121. Best Time to Buy and Sell Stock', slug: 'best-time-to-buy-and-sell-stock', difficulty: 'EASY', topic: 'Sliding Window', url: 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock/',
        solution: '// Track min price',
      ),
      ApasDsaProblem(
        id: 3, title: '3. Longest Substring Without Repeating Characters', slug: 'longest-substring-without-repeating-characters', difficulty: 'MEDIUM', topic: 'Sliding Window', url: 'https://leetcode.com/problems/longest-substring-without-repeating-characters/',
        solution: '// Sliding Window + Map',
      ),
      ApasDsaProblem(
        id: 424, title: '424. Longest Repeating Character Replacement', slug: 'longest-repeating-character-replacement', difficulty: 'MEDIUM', topic: 'Sliding Window', url: 'https://leetcode.com/problems/longest-repeating-character-replacement/',
        solution: '// Sliding Window + char counts',
      ),
      ApasDsaProblem(
        id: 567, title: '567. Permutation in String', slug: 'permutation-in-string', difficulty: 'MEDIUM', topic: 'Sliding Window', url: 'https://leetcode.com/problems/permutation-in-string/',
        solution: '// Sliding window with frequency arrays',
      ),
      ApasDsaProblem(
        id: 76, title: '76. Minimum Window Substring', slug: 'minimum-window-substring', difficulty: 'HARD', topic: 'Sliding Window', url: 'https://leetcode.com/problems/minimum-window-substring/',
        solution: '// Sliding window with multiple char counts',
      ),

      // Stack (5)
      ApasDsaProblem(
        id: 20, title: '20. Valid Parentheses', slug: 'valid-parentheses', difficulty: 'EASY', topic: 'Stack', url: 'https://leetcode.com/problems/valid-parentheses/',
        solution: '// Stack-based matching',
      ),
      ApasDsaProblem(
        id: 155, title: '155. Min Stack', slug: 'min-stack', difficulty: 'MEDIUM', topic: 'Stack', url: 'https://leetcode.com/problems/min-stack/',
        solution: '// Two stacks',
      ),
      ApasDsaProblem(
        id: 150, title: '150. Evaluate Reverse Polish Notation', slug: 'evaluate-reverse-polish-notation', difficulty: 'MEDIUM', topic: 'Stack', url: 'https://leetcode.com/problems/evaluate-reverse-polish-notation/',
        solution: '// Stack for operands',
      ),
      ApasDsaProblem(
        id: 22, title: '22. Generate Parentheses', slug: 'generate-parentheses', difficulty: 'MEDIUM', topic: 'Stack', url: 'https://leetcode.com/problems/generate-parentheses/',
        solution: '// Recursion/Stack with open/close counts',
      ),
      ApasDsaProblem(
        id: 739, title: '739. Daily Temperatures', slug: 'daily-temperatures', difficulty: 'MEDIUM', topic: 'Stack', url: 'https://leetcode.com/problems/daily-temperatures/',
        solution: '// Monotonic decreasing stack',
      ),

      // Binary Search (5)
      ApasDsaProblem(
        id: 704, title: '704. Binary Search', slug: 'binary-search', difficulty: 'EASY', topic: 'Binary Search', url: 'https://leetcode.com/problems/binary-search/',
        solution: '// Basic binary search',
      ),
      ApasDsaProblem(
        id: 74, title: '74. Search a 2D Matrix', slug: 'search-a-2d-matrix', difficulty: 'MEDIUM', topic: 'Binary Search', url: 'https://leetcode.com/problems/search-a-2d-matrix/',
        solution: '// Treat as 1D array',
      ),
      ApasDsaProblem(
        id: 875, title: '875. Koko Eating Bananas', slug: 'koko-eating-bananas', difficulty: 'MEDIUM', topic: 'Binary Search', url: 'https://leetcode.com/problems/koko-eating-bananas/',
        solution: '// Binary search on answer',
      ),
      ApasDsaProblem(
        id: 153, title: '153. Find Minimum in Rotated Sorted Array', slug: 'find-minimum-in-rotated-sorted-array', difficulty: 'MEDIUM', topic: 'Binary Search', url: 'https://leetcode.com/problems/find-minimum-in-rotated-sorted-array/',
        solution: '// Binary search comparing to right',
      ),
      ApasDsaProblem(
        id: 33, title: '33. Search in Rotated Sorted Array', slug: 'search-in-rotated-sorted-array', difficulty: 'MEDIUM', topic: 'Binary Search', url: 'https://leetcode.com/problems/search-in-rotated-sorted-array/',
        solution: '// Modified Binary Search',
      ),

      // Linked List (5)
      ApasDsaProblem(
        id: 206, title: '206. Reverse Linked List', slug: 'reverse-linked-list', difficulty: 'EASY', topic: 'Linked List', url: 'https://leetcode.com/problems/reverse-linked-list/',
        solution: '// Iterative in-place pointer reversal',
      ),
      ApasDsaProblem(
        id: 21, title: '21. Merge Two Sorted Lists', slug: 'merge-two-sorted-lists', difficulty: 'EASY', topic: 'Linked List', url: 'https://leetcode.com/problems/merge-two-sorted-lists/',
        solution: '// Dummy head + two pointers',
      ),
      ApasDsaProblem(
        id: 141, title: '141. Linked List Cycle', slug: 'linked-list-cycle', difficulty: 'EASY', topic: 'Linked List', url: 'https://leetcode.com/problems/linked-list-cycle/',
        solution: '// Fast and slow pointers',
      ),
      ApasDsaProblem(
        id: 19, title: '19. Remove Nth Node From End of List', slug: 'remove-nth-node-from-end-of-list', difficulty: 'MEDIUM', topic: 'Linked List', url: 'https://leetcode.com/problems/remove-nth-node-from-end-of-list/',
        solution: '// Two pointers separated by N',
      ),
      ApasDsaProblem(
        id: 138, title: '138. Copy List with Random Pointer', slug: 'copy-list-with-random-pointer', difficulty: 'MEDIUM', topic: 'Linked List', url: 'https://leetcode.com/problems/copy-list-with-random-pointer/',
        solution: '// HashMap or intertwining nodes',
      ),

      // Trees (8)
      ApasDsaProblem(
        id: 226, title: '226. Invert Binary Tree', slug: 'invert-binary-tree', difficulty: 'EASY', topic: 'Trees', url: 'https://leetcode.com/problems/invert-binary-tree/',
        solution: '// Recursive swap left/right',
      ),
      ApasDsaProblem(
        id: 104, title: '104. Maximum Depth of Binary Tree', slug: 'maximum-depth-of-binary-tree', difficulty: 'EASY', topic: 'Trees', url: 'https://leetcode.com/problems/maximum-depth-of-binary-tree/',
        solution: '// Recursive DFS',
      ),
      ApasDsaProblem(
        id: 100, title: '100. Same Tree', slug: 'same-tree', difficulty: 'EASY', topic: 'Trees', url: 'https://leetcode.com/problems/same-tree/',
        solution: '// Recursive comparison',
      ),
      ApasDsaProblem(
        id: 572, title: '572. Subtree of Another Tree', slug: 'subtree-of-another-tree', difficulty: 'EASY', topic: 'Trees', url: 'https://leetcode.com/problems/subtree-of-another-tree/',
        solution: '// Check same tree on each node',
      ),
      ApasDsaProblem(
        id: 235, title: '235. Lowest Common Ancestor of a BST', slug: 'lowest-common-ancestor-of-a-binary-search-tree', difficulty: 'MEDIUM', topic: 'Trees', url: 'https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/',
        solution: '// BST property walk',
      ),
      ApasDsaProblem(
        id: 102, title: '102. Binary Tree Level Order Traversal', slug: 'binary-tree-level-order-traversal', difficulty: 'MEDIUM', topic: 'Trees', url: 'https://leetcode.com/problems/binary-tree-level-order-traversal/',
        solution: '// BFS with Queue',
      ),
      ApasDsaProblem(
        id: 98, title: '98. Validate Binary Search Tree', slug: 'validate-binary-search-tree', difficulty: 'MEDIUM', topic: 'Trees', url: 'https://leetcode.com/problems/validate-binary-search-tree/',
        solution: '// Min/max bounds passing',
      ),
      ApasDsaProblem(
        id: 230, title: '230. Kth Smallest Element in a BST', slug: 'kth-smallest-element-in-a-bst', difficulty: 'MEDIUM', topic: 'Trees', url: 'https://leetcode.com/problems/kth-smallest-element-in-a-bst/',
        solution: '// Inorder traversal',
      ),

      // Heap / Priority Queue (3)
      ApasDsaProblem(
        id: 703, title: '703. Kth Largest Element in a Stream', slug: 'kth-largest-element-in-a-stream', difficulty: 'EASY', topic: 'Heap / Priority Queue', url: 'https://leetcode.com/problems/kth-largest-element-in-a-stream/',
        solution: '// Min heap of size K',
      ),
      ApasDsaProblem(
        id: 1046, title: '1046. Last Stone Weight', slug: 'last-stone-weight', difficulty: 'EASY', topic: 'Heap / Priority Queue', url: 'https://leetcode.com/problems/last-stone-weight/',
        solution: '// Max heap',
      ),
      ApasDsaProblem(
        id: 215, title: '215. Kth Largest Element in an Array', slug: 'kth-largest-element-in-an-array', difficulty: 'MEDIUM', topic: 'Heap / Priority Queue', url: 'https://leetcode.com/problems/kth-largest-element-in-an-array/',
        solution: '// Min heap or QuickSelect',
      ),

      // Backtracking (4)
      ApasDsaProblem(
        id: 78, title: '78. Subsets', slug: 'subsets', difficulty: 'MEDIUM', topic: 'Backtracking', url: 'https://leetcode.com/problems/subsets/',
        solution: '// Pick/not pick backtracking',
      ),
      ApasDsaProblem(
        id: 39, title: '39. Combination Sum', slug: 'combination-sum', difficulty: 'MEDIUM', topic: 'Backtracking', url: 'https://leetcode.com/problems/combination-sum/',
        solution: '// Backtracking with target sum',
      ),
      ApasDsaProblem(
        id: 46, title: '46. Permutations', slug: 'permutations', difficulty: 'MEDIUM', topic: 'Backtracking', url: 'https://leetcode.com/problems/permutations/',
        solution: '// Swap based backtracking',
      ),
      ApasDsaProblem(
        id: 79, title: '79. Word Search', slug: 'word-search', difficulty: 'MEDIUM', topic: 'Backtracking', url: 'https://leetcode.com/problems/word-search/',
        solution: '// DFS on grid',
      ),

      // Graphs (6)
      ApasDsaProblem(
        id: 200, title: '200. Number of Islands', slug: 'number-of-islands', difficulty: 'MEDIUM', topic: 'Graphs', url: 'https://leetcode.com/problems/number-of-islands/',
        solution: '// DFS Flood Fill',
      ),
      ApasDsaProblem(
        id: 133, title: '133. Clone Graph', slug: 'clone-graph', difficulty: 'MEDIUM', topic: 'Graphs', url: 'https://leetcode.com/problems/clone-graph/',
        solution: '// DFS with HashMap',
      ),
      ApasDsaProblem(
        id: 695, title: '695. Max Area of Island', slug: 'max-area-of-island', difficulty: 'MEDIUM', topic: 'Graphs', url: 'https://leetcode.com/problems/max-area-of-island/',
        solution: '// DFS counting area',
      ),
      ApasDsaProblem(
        id: 417, title: '417. Pacific Atlantic Water Flow', slug: 'pacific-atlantic-water-flow', difficulty: 'MEDIUM', topic: 'Graphs', url: 'https://leetcode.com/problems/pacific-atlantic-water-flow/',
        solution: '// DFS from edges',
      ),
      ApasDsaProblem(
        id: 207, title: '207. Course Schedule', slug: 'course-schedule', difficulty: 'MEDIUM', topic: 'Graphs', url: 'https://leetcode.com/problems/course-schedule/',
        solution: '// Topological Sort',
      ),
      ApasDsaProblem(
        id: 323, title: '323. Number of Connected Components in an Undirected Graph', slug: 'number-of-connected-components-in-an-undirected-graph', difficulty: 'MEDIUM', topic: 'Graphs', url: 'https://leetcode.com/problems/number-of-connected-components-in-an-undirected-graph/',
        solution: '// Union Find or DFS',
      ),

      // Dynamic Programming (10)
      ApasDsaProblem(
        id: 70, title: '70. Climbing Stairs', slug: 'climbing-stairs', difficulty: 'EASY', topic: 'Dynamic Programming', url: 'https://leetcode.com/problems/climbing-stairs/',
        solution: '// Fibonacci DP',
      ),
      ApasDsaProblem(
        id: 746, title: '746. Min Cost Climbing Stairs', slug: 'min-cost-climbing-stairs', difficulty: 'EASY', topic: 'Dynamic Programming', url: 'https://leetcode.com/problems/min-cost-climbing-stairs/',
        solution: '// DP array',
      ),
      ApasDsaProblem(
        id: 198, title: '198. House Robber', slug: 'house-robber', difficulty: 'MEDIUM', topic: 'Dynamic Programming', url: 'https://leetcode.com/problems/house-robber/',
        solution: '// DP skip adjacent',
      ),
      ApasDsaProblem(
        id: 213, title: '213. House Robber II', slug: 'house-robber-ii', difficulty: 'MEDIUM', topic: 'Dynamic Programming', url: 'https://leetcode.com/problems/house-robber-ii/',
        solution: '// Run House Robber twice',
      ),
      ApasDsaProblem(
        id: 5, title: '5. Longest Palindromic Substring', slug: 'longest-palindromic-substring', difficulty: 'MEDIUM', topic: 'Dynamic Programming', url: 'https://leetcode.com/problems/longest-palindromic-substring/',
        solution: '// Expand around center',
      ),
      ApasDsaProblem(
        id: 647, title: '647. Palindromic Substrings', slug: 'palindromic-substrings', difficulty: 'MEDIUM', topic: 'Dynamic Programming', url: 'https://leetcode.com/problems/palindromic-substrings/',
        solution: '// Expand around center',
      ),
      ApasDsaProblem(
        id: 91, title: '91. Decode Ways', slug: 'decode-ways', difficulty: 'MEDIUM', topic: 'Dynamic Programming', url: 'https://leetcode.com/problems/decode-ways/',
        solution: '// DP 1D',
      ),
      ApasDsaProblem(
        id: 322, title: '322. Coin Change', slug: 'coin-change', difficulty: 'MEDIUM', topic: 'Dynamic Programming', url: 'https://leetcode.com/problems/coin-change/',
        solution: '// Bottom-Up DP',
      ),
      ApasDsaProblem(
        id: 152, title: '152. Maximum Product Subarray', slug: 'maximum-product-subarray', difficulty: 'MEDIUM', topic: 'Dynamic Programming', url: 'https://leetcode.com/problems/maximum-product-subarray/',
        solution: '// Track min and max',
      ),
      ApasDsaProblem(
        id: 139, title: '139. Word Break', slug: 'word-break', difficulty: 'MEDIUM', topic: 'Dynamic Programming', url: 'https://leetcode.com/problems/word-break/',
        solution: '// DP array of booleans',
      ),

      // Greedy (4)
      ApasDsaProblem(
        id: 53, title: '53. Maximum Subarray', slug: 'maximum-subarray', difficulty: 'MEDIUM', topic: 'Greedy', url: 'https://leetcode.com/problems/maximum-subarray/',
        solution: '// Kadane\'s algorithm',
      ),
      ApasDsaProblem(
        id: 55, title: '55. Jump Game', slug: 'jump-game', difficulty: 'MEDIUM', topic: 'Greedy', url: 'https://leetcode.com/problems/jump-game/',
        solution: '// Track max reachable index',
      ),
      ApasDsaProblem(
        id: 45, title: '45. Jump Game II', slug: 'jump-game-ii', difficulty: 'MEDIUM', topic: 'Greedy', url: 'https://leetcode.com/problems/jump-game-ii/',
        solution: '// BFS-style greedy',
      ),
      ApasDsaProblem(
        id: 134, title: '134. Gas Station', slug: 'gas-station', difficulty: 'MEDIUM', topic: 'Greedy', url: 'https://leetcode.com/problems/gas-station/',
        solution: '// Greedy single pass',
      ),

      // Intervals (3)
      ApasDsaProblem(
        id: 57, title: '57. Insert Interval', slug: 'insert-interval', difficulty: 'MEDIUM', topic: 'Intervals', url: 'https://leetcode.com/problems/insert-interval/',
        solution: '// Iterate and merge',
      ),
      ApasDsaProblem(
        id: 56, title: '56. Merge Intervals', slug: 'merge-intervals', difficulty: 'MEDIUM', topic: 'Intervals', url: 'https://leetcode.com/problems/merge-intervals/',
        solution: '// Sort and merge',
      ),
      ApasDsaProblem(
        id: 435, title: '435. Non-overlapping Intervals', slug: 'non-overlapping-intervals', difficulty: 'MEDIUM', topic: 'Intervals', url: 'https://leetcode.com/problems/non-overlapping-intervals/',
        solution: '// Sort by end time, greedy',
      ),

      // Math & Bit Manipulation (3)
      ApasDsaProblem(
        id: 136, title: '136. Single Number', slug: 'single-number', difficulty: 'EASY', topic: 'Math & Bit Manipulation', url: 'https://leetcode.com/problems/single-number/',
        solution: '// XOR all numbers',
      ),
      ApasDsaProblem(
        id: 191, title: '191. Number of 1 Bits', slug: 'number-of-1-bits', difficulty: 'EASY', topic: 'Math & Bit Manipulation', url: 'https://leetcode.com/problems/number-of-1-bits/',
        solution: '// Bit shift and mask',
      ),
      ApasDsaProblem(
        id: 338, title: '338. Counting Bits', slug: 'counting-bits', difficulty: 'EASY', topic: 'Math & Bit Manipulation', url: 'https://leetcode.com/problems/counting-bits/',
        solution: '// DP with bit shift',
      ),

      // Trie (2)
      ApasDsaProblem(
        id: 208, title: '208. Implement Trie (Prefix Tree)', slug: 'implement-trie-prefix-tree', difficulty: 'MEDIUM', topic: 'Trie', url: 'https://leetcode.com/problems/implement-trie-prefix-tree/',
        solution: '// TrieNode with array of children',
      ),
      ApasDsaProblem(
        id: 211, title: '211. Design Add and Search Words Data Structure', slug: 'design-add-and-search-words-data-structure', difficulty: 'MEDIUM', topic: 'Trie', url: 'https://leetcode.com/problems/design-add-and-search-words-data-structure/',
        solution: '// Trie with DFS for wildcard',
      ),
    ];
  }
}
