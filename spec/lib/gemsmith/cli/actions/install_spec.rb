# frozen_string_literal: true

require "spec_helper"
require "dry/monads"

RSpec.describe Gemsmith::CLI::Actions::Install do
  include Dry::Monads[:result]

  using Refinements::Pathnames

  subject(:action) { described_class.new installer: }

  include_context "with application container"

  let(:installer) { instance_spy Gemsmith::Tools::Installer, call: result }
  let(:specification) { Gemsmith::Gems::Loader.call temp_dir.join("gemsmith-test.gemspec") }

  describe "#call" do
    before { Bundler.root.join("spec/support/fixtures/gemsmith-test.gemspec").copy temp_dir }

    context "when success" do
      let(:result) { Success specification }

      it "installs gem" do
        temp_dir.change_dir do
          action.call configuration
          expect(installer).to have_received(:call).with(kind_of(Gemsmith::Gems::Presenter))
        end
      end

      it "logs gem was installed" do
        temp_dir.change_dir do
          expectation = proc { action.call configuration }
          expect(&expectation).to output("Installed: gemsmith-test-0.0.0.gem.\n").to_stdout
        end
      end
    end

    context "when failure" do
      let(:result) { Failure "Danger!" }

      it "logs error" do
        temp_dir.change_dir do
          expectation = proc { action.call configuration }
          expect(&expectation).to output("Danger!\n").to_stdout
        end
      end
    end

    context "when unknown" do
      let(:result) { "bogus" }

      it "logs error" do
        temp_dir.change_dir do
          expectation = proc { action.call configuration }
          expect(&expectation).to output("Unable to handle install action.\n").to_stdout
        end
      end
    end
  end
end
