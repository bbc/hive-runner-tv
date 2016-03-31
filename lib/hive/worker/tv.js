var hive_mind_com;
(function() {
  var HiveMindCom = function() {};
  HiveMindCom.prototype = {
    init: function(app, app_name, url) {
      this.app = app;
      this.app_name = app_name;
      this.device = app.getDevice();
      this.url = url;
      this.poll_url = this.url + '/mm_poll/';
      this.id = null;
      this.poll_timeout = 15000;
      this.poll_spacing = this.poll_timeout * 2;
      this.viewers = {};
    },

    poll: function() {
      var self = this;
      if ( this.id ) {
        url = this.poll_url + "?id=" + this.id + "&application=" + this.app_name + "&callback=hive_mind_com.respond";
      } else {
        url = this.poll_url + "?application=" + this.app_name + "&callback=hive_mind_com.respond";
      }
      script = document.createElement('script');
      var head = document.getElementByTagName('head')[0];
      head.appendChild(script);
    },

    respond: function(obj) {
      alert('Hello');
    },

    setView: function(key, viewer) {
      this.viewers[key] = viewer;
    },

    nextExecution: function() {
      var self = this;
      setTimeout(function() {
        self.poll();
        self.nextExecution();
      }, this.poll_spacing);
    },

    start: function() {
      this.nextExecution();
    }
    
  };

  hive_mind_com = new HiveMindCom();
})();

require.def("hive_mind_com",
  [
    "antie/application"
  ],
function(Application) {
  hive_mind_com.init(Application.getCurrentApplication(), 'Blob', 'http://titantv.dev.pod.bbc');
  hive_mind_com.start();
}
