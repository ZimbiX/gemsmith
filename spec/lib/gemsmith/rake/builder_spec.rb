# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gemsmith::Rake::Builder do
  subject(:builder) { described_class.new kernel: kernel }

  include_context "with temporary directory"

  let(:kernel) { class_spy Kernel }

  describe "#clean" do
    let(:package_dir) { File.join temp_dir, "pkg" }
    let(:gem_file) { File.join package_dir, "test-0.1.0.gem" }

    before do
      FileUtils.mkdir_p package_dir
      FileUtils.touch gem_file
    end

    it "removes previously built gem artifacts" do
      Dir.chdir(temp_dir) { builder.clean }
      expect(File.exist?(gem_file)).to eq(false)
    end

    it "prints status message" do
      result = -> { Dir.chdir(temp_dir) { builder.clean } }
      expect(&result).to output("Cleaned gem artifacts.\n").to_stdout
    end
  end

  describe "#validate" do
    before do
      Dir.chdir temp_dir do
        `git init`
        `git config --local user.name "Testy Tester"`
        `git config --local user.email "tester@example.com"`
        `rm -rf .git/hooks`
        `touch test.txt`
        `git add --all .`
        `git commit --all --message "Added test.txt."`
      end
    end

    context "with Git changes" do
      before { Dir.chdir(temp_dir) { `touch extra.txt` } }

      it "prints build error" do
        Dir.chdir temp_dir do
          result = -> { builder.validate }
          expect(&result).to output(/Build\sfailed:\sGem\shas\suncommitted\schanges\.\n/).to_stderr
        end
      end

      it "exits with error" do
        Dir.chdir temp_dir do
          builder.validate
          expect(kernel).to have_received(:exit).with(1)
        end
      end
    end

    context "without Git changes" do
      it "does not print output" do
        Dir.chdir temp_dir do
          result = -> { builder.validate }
          expect(&result).not_to output.to_stdout
        end
      end

      it "does not exit" do
        Dir.chdir temp_dir do
          builder.validate
          expect(kernel).not_to have_received(:exit)
        end
      end
    end
  end

  describe "#build" do
    let(:fixtures_dir) { File.join File.dirname(__FILE__), "..", "..", "..", "support", "fixtures" }
    let(:gem_spec_fixture_file) { File.join fixtures_dir, "tester-valid.gemspec" }
    let(:gem_spec_file) { File.join temp_dir, "tester.gemspec" }
    let(:gem_spec) { Gemsmith::Gem::Specification.new gem_spec_file }

    before { FileUtils.cp gem_spec_fixture_file, gem_spec_file }

    context "when success" do
      subject(:builder) { described_class.new }

      it "builds gem package" do
        Dir.chdir temp_dir do
          builder.build gem_spec
          expect(File.exist?("pkg/tester-0.1.0.gem")).to eq(true)
        end
      end

      it "prints package built successfully" do
        Dir.chdir temp_dir do
          result = -> { builder.build gem_spec }
          expect(&result).to output(%r(Built:\spkg/tester-0\.1\.0\.gem\.\n)).to_stdout
        end
      end
    end

    context "when failure" do
      let(:kernel) { class_spy Kernel, system: false }

      it "does not build gem package" do
        Dir.chdir temp_dir do
          builder.build gem_spec
          expect(File.exist?("pkg/tester-0.1.0.gem")).to eq(false)
        end
      end

      it "prints error message" do
        Dir.chdir temp_dir do
          result = -> { builder.build gem_spec }
          expect(&result).to output(%r(Unable\sto\sbuild:\spkg/tester-0\.1\.0\.gem\.\n)).to_stderr
        end
      end
    end
  end

  describe "#install" do
    let(:fixtures_dir) { File.join File.dirname(__FILE__), "..", "..", "..", "support", "fixtures" }
    let(:gem_spec_fixture_file) { File.join fixtures_dir, "tester-valid.gemspec" }
    let(:gem_spec) { Gemsmith::Gem::Specification.new gem_spec_fixture_file }

    context "when success" do
      let(:kernel) { class_spy Kernel, system: true }

      it "prints gem was installed" do
        result = -> { builder.install gem_spec }
        expect(&result).to output("Installed: tester 0.1.0.\n").to_stdout
      end
    end

    context "when failure" do
      let(:kernel) { class_spy Kernel, system: false }

      it "prints gem wasn't installed" do
        result = -> { builder.install gem_spec }
        expect(&result).to output(/Unable\sto\sinstall:\stester\s0\.1\.0\.\n/).to_stderr
      end
    end
  end
end
