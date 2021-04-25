import 'package:memo/data/serializers/memo_difficulty_parser.dart';
import 'package:memo/data/serializers/serializer.dart';
import 'package:memo/domain/models/memo_execution.dart';

class MemoExecutionKeys {
  static const memoId = 'memoId';
  static const collectionId = 'collectionId';
  static const started = 'started';
  static const finished = 'finished';
  static const rawQuestion = 'question';
  static const rawAnswer = 'answer';
  static const markedDifficulty = 'markedDifficulty';
}

class MemoExecutionSerializer implements Serializer<MemoExecution, Map<String, dynamic>> {
  @override
  MemoExecution from(Map<String, dynamic> json) {
    final memoId = json[MemoExecutionKeys.memoId] as String;
    final collectionId = json[MemoExecutionKeys.collectionId] as String;

    final rawStarted = json[MemoExecutionKeys.started] as int;
    final started = DateTime.fromMillisecondsSinceEpoch(rawStarted, isUtc: true);

    final rawFinished = json[MemoExecutionKeys.finished] as int;
    final finished = DateTime.fromMillisecondsSinceEpoch(rawFinished, isUtc: true);

    // Casting just to make sure, because sembast returns an ImmutableList<dynamic>
    final rawQuestion = (json[MemoExecutionKeys.rawQuestion] as List).cast<Map<String, dynamic>>();
    final rawAnswer = (json[MemoExecutionKeys.rawAnswer] as List).cast<Map<String, dynamic>>();

    final rawDifficulty = json[MemoExecutionKeys.markedDifficulty] as String;
    final markedDifficulty = memoDifficultyFromRaw(rawDifficulty);

    return MemoExecution(
      memoId: memoId,
      collectionId: collectionId,
      started: started,
      finished: finished,
      rawQuestion: rawQuestion,
      rawAnswer: rawAnswer,
      markedDifficulty: markedDifficulty,
    );
  }

  @override
  Map<String, dynamic> to(MemoExecution execution) => <String, dynamic>{
        MemoExecutionKeys.memoId: execution.memoId,
        MemoExecutionKeys.collectionId: execution.collectionId,
        MemoExecutionKeys.started: execution.started.toUtc().millisecondsSinceEpoch,
        MemoExecutionKeys.finished: execution.finished.toUtc().millisecondsSinceEpoch,
        MemoExecutionKeys.rawQuestion: execution.rawQuestion,
        MemoExecutionKeys.rawAnswer: execution.rawAnswer,
        MemoExecutionKeys.markedDifficulty: execution.markedDifficulty.raw,
      };
}
