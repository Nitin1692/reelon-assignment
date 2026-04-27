class Current < ActiveSupport::CurrentAttributes
  attribute :user
  attribute :request_id
  attribute :ip_address
end
