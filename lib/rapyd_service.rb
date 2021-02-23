# Module RapydService
#
# The module is written for manage all Rapyd payment gateway calls and processing
#
# Author:: Furqan Wasi
# 

require_relative 'rapyd_service/version'
require_relative 'rapyd_service/rest_client_service'
require 'rapyd_service'

module RapydService
  class RapydService
    attr_accessor :base_url
    attr_accessor :access_key
    attr_accessor :secret_key
    attr_accessor :rest_client
    attr_accessor :timestamp
    attr_accessor :salt

    def initialize(rapid_api_endpoint, rapid_access_key, rapyd_secret_key)
      if rapid_api_endpoint.present? && rapid_access_key.present? && rapyd_secret_key.present?
        self.base_url = rapid_api_endpoint
        self.access_key = rapid_access_key
        self.secret_key = rapyd_secret_key
        self.rest_client = RestClientService.new(base_url)
      else
        raise StandardError, 'Missing paramteres'
      end
    end

    # add_timestamp
    #
    # @return [String]
    def add_timestamp
      self.timestamp = Time.now.to_i.to_s
    end

    # add_salt
    #
    # @return [String]
    def add_salt
      o = [('a'..'z')].map(&:to_a).flatten
      self.salt = (0...8).map { o[rand(o.length)] }.join
    end

    # Rapay signature generator
    #
    # @param [Object]  body
    # @param [Object]  http_method
    # @param [Object]  uri
    # @return [Object]
    def signature(body, http_method, uri)
      to_sign = if body.present?
                  "#{http_method}#{uri}#{salt}#{timestamp}#{access_key}#{secret_key}#{body}"
                else
                  "#{http_method}#{uri}#{salt}#{timestamp}#{access_key}#{secret_key}"
                end
      mac = OpenSSL::HMAC.hexdigest('SHA256', secret_key, to_sign)
      tempBS64 = Base64.urlsafe_encode64(mac)
      tempBS64
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def identification_type_information(country)
      add_timestamp
      add_salt
      headers = { 'content-type' => 'application/json', 'signature' => signature('', 'get', "/v1/identities/types?country=#{country}"),
                  'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.getCall("/v1/identities/types?country=#{country}", headers)
      JSON.parse(response.body) if response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS'
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    # Search For existing wallet with wallet_id i.e. ewallet_db405029bac88de81f3072f31fcf0442
    #
    # @param [Object]  wallet_id
    # @return [Object]
    def wallet_information(wallet_id)
      add_timestamp
      add_salt
      headers = { 'content-type' => 'application/json', 'signature' => signature('', 'get', "/v1/user/#{wallet_id}"), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.getCall("/v1/user/#{wallet_id}", headers)
      if response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS'
        JSON.parse(response.body)
      else
        msg
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def create_wallet_with_contact(body)
      add_timestamp
      add_salt
      headers = { 'Content-type' => 'application/json', 'signature' => signature(body.to_json, 'post', '/v1/user'), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.postCall('/v1/user', body.to_json, headers)
      if (response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['data']['id'].present?
        JSON.parse(response.body)['data']
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def identify_contact(country, ewallet, contact)
      body = {
        'country' => country,
        'ewallet' => ewallet,
        'reference_id' => "ArtWallSt-#{rand(0..9)}-" + rand(1000..2000).to_s,
        'contact' => contact
      }.to_json

      add_timestamp
      add_salt
      headers = { 'Content-type' => 'application/json', 'signature' => signature(body, 'post', '/v1/hosted/idv'), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.postCall('/v1/hosted/idv', body, headers)
      if (response.present? && response.class != String && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['data']['id'].present?
        JSON.parse(response.body)
      end
    end

    # List of all transactions for existing wallet_id i.e. ewallet_db405029bac88de81f3072f31fcf0442
    def wallet_transactions_listing(wallet_id, type)
      add_timestamp
      add_salt
      headers = { 'content-type' => 'application/json', 'signature' => signature('', 'get', "/v1/user/#{wallet_id}/transactions?type=#{type}"), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.getCall("/v1/user/#{wallet_id}/transactions?type=#{type}", headers)
      JSON.parse(response)['data'] if response.present?
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def create_payout_sender(body)
      add_timestamp
      add_salt
      headers = { 'Content-type' => 'application/json', 'signature' => signature(body.to_json, 'post', '/v1/payouts/sender'), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.postCall('/v1/payouts/sender', body.to_json, headers)
      if (response.present? && response.class != String && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['data']['id'].present?
        JSON.parse(response.body)['data']
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def create_payout_beneficiary(body)
      add_timestamp
      add_salt
      headers = { 'Content-type' => 'application/json', 'signature' => signature(body.to_json, 'post', '/v1/payouts/beneficiary'), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.postCall('/v1/payouts/beneficiary', body.to_json, headers)
      if (response.present? && response.class != String && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['data']['id'].present?
        JSON.parse(response.body)['data']
      else
        msg
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def create_artist_payout_to_bank(body)
      add_timestamp
      add_salt
      headers = { 'Content-type' => 'application/json', 'signature' => signature(body.to_json, 'post', '/v1/payouts'), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.postCall('/v1/payouts',  body.to_json, headers)
      if (response.present? && response.class != String && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['data']['id'].present?
        JSON.parse(response.body)['data']
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def payout_sender(sender)
      add_timestamp
      add_salt
      headers = { 'content-type' => 'application/json', 'signature' => signature('', 'get', "/v1/payouts/sender/#{sender}"), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.getCall("/v1/payouts/sender/#{sender}", headers)
      JSON.parse(response)['data'] if response.present?
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def payout_beneficiary(beneficiary)
      add_timestamp
      add_salt
      headers = { 'content-type' => 'application/json', 'signature' => signature('', 'get', "/v1/payouts/beneficiary/#{beneficiary}"), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.getCall("/v1/payouts/beneficiary/#{beneficiary}", headers)
      JSON.parse(response)['data'] if response.present?
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def payout_method_type_list(beneficiary_country, payout_currency, category, sender_entity)
      add_timestamp
      add_salt
      headers = { 'content-type' => 'application/json', 'signature' => signature('', 'get', "/v1/payouts/supported_types?beneficiary_country=#{beneficiary_country}&payout_currency=#{payout_currency}&category=#{category}&sender_entity=#{sender_entity}"), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.getCall("/v1/payouts/supported_types?beneficiary_country=#{beneficiary_country}&payout_currency=#{payout_currency}&category=#{category}&sender_entity=#{sender_entity}", headers)
      JSON.parse(response)['data'] if response.present?
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def additional_fields(payout_method_type, beneficiary_country, beneficiary_entity_type, amount, payout_currency, sender_country, sender_currency, sender_entity_type)
      add_timestamp
      add_salt
      headers = { 'content-type' => 'application/json', 'signature' => signature('', 'get', "/v1/payouts/#{payout_method_type}/details?beneficiary_country=#{beneficiary_country}&beneficiary_entity_type=#{beneficiary_entity_type}&amount=#{amount}&payout_currency=#{payout_currency}&sender_country=#{sender_country}&sender_currency=#{sender_currency}&sender_entity_type=#{sender_entity_type}"), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.getCall("/v1/payouts/#{payout_method_type}/details?beneficiary_country=#{beneficiary_country}&beneficiary_entity_type=#{beneficiary_entity_type}&amount=#{amount}&payout_currency=#{payout_currency}&sender_country=#{sender_country}&sender_currency=#{sender_currency}&sender_entity_type=#{sender_entity_type}", headers)
      JSON.parse(response)['data'] if response.present?
    rescue StandardError => e
      Rails.logger.error e
      nil
    end
  end
end
