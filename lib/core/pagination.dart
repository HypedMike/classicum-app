class Paginated<T> {
  const Paginated({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });

  final List<T> items;
  final int page;
  final int total;
  final bool hasMore;
}
