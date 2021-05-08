# frozen_string_literal: true

require "refinements/arrays"

module Gemsmith
  module Generators
    # Generates Rake support.
    class Rake < Base
      using Refinements::Arrays

      def run
        template "%gem_name%/Rakefile.tt"
        append_code_quality_task
        append_default_task
      end

      def generate_code_quality_task
        return "" if code_quality_tasks.empty?

        %(\ndesc "Run code quality checks"\ntask code_quality: %i[#{code_quality_tasks}]\n)
      end

      def generate_default_task
        return "" if default_task.empty?

        %(\ntask default: %i[#{default_task}]\n)
      end

      private

      def rspec_task
        configuration.dig(:generate, :rspec) ? "spec" : ""
      end

      def bundler_audit_task
        configuration.dig(:generate, :bundler_audit) ? "bundle:audit" : ""
      end

      def git_lint_task
        configuration.dig(:generate, :git_lint) ? "git_lint" : ""
      end

      def reek_task
        configuration.dig(:generate, :reek) ? "reek" : ""
      end

      def rubocop_task
        configuration.dig(:generate, :rubocop) ? "rubocop" : ""
      end

      def code_quality_tasks
        [bundler_audit_task, git_lint_task, reek_task, rubocop_task].compress.join " "
      end

      def code_quality_task
        code_quality_tasks.empty? ? "" : "code_quality"
      end

      def default_task
        [code_quality_task, rspec_task].compress.join " "
      end

      def append_code_quality_task
        return if code_quality_task.empty?

        cli.append_to_file "%gem_name%/Rakefile", generate_code_quality_task
      end

      def append_default_task
        return if default_task.empty?

        cli.append_to_file "%gem_name%/Rakefile", generate_default_task
      end
    end
  end
end
