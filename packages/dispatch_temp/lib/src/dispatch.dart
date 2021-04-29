class Typename {
  const Typename({required this.type, required this.name});

  final String type;
  final String? name;

  @override
  String toString() {
    return {
      'type': type,
      'name': name,
    }.toString();
  }
}

class DispatchCallback {
  DispatchCallback({
    required this.name,
    required this.value,
  });

  final String? name;
  Function() value;

  @override
  String toString() {
    return {
      'name': name,
      'value': value,
    }.toString();
  }
}

class Dispatch {
  Dispatch(Set<String> events) : _events = {} {
    for (final e in events) {
      if (e.isEmpty || e.contains(RegExp(r'[\s.]')))
        throw Exception('Illegal type: $e');
      _events[e] = [];
    }
  }

  /// `_events` is of the form:
  ///
  /// `{
  ///   event: [
  ///     foo: () {},
  ///     null: () {}
  ///   ]
  /// }
  ///
  final Map<String, List<DispatchCallback>> _events;

  List<Typename> parseTypenames(String typenames) {
    return typenames.trim().split(RegExp(r'^|\s+')).map((match) {
      late final String type;
      String? name;

      final int i = match.indexOf(RegExp(r'\.'));

      if (i >= 0) {
        type = match.substring(0, i);
        name = match.substring(i + 1);
      } else {
        type = match;
      }

      if (type.isNotEmpty && !_events.containsKey(type))
        throw Exception('Unknown type: $type');

      return Typename(type: type, name: name);
    }).toList();
  }

  Function()? onEvent(
    String typename, {
    Function()? callback,
    bool shouldRemove = false,
  }) {
    final typenames = parseTypenames(typename);
    final n = typenames.length;
    int i = 0;

    /// If no callback specified, return callback associated with the given
    /// [Typename].
    if (callback == null && !shouldRemove) {
      Function()? currentCallback;

      while (i < n) {
        final typename = typenames[i];
        currentCallback = getCallback(_events[typename.type], typename.name);
        if (currentCallback != null) break;
        i++;
      }

      return currentCallback;
    }

    /// If a type was specified, setCallback the callback for the given type and name.
    /// Otherwise, if a null callback was specified, remove callbacks
    /// of the given name
    while (i < n) {
      final typename = typenames[i];
      i++;

      if (callback == null) {
        for (final e in _events.keys) {
          _events[e] = setCallback(_events[e], typename.name, null) ?? [];
        }
        continue;
      }

      _events[typename.type] =
          setCallback(_events[typename.type], typename.name, callback) ?? [];
    }

    return callback;
  }

  Function()? getCallback(List<DispatchCallback>? dcs, String? name) {
    if (dcs == null) return null;

    for (final dc in dcs) {
      if (dc.name == name) return dc.value;
    }
  }

  List<DispatchCallback>? setCallback(
    List<DispatchCallback>? dcs,
    String? name,
    Function()? callback,
  ) {
    if (dcs == null) return null;

    final n = dcs.length;
    for (int i = 0; i < n; i++) {
      if (dcs[i].name == name) {
        dcs.removeAt(i);
        break;
      }
    }

    if (callback != null)
      dcs.add(DispatchCallback(
        name: name,
        value: callback,
      ));
    return dcs;
  }
}
