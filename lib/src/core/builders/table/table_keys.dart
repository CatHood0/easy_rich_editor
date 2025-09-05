class TableKeys {
  TableKeys._();

  static const String key = 'Table';
  static const String columnKey = 'Column';

  /// Specifies the number of columns into the [Table]
  ///
  /// It must be updated each time that 
  /// we add a new column
  static const String columnNumKey = 'Column-num';

  /// Specifies the number of rows into every column [Node]
  ///
  /// It must be updated each time that 
  /// we add a new row 
  static const String rowNumKey = 'Row-per-column-num';
}
