# frozen_string_literal: true

require_relative '../error'
require_relative '../translator'
require_relative '../pipeline'
require_relative 'gha/jobs'
require_relative 'gha/steps'

module BK
  module Compat
    # GitHub Actions converter
    class GitHubActions
      include StepTranslator
      require 'yaml'

      def self.name
        'GitHub Actions'
      end

      def self.option
        'gha'
      end

      def self.matches?(text)
        config = YAML.safe_load(text)
        # YAML translates the `on` key in YAML to ruby's `true` boolean
        mandatory_keys = ['jobs', true]

        config.is_a?(Hash) && mandatory_keys & config.keys == mandatory_keys
      end

      def initialize(text, options = {})
        @config = YAML.safe_load(text)
        @options = options

        GHABuiltins.new(register: method(:register_translator))
      end

      def parse
        # Pipeline with steps defined as jobs
        defaults = @config.fetch('defaults', {})
        Pipeline.new(
          steps: @config.fetch('jobs', {}).map { |key, config| parse_job(key, defaults.merge(config)) },
          env: @config.fetch('env', {})
        )
      end
    end
  end
end

require_relative '../parsers'

BK::Compat::Parsers.register_plugin(BK::Compat::GitHubActions)
