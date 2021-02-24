# frozen_string_literal: true

# app/services/rest_client_service.rb
# app/services/rest_client_service.rb
#
# Module RestClientService
#
# Author::    Furqan Wasi

# Rest Client Service Class for all api calls
class RestClientService
  require 'rest-client'
  attr_accessor :end_point

  # @param [Object]  end_point
  # @return [Object]
  def initialize(end_point)
    self.end_point = end_point
  end

  # postCall used to send POST call
  #
  # @param [Object]  uri
  # @param [Object]  body
  # @param [Object]  headers
  # @return [String]
  def postCall(uri, body, headers)
    [RestClient.post(end_point + uri, body, headers), 'success']
  rescue StandardError => e
    [nil, "Failed to process this request #{end_point + uri}  #{e}"]
  end

  def putCall(uri, body, headers)
    [RestClient.put(end_point + uri, body, headers), 'success']
  rescue StandardError => e
    [nil, "Failed to process this request #{end_point + uri}  #{e}"]
  end

  # getCall used to send GET call
  #
  # @param [Object]  uri
  # @param [Object]  headers
  # @return [Object]
  def getCall(uri, headers)
    [RestClient.get(end_point + uri, headers), 'success']
  rescue StandardError => e
    [nil, "Failed to process this request #{end_point + uri} #{e}"]
  end
end
