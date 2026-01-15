enum SortMode {
  alphabetical,
  custom,
  chronological;

  String toDisplayString() {
    switch (this) {
      case SortMode.alphabetical:
        return 'Alphabetical';
      case SortMode.custom:
        return 'Custom Order';
      case SortMode.chronological:
        return 'Newest First';
    }
  }

  static SortMode fromString(String value) {
    switch (value) {
      case 'alphabetical':
        return SortMode.alphabetical;
      case 'custom':
        return SortMode.custom;
      case 'chronological':
      default:
        return SortMode.chronological;
    }
  }

  @override
  String toString() {
    return name;
  }
}
