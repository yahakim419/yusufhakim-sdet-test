# frozen_string_literal: true

module JsonHelpers
  def json_body
    JSON.parse(response.body)
  end
end
