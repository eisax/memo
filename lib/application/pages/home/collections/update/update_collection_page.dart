import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:layoutr/common_layout.dart';
import 'package:memo/application/constants/strings.dart' as strings;
import 'package:memo/application/pages/home/collections/update/update_collection_details.dart';
import 'package:memo/application/pages/home/collections/update/update_collection_memos.dart';
import 'package:memo/application/pages/home/collections/update/update_collection_providers.dart';
import 'package:memo/application/theme/theme_controller.dart';
import 'package:memo/application/view-models/home/update_collection_details_vm.dart';
import 'package:memo/application/view-models/home/update_collection_vm.dart';
import 'package:memo/application/widgets/theme/custom_button.dart';
import 'package:memo/application/widgets/theme/exception_retry_container.dart';
import 'package:memo/application/widgets/theme/themed_container.dart';
import 'package:memo/application/widgets/theme/themed_tab_bar.dart';
import 'package:memo/core/faults/errors/inconsistent_state_error.dart';

enum _Segment { details, memos }

class UpdateCollectionPage extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(updateCollectionVM.notifier);

    final selectedSegment = useState(_Segment.details);
    final tabController = useTabController(initialLength: _Segment.values.length);

    useEffect(() {
      void tabListener() => selectedSegment.value = _Segment.values[tabController.index];

      tabController.addListener(tabListener);
      return () => tabController.removeListener(tabListener);
    });

    final tabs = _Segment.values.map((segment) => Text(segment.title)).toList();
    final title = vm.isEditing ? strings.editCollection : strings.newCollection;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          ThemedTabBar(controller: tabController, tabs: tabs),
          Expanded(child: _UpdateCollectionContents(selectedSegment: selectedSegment.value)),
          context.verticalBox(Spacing.large),
          _BottomActionContainer(
            onSegmentSwapRequested: (segment) => tabController.animateTo(_Segment.values.indexOf(segment)),
            selectedSegment: selectedSegment.value,
          ),
        ],
      ),
    );
  }
}

class _UpdateCollectionContents extends ConsumerWidget {
  const _UpdateCollectionContents({required this.selectedSegment});

  final _Segment selectedSegment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(updateCollectionVM.notifier);
    final state = ref.watch(updateCollectionVM);

    if (state is UpdateCollectionFailedLoading) {
      return Center(child: ExceptionRetryContainer(exception: state.exception, onRetry: vm.loadContent));
    }

    if (state is UpdateCollectionLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is UpdateCollectionLoaded) {
      switch (selectedSegment) {
        case _Segment.details:
          return ProviderScope(
            overrides: [
              updateDetailsMetadata.overrideWithValue(state.collectionMetadata),
            ],
            child: _UpdateCollectionDetails(),
          );
        case _Segment.memos:
          return UpdateCollectionMemos();
      }
    }

    throw InconsistentStateError.layout('Unsupported subtype (${state.runtimeType}) of `UpdateCollectionState`');
  }
}

class _UpdateCollectionDetails extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(updateCollectionVM.notifier);

    ref.listen<UpdatedDetailsState>(
      updateCollectionDetailsVM,
      (_, state) => vm.updateMetadata(metadata: state.metadata),
    );

    return UpdateCollectionDetails();
  }
}

extension on _Segment {
  String get title {
    switch (this) {
      case _Segment.details:
        return strings.details;
      case _Segment.memos:
        return strings.memos;
    }
  }
}

class _BottomActionContainer extends ConsumerWidget {
  const _BottomActionContainer({required this.selectedSegment, required this.onSegmentSwapRequested});

  final _Segment selectedSegment;
  final void Function(_Segment segment) onSegmentSwapRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeController);

    late Widget button;

    switch (selectedSegment) {
      case _Segment.details:
        button = _DetailsActionButton(onSegmentSwapRequested: onSegmentSwapRequested);
        break;
      case _Segment.memos:
        button = _MemosActionButton();
        break;
    }

    return ThemedBottomContainer(
      child: Container(
        color: theme.neutralSwatch.shade800,
        child: SafeArea(
          child: button.withSymmetricalPadding(context, vertical: Spacing.small, horizontal: Spacing.medium),
        ),
      ),
    );
  }
}

class _DetailsActionButton extends ConsumerWidget {
  const _DetailsActionButton({required this.onSegmentSwapRequested});

  final Function(_Segment segment) onSegmentSwapRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(updateCollectionVM.notifier);
    final state = ref.watch(updateCollectionVM);

    if (state is! UpdateCollectionLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    void onPressed() => state.hasMemos ? vm.saveCollection : onSegmentSwapRequested(_Segment.memos);
    final buttonTitle = state.hasMemos ? strings.saveCollection : strings.next;
    return PrimaryElevatedButton(onPressed: state.hasDetails ? onPressed : null, text: buttonTitle.toUpperCase());
  }
}

class _MemosActionButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(updateCollectionVM.notifier);
    final state = ref.watch(updateCollectionVM);

    if (state is! UpdateCollectionLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return PrimaryElevatedButton(
      onPressed: state.canSaveCollection ? vm.saveCollection : null,
      text: strings.saveCollection.toUpperCase(),
    );
  }
}
