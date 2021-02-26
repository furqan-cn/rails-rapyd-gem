# RapydService

## Installation

    Add this line to your application's Gemfile:
    gem 'rapyd_service', :git => 'git@github.com:furqan-cn/rails-rapyd-gem.git', branch: :main

    And then execute:
    $ bundle install


## Description
    Gem provides funtionalities
    1. Ewallet creation
    2. Identity verification
    3. Beneficiary creation
    4. Withdraw payout to bank(beneficiary) account
    5. Withdrawals history
    6. List of Beneficiaries
    7. List of supported country/currency(payout method type)
    8. Ewallet Information

## Usage
    1. Use in the file by 
        require 'rapyd_service'

    2. Then initilize the main RAPYD SERVICE object by giving three parameters:
        RapydService = RapydService::RapydService.new('rapid_api_endpoint','rapid_access_key','rapyd_secret_key')

    3. Then call methods
        To see the  supported countries and the currency 
            - RapydService.payout_method_type_list('US','USD','bank','individual')
        To see the ewallet information give the 'ewallet id' 
            - RapydService.wallet_information("e31231sd21321321")
