import consumer from "channels/consumer"

consumer.subscriptions.create("TrendsChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
    console.log("Connected to TrendsChannel");
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
    console.log("Disconnected from TrendsChannel");
  },

  received(data) {
    // Called when there's incoming data on the websocket for this channel
    if (data.action === "update_trends") {
      const trendingList = document.getElementById("trending_list");
      if (trendingList) {
        trendingList.innerHTML = data.html;
        console.log("Trends updated via WebSocket");
      }
    }
  }
});
