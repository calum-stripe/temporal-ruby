require 'temporal/connection/serializer/base'
require 'temporal/concerns/payloads'

module Temporal
  module Connection
    module Serializer
      class UpsertSearchAttributes < Base
        include Concerns::Payloads

        def to_proto
          Temporalio::Api::Command::V1::Command.new(
            command_type: Temporalio::Api::Enums::V1::CommandType::COMMAND_TYPE_UPSERT_WORKFLOW_SEARCH_ATTRIBUTES,
            upsert_workflow_search_attributes_command_attributes:
              Temporalio::Api::Command::V1::UpsertWorkflowSearchAttributesCommandAttributes.new(
                search_attributes: Temporalio::Api::Common::V1::SearchAttributes.new(
                  indexed_fields: to_search_attribute_payload(object.search_attributes || {})
                ),
              )
          )
        end
      end
    end
  end
end
