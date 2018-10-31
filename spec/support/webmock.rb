require "webmock/rspec"

class WebMock::RequestStub
  def to_return_json(hash, options = {})
    options[:body] = MultiJson.dump(hash)
    to_return(options)
  end

  def to_return_fm(hash, options = {})
    wrapped_hash = {
      response: hash,
      messages: [{ code: "0", message: "OK" }]
    }

    to_return_json(wrapped_hash, options = {})
  end
end

# Don't raise but report uncaught net connections
WebMock.allow_net_connect!
WebMock.stub_request(:any, /.*/).to_return do |request|
  puts "\e[35mUNSTUBBED REQUEST:\e[0m #{request.method.upcase} #{request.uri}"
  { body: nil }
end
