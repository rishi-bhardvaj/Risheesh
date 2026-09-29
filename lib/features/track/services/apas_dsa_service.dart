import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/network/feed_utils.dart';

/// A LeetCode problem in the shape APAS (com.freetymekiyan.apas) models it:
/// frontend id, title, slug, difficulty, topic tags and acceptance rate.
class ApasDsaProblem {
  final int id;
  final String title;
  final String slug;
  final String difficulty;
  final String topic;
  final String url;
  final List<String> topicTags;
  final double? acRate;
  final bool paidOnly;

  const ApasDsaProblem({
    required this.id,
    required this.title,
    required this.slug,
    required this.difficulty,
    required this.topic,
    required this.url,
    this.topicTags = const [],
    this.acRate,
    this.paidOnly = false,
  });

  String get displayTitle => '$id. $title';
}

class DsaFetchResult {
  final List<ApasDsaProblem> problems;
  final bool fromNetwork;
  final int pagesRequested;
  final int pagesFailed;
  final String? error;

  const DsaFetchResult({
    required this.problems,
    required this.fromNetwork,
    this.pagesRequested = 0,
    this.pagesFailed = 0,
    this.error,
  });
}

class DsaSyncResult {
  final int added;
  final int alreadyTracked;
  final DsaFetchResult fetch;

  const DsaSyncResult({required this.added, required this.alreadyTracked, required this.fetch});

  String get summary {
    final source = fetch.fromNetwork ? 'LeetCode' : 'the offline bank (LeetCode unreachable)';
    final partial = fetch.fromNetwork && fetch.pagesFailed > 0
        ? ' · ${fetch.pagesFailed}/${fetch.pagesRequested} pages failed'
        : '';
    return 'Synced ${fetch.problems.length} problems from $source · $added new · $alreadyTracked already tracked$partial';
  }
}

class ApasDsaService {
  final AppDatabase db;
  final http.Client _client;
  static const _uuid = Uuid();
  static const pageSize = 100; // LeetCode caps questionList at 100 per request

  ApasDsaService({required this.db, http.Client? client}) : _client = client ?? http.Client();

  static const _query = r'''
query problemsetQuestionList($categorySlug: String, $limit: Int, $skip: Int, $filters: QuestionListFilterInput) {
  problemsetQuestionList: questionList(categorySlug: $categorySlug, limit: $limit, skip: $skip, filters: $filters) {
    total: totalNum
    questions: data {
      acRate
      difficulty
      frontendQuestionId: questionFrontendId
      paidOnly: isPaidOnly
      title
      titleSlug
      topicTags { name slug }
    }
  }
}''';

  /// Fetches [targetCount] problems in parallel pages of 100
  /// (`skip: 0, 100, 200, ...`). Pages fail independently; the offline bank
  /// is used only when every page fails.
  Future<DsaFetchResult> fetchProblems({int targetCount = 500}) async {
    final pages = (targetCount / pageSize).ceil().clamp(1, 20);
    final results = await Future.wait(List.generate(pages, (i) => _fetchPage(i * pageSize)));

    final problems = <ApasDsaProblem>[];
    var failed = 0;
    String? firstError;
    for (final r in results) {
      if (r.$1 != null) {
        problems.addAll(r.$1!);
      } else {
        failed++;
        firstError ??= r.$2;
      }
    }
    if (problems.isEmpty) {
      return DsaFetchResult(
        problems: offlineBank,
        fromNetwork: false,
        pagesRequested: pages,
        pagesFailed: failed,
        error: firstError,
      );
    }
    problems.sort((a, b) => a.id.compareTo(b.id));
    return DsaFetchResult(problems: problems, fromNetwork: true, pagesRequested: pages, pagesFailed: failed, error: firstError);
  }

  Future<(List<ApasDsaProblem>?, String?)> _fetchPage(int skip) async {
    try {
      final response = await _client
          .post(
            Uri.parse('https://leetcode.com/graphql'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Referer': 'https://leetcode.com/problemset/',
              'User-Agent': FeedUtils.userAgent,
            },
            body: jsonEncode({
              'query': _query,
              // "algorithms" excludes LeetCode's SQL, shell and concurrency sets.
              'variables': {'categorySlug': 'algorithms', 'skip': skip, 'limit': pageSize, 'filters': {}},
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return (null, 'HTTP ${response.statusCode}');
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final list = (data['data']?['problemsetQuestionList']?['questions'] as List<dynamic>?) ?? const [];
      return (list.whereType<Map<String, dynamic>>().map(parseQuestion).whereType<ApasDsaProblem>().toList(), null);
    } catch (e) {
      return (null, e.toString());
    }
  }

  static ApasDsaProblem? parseQuestion(Map<String, dynamic> q) {
    final slug = q['titleSlug']?.toString();
    final id = int.tryParse(q['frontendQuestionId']?.toString() ?? '');
    if (slug == null || slug.isEmpty || id == null) return null;
    final tags = (q['topicTags'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList();
    return ApasDsaProblem(
      id: id,
      title: q['title']?.toString() ?? slug,
      slug: slug,
      difficulty: normalizeDifficulty(q['difficulty']?.toString()),
      topic: topicForTags(tags.map((t) => t['slug']?.toString() ?? '').toList()),
      url: 'https://leetcode.com/problems/$slug/',
      topicTags: tags.map((t) => t['name']?.toString() ?? '').where((n) => n.isNotEmpty).toList(),
      acRate: (q['acRate'] as num?)?.toDouble(),
      paidOnly: q['paidOnly'] == true,
    );
  }

  /// Fetches and inserts problems not already tracked (matched by LeetCode
  /// slug, falling back to title), in one batch.
  Future<DsaSyncResult> sync({int limit = 500}) async {
    final fetch = await fetchProblems(targetCount: limit);
    final existing = await db.getAllDSAProblems();
    final seenSlugs = existing.map((p) => slugFromUrl(p.url)).whereType<String>().toSet();
    final seenTitles = existing.map((p) => _titleKey(p.title)).toSet();

    final now = DateTime.now();
    final inserts = <DSAProblemsCompanion>[];
    var skipped = 0;
    for (final p in fetch.problems.take(limit)) {
      if (seenSlugs.contains(p.slug) || seenTitles.contains(_titleKey(p.title))) {
        skipped++;
        continue;
      }
      seenSlugs.add(p.slug);
      inserts.add(DSAProblemsCompanion(
        id: drift.Value(_uuid.v4()),
        title: drift.Value(FeedUtils.truncate(p.displayTitle, 200)),
        platform: const drift.Value('LeetCode'),
        url: drift.Value(p.url),
        topic: drift.Value(p.topic),
        difficulty: drift.Value(p.difficulty),
        status: const drift.Value('TODO'),
        attempts: const drift.Value(0),
        notes: drift.Value(notesFor(p)),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ));
    }
    if (inserts.isNotEmpty) {
      await db.batch((b) => b.insertAll(db.dSAProblems, inserts));
    }
    return DsaSyncResult(added: inserts.length, alreadyTracked: skipped, fetch: fetch);
  }

  /// Kept for existing callers: returns the number of newly added problems.
  Future<int> syncProblemsToDatabase({int limit = 500}) async => (await sync(limit: limit)).added;

  static String notesFor(ApasDsaProblem p) => [
        if (p.topicTags.isNotEmpty) 'Tags: ${p.topicTags.join(', ')}',
        if (p.acRate != null) 'Acceptance: ${p.acRate!.toStringAsFixed(1)}%',
        if (p.paidOnly) 'LeetCode Premium',
      ].join('\n');

  static String? slugFromUrl(String? url) =>
      url == null ? null : RegExp(r'leetcode\.com/problems/([a-z0-9-]+)').firstMatch(url)?.group(1);

  static String _titleKey(String title) =>
      title.toLowerCase().replaceFirst(RegExp(r'^\d+\.\s*'), '').replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  static String normalizeDifficulty(String? diff) {
    final lower = (diff ?? '').toLowerCase();
    if (lower.contains('easy')) return 'EASY';
    if (lower.contains('hard')) return 'HARD';
    return 'MEDIUM';
  }

  /// Picks the most specific NeetCode-style category from LeetCode tag
  /// slugs. Order matters: nearly every problem is tagged `array`, so the
  /// generic buckets come last, and tree tags win over `depth-first-search`.
  static String topicForTags(List<String> slugs) {
    final s = slugs.toSet();
    bool any(List<String> xs) => xs.any(s.contains);
    if (any(['dynamic-programming', 'memoization'])) return 'Dynamic Programming';
    if (any(['backtracking'])) return 'Backtracking';
    if (any(['trie'])) return 'Trie';
    if (any(['tree', 'binary-tree', 'binary-search-tree'])) return 'Trees';
    if (any(['graph', 'topological-sort', 'union-find', 'shortest-path', 'minimum-spanning-tree',
        'breadth-first-search', 'depth-first-search'])) {
      return 'Graphs';
    }
    if (any(['heap-priority-queue'])) return 'Heap / Priority Queue';
    if (any(['linked-list', 'doubly-linked-list'])) return 'Linked List';
    if (any(['sliding-window'])) return 'Sliding Window';
    if (any(['binary-search'])) return 'Binary Search';
    if (any(['stack', 'monotonic-stack', 'queue', 'monotonic-queue'])) return 'Stack';
    if (any(['two-pointers'])) return 'Two Pointers';
    if (any(['greedy'])) return 'Greedy';
    if (any(['line-sweep'])) return 'Intervals';
    if (any(['string', 'string-matching'])) return 'Strings';
    if (any(['bit-manipulation'])) return 'Math & Bit Manipulation';
    if (any(['array', 'hash-table', 'matrix', 'sorting', 'prefix-sum', 'counting'])) return 'Arrays & Hashing';
    if (any(['math', 'geometry', 'number-theory'])) return 'Math & Bit Manipulation';
    return 'Other';
  }

  /// NeetCode-style offline bank (146 problems) used when LeetCode is
  /// unreachable. Records are (id, title, slug, difficulty, topic, premium).
  static final List<ApasDsaProblem> offlineBank = [
    for (final r in _bank)
      ApasDsaProblem(
        id: r.$1,
        title: r.$2,
        slug: r.$3,
        difficulty: r.$4,
        topic: r.$5,
        url: 'https://leetcode.com/problems/${r.$3}/',
        paidOnly: r.$6,
      ),
  ];

  static const _e = 'EASY', _m = 'MEDIUM', _h = 'HARD';
  static const _bank = <(int, String, String, String, String, bool)>[
    // Arrays & Hashing
    (1, 'Two Sum', 'two-sum', _e, 'Arrays & Hashing', false),
    (217, 'Contains Duplicate', 'contains-duplicate', _e, 'Arrays & Hashing', false),
    (242, 'Valid Anagram', 'valid-anagram', _e, 'Arrays & Hashing', false),
    (169, 'Majority Element', 'majority-element', _e, 'Arrays & Hashing', false),
    (49, 'Group Anagrams', 'group-anagrams', _m, 'Arrays & Hashing', false),
    (347, 'Top K Frequent Elements', 'top-k-frequent-elements', _m, 'Arrays & Hashing', false),
    (238, 'Product of Array Except Self', 'product-of-array-except-self', _m, 'Arrays & Hashing', false),
    (36, 'Valid Sudoku', 'valid-sudoku', _m, 'Arrays & Hashing', false),
    (128, 'Longest Consecutive Sequence', 'longest-consecutive-sequence', _m, 'Arrays & Hashing', false),
    (271, 'Encode and Decode Strings', 'encode-and-decode-strings', _m, 'Arrays & Hashing', true),
    (560, 'Subarray Sum Equals K', 'subarray-sum-equals-k', _m, 'Arrays & Hashing', false),
    (41, 'First Missing Positive', 'first-missing-positive', _h, 'Arrays & Hashing', false),
    // Strings
    (14, 'Longest Common Prefix', 'longest-common-prefix', _e, 'Strings', false),
    (13, 'Roman to Integer', 'roman-to-integer', _e, 'Strings', false),
    (28, 'Find the Index of the First Occurrence in a String', 'find-the-index-of-the-first-occurrence-in-a-string', _e, 'Strings', false),
    (344, 'Reverse String', 'reverse-string', _e, 'Strings', false),
    (387, 'First Unique Character in a String', 'first-unique-character-in-a-string', _e, 'Strings', false),
    (8, 'String to Integer (atoi)', 'string-to-integer-atoi', _m, 'Strings', false),
    (6, 'Zigzag Conversion', 'zigzag-conversion', _m, 'Strings', false),
    (151, 'Reverse Words in a String', 'reverse-words-in-a-string', _m, 'Strings', false),
    (438, 'Find All Anagrams in a String', 'find-all-anagrams-in-a-string', _m, 'Strings', false),
    // Two Pointers
    (125, 'Valid Palindrome', 'valid-palindrome', _e, 'Two Pointers', false),
    (283, 'Move Zeroes', 'move-zeroes', _e, 'Two Pointers', false),
    (167, 'Two Sum II - Input Array Is Sorted', 'two-sum-ii-input-array-is-sorted', _m, 'Two Pointers', false),
    (15, '3Sum', '3sum', _m, 'Two Pointers', false),
    (11, 'Container With Most Water', 'container-with-most-water', _m, 'Two Pointers', false),
    (75, 'Sort Colors', 'sort-colors', _m, 'Two Pointers', false),
    (42, 'Trapping Rain Water', 'trapping-rain-water', _h, 'Two Pointers', false),
    // Sliding Window
    (121, 'Best Time to Buy and Sell Stock', 'best-time-to-buy-and-sell-stock', _e, 'Sliding Window', false),
    (3, 'Longest Substring Without Repeating Characters', 'longest-substring-without-repeating-characters', _m, 'Sliding Window', false),
    (424, 'Longest Repeating Character Replacement', 'longest-repeating-character-replacement', _m, 'Sliding Window', false),
    (567, 'Permutation in String', 'permutation-in-string', _m, 'Sliding Window', false),
    (76, 'Minimum Window Substring', 'minimum-window-substring', _h, 'Sliding Window', false),
    (239, 'Sliding Window Maximum', 'sliding-window-maximum', _h, 'Sliding Window', false),
    // Stack
    (20, 'Valid Parentheses', 'valid-parentheses', _e, 'Stack', false),
    (155, 'Min Stack', 'min-stack', _m, 'Stack', false),
    (150, 'Evaluate Reverse Polish Notation', 'evaluate-reverse-polish-notation', _m, 'Stack', false),
    (22, 'Generate Parentheses', 'generate-parentheses', _m, 'Stack', false),
    (739, 'Daily Temperatures', 'daily-temperatures', _m, 'Stack', false),
    (853, 'Car Fleet', 'car-fleet', _m, 'Stack', false),
    (84, 'Largest Rectangle in Histogram', 'largest-rectangle-in-histogram', _h, 'Stack', false),
    // Binary Search
    (704, 'Binary Search', 'binary-search', _e, 'Binary Search', false),
    (74, 'Search a 2D Matrix', 'search-a-2d-matrix', _m, 'Binary Search', false),
    (875, 'Koko Eating Bananas', 'koko-eating-bananas', _m, 'Binary Search', false),
    (153, 'Find Minimum in Rotated Sorted Array', 'find-minimum-in-rotated-sorted-array', _m, 'Binary Search', false),
    (33, 'Search in Rotated Sorted Array', 'search-in-rotated-sorted-array', _m, 'Binary Search', false),
    (981, 'Time Based Key-Value Store', 'time-based-key-value-store', _m, 'Binary Search', false),
    (4, 'Median of Two Sorted Arrays', 'median-of-two-sorted-arrays', _h, 'Binary Search', false),
    // Linked List
    (206, 'Reverse Linked List', 'reverse-linked-list', _e, 'Linked List', false),
    (21, 'Merge Two Sorted Lists', 'merge-two-sorted-lists', _e, 'Linked List', false),
    (141, 'Linked List Cycle', 'linked-list-cycle', _e, 'Linked List', false),
    (143, 'Reorder List', 'reorder-list', _m, 'Linked List', false),
    (19, 'Remove Nth Node From End of List', 'remove-nth-node-from-end-of-list', _m, 'Linked List', false),
    (138, 'Copy List with Random Pointer', 'copy-list-with-random-pointer', _m, 'Linked List', false),
    (2, 'Add Two Numbers', 'add-two-numbers', _m, 'Linked List', false),
    (287, 'Find the Duplicate Number', 'find-the-duplicate-number', _m, 'Linked List', false),
    (146, 'LRU Cache', 'lru-cache', _m, 'Linked List', false),
    (23, 'Merge k Sorted Lists', 'merge-k-sorted-lists', _h, 'Linked List', false),
    (25, 'Reverse Nodes in k-Group', 'reverse-nodes-in-k-group', _h, 'Linked List', false),
    // Trees
    (226, 'Invert Binary Tree', 'invert-binary-tree', _e, 'Trees', false),
    (104, 'Maximum Depth of Binary Tree', 'maximum-depth-of-binary-tree', _e, 'Trees', false),
    (543, 'Diameter of Binary Tree', 'diameter-of-binary-tree', _e, 'Trees', false),
    (110, 'Balanced Binary Tree', 'balanced-binary-tree', _e, 'Trees', false),
    (100, 'Same Tree', 'same-tree', _e, 'Trees', false),
    (572, 'Subtree of Another Tree', 'subtree-of-another-tree', _e, 'Trees', false),
    (235, 'Lowest Common Ancestor of a Binary Search Tree', 'lowest-common-ancestor-of-a-binary-search-tree', _m, 'Trees', false),
    (102, 'Binary Tree Level Order Traversal', 'binary-tree-level-order-traversal', _m, 'Trees', false),
    (199, 'Binary Tree Right Side View', 'binary-tree-right-side-view', _m, 'Trees', false),
    (1448, 'Count Good Nodes in Binary Tree', 'count-good-nodes-in-binary-tree', _m, 'Trees', false),
    (98, 'Validate Binary Search Tree', 'validate-binary-search-tree', _m, 'Trees', false),
    (230, 'Kth Smallest Element in a BST', 'kth-smallest-element-in-a-bst', _m, 'Trees', false),
    (105, 'Construct Binary Tree from Preorder and Inorder Traversal', 'construct-binary-tree-from-preorder-and-inorder-traversal', _m, 'Trees', false),
    (124, 'Binary Tree Maximum Path Sum', 'binary-tree-maximum-path-sum', _h, 'Trees', false),
    (297, 'Serialize and Deserialize Binary Tree', 'serialize-and-deserialize-binary-tree', _h, 'Trees', false),
    // Trie
    (208, 'Implement Trie (Prefix Tree)', 'implement-trie-prefix-tree', _m, 'Trie', false),
    (211, 'Design Add and Search Words Data Structure', 'design-add-and-search-words-data-structure', _m, 'Trie', false),
    (212, 'Word Search II', 'word-search-ii', _h, 'Trie', false),
    // Heap / Priority Queue
    (703, 'Kth Largest Element in a Stream', 'kth-largest-element-in-a-stream', _e, 'Heap / Priority Queue', false),
    (1046, 'Last Stone Weight', 'last-stone-weight', _e, 'Heap / Priority Queue', false),
    (973, 'K Closest Points to Origin', 'k-closest-points-to-origin', _m, 'Heap / Priority Queue', false),
    (215, 'Kth Largest Element in an Array', 'kth-largest-element-in-an-array', _m, 'Heap / Priority Queue', false),
    (621, 'Task Scheduler', 'task-scheduler', _m, 'Heap / Priority Queue', false),
    (355, 'Design Twitter', 'design-twitter', _m, 'Heap / Priority Queue', false),
    (295, 'Find Median from Data Stream', 'find-median-from-data-stream', _h, 'Heap / Priority Queue', false),
    // Backtracking
    (78, 'Subsets', 'subsets', _m, 'Backtracking', false),
    (39, 'Combination Sum', 'combination-sum', _m, 'Backtracking', false),
    (46, 'Permutations', 'permutations', _m, 'Backtracking', false),
    (90, 'Subsets II', 'subsets-ii', _m, 'Backtracking', false),
    (40, 'Combination Sum II', 'combination-sum-ii', _m, 'Backtracking', false),
    (79, 'Word Search', 'word-search', _m, 'Backtracking', false),
    (131, 'Palindrome Partitioning', 'palindrome-partitioning', _m, 'Backtracking', false),
    (17, 'Letter Combinations of a Phone Number', 'letter-combinations-of-a-phone-number', _m, 'Backtracking', false),
    (51, 'N-Queens', 'n-queens', _h, 'Backtracking', false),
    // Graphs
    (200, 'Number of Islands', 'number-of-islands', _m, 'Graphs', false),
    (133, 'Clone Graph', 'clone-graph', _m, 'Graphs', false),
    (695, 'Max Area of Island', 'max-area-of-island', _m, 'Graphs', false),
    (417, 'Pacific Atlantic Water Flow', 'pacific-atlantic-water-flow', _m, 'Graphs', false),
    (130, 'Surrounded Regions', 'surrounded-regions', _m, 'Graphs', false),
    (994, 'Rotting Oranges', 'rotting-oranges', _m, 'Graphs', false),
    (207, 'Course Schedule', 'course-schedule', _m, 'Graphs', false),
    (210, 'Course Schedule II', 'course-schedule-ii', _m, 'Graphs', false),
    (684, 'Redundant Connection', 'redundant-connection', _m, 'Graphs', false),
    (323, 'Number of Connected Components in an Undirected Graph', 'number-of-connected-components-in-an-undirected-graph', _m, 'Graphs', true),
    (743, 'Network Delay Time', 'network-delay-time', _m, 'Graphs', false),
    (1584, 'Min Cost to Connect All Points', 'min-cost-to-connect-all-points', _m, 'Graphs', false),
    (787, 'Cheapest Flights Within K Stops', 'cheapest-flights-within-k-stops', _m, 'Graphs', false),
    (127, 'Word Ladder', 'word-ladder', _h, 'Graphs', false),
    // Dynamic Programming
    (70, 'Climbing Stairs', 'climbing-stairs', _e, 'Dynamic Programming', false),
    (746, 'Min Cost Climbing Stairs', 'min-cost-climbing-stairs', _e, 'Dynamic Programming', false),
    (198, 'House Robber', 'house-robber', _m, 'Dynamic Programming', false),
    (213, 'House Robber II', 'house-robber-ii', _m, 'Dynamic Programming', false),
    (5, 'Longest Palindromic Substring', 'longest-palindromic-substring', _m, 'Dynamic Programming', false),
    (647, 'Palindromic Substrings', 'palindromic-substrings', _m, 'Dynamic Programming', false),
    (91, 'Decode Ways', 'decode-ways', _m, 'Dynamic Programming', false),
    (322, 'Coin Change', 'coin-change', _m, 'Dynamic Programming', false),
    (152, 'Maximum Product Subarray', 'maximum-product-subarray', _m, 'Dynamic Programming', false),
    (139, 'Word Break', 'word-break', _m, 'Dynamic Programming', false),
    (300, 'Longest Increasing Subsequence', 'longest-increasing-subsequence', _m, 'Dynamic Programming', false),
    (416, 'Partition Equal Subset Sum', 'partition-equal-subset-sum', _m, 'Dynamic Programming', false),
    (62, 'Unique Paths', 'unique-paths', _m, 'Dynamic Programming', false),
    (1143, 'Longest Common Subsequence', 'longest-common-subsequence', _m, 'Dynamic Programming', false),
    (518, 'Coin Change II', 'coin-change-ii', _m, 'Dynamic Programming', false),
    (72, 'Edit Distance', 'edit-distance', _m, 'Dynamic Programming', false),
    (312, 'Burst Balloons', 'burst-balloons', _h, 'Dynamic Programming', false),
    (10, 'Regular Expression Matching', 'regular-expression-matching', _h, 'Dynamic Programming', false),
    // Greedy
    (53, 'Maximum Subarray', 'maximum-subarray', _m, 'Greedy', false),
    (55, 'Jump Game', 'jump-game', _m, 'Greedy', false),
    (45, 'Jump Game II', 'jump-game-ii', _m, 'Greedy', false),
    (134, 'Gas Station', 'gas-station', _m, 'Greedy', false),
    (846, 'Hand of Straights', 'hand-of-straights', _m, 'Greedy', false),
    (763, 'Partition Labels', 'partition-labels', _m, 'Greedy', false),
    (678, 'Valid Parenthesis String', 'valid-parenthesis-string', _m, 'Greedy', false),
    // Intervals
    (252, 'Meeting Rooms', 'meeting-rooms', _e, 'Intervals', true),
    (57, 'Insert Interval', 'insert-interval', _m, 'Intervals', false),
    (56, 'Merge Intervals', 'merge-intervals', _m, 'Intervals', false),
    (435, 'Non-overlapping Intervals', 'non-overlapping-intervals', _m, 'Intervals', false),
    (253, 'Meeting Rooms II', 'meeting-rooms-ii', _m, 'Intervals', true),
    // Math & Bit Manipulation
    (136, 'Single Number', 'single-number', _e, 'Math & Bit Manipulation', false),
    (191, 'Number of 1 Bits', 'number-of-1-bits', _e, 'Math & Bit Manipulation', false),
    (338, 'Counting Bits', 'counting-bits', _e, 'Math & Bit Manipulation', false),
    (190, 'Reverse Bits', 'reverse-bits', _e, 'Math & Bit Manipulation', false),
    (268, 'Missing Number', 'missing-number', _e, 'Math & Bit Manipulation', false),
    (371, 'Sum of Two Integers', 'sum-of-two-integers', _m, 'Math & Bit Manipulation', false),
    (48, 'Rotate Image', 'rotate-image', _m, 'Math & Bit Manipulation', false),
    (54, 'Spiral Matrix', 'spiral-matrix', _m, 'Math & Bit Manipulation', false),
    (50, 'Pow(x, n)', 'powx-n', _m, 'Math & Bit Manipulation', false),
  ];
}
