require "net/http"

module Spotify
  # Small wrapper around Net::HTTP: timeouts, JSON parsing and turning failures into
  # Spotify::Error, so callers only deal with one kind of exception.
  module Http
    TIMEOUT_SECONDS = 5

    module_function

    def request(method, url, headers: {}, form: nil, json: nil)
      uri = URI(url)
      has_body = form.present? || !json.nil?
      request = Net::HTTPGenericRequest.new(method, has_body, true, uri.request_uri, headers)
      request.set_form_data(form) if form
      if json
        request["Content-Type"] = "application/json"
        request.body = json.to_json
      end

      response = perform(uri, request)
      [response.code.to_i, parse_json(response.body)]
    end

    def perform(uri, request)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                          open_timeout: TIMEOUT_SECONDS, read_timeout: TIMEOUT_SECONDS) do |http|
        http.request(request)
      end
    rescue Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError => e
      raise Error, "Could not reach Spotify: #{e.class}"
    end

    def parse_json(body)
      body.present? ? JSON.parse(body) : {}
    rescue JSON::ParserError
      raise Error, "Spotify sent an invalid JSON response"
    end
  end
end
