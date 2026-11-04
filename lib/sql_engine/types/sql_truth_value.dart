/// SQL's three-valued logical domain.
///
/// UNKNOWN is not the same as FALSE. In a WHERE clause only TRUE qualifies.
enum SqlTruthValue {
  trueValue,
  falseValue,
  unknown;

  static SqlTruthValue fromNullableBool(bool? value) {
    if (value == null) return SqlTruthValue.unknown;
    return value ? SqlTruthValue.trueValue : SqlTruthValue.falseValue;
  }

}

extension SqlTruthValueOperations on SqlTruthValue {
  SqlTruthValue not() => switch (this) {
        SqlTruthValue.trueValue => SqlTruthValue.falseValue,
        SqlTruthValue.falseValue => SqlTruthValue.trueValue,
        SqlTruthValue.unknown => SqlTruthValue.unknown,
      };

  SqlTruthValue and(SqlTruthValue other) {
    if (this == SqlTruthValue.falseValue ||
        other == SqlTruthValue.falseValue) {
      return SqlTruthValue.falseValue;
    }
    if (this == SqlTruthValue.unknown ||
        other == SqlTruthValue.unknown) {
      return SqlTruthValue.unknown;
    }
    return SqlTruthValue.trueValue;
  }

  SqlTruthValue or(SqlTruthValue other) {
    if (this == SqlTruthValue.trueValue ||
        other == SqlTruthValue.trueValue) {
      return SqlTruthValue.trueValue;
    }
    if (this == SqlTruthValue.unknown ||
        other == SqlTruthValue.unknown) {
      return SqlTruthValue.unknown;
    }
    return SqlTruthValue.falseValue;
  }

  bool passesWhere() => this == SqlTruthValue.trueValue;


}
