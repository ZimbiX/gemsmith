# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gemsmith::Generators::Git do
  subject(:git) { described_class.new cli, configuration: configuration, shell: shell }

  include_context "with temporary directory"

  let(:cli) { instance_spy Gemsmith::CLI, destination_root: temp_dir }
  let(:configuration) { {gem: {name: "tester"}} }
  let(:shell) { class_spy Open3 }
  let(:gem_dir) { temp_dir.join configuration.dig(:gem, :name) }

  describe "#run" do
    before do
      FileUtils.mkdir gem_dir
      git.run
    end

    it "creates Git ignore file" do
      expect(cli).to have_received(:template).with("%gem_name%/.gitignore.tt", configuration)
    end

    it "initializes Git repository" do
      expect(shell).to have_received(:capture3).with("git init")
    end

    it "adds generated files" do
      expect(shell).to have_received(:capture3).with("git add .")
    end

    it "creates initial commit" do
      commit_subject = "Added gem skeleton"
      body = "Generated with [Gemsmith](https://www.alchemists.io/projects/gemsmith)\n" \
             "#{Gemsmith::Identity::VERSION}."

      expect(shell).to have_received(:capture3).with(
        %(git commit --all --no-verify --message "#{commit_subject}" --message "#{body}")
      )
    end
  end
end
