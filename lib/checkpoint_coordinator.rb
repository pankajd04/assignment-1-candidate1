
class CheckpointCoordinator
  def initialize(replicas)
    # Keep a separate list so we can remove replicas without changing the original array.
    @replicas = replicas.dup

    # Every replica starts at checkpoint 0.
    @replica_checkpoints = @replicas.to_h do |replica|
      [replica, 0]
    end

    # The proposed checkpoint is the current target.
    # The committed checkpoint is the last checkpoint confirmed by two replicas.
    @proposed_checkpoint = 0
    @committed_checkpoint = 0

    # Stores the replicas that have acknowledged the current proposal.
    @acknowledgements = []
  end

  def process_replica_turn(replica)
    # Get how far this replica wants to advance.
    advance = replica.get_checkpoint_advance

    current_checkpoint = @replica_checkpoints[replica]
    target_checkpoint = current_checkpoint + advance

    if target_checkpoint < @proposed_checkpoint
      # This replica cannot catch up, so remove it.
      # Its attempted checkpoint increase is not applied.
      @replicas.delete(replica)
      @acknowledgements.delete(replica)

    elsif target_checkpoint > @proposed_checkpoint
      # A higher checkpoint becomes the new proposal.
      # Only this replica has acknowledged the new proposal so far.
      @replica_checkpoints[replica] = target_checkpoint
      @proposed_checkpoint = target_checkpoint
      @acknowledgements = [replica]

    else
      # The replica has reached the current proposal.
      @replica_checkpoints[replica] = target_checkpoint

      # Count each replica only once for this proposal.
      unless @acknowledgements.include?(replica)
        @acknowledgements << replica
      end
    end

    # Only active replicas can count towards committing a proposal.
    active_acknowledgements = @acknowledgements.select do |acknowledger|
      @replicas.include?(acknowledger)
    end

    # Two different active replicas must acknowledge the same proposal.
    if active_acknowledgements.uniq.length >= 2
      @committed_checkpoint = @proposed_checkpoint
    end
  end

  def agreement_reached?
    # Stop when the proposal is committed and every active replica
    # has acknowledged that proposal.
    @proposed_checkpoint == @committed_checkpoint &&
      @replicas.all? do |replica|
        @acknowledgements.include?(replica)
      end
  end

  def run
    # Start with the first replica in the list.
    index = 0

    loop do
      # Stop if only one replica remains.
      break if @replicas.length <= 1

      # Do not give another turn once agreement is complete.
      break if agreement_reached?

      replica = @replicas[index]

      process_replica_turn(replica)

      if @replicas.empty?
        break
      elsif @replicas.include?(replica)
        # Move to the next active replica, wrapping around to the start.
        index = (index + 1) % @replicas.length
      else
        # The current replica was removed. Keep the index on the
        # next replica, accounting for the shorter list.
        index = index % @replicas.length
      end
    end

    # Return the last committed checkpoint and the replicas still active.
    {
      checkpoint: @committed_checkpoint,
      replicas: @replicas
    }
  end
end

