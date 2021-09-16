require "webmock/rspec"

class WebMock::RequestStub
  def to_return_json(hash = {}, options = {})
    options[:headers] ||= {}
    options[:headers]["Content-Type"] = "application/json"
    options[:body] = JSON.dump(hash)
    to_return(options)
  end

  def to_return_fm(hash_or_status = {}, options = {})
    if hash_or_status == false || hash_or_status.kind_of?(Integer)
      error_code = hash_or_status.kind_of?(Integer) ? hash_or_status.to_s : "-1"

      wrapped_hash =
        { response: {},
          messages: [{ code: error_code, message: "Unknown error" }] }

      options[:status] = 500
    else
      wrapped_hash =
        { response: hash_or_status,
          messages: [{ code: "0", message: "OK" }] }
    end

    to_return_json(wrapped_hash, options)
  end
end

# Raise errors for unstubbed net connections
WebMock.disable_net_connect!
