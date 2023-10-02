# frozen_string_literal: true

module BK
  module Compat
    module CircleCISteps
      # Implementation of native step translation
      class Builtins
        def register
          [
            %w[
              add_ssh_keys attach_workspace checkout deploy persist_to_workspace restore_cache
              run save_cache setup_remote_docker store_artifacts store_test_results when
            ].freeze,
            method(:translator)
          ]
        end

        private

        def translator(action, config)
          send("translate_#{action.gsub('-', '_')}", config)
        end

        def translate_add_ssh_keys(_config)
          ['# `add_ssh_keys` has no translation, your agent should have the keys to connect where it needs to']
        end

        def translate_attach_workspace(config)
          # TODO: it may be a good idea to use a prefix for workspace artifacts
          [
            '# :circleci: attach_workspace ',
            "if [ ! -d '#{config['at']}' ]; then mkdir '#{config['at']}'; fi",
            "cd '#{config['at']}'",
            'buildkite agent artifact download *'
          ]
        end

        def translate_checkout(*_args)
          ['# No need for checkout, the agent takes care of that']
        end

        def translate_deploy(_config)
          # TODO
          ['# `deploy` not implemented yet (and it has been deprecated)']
        end

        def translate_persist_to_workspace(config)
          # TODO: it may be a good idea to use a prefix for workspace artifacts
          # possibily with a tempdir and a symlink
          [
            "cd #{config['root']}",
            "buildkite-agent artifact upload '#{config['paths'].join(';')}'",
            'cd -'
          ]
        end

        def translate_restore_cache(_config)
          # TODO
          ['# `restore_cache` not implemented yet']
        end

        def translate_run(config)
          return [config] if config.is_a?(String)

          [
            config.include?('name') ? "echo '~~~ #{config['name']}'" : nil,
            config.include?('working_directory') ? ['OLD_DIR="$PWD"', "cd #{config['working_directory']}"] : nil,
            config.include?('no_output_timeout') ? '# no_output_timeout option has no translation' : nil,
            config.include?('shell') ? '# shell is environment-dependent and should be configured in the agent' : nil,
            generate_command_string(commands: config['command'],
                                    env: config.fetch('environment', {}),
                                    background: config.fetch('background', false)),
            config.include?('working_directory') ? 'cd "$OLD_DIR"' : nil
          ].compact
        end

        def generate_command_string(commands: [], env: {}, background: false)
          vars = env&.map { |k, v| "#{k}='#{v}'" }&.join(' ')
          bg = background ? '&' : ''
          cmd = commands.lines(chomp: true).join('; ')
          "#{vars} (#{cmd}) #{bg}".strip
        end

        def translate_save_cache(_config)
          # TODO
          ['# `save_cache` not implemented yet']
        end

        def translate_setup_remote_docker(_config)
          ['#  No need to setup remote docker, use the host docker']
        end

        def translate_store_artifacts(_config)
          # TODO
          ['# `store_artifacts` not implemented yet']
        end

        def translate_store_test_results(_config)
          # TODO
          ['# `store_test_results` has no direct translation (you should try Test Analytics!)']
        end

        def translate_when(_config)
          # TODO
          ['# `when` not implemented yet']
        end
      end
    end
  end
end