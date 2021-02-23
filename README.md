# RapydService

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/rapyd_service`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
    gem 'rapyd_service', :git => 'git@github.com:furqan-cn/rails-rapyd-gem.git', branch: :main
```

And then execute:

    $ bundle install


## Usage
1. Use in the file by 
    require 'rapyd_service'

2. Then initilize the main RAPYD SERVICE object by giving three parameters:
    RapydService = RapydService::RapydService.new('rapid_api_endpoint','rapid_access_key','rapyd_secret_key')

3. Then call any method
    RapydService.payout_method_type_list('US','USD','bank','individual')

TODO: Write usage instructions here
