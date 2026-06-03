import '../../models/optimus_models.dart';

/// Pagination helper for large glucose reading datasets.
class ReadingsPaginator {
  ReadingsPaginator({
    required List<OptimusGlucoseReading> allReadings,
    this.pageSize = 100,
  }) : _allReadings = List.unmodifiable(allReadings);

  final List<OptimusGlucoseReading> _allReadings;
  final int pageSize;

  int _currentPage = 0;

  /// Total number of readings available.
  int get totalCount => _allReadings.length;

  /// Total number of pages.
  int get totalPages => (totalCount / pageSize).ceil();

  /// Current page index (0-based).
  int get currentPage => _currentPage;

  /// Whether more pages are available.
  bool get hasMore => _currentPage < totalPages - 1;

  /// Get readings for the current page.
  List<OptimusGlucoseReading> get currentPageReadings {
    final start = _currentPage * pageSize;
    final end = (start + pageSize).clamp(0, totalCount);
    return _allReadings.sublist(start, end);
  }

  /// Get all readings loaded so far (pages 0 through currentPage).
  List<OptimusGlucoseReading> get loadedReadings {
    final end = ((_currentPage + 1) * pageSize).clamp(0, totalCount);
    return _allReadings.sublist(0, end);
  }

  /// Load the next page. Returns the newly loaded readings.
  List<OptimusGlucoseReading> loadNext() {
    if (!hasMore) return const [];
    _currentPage++;
    return currentPageReadings;
  }

  /// Reset to the first page.
  void reset() {
    _currentPage = 0;
  }

  /// Jump to a specific page.
  void goToPage(int page) {
    _currentPage = page.clamp(0, totalPages - 1);
  }
}
