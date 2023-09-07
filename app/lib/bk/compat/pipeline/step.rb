# frozen_string_literal: true

module BK
  module Compat
    # simple waiting step
    class WaitStep
      def to_h
        'wait'
      end

      def <<(_obj)
        raise 'Can not add to a wait step'
      end
    end

    # basic command step
    class CommandStep
      attr_accessor :label, :key, :agents, :plugins, :depends_on, :soft_fail, :conditional
      attr_reader :commands, :env # we define special writers

      def initialize(label: nil, key: nil, agents: {}, commands: [], plugins: [], depends_on: [], soft_fail: nil,
                     env: nil, conditional: nil)
        self.label = label
        self.commands = commands
        self.agents = agents
        self.key = key
        self.plugins = plugins
        self.depends_on = depends_on
        self.soft_fail = soft_fail
        self.env = env
        self.conditional = conditional
      end

      def commands=(value)
        @commands = [*value].flatten
      end

      def env=(value)
        @env = if value.is_a?(BK::Compat::Environment)
                 value
               else
                 BK::Compat::Environment.new(value)
               end
      end

      def to_h
        {}.tap do |h|
          h[:key] = @key if @key
          h[:label] = @label if @label
          h[:agents] = @agents unless @agents.empty?
          if @commands.is_a?(Array)
            if @commands.length == 1
              h[:command] = @commands.first
            elsif @commands.length > 1
              h[:commands] = @commands
            end
          end
          h[:env] = @env.to_h if @env && !@env.empty?
          h[:depends_on] = @depends_on if @depends_on && !@depends_on.empty?
          h[:plugins] = @plugins.map(&:to_h) if @plugins && !@plugins.empty?
          h[:soft_fail] = @soft_fail unless @soft_fail.nil?
          h[:if] = @conditional unless @conditional.nil?
        end
      end

      def <<(new_step)
        if new_step.is_a?(self.class)
          env.merge(new_step.env)
          agents.merge(new_step.agents)
          @commands.concat(new_step.commands)
          @plugins.concat(new_step.plugins)

          # TODO: add soft_fail, depends and ifs
          @depends_on.concat(new_step.commands)
        elsif new_step.is_a?(BK::Compat::WaitStep)
          raise 'Can not add a wait step to another step'
        else
          @commands.concat(new_step)
        end
      end
    end

    # group step
    class GroupStep
      attr_accessor :label, :key, :steps, :conditional

      def initialize(label: nil, key: nil, steps: [], conditional: nil)
        @label = label
        @key = key
        @steps = steps
        @conditional = conditional
      end

      def to_h
        { group: @label, key: @key, steps: @steps.map(&:to_h) }.tap do |h|
          h[:if] = @conditional unless @conditional.nil?
        end
      end
    end
  end
end
