# frozen_string_literal: true

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
    attr_accessor :base_url, :access_key, :secret_key, :rest_client, :timestamp, :salt

    # Initilize the Service by giving Sandbox or Production credientials i.e:
    #  rapid_api_endpoint: "https://sandboxapi.rapyd.net"  
    #  rapid_access_key: "sdqbdb34k3jb432h4vjh32v4j2h3v4"
    #  rapyd_secret_key: "dew123123qbdb34k3jb432h4vjh32v4j2h3v4" 
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
      Base64.urlsafe_encode64(mac)
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    # Get the identification documents information with country e.g US
    def identification_type_information(country)
      add_timestamp
      add_salt
      headers = { 'content-type' => 'application/json', 'signature' => signature('', 'get', "/v1/identities/types?country=#{country}"),
                  'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.getCall("/v1/identities/types?country=#{country}", headers)
      if response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS'
        JSON.parse(response.body)
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    # Search For existing wallet with wallet_id i.e. ewallet_db405029bac88de81f3072f31fcf0442
    def wallet_information(wallet_id)
      add_timestamp
      add_salt
      headers = { 'content-type' => 'application/json', 'signature' => signature('', 'get', "/v1/user/#{wallet_id}"),
                  'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
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

    # Search For existing wallet with wallet_id i.e. 
    # {
    #   "first_name": "John",
    #   "last_name": "Doe",
    #   "ewallet_reference_id": "e-7765",
    #   "type": "person",
    #   "contact": {
    #       "phone_number": "+14155551234",
    #       "email": "johndoe@rapyd.net",
    #       "first_name": "John",
    #       "last_name": "Doe",
    #       "contact_type": "personal",
    #       "address": {
    #           "name": "John Doe",
    #           "line_1": "123 Main Street",
    #           "city": "Anytown",
    #           "state": "NY",
    #           "country": "US",
    #           "zip": "12345",
    #           "phone_number": "+14155551234"
    #       },
    #       "identification_type": "PA",
    #       "identification_number": "1234567890",
    #       "date_of_birth": "11/22/2000",
    #       "country": "US"
    #   }
    # }
    def create_wallet_with_contact(body)
      add_timestamp
      add_salt
      headers = { 'Content-type' => 'application/json', 'signature' => signature(body.to_json, 'post', '/v1/user'),
                  'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.postCall('/v1/user', body.to_json, headers)
      if (response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['data']['id'].present?
        JSON.parse(response.body)['data']
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def update_wallet(body)
      add_timestamp
      add_salt
      headers = { 'Content-type' => 'application/json', 'signature' => signature(body.to_json, 'put', '/v1/user'),
                  'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.putCall('/v1/user', body.to_json, headers)
      if (response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['data']['id'].present?
        JSON.parse(response.body)['data']
      end
    rescue StandardError => e
      Rails.logger.error e
      puts e
      nil
    end

    def disable_wallet(body)
      add_timestamp
      add_salt
      headers = { 'Content-type' => 'application/json', 'signature' => signature(body.to_json, 'put', '/v1/user/disable'),
                  'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.putCall('/v1/user/disable', body.to_json, headers)
      if (response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['status']['operation_id'].present?
        JSON.parse(response.body)['status']
      end
    rescue StandardError => e
      nil
    end

    def enable_wallet(body)
      add_timestamp
      add_salt
      headers = { 'Content-type' => 'application/json', 'signature' => signature(body.to_json, 'put', '/v1/user/enable'),
                  'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.putCall('/v1/user/enable', body.to_json, headers)
      if (response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['status']['operation_id'].present?
        JSON.parse(response.body)['status']
      end
    rescue StandardError => e
      nil
    end

    def delete_wallet(wallet_id)
      add_timestamp
      add_salt
      headers = { 'Content-type' => 'application/json', 'signature' => signature('', 'delete', "/v1/user/#{wallet_id}"),
                  'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.deleteCall("/v1/user/#{wallet_id}",headers)
      if (response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['status']['operation_id'].present?
        JSON.parse(response.body)['status']
      end
    rescue StandardError => e
      nil
    end

    def add_contact_to_wallet(body,wallet_id)
      add_timestamp
      add_salt
      headers = { 'Content-type' => 'application/json', 'signature' => signature(body.to_json, 'post', "/v1/ewallets/#{wallet_id}/contacts"),
                  'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.postCall("/v1/ewallets/#{wallet_id}/contacts", body.to_json, headers)
      if (response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['data']['id'].present?
        JSON.parse(response.body)['data']
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def update_contact_in_wallet(body,wallet_id,contact_id)
      add_timestamp
      add_salt
      headers = { 'Content-type' => 'application/json', 'signature' => signature(body.to_json, 'post', "/v1/ewallets/#{wallet_id}/contacts/#{contact_id}"),
                  'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.postCall("/v1/ewallets/#{wallet_id}/contacts/#{contact_id}", body.to_json, headers)
      if (response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['data']['id'].present?
        JSON.parse(response.body)['data']
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def retrieve_wallet_contact_information(wallet_id,contact_id)
      add_timestamp
      add_salt
      headers = { 'content-type' => 'application/json', 'signature' => signature('', 'get', "/v1/ewallets/#{wallet_id}/contacts/#{contact_id}"),
                  'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.getCall("/v1/ewallets/#{wallet_id}/contacts/#{contact_id}", headers)
      if response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS'
        JSON.parse(response.body)
      else
        msg
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def retrieve_list_of_wallet_contacts(wallet_id)
      add_timestamp
      add_salt
      headers = { 'content-type' => 'application/json', 'signature' => signature('', 'get', "/v1/ewallets/#{wallet_id}/contacts"),
                  'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.getCall("/v1/ewallets/#{wallet_id}/contacts", headers)
      if response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS'
        JSON.parse(response.body)
      else
        msg
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def delete_wallet_contact(wallet_id,contact_id)
      add_timestamp
      add_salt
      headers = { 'Content-type' => 'application/json', 'signature' => signature('', 'delete', "/v1/ewallets/#{wallet_id}/contacts/#{contact_id}"),
                  'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.deleteCall("/v1/ewallets/#{wallet_id}/contacts/#{contact_id}",headers)
      if (response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['status']['operation_id'].present?
        JSON.parse(response.body)['status']
      end
    rescue StandardError => e
      nil
    end


    def transfer_with_wallet(body)
      add_timestamp
      add_salt
      headers = {'Content-type' => 'application/json', 'signature' => signature(body.to_json, 'post', '/v1/account/transfer'), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key}
      response, msg = rest_client.postCall('/v1/account/transfer', body.to_json, headers)
      if (response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['data']['id'].present?
        JSON.parse(response.body)['data']
      else
        nil
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end


    def set_transfer_with_wallet_response(body)
      add_timestamp
      add_salt
      headers = {'Content-type' => 'application/json', 'signature' => signature(body.to_json, 'post', '/v1/account/transfer/response'), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key}
      response, msg = rest_client.postCall('/v1/account/transfer/response', body.to_json, headers)
      if (response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['data']['id'].present?
        JSON.parse(response.body)['data']
      else
        nil
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def put_funds_on_hold(body)
      add_timestamp
      add_salt
      headers = {'Content-type' => 'application/json', 'signature' => signature(body.to_json, 'post', '/v1/account/balance/hold'), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key}
      response, msg = rest_client.postCall('/v1/account/balance/hold', body.to_json, headers)
      if (response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['data']['id'].present?
        JSON.parse(response.body)['data']
      else
        nil
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def release_funds_on_hold(body)
      add_timestamp
      add_salt
      headers = {'Content-type' => 'application/json', 'signature' => signature(body.to_json, 'post', '/v1/account/balance/release'), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key}
      response, msg = rest_client.postCall('/v1/account/balance/release', body.to_json, headers)
      if (response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['data']['id'].present?
        JSON.parse(response.body)['data']
      else
        nil
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def set_wallet_account_limit(body,wallet_id)
      add_timestamp
      add_salt
      headers = {'Content-type' => 'application/json', 'signature' => signature(body.to_json, 'post', "/v1/user/#{wallet_id}/account/limits"), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key}
      response, msg = rest_client.postCall("/v1/user/#{wallet_id}/account/limits", body.to_json, headers)
      if (response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['data'][0]['id'].present?
        JSON.parse(response.body)['data']
      else
        nil
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def delete_wallet_account_limit(body,wallet_id)
      add_timestamp
      add_salt
      headers = { 'Content-type' => 'application/json', 'signature' => signature(body.to_json, 'delete', "/v1/user/wallet/#{wallet_id}/limits"),
                  'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.delete("/v1/user/wallet/#{wallet_id}/limits",body.to_json,headers)
      if (response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['data'][0]['id'].present?
        JSON.parse(response.body)['status']
      end
    rescue StandardError => e
      nil
    end

    def list_of_wallet_transactions(wallet_id)
      add_timestamp
      add_salt
      headers = { 'content-type' => 'application/json', 'signature' => signature('', 'get', "/v1/user/#{wallet_id}/transactions"),
                  'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.getCall("/v1/user/#{wallet_id}/transactions", headers)
      if response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS'
        JSON.parse(response.body)
      else
        msg
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def retrieve_wallet_balance(wallet_id)
      add_timestamp
      add_salt
      headers = { 'content-type' => 'application/json', 'signature' => signature('', 'get', "/v1/user/#{wallet_id}/accounts"),
                  'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.getCall("/v1/user/#{wallet_id}/accounts", headers)
      if response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS'
        JSON.parse(response.body)
      else
        msg
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    def details_of_wallet_transaction(wallet_id,transaction_id)
      add_timestamp
      add_salt
      headers = { 'content-type' => 'application/json', 'signature' => signature('', 'get', "/v1/user/#{wallet_id}/transactions/#{transaction_id}"),
                  'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.getCall("/v1/user/#{wallet_id}/transactions/#{transaction_id}", headers)
      if response.present? && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS'
        JSON.parse(response.body)
      else
        msg
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end


    # Verifying the identity of a personal contact for a Rapyd Wallet by giving country ewalllet_id and contact_id i.e. US, ewallet_db405029bac88de81f3072f31fcf0442, contact_db34235235423423423343dfewf32rdsc
    def identify_contact(country, ewallet, contact)
      body = {
        'country' => country,
        'ewallet' => ewallet,
        'reference_id' => "ArtWallSt-#{rand(0..9)}-" + rand(1000..2000).to_s,
        'contact' => contact
      }.to_json

      add_timestamp
      add_salt
      headers = { 'Content-type' => 'application/json', 'signature' => signature(body, 'post', '/v1/hosted/idv'),
                  'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.postCall('/v1/hosted/idv', body, headers)
      if (response.present? && response.class != String && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['data']['id'].present?
        JSON.parse(response.body)
      end
    end

    # List of all transactions for existing wallet_id and by type i.e. ewallet_db405029bac88de81f3072f31fcf0442 , payout_funds_out
    def wallet_transactions_listing(wallet_id, type)
      add_timestamp
      add_salt
      headers = { 'content-type' => 'application/json',
                  'signature' => signature('', 'get', "/v1/user/#{wallet_id}/transactions?type=#{type}"), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.getCall("/v1/user/#{wallet_id}/transactions?type=#{type}", headers)
      JSON.parse(response)['data'] if response.present?
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    # You can create a payout sender by giving the required body params i.e 
    # {
    #   "currency": "PHP",
    #   "country": "PH",
    #   "entity_type": "individual",
    #   "first_name": "John",
    #   "last_name": "Doe",
    #   "identification_type": "work permit",
    #   "identification_value": "6584133",
    # // Fields from 'sender_required_fields' in the response to 'Get Payout Method Type Required Fields'
    #   "phone_number": "621212938122",
    #   "date_of_birth": "12/12/1980",
    #   "address": "123 Main Street",
    # }
    def create_payout_sender(body)
      add_timestamp
      add_salt
      headers = { 'Content-type' => 'application/json',
                  'signature' => signature(body.to_json, 'post', '/v1/payouts/sender'), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.postCall('/v1/payouts/sender', body.to_json, headers)
      if (response.present? && response.class != String && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['data']['id'].present?
        JSON.parse(response.body)['data']
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    # You can create a payout by giving the required body params i.e
    #  {
    #     "category": "bank",
    #     "default_payout_method_type": "us_visa_card",
    #     "country": "US",
    #     "currency": "USD",
    #     "entity_type": "individual",
    #     "first_name": "John",
    #     "identification_type": "work permit",
    #     "identification_value": "6658412",
    #     "last_name": "Doe",
    #     "payment_type": "regular",
    #     "address": "123 Main Street",
    #     "city": "NY",
    #     "postcode": "12345",
    #     "account_number": "1234567890",
    #     "merchant_reference_id": "JohnDoeOffice",
    #     "bsb_code": "154126"
    # }
    def create_payout_beneficiary(body)
      add_timestamp
      add_salt
      headers = { 'Content-type' => 'application/json',
                  'signature' => signature(body.to_json, 'post', '/v1/payouts/beneficiary'), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
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

    # You can create a payout by giving body params i.e
    # {
    #     "beneficiary": {
    #         "name": "Jane Doe",
    #         "address": "456 Second Street",
    #         "email": "janedoe@rapyd.net",
    #         "country": "US",
    #         "city": "Anytown",
    #         "postcode": "10101",
    #         "account_number": "BG96611020345678",
    #         "bank_name": "US General Bank",
    #         "state": "NY",
    #         "identification_type": "SSC",
    #         "identification_value": "123456789",
    #         "bic_swift": "BUINBGSF",
    #         "ach_code": "123456789"
    #     },
    #     "beneficiary_country": "US",
    #     "beneficiary_entity_type": "individual",
    #     "description": "Payout - Bank Transfer: Beneficiary/Sender objects",
    #     "merchant_reference_id": "GHY-0YU-HUJ-POI",
    #     "ewallet": "ewallet_4f1757749b8858160274e6db49f78ff3",
    #     "payout_amount": "110",
    #     "payout_currency": "USD",
    #     "payout_method_type": "us_general_bank",
    #     "sender": {
    #         "name": "John Doe",
    #         "address": "123 First Street",
    #         "city": "Anytown",
    #         "state": "NY",
    #         "date_of_birth": "22/02/1980",
    #         "postcode": "12345",
    #         "phonenumber": "621212938122",
    #         "remitter_account_type": "Individual",
    #         "source_of_income": "salary",
    #         "identification_type": "License No",
    #         "identification_value": "123456789",
    #         "purpose_code": "ABCDEFGHI",
    #         "account_number": "123456789",
    #         "beneficiary_relationship": "client"
    #     },
    #     "sender_country": "US",
    #     "sender_currency": "USD",
    #     "sender_entity_type": "individual",
    #     "statement_descriptor":"GHY* Limited Access 800-123-4567",
    #     "metadata": {
    #         "merchant_defined": true
    #     }   
    # }
    def create_artist_payout_to_bank(body)
      add_timestamp
      add_salt
      headers = { 'Content-type' => 'application/json', 'signature' => signature(body.to_json, 'post', '/v1/payouts'),
                  'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.postCall('/v1/payouts',  body.to_json, headers)
      if (response.present? && response.class != String && response.body.present? && JSON.parse(response.body)['status']['status'] == 'SUCCESS') && JSON.parse(response.body)['data']['id'].present?
        JSON.parse(response.body)['data']
      end
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    # You can create a payout sender by giving the sender id  i.e sender_efa35c7f32b39aa30f6bccfba640fcd0
    def payout_sender(sender)
      add_timestamp
      add_salt
      headers = { 'content-type' => 'application/json',
                  'signature' => signature('', 'get', "/v1/payouts/sender/#{sender}"), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.getCall("/v1/payouts/sender/#{sender}", headers)
      JSON.parse(response)['data'] if response.present?
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    # Use the GET method to retrieve details of a payout beneficiary by giving beneficiary i.e beneficiary_2c0aca540aca5d2f7700270b201b2157
    def payout_beneficiary(beneficiary)
      add_timestamp
      add_salt
      headers = { 'content-type' => 'application/json',
                  'signature' => signature('', 'get', "/v1/payouts/beneficiary/#{beneficiary}"), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.getCall("/v1/payouts/beneficiary/#{beneficiary}", headers)
      JSON.parse(response)['data'] if response.present?
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    # List of all available payout method types for bank transfers by giving beneficiary_country, payout_currency, category, sender_entity i.e US,usd,bank,individual
    def payout_method_type_list(beneficiary_country, payout_currency, category, sender_entity)
      add_timestamp
      add_salt
      headers = { 'content-type' => 'application/json',
                  'signature' => signature('', 'get', "/v1/payouts/supported_types?beneficiary_country=#{beneficiary_country}&payout_currency=#{payout_currency}&category=#{category}&sender_entity=#{sender_entity}"), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.getCall(
        "/v1/payouts/supported_types?beneficiary_country=#{beneficiary_country}&payout_currency=#{payout_currency}&category=#{category}&sender_entity=#{sender_entity}", headers
      )
      JSON.parse(response)['data'] if response.present?
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    # You can additional fields while selecting the payout method type such as payout_method_type, beneficiary_country, beneficiary_entity_type, amount, payout_currency, sender_country, sender_currency, sender_entity_type i.e bank,US,individual,35000,usd,usd,individual
    def additional_fields(payout_method_type, beneficiary_country, beneficiary_entity_type, amount, payout_currency, sender_country, sender_currency, sender_entity_type)
      add_timestamp
      add_salt
      headers = { 'content-type' => 'application/json',
                  'signature' => signature('', 'get', "/v1/payouts/#{payout_method_type}/details?beneficiary_country=#{beneficiary_country}&beneficiary_entity_type=#{beneficiary_entity_type}&amount=#{amount}&payout_currency=#{payout_currency}&sender_country=#{sender_country}&sender_currency=#{sender_currency}&sender_entity_type=#{sender_entity_type}"), 'salt' => salt, 'timestamp' => timestamp, 'access_key' => access_key }
      response, msg = rest_client.getCall(
        "/v1/payouts/#{payout_method_type}/details?beneficiary_country=#{beneficiary_country}&beneficiary_entity_type=#{beneficiary_entity_type}&amount=#{amount}&payout_currency=#{payout_currency}&sender_country=#{sender_country}&sender_currency=#{sender_currency}&sender_entity_type=#{sender_entity_type}", headers
      )
      JSON.parse(response)['data'] if response.present?
    rescue StandardError => e
      Rails.logger.error e
      nil
    end

    # private
      
  end
end
