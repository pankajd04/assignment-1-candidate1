# Checkpoint Coordinator — Notes

## Approach

I implemented the `CheckpointCoordinator` to manage replica checkpoints and coordinate agreement.

- All replicas start at checkpoint `0`.
- The coordinator tracks the proposed checkpoint separately from the committed checkpoint.
- Replicas take turns in their original input order. Replicas that drop out are skipped.
- On each turn, the coordinator calculates the target checkpoint using the replica's current checkpoint and its returned advance.
- If a replica cannot reach the current proposal, it is removed without applying its attempted advance.
- If a replica proposes a higher checkpoint, the proposal is updated, and acknowledgements for the previous proposal no longer count.
- A proposal is committed when two distinct active replicas acknowledge that exact proposal.
- The process stops when the current proposal is committed and every active replica has acknowledged it, or when only one active replica remains.
- The final result contains the last committed checkpoint and the replicas that remain active.

## Assumptions

- At least two replicas are provided, as specified in the assignment.
- Each replica returns a non-negative integer from `get_checkpoint_advance`.
- The `Replica` class is provided externally and is not modified.
- Replica checkpoint values and acknowledgement state are tracked by the coordinator.

## Test Coverage

The test suite covers the following scenarios:

1. Initializes the coordinator successfully.
2. Returns checkpoint `0` when only one replica is active initially.
3. Commits a checkpoint when two replicas acknowledge the same proposal.
4. Drops a replica when it cannot catch up with the current proposal.
5. Replaces an uncommitted proposal with a higher proposal.
6. Returns the last committed checkpoint when only one replica remains and a higher proposal is uncommitted.
7. Stops immediately when agreement is reached, without giving replicas additional turns.
8. Handles multiple rounds and skips replicas that have dropped out.

## Incomplete Work and Future Improvements

- Add more edge-case tests for checkpoint transitions, acknowledgement tracking, and replica removal.
- Consider refactoring the coordinator into smaller helper methods if the implementation grows.

## Running Tests

Run the following command from the project root:

```bash
bundle exec rspec
```

Latest test result: **8 examples, 0 failures**.

## Review Information

- Repository: `assignment-1-candidate1`
- Branch: `main`
- Commit: `Implement checkpoint coordinator`
