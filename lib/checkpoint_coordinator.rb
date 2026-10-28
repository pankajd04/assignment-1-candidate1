
class CheckpointCoordinator
  def initialize(replicas)
    @replicas = replicas.dup

    @replica_checkpoints = @replicas.to_h do |replica|
      [replica, 0]
    end

    @proposed_checkpoint = 0
    @committed_checkpoint = 0
    @acknowledgements = []
  end

  def process_replica_turn(replica)
    advance = replica.get_checkpoint_advance

    current_checkpoint = @replica_checkpoints[replica]
    target_checkpoint = current_checkpoint + advance

    if target_checkpoint < @proposed_checkpoint
      @replicas.delete(replica)
      @acknowledgements.delete(replica)

    elsif target_checkpoint > @proposed_checkpoint
      @replica_checkpoints[replica] = target_checkpoint
      @proposed_checkpoint = target_checkpoint
      @acknowledgements = [replica]

    else
      @replica_checkpoints[replica] = target_checkpoint

      unless @acknowledgements.include?(replica)
        @acknowledgements << replica
      end
    end

    active_acknowledgements = @acknowledgements.select do |acknowledger|
      @replicas.include?(acknowledger)
    end

    if active_acknowledgements.uniq.length >= 2
      @committed_checkpoint = @proposed_checkpoint
    end
  end
  
  def agreement_reached?
    @proposed_checkpoint == @committed_checkpoint &&
    @replicas.all? do |replica|
      @acknowledgements.include?(replica)
    end
  end

  def run
    index = 0

    loop do
      break if @replicas.length <= 1
      break if agreement_reached?

      replica = @replicas[index]

      process_replica_turn(replica)

      if @replicas.empty?
        break
      elsif @replicas.include?(replica)
        index = (index + 1) % @replicas.length
      else
        index = index % @replicas.length
      end
    end

    {
      checkpoint: @committed_checkpoint,
      replicas: @replicas
    }
  end

end
