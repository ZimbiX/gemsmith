# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gemsmith::Generators::Gem do
  subject(:gem_generator) { described_class.new cli, configuration: configuration }

  include_context "with temporary directory"

  let(:cli) { instance_spy Gemsmith::CLI, destination_root: temp_dir }
  let(:configuration) { {gem: {name: "tester"}} }

  describe "#run" do
    before { gem_generator.run }

    it "creates console script" do
      expect(cli).to have_received(:template).with("%gem_name%/bin/console.tt", configuration)
    end

    it "creates setup script" do
      expect(cli).to have_received(:template).with("%gem_name%/bin/setup.tt", configuration)
    end

    it "sets excecutable file permission for console script" do
      expect(cli).to have_received(:chmod).with("tester/bin/console", 0o755)
    end

    it "sets excecutable file permission for setup script" do
      expect(cli).to have_received(:chmod).with("tester/bin/setup", 0o755)
    end

    it "creates Gemfile" do
      expect(cli).to have_received(:template).with("%gem_name%/Gemfile.tt", configuration)
    end

    it "creates gem spec" do
      expect(cli).to have_received(:template).with(
        "%gem_name%/%gem_name%.gemspec.tt",
        configuration
      )
    end

    it "creates gem library" do
      expect(cli).to have_received(:template).with("%gem_name%/lib/%gem_path%.rb.tt", configuration)
    end

    it "creates gem identity" do
      expect(cli).to have_received(:template).with(
        "%gem_name%/lib/%gem_path%/identity.rb.tt",
        configuration
      )
    end
  end
end
