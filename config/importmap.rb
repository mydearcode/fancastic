# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "reply_form", to: "reply_form.js"
pin "dropdown", to: "dropdown.js"
pin "youtube_player", to: "youtube_player.js"
pin "tiktok_player", to: "tiktok_player.js"
pin "image_paste", to: "image_paste.js"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin_all_from "app/javascript/channels", under: "channels"
