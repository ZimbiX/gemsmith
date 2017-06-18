# frozen_string_literal: true

require "thor"
require "thor/actions"
require "refinements/strings"
require "refinements/hashes"
require "runcom"
require "gemsmith/helpers/cli"
require "gemsmith/helpers/template"

module Gemsmith
  # The Command Line Interface (CLI) for the gem.
  # rubocop:disable Metrics/ClassLength
  class CLI < Thor
    include Thor::Actions
    include Helpers::CLI
    include Helpers::Template

    using Refinements::Strings
    using Refinements::Hashes

    package_name Identity.version_label

    # Overwrites Thor's template source root.
    def self.source_root
      File.expand_path File.join(File.dirname(__FILE__), "templates")
    end

    # rubocop:disable Metrics/MethodLength
    def self.configuration
      Runcom::Configuration.new project_name: Identity.name, defaults: {
        year: Time.now.year,
        github_user: Git.github_user,
        gem: {
          label: "Undefined",
          name: "undefined",
          path: "undefined",
          class: "Undefined",
          platform: "Gem::Platform::RUBY",
          url: Git.github_url("undefined"),
          license: "MIT"
        },
        author: {
          name: Git.config_value("user.name"),
          email: Git.config_value("user.email"),
          url: ""
        },
        organization: {
          name: "",
          url: ""
        },
        versions: {
          ruby: RUBY_VERSION,
          rails: "5.1"
        },
        generate: {
          cli: false,
          rails: false,
          security: true,
          pry: true,
          guard: true,
          git_cop: true,
          rspec: true,
          reek: true,
          rubocop: true,
          scss_lint: false,
          git_hub: false,
          code_climate: false,
          gemnasium: false,
          circle_ci: false,
          patreon: false
        },
        publish: {
          sign: false
        }
      }
    end

    def self.generators
      [
        Generators::Gem,
        Generators::Documentation,
        Generators::Rake,
        Generators::CLI,
        Generators::Ruby,
        Generators::Rails,
        Generators::Rspec,
        Generators::GitCop,
        Generators::Reek,
        Generators::Rubocop,
        Generators::SCSSLint,
        Generators::CodeClimate,
        Generators::Guard,
        Generators::CircleCI,
        Generators::Bundler,
        Generators::GitHub,
        Generators::Pragma,
        Generators::Git
      ]
    end

    # Initialize.
    def initialize args = [], options = {}, config = {}
      super args, options, config
      @configuration = {}
    end

    desc "-g, [--generate=GEM]", "Generate new gem."
    map %w[-g --generate] => :generate
    method_option :cli,
                  desc: "Add CLI support.",
                  type: :boolean,
                  default: configuration.to_h.dig(:generate, :cli)
    method_option :rails,
                  desc: "Add Rails support.",
                  type: :boolean,
                  default: configuration.to_h.dig(:generate, :rails)
    method_option :security,
                  desc: "Add security support.",
                  type: :boolean,
                  default: configuration.to_h.dig(:generate, :security)
    method_option :pry,
                  desc: "Add Pry support.",
                  type: :boolean,
                  default: configuration.to_h.dig(:generate, :pry)
    method_option :guard,
                  desc: "Add Guard support.",
                  type: :boolean,
                  default: configuration.to_h.dig(:generate, :guard)
    method_option :git_cop,
                  desc: "Add Git Cop support.",
                  type: :boolean,
                  default: configuration.to_h.dig(:generate, :git_cop)
    method_option :rspec,
                  desc: "Add RSpec support.",
                  type: :boolean,
                  default: configuration.to_h.dig(:generate, :rspec)
    method_option :reek,
                  desc: "Add Reek support.",
                  type: :boolean,
                  default: configuration.to_h.dig(:generate, :reek)
    method_option :rubocop,
                  desc: "Add Rubocop support.",
                  type: :boolean,
                  default: configuration.to_h.dig(:generate, :rubocop)
    method_option :scss_lint,
                  desc: "Add SCSS Lint support.",
                  type: :boolean,
                  default: configuration.to_h.dig(:generate, :scss_lint)
    method_option :git_hub,
                  desc: "Add GitHub support.",
                  type: :boolean,
                  default: configuration.to_h.dig(:generate, :git_hub)
    method_option :code_climate,
                  desc: "Add Code Climate support.",
                  type: :boolean,
                  default: configuration.to_h.dig(:generate, :code_climate)
    method_option :gemnasium,
                  desc: "Add Gemnasium support.",
                  type: :boolean,
                  default: configuration.to_h.dig(:generate, :gemnasium)
    method_option :circle_ci,
                  desc: "Add Circle CI support.",
                  type: :boolean,
                  default: configuration.to_h.dig(:generate, :circle_ci)
    method_option :patreon,
                  desc: "Add Patreon support.",
                  type: :boolean,
                  default: configuration.to_h.dig(:generate, :patreon)
    # rubocop:disable Metrics/AbcSize
    def generate name
      print_cli_and_rails_engine_option_error && return if options.cli? && options.rails?

      say_status :info, "Generating gem...", :green

      setup_configuration name: name, options: options.to_h
      self.class.generators.each { |generator| generator.run self, configuration: configuration }

      say_status :info, "Gem generation finished.", :green
    end

    desc "-o, [--open=GEM]", "Open a gem in default editor."
    map %w[-o --open] => :open
    def open name
      process_gem name, "edit"
    end

    desc "-r, [--read=GEM]", "Open a gem in default browser."
    map %w[-r --read] => :read
    def read name
      say_status :error, "Gem home page is not defined.", :red unless process_gem(name, "visit")
    end

    desc "-c, [--config]", "Manage gem configuration."
    map %w[-c --config] => :config
    method_option :edit,
                  aliases: "-e",
                  desc: "Edit gem configuration.",
                  type: :boolean, default: false
    method_option :info,
                  aliases: "-i",
                  desc: "Print gem configuration.",
                  type: :boolean, default: false
    def config
      path = self.class.configuration.path

      if options.edit? then `#{ENV["EDITOR"]} #{path}`
      elsif options.info?
        path ? say(path) : say("Configuration doesn't exist.")
      else help(:config)
      end
    end

    desc "-v, [--version]", "Show gem version."
    map %w[-v --version] => :version
    def version
      say Identity.version_label
    end

    desc "-h, [--help=COMMAND]", "Show this message or get help for a command."
    map %w[-h --help] => :help
    def help task = nil
      say and super
    end

    private

    attr_reader :configuration

    def setup_configuration name:, options: {}
      @configuration = self.class.configuration.to_h.merge(
        gem: {
          label: name.titleize,
          name: name,
          path: name.snakecase,
          class: name.camelcase,
          platform: "Gem::Platform::RUBY",
          url: Git.github_url(name),
          license: "MIT"
        },
        generate: options.symbolize_keys
      )
    end

    def print_cli_and_rails_engine_option_error
      say_status :error,
                 "Generating a gem with CLI and Rails Engine functionality is not allowed. " \
                 "Build separate gems for improved separation of concerns and design.",
                 :red
    end
  end
end
