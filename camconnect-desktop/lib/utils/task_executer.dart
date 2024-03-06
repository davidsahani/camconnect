/// A utility class for executing asynchronous tasks with unique task IDs.
///
/// This class is designed to ensure that tasks with unique `taskId` values are
/// executed without duplication. If a task with a given `taskId` is currently
/// running, another task with the same `taskId` will not be executed.
///
/// Usage:
/// ```dart
/// TaskExecuter.run(
///   () async {
///     // Your async task here
///   },
///   taskId: uniqueTaskId,
///   onError: (error) {
///     // Handle error here
///   },
/// );
/// ```
class TaskExecuter {
  /// A private list to keep track of the task IDs that are currently being executed.
  static final List<int> _taskIds = [];

  /// Executes a given asynchronous task function if its `taskId` is not already in the list of executing taskIds.
  ///
  /// This method ensures that tasks are executed in a non-duplicative manner based on their `taskId`.
  /// If a task with the same `taskId` is already running, the function will not execute the new task.
  /// If `taskId` is not provided, that function will execute as is in duplicative manner.
  ///
  /// Parameters:
  /// - `fn`: The asynchronous function to be executed.
  /// - `taskId`: An integer that uniquely identifies the task to be executed. This is used to prevent duplicate task executions.
  /// - `onError`: A callback function that handles errors thrown during the execution of the task, if no callback is provided error is ignored.
  ///
  /// Returns: true if succeeded without errors otherwise false, null if task is still running if taskId was provided.
  ///
  /// Usage example:
  /// ```dart
  /// TaskExecuter.run(
  ///   () async {
  ///     print('Executing task');
  ///     await Future.delayed(Duration(seconds: 1));
  ///     print('Task completed');
  ///   },
  ///   taskId: 0,
  ///   onError: (error) {
  ///     print('Error occurred: $error');
  ///   },
  /// );
  /// ```
  static Future<bool?> run(Future<void> Function() fn,
      {int? taskId, void Function(Object)? onError}) async {
    if (taskId != null && _taskIds.contains(taskId)) {
      // If the task ID is already in the list, don't execute the function again.
      return null;
    }

    // Add the task ID to the list and execute the function.
    if (taskId != null) {
      _taskIds.add(taskId);
    }

    bool succeeded = true;

    try {
      await fn();
    } catch (e) {
      onError?.call(e);
      succeeded = false;
    }

    // Once the function has completed execution, remove the task ID from the list.
    if (taskId != null) {
      _taskIds.remove(taskId);
    }

    return succeeded;
  }
}
