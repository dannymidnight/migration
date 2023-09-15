# frozen_string_literal: true

require_relative '../environment'

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
      attr_accessor :agents, :conditional, :depends_on, :key, :label, :plugins, :soft_fail
      attr_reader :commands, :env # we define special writers

      def list_attributes
        %w[commands depends_on plugins]
      end

      def hash_attributes
        %w[agents env]
      end

      def initialize(**kwargs)
        kwargs.map do |k, v|
          # set attributes passed through as-is
          send("#{k}=", v)
        end

        # nil as default are not acceptable
        list_attributes.each { |k| send("#{k}=", []) unless kwargs.include?(k) }
        hash_attributes.each { |k| send("#{k}=", {}) unless kwargs.include?(k) }
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
        instance_attributes.tap do |h|
          # rename conditional to if (a reserved word as an attribute or instance variable is complicated)
          h[:if] = h.delete('conditional')

          # special handling
          h[:plugins] = @plugins.map(&:to_h)
          h[:env] = @env&.to_h

          # remove empty and nil values
          h.delete_if { |_, v| v&.empty? }
        end
      end

      def <<(new_step)
        case new_step
        when BK::Compat::WaitStep
          raise 'Can not add a wait step to another step'
        when self.class
          merge(new_step)
        when BK::Compat::Plugin
          @plugins << new_step
        else
          @commands.concat(new_step)
        end
      end

      def merge(new_step)
        list_attributes.each { |a| send(a).concat(new_step.send(a)) }
        hash_attributes.each { |a| send(a).merge!(new_step.send(a)) }

        @conditional = xxand(conditional, new_step.conditional)

        # TODO: these could be a hash with exit codes
        @soft_fail = soft_fail || new_step.soft_fail
      end

      def self.instance_attributes
        # helper method to get all instance attributes as a dictionary
        instance_variables.to_h { |v| [v.to_s.delete_prefix('@').to_sym, instance_variable_get(v)] }
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
