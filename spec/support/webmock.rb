require "webmock/rspec"

class WebMock::RequestStub
  def to_return_json(hash = {}, options = {})
    options[:body] = MultiJson.dump(hash)
    to_return(options)
  end

  def to_return_fm(hash_or_status = {}, options = {})
    if hash_or_status == false
      wrapped_hash =
        { response: {},
          messages: [{ code: "500", message: "Error" }] }

      options[:status] = 500
    else
      wrapped_hash =
        { response: hash_or_status,
          messages: [{ code: "0", message: "OK" }] }
    end

    to_return_json(wrapped_hash, options)
  end
end

# Don't raise but report uncaught net connections
WebMock.allow_net_connect!
WebMock.stub_request(:any, /.*/).to_return do |request|
  puts "\e[35mUNSTUBBED REQUEST:\e[0m #{request.method.upcase} #{request.uri}"
  { body: nil }
end
