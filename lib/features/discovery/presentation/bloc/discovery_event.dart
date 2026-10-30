import 'package:equatable/equatable.dart';

sealed class DiscoveryEvent extends Equatable {
  const DiscoveryEvent();

  @override
  List<Object?> get props => [];
}

class ExploreRequested extends DiscoveryEvent {
  const ExploreRequested();
}

class ExploreQueryChanged extends DiscoveryEvent {
  const ExploreQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class ExploreTabChanged extends DiscoveryEvent {
  const ExploreTabChanged(this.tab);

  final int tab;

  @override
  List<Object?> get props => [tab];
}

/// `null` means all stages.
class ExploreLevelChanged extends DiscoveryEvent {
  const ExploreLevelChanged(this.level);

  final String? level;

  @override
  List<Object?> get props => [level];
}
