module Temporal
  class Workflow
    class Dispatcher
      class DispatchHandler
        def initialize(handlers_for_target, id)
          @handlers_for_target = handlers_for_target
          @id = id
        end

        # Unregister the handler from the dispatcher
        def unregister
          handlers_for_target.delete(id)
        end

        private

        attr_reader :handlers_for_target, :id
      end

      WILDCARD = '*'.freeze
      TARGET_WILDCARD = '*'.freeze

      def initialize
        @handlers = Hash.new { |hash, key| hash[key] = {} }
        @next_id = 0
      end

      def register_handler(target, event_name, &handler)
        @next_id += 1
        handlers[target][@next_id] = [event_name, handler]

        DispatchHandler.new(handlers[target], @next_id)
      end

      def dispatch(target, event_name, args = nil)
        handlers_for(target, event_name).each do |handler|
          handler.call(*args)
        end
      end

      private

      attr_reader :handlers

      def handlers_for(target, event_name)
        handlers[target]
          .merge(handlers[TARGET_WILDCARD]) { raise 'Cannot resolve duplicate dispatcher handler IDs'}
          .select { |_, (name, _)| name == event_name || name == WILDCARD }
          .sort
          .map { |_, (_, handler)| handler }
      end
    end
  end
end
