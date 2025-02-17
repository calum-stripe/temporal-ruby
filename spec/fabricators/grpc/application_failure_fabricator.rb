require 'temporal/concerns/payloads'
class TestDeserializer
  include Temporal::Concerns::Payloads
end
# Simulates Temporal::Connection::Serializer::Failure
Fabricator(:api_application_failure, from: Temporal::Api::Failure::V1::Failure) do
  transient :error_class, :backtrace
  message { |attrs| attrs[:message] }
  stack_trace { |attrs| attrs[:backtrace].join("\n") }
  application_failure_info do |attrs|
    Temporal::Api::Failure::V1::ApplicationFailureInfo.new(
      type: attrs[:error_class],
      details: TestDeserializer.new.to_details_payloads(attrs[:message]),
    )
  end
end
