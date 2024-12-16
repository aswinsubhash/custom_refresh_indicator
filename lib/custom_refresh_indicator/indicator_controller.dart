part of 'custom_refresh_indicator.dart';

class IndicatorController extends Animation<double> with AnimationEagerListenerMixin, AnimationLocalListenersMixin, AnimationLocalStatusListenersMixin, ClampingWithOverscrollPhysicsState {
  double _value;

  /// Represents the **minimum** value that an indicator can have.
  static double get minValue => 0.0;

  /// Represents the **maximum** value that an indicator can have.
  static double get maxValue => 1.5;

  /// Current indicator value / progress
  @override
  double get value => _value;

  /// Creates [CustomRefreshIndicator] controller class
  factory IndicatorController({
    bool? refreshEnabled,
  }) =>
      IndicatorController._(refreshEnabled: refreshEnabled);

  IndicatorController._({
    double? value,
    AxisDirection? direction,
    ScrollDirection? scrollingDirection,
    IndicatorState? state,
    bool? refreshEnabled,
  })  : _currentState = state ?? IndicatorState.idle,
        _scrollingDirection = scrollingDirection ?? ScrollDirection.idle,
        _direction = direction ?? AxisDirection.down,
        _value = value ?? 0.0,
        _isRefreshEnabled = refreshEnabled ?? true,
        _shouldStopDrag = false;

  @protected
  @visibleForTesting
  void setValue(double value) {
    _value = value;
    notifyListeners();
  }

  ScrollDirection _scrollingDirection;
  @protected
  @visibleForTesting
  void setScrollingDirection(ScrollDirection userScrollDirection) {
    _scrollingDirection = userScrollDirection;
  }

  /// The direction in which the user scrolls.
  ScrollDirection get scrollingDirection => _scrollingDirection;

  /// Scrolling is happening in the positive scroll offset direction.
  bool get isScrollingForward => scrollingDirection == ScrollDirection.forward;

  /// Scrolling is happening in the negative scroll offset direction.
  bool get isScrollingReverse => scrollingDirection == ScrollDirection.reverse;

  /// No scrolling is underway.
  bool get isScrollIdle => scrollingDirection == ScrollDirection.idle;

  AxisDirection _direction;

  /// Sets the direction in which list scrolls
  @protected
  @visibleForTesting
  void setAxisDirection(AxisDirection direction) {
    _direction = direction;
  }

  /// Whether the pull to refresh gesture is triggered from the start
  /// of the list or from the end.
  ///
  /// This is especially useful with [CustomRefreshIndicator.trigger]
  /// set to [IndicatorTrigger.bothEdges], as the gesture
  /// can then be triggered from both edges.
  ///
  /// It is null when the edge is still not determined by
  /// the [CustomRefreshIndicator] widget.
  IndicatorEdge? get edge => _edge;
  IndicatorEdge? _edge;

  /// Whether the [edge] was determined by the [CustomRefreshIndicator] widget.
  bool get hasEdge => edge != null;

  DragUpdateDetails? get dragDetails => _dragDetails;
  DragUpdateDetails? _dragDetails;

  @protected
  @visibleForTesting
  void setIndicatorDragDetails(DragUpdateDetails? dragDetails) {
    _dragDetails = dragDetails;
  }

  @protected
  @visibleForTesting
  void setIndicatorEdge(IndicatorEdge? edge) {
    _edge = edge;
  }

  /// The direction in which the list scrolls
  ///
  /// For example:
  /// ```
  /// ListView.builder(
  ///   scrollDirection: Axis.horizontal,
  ///   reverse: true,
  ///   // ***
  /// ```
  /// will have the direction of `AxisDirection.left`
  AxisDirection get direction => _direction;

  /// Whether list scrolls horizontally
  ///
  /// (direction equals `AxisDirection.left` or `AxisDirection.right`)
  bool get isHorizontalDirection => direction == AxisDirection.left || direction == AxisDirection.right;

  /// Whether list scrolls vertically
  ///
  /// (direction equals `AxisDirection.up` or `AxisDirection.down`)
  bool get isVerticalDirection => direction == AxisDirection.up || direction == AxisDirection.down;

  IndicatorState _currentState;

  /// sets indicator state and notifies listeners
  @protected
  @visibleForTesting
  void setIndicatorState(IndicatorState newState) {
    _currentState = newState;

    notifyListeners();
  }

  /// Describes current [CustomRefreshIndicator] state
  IndicatorState get state => _currentState;

  /// {@macro custom_refresh_indicator.indicator_state.idle}
  bool get isIdle => _currentState.isIdle;

  /// {@macro custom_refresh_indicator.indicator_state.dragging}
  bool get isDragging => _currentState.isDragging;

  /// {@macro custom_refresh_indicator.indicator_state.canceling}
  bool get isCanceling => _currentState.isCanceling;

  /// {@macro custom_refresh_indicator.indicator_state.armed}
  bool get isArmed => _currentState.isArmed;

  /// {@macro custom_refresh_indicator.indicator_state.settling}
  bool get isSettling => _currentState.isSettling;

  /// {@macro custom_refresh_indicator.indicator_state.loading}
  bool get isLoading => _currentState.isLoading;

  /// {@macro custom_refresh_indicator.indicator_state.complete}
  bool get isComplete => _currentState.isComplete;

  /// {@macro custom_refresh_indicator.indicator_state.finalizing}
  bool get isFinalizing => _currentState.isFinalizing;

  bool _shouldStopDrag;

  /// Should the dragging be stopped
  bool get shouldStopDrag => _shouldStopDrag;

  /// Whether custom refresh indicator can change [IndicatorState] from `idle` to `dragging`
  bool get isRefreshEnabled => _isRefreshEnabled;
  bool _isRefreshEnabled;

  void stopDrag() {
    if (state.isDragging || state.isArmed) {
      _shouldStopDrag = true;
    } else {
      throw StateError(
        "stopDrag method can be used only during "
        "drag or armed indicator state.",
      );
    }
  }

  /// Disables list pull to refresh
  void disableRefresh() {
    _isRefreshEnabled = false;
    notifyListeners();
  }

  /// Enables list pull to refresh
  void enableRefresh() {
    _isRefreshEnabled = true;
    notifyListeners();
  }

  /// Provides the status of the animation: [AnimationStatus.dismissed] when
  /// the indicator [state] is [IndicatorState.idle],
  /// and [AnimationStatus.forward] otherwise.
  @override
  AnimationStatus get status => state.isIdle ? AnimationStatus.dismissed : AnimationStatus.forward;
}

/// Creates scroll physics that prevent the scroll offset from exceeding the
/// bounds of the content while handling the overscroll.
class ClampingWithOverscrollPhysics extends ClampingScrollPhysics {
  final ClampingWithOverscrollPhysicsState _state;

  /// Creates scroll physics that prevent the scroll offset from exceeding the
  /// bounds of the content while handling the overscroll.
  const ClampingWithOverscrollPhysics({
    super.parent,
    required ClampingWithOverscrollPhysicsState state,
  }) : _state = state;

  @override
  ClampingWithOverscrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ClampingWithOverscrollPhysics(
      parent: buildParent(ancestor),
      state: _state,
    );
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    assert(() {
      if (value == position.pixels) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('$runtimeType.applyBoundaryConditions() was called redundantly.'),
          ErrorDescription(
            'The proposed new position, $value, is exactly equal to the current position of the '
            'given ${position.runtimeType}, ${position.pixels}.\n'
            'The applyBoundaryConditions method should only be called when the value is '
            'going to actually change the pixels, otherwise it is redundant.',
          ),
          DiagnosticsProperty<ScrollPhysics>('The physics object in question was', this, style: DiagnosticsTreeStyle.errorProperty),
          DiagnosticsProperty<ScrollMetrics>('The position object in question was', position, style: DiagnosticsTreeStyle.errorProperty),
        ]);
      }
      return true;
    }());

    if (value < position.pixels && position.pixels <= position.minScrollExtent) {
      // Underscroll.

      final delta = value - position.pixels;
      _state._addOverscroll(delta.abs());
      return delta;
    }
    if (position.maxScrollExtent <= position.pixels && position.pixels < value) {
      // Overscroll.
      final delta = value - position.pixels;
      _state._addOverscroll(delta);
      return delta;
    }
    if (value < position.minScrollExtent && position.minScrollExtent < position.pixels) {
      // Hit top edge.
      final delta = value - position.minScrollExtent;
      _state._addOverscroll(delta);
      return delta;
    }
    if (position.pixels < position.maxScrollExtent && position.maxScrollExtent < value) {
      // Hit bottom edge.
      final delta = value - position.maxScrollExtent;
      _state._addOverscroll(delta);
      return delta;
    }
    if (_state._hasOverscroll) {
      final delta = value - position.pixels;
      _state._removeOverscroll(delta.abs());

      return delta;
    } else {
      return 0;
    }
  }
}

enum IndicatorEdge {
  leading,
  trailing,
}

extension IndicatorEdgeGetters on IndicatorEdge {
  bool get isTrailing => this == IndicatorEdge.trailing;
  bool get isLeading => this == IndicatorEdge.leading;
}

/// Describes state of CustomRefreshIndicator widget.
enum IndicatorState {
  /// {@template custom_refresh_indicator.indicator_state.idle}
  /// In this state, the indicator is not visible.
  /// No user action is performed. Value remains at *0.0*.
  /// {@endtemplate}
  idle,

  /// {@template custom_refresh_indicator.indicator_state.dragging}
  /// The user starts scrolling/dragging the pointer to refresh.
  /// Releasing the pointer in this state will not trigger
  /// the *onRefresh* function. The controller value changes
  /// from *0.0* to *1.0*.
  /// {@endtemplate}
  dragging,

  /// {@template custom_refresh_indicator.indicator_state.canceling}
  /// The function *onRefresh* **has not been executed**,
  /// and the indicator is hidding from its current value
  /// that is lower than *1.0* to *0.0*.
  /// {@endtemplate}
  canceling,

  /// {@template custom_refresh_indicator.indicator_state.armed}
  /// The user has dragged the pointer further than the distance
  /// declared by *containerExtentPercentageToArmed* or *offsetToArmed*
  /// (over the value of *1.0*). Releasing the pointer in this state will
  /// trigger the *onRefresh* function.
  /// {@endtemplate}
  armed,

  /// {@template custom_refresh_indicator.indicator_state.settling}
  /// The user has released the indicator in the armed state.
  /// The indicator settles on its target value *1.0*.
  /// {@endtemplate}
  settling,

  /// {@template custom_refresh_indicator.indicator_state.loading}
  /// The indicator is in its target value *1.0*.
  /// The *onRefresh* function is triggered.
  /// {@endtemplate}
  loading,

  /// {@template custom_refresh_indicator.indicator_state.complete}
  /// **OPTIONAL** - Provide `completeStateDuration` argument to enable it.
  /// The *onRefresh* callback has completed and the pointer remains
  /// at value *1.0* for the specified duration.
  /// {@endtemplate}
  complete,

  /// {@template custom_refresh_indicator.indicator_state.finalizing}
  /// The *onRefresh* function **has been executed**, and the indicator
  /// hides from the value *1.0* to *0.0*.
  /// {@endtemplate}
  finalizing,
}

extension IndicatorStateGetters on IndicatorState {
  /// {@macro custom_refresh_indicator.indicator_state.idle}
  bool get isIdle => this == IndicatorState.idle;

  /// {@macro custom_refresh_indicator.indicator_state.dragging}
  bool get isDragging => this == IndicatorState.dragging;

  /// {@macro custom_refresh_indicator.indicator_state.canceling}
  bool get isCanceling => this == IndicatorState.canceling;

  /// {@macro custom_refresh_indicator.indicator_state.armed}
  bool get isArmed => this == IndicatorState.armed;

  /// {@macro custom_refresh_indicator.indicator_state.settling}
  bool get isSettling => this == IndicatorState.settling;

  /// {@macro custom_refresh_indicator.indicator_state.loading}
  bool get isLoading => this == IndicatorState.loading;

  /// {@macro custom_refresh_indicator.indicator_state.complete}
  bool get isComplete => this == IndicatorState.complete;

  /// {@macro custom_refresh_indicator.indicator_state.finalizing}
  bool get isFinalizing => this == IndicatorState.finalizing;
}

@immutable
class IndicatorStateChange {
  final IndicatorState currentState;
  final IndicatorState newState;

  const IndicatorStateChange(this.currentState, this.newState);

  /// - When [from] and [to] are provided - returns `true` when state did change [from] to [to].
  /// - When only [from] is provided - returns `true` when state did change from [from].
  /// - When only [to] is provided - returns `true` when state did change to [to].
  /// - When [from] and [to] equals `null` - returns `true` for any state change.
  bool didChange({IndicatorState? from, IndicatorState? to}) {
    final stateChanged = currentState != newState;
    if (to == null && from != null) return currentState == from && stateChanged;
    if (to != null && from == null) return newState == to && stateChanged;
    if (to == null && from == null) return stateChanged;
    return currentState == from && newState == to;
  }

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType && other is IndicatorStateChange && other.currentState == currentState && other.newState == newState;

  @override
  int get hashCode => Object.hash(currentState, newState);

  @override
  String toString() => "$runtimeType(${currentState.name} → ${newState.name})";
}

/// {@template custom_refresh_indicator.indicator_trigger}
/// Defines the trigger for the pull to refresh gesture.
/// {@endtemplate}
///
/// **startEdge**:
/// {@macro custom_refresh_indicator.indicator_trigger.leading}
///
/// **endEdge**:
/// {@macro custom_refresh_indicator.indicator_trigger.trailing}
///
/// **bothEdges**:
/// {@macro custom_refresh_indicator.indicator_trigger.both}
enum IndicatorTrigger {
  /// {@template custom_refresh_indicator.indicator_trigger.leading}
  /// Pull to refresh can be triggered only from the **leading** edge of the list.
  /// Mostly top side, but can be bottom for reversed ListView
  /// (with *reverse* argument set to true).
  /// {@endtemplate}
  leadingEdge,

  /// {@template custom_refresh_indicator.indicator_trigger.trailing}
  /// Pull to refresh can be triggered only from the **trailing** edge of the list.
  /// Mostly bottom, but can be top for reversed ListView
  /// (with *reverse* argument set to true).
  /// {@endtemplate}
  trailingEdge,

  /// {@template custom_refresh_indicator.indicator_trigger.both}
  /// Pull to refresh can be triggered from **both edges** of the list.
  /// {@endtemplate}
  bothEdges,
}

// /// Encapsulates the duration of various phases of the refresh indicator's animation.
// ///
// /// The durations defined within are used to control how long each respective
// /// phase lasts, allowing for customization of the refresh indicator's behavior.
class RefreshIndicatorDurations {
  /// Duration of hiding the indicator when dragging was stopped before
  /// the indicator was armed (the *onRefresh* callback was not called).
  ///
  /// The default is 300 milliseconds.
  final Duration cancelDuration;

  /// The time of settling the pointer on the target location after releasing
  /// the pointer in the armed state.
  ///
  /// During this process, the value of the indicator decreases from its current value,
  /// which can be greater than or equal to 1.0 but less or equal to 1.5,
  /// to a target value of `1.0`.
  /// During this process, the state is set to [IndicatorState.loading].
  ///
  /// The default is 150 milliseconds.
  final Duration settleDuration;

  /// Duration of hiding the pointer after the [onRefresh] function completes.
  ///
  /// During this time, the value of the controller decreases from `1.0` to `0.0`
  /// with a state set to [IndicatorState.finalizing].
  ///
  /// The default is 100 milliseconds.
  final Duration finalizeDuration;

  /// Duration for which the indicator remains at value of *1.0* and
  /// [IndicatorState.complete] state after the [onRefresh] function completes.
  final Duration? completeDuration;

  /// Constructs a `RefreshIndicatorDurations` with the specified durations.
  ///
  /// If a duration is not specified, it falls back to a default value:
  /// - `cancelDuration`: 300 milliseconds
  /// - `settleDuration`: 150 milliseconds
  /// - `finalizeDuration`: 100 milliseconds
  const RefreshIndicatorDurations({
    this.cancelDuration = const Duration(milliseconds: 300),
    this.settleDuration = const Duration(milliseconds: 150),
    this.finalizeDuration = const Duration(milliseconds: 100),
    this.completeDuration,
  });
}

/// Used to configure how [CustomRefreshIndicator] can be triggered.
enum IndicatorTriggerMode {
  /// The indicator can be triggered regardless of the scroll position
  /// of the [Scrollable] when the drag starts.
  anywhere,

  /// The indicator can only be triggered if the [Scrollable] is at the edge
  /// when the drag starts.
  onEdge,
}
