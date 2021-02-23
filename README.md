# RapydService

## Installation

    Add this line to your application's Gemfile:

    ```ruby
        gem 'rapyd_service', :git => 'git@github.com:furqan-cn/rails-rapyd-gem.git', branch: :main
    ```

    And then execute:

        $ bundle install


## Description
    Gem provides funtionaities
    1. Payout Process
    2. Beneficaiary creation
    3. Documnets verification
    4. Ewallet creation



## Usage
    1. Use in the file by 
        require 'rapyd_service'

    2. Then initilize the main RAPYD SERVICE object by giving three parameters:
        RapydService = RapydService::RapydService.new('rapid_api_endpoint','rapid_access_key','rapyd_secret_key')

    3. Then call method
        RapydService.payout_method_type_list('US','USD','bank','individual')

    TODO: Write usage instructions here
