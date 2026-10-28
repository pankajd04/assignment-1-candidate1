
require_relative "../lib/checkpoint_coordinator"

RSpec.describe CheckpointCoordinator do

  describe "#initialize" do
    it "creates a coordinator with the initial checkpoint at zero" do
      replica = double("Replica")

      coordinator = described_class.new([replica])

      expect(coordinator).to be_a(CheckpointCoordinator)
    end
  end

  
  describe "#run" do
    it "returns checkpoint zero when only one replica is active" do
      replica = double("Replica")

      coordinator = described_class.new([replica])

      result = coordinator.run

      expect(result[:checkpoint]).to eq(0)
      expect(result[:replicas]).to eq([replica])
    end

    
    it "commits a checkpoint when two replicas acknowledge the same proposal" do
        replica_a = double("Replica A")
        replica_b = double("Replica B")

        allow(replica_a).to receive(:get_checkpoint_advance).and_return(5, 0)
        allow(replica_b).to receive(:get_checkpoint_advance).and_return(5, 0)

        coordinator = described_class.new([replica_a, replica_b])

        result = coordinator.run

        expect(result[:checkpoint]).to eq(5)
        expect(result[:replicas]).to eq([replica_a, replica_b])
    end

    
    it "drops a replica whose target is lower than the current proposal" do
        replica_a = double("Replica A")
        replica_b = double("Replica B")
        replica_c = double("Replica C")

        allow(replica_a).to receive(:get_checkpoint_advance).and_return(5, 0)
        allow(replica_b).to receive(:get_checkpoint_advance).and_return(10)
        allow(replica_c).to receive(:get_checkpoint_advance).and_return(10)

        coordinator = described_class.new([replica_a, replica_b, replica_c])

        result = coordinator.run

        expect(result[:checkpoint]).to eq(10)
        expect(result[:replicas]).to eq([replica_b, replica_c])
    end

    
    it "replaces an uncommitted proposal with a higher proposal" do
      replica_a = double("Replica A")
      replica_b = double("Replica B")
      replica_c = double("Replica C")

      allow(replica_a).to receive(:get_checkpoint_advance).and_return(5)
      allow(replica_b).to receive(:get_checkpoint_advance).and_return(10)
      allow(replica_c).to receive(:get_checkpoint_advance).and_return(10)

      coordinator = described_class.new([replica_a, replica_b, replica_c])

      result = coordinator.run

      expect(result[:checkpoint]).to eq(10)
      expect(result[:replicas]).to eq([replica_a, replica_b, replica_c])
    end

    
    it "returns the last committed checkpoint when only one replica remains" do
      replica_a = double("Replica A")
      replica_b = double("Replica B")
      replica_c = double("Replica C")

      allow(replica_a).to receive(:get_checkpoint_advance).and_return(5, 0)
      allow(replica_b).to receive(:get_checkpoint_advance).and_return(5, 0)
      allow(replica_c).to receive(:get_checkpoint_advance).and_return(10)

      coordinator = described_class.new([replica_a, replica_b, replica_c])

      result = coordinator.run

      expect(result[:checkpoint]).to eq(5)
      expect(result[:replicas]).to eq([replica_c])
    end

    it "stops immediately when agreement is reached" do
      replica_a = double("Replica A")
      replica_b = double("Replica B")

      allow(replica_a).to receive(:get_checkpoint_advance).and_return(5)
      allow(replica_b).to receive(:get_checkpoint_advance).and_return(5)

      coordinator = described_class.new([replica_a, replica_b])

      result = coordinator.run

      expect(result[:checkpoint]).to eq(5)
      expect(result[:replicas]).to eq([replica_a, replica_b])

      expect(replica_a).to have_received(:get_checkpoint_advance).once
      expect(replica_b).to have_received(:get_checkpoint_advance).once
    end

    it "handles multiple rounds and skips a dropped replica" do
      replica_a = double("Replica A")
      replica_b = double("Replica B")
      replica_c = double("Replica C")

      allow(replica_a).to receive(:get_checkpoint_advance).and_return(5, 0)
      allow(replica_b).to receive(:get_checkpoint_advance).and_return(10, 0)
      allow(replica_c).to receive(:get_checkpoint_advance).and_return(10, 0)

      coordinator = described_class.new([replica_a, replica_b, replica_c])

      result = coordinator.run

      expect(result[:checkpoint]).to eq(10)
      expect(result[:replicas]).to eq([replica_b, replica_c])

      expect(replica_a).to have_received(:get_checkpoint_advance).twice
      expect(replica_b).to have_received(:get_checkpoint_advance).once
      expect(replica_c).to have_received(:get_checkpoint_advance).once
    end


  end

end
