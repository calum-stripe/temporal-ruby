require 'temporal/metadata'
require 'temporal/error_handler'
require 'temporal/errors'
require 'temporal/activity/context'
require 'temporal/concerns/payloads'
require 'temporal/connection/retryer'
require 'temporal/connection'

module Temporal
  class Activity
    class TaskProcessor
      include Concerns::Payloads

      def initialize(task, namespace, activity_lookup, middleware_chain, config)
        @task = task
        @namespace = namespace
        @metadata = Metadata.generate_activity_metadata(task, namespace)
        @task_token = task.task_token
        @activity_name = task.activity_type.name
        @activity_class = activity_lookup.find(activity_name)
        @middleware_chain = middleware_chain
        @config = config
      end

      def process
        start_time = Time.now

        Temporal.logger.debug("Processing Activity task", metadata.to_h)
        Temporal.metrics.timing('activity_task.queue_time', queue_time_ms, activity: activity_name, namespace: namespace, workflow: metadata.workflow_name)

        context = Activity::Context.new(connection, metadata)

        if !activity_class
          raise ActivityNotRegistered, 'Activity is not registered with this worker'
        end

        result = middleware_chain.invoke(metadata) do
          activity_class.execute_in_context(context, from_payloads(task.input))
        end

        # Do not complete asynchronous activities, these should be completed manually
        respond_completed(result) unless context.async?
      rescue StandardError, ScriptError => error
        Temporal::ErrorHandler.handle(error, config, metadata: metadata)

        respond_failed(error)
      ensure
        time_diff_ms = ((Time.now - start_time) * 1000).round
        Temporal.metrics.timing('activity_task.latency', time_diff_ms, activity: activity_name, namespace: namespace, workflow: metadata.workflow_name)
        Temporal.logger.debug("Activity task processed", metadata.to_h.merge(execution_time: time_diff_ms))
      end

      private

      attr_reader :task, :namespace, :task_token, :activity_name, :activity_class,
      :middleware_chain, :metadata, :config

      def connection
        @connection ||= Temporal::Connection.generate(config.for_connection)
      end

      def queue_time_ms
        scheduled = task.current_attempt_scheduled_time.to_f
        started = task.started_time.to_f
        ((started - scheduled) * 1_000).round
      end

      def respond_completed(result)
        Temporal.logger.info("Activity task completed", metadata.to_h)
        log_retry = proc do
          Temporal.logger.debug("Failed to report activity task completion, retrying", metadata.to_h)
        end
        Temporal::Connection::Retryer.with_retries(on_retry: log_retry) do
          connection.respond_activity_task_completed(namespace: namespace, task_token: task_token, result: result)
        end
      rescue StandardError => error
        Temporal.logger.error("Unable to complete Activity", metadata.to_h.merge(error: error.inspect))

        Temporal::ErrorHandler.handle(error, config, metadata: metadata)
      end

      def respond_failed(error)
        Temporal.logger.error("Activity task failed", metadata.to_h.merge(error: error.inspect))
        log_retry = proc do
          Temporal.logger.debug("Failed to report activity task failure, retrying", metadata.to_h)
        end
        Temporal::Connection::Retryer.with_retries(on_retry: log_retry) do
          connection.respond_activity_task_failed(namespace: namespace, task_token: task_token, exception: error)
        end
      rescue StandardError => error
        Temporal.logger.error("Unable to fail Activity task", metadata.to_h.merge(error: error.inspect))

        Temporal::ErrorHandler.handle(error, config, metadata: metadata)
      end
    end
  end
end
