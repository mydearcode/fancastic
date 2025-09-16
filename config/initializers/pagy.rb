# Pagy initializer
# See https://ddnexus.github.io/pagy/api/pagy.html for details

# Pagy Variables
# See https://ddnexus.github.io/pagy/api/pagy.html#variables
Pagy::DEFAULT[:items] = 10        # items per page
Pagy::DEFAULT[:size]  = [1, 4, 4, 1] # nav bar links

# Extra
# See https://ddnexus.github.io/pagy/extras
require 'pagy/extras/overflow'
Pagy::DEFAULT[:overflow] = :last_page  # default handling of overflowing pages

# Enable Pagy for Turbo Streams and AJAX requests
require 'pagy/extras/headers'
require 'pagy/extras/metadata'

# Enable JavaScript features
require 'pagy/extras/navs'