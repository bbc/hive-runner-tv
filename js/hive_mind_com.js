var hive_mind_com;
(function() {
  var HiveMindCom = function() {};
  HiveMindCom.prototype = {
    init: function(app_name, url) {
      this.app_name = app_name;
      this.url = url;
      this.poll_url = this.url + '/mm_poll/';
      this.id = null;
      this.poll_timeout = 5000;
      this.poll_spacing = this.poll_timeout * 2;
      this.viewers = {};
    },

    poll: function() {
      var self = this;
      if ( this.id ) {
        url = this.poll_url + "?id=" + this.id + "&application=" + this.app_name + "&callback=respond";
      } else {
        url = this.poll_url + "?application=" + this.app_name + "&callback=respond";
      }
      script = document.createElement('script');
      script.src = url;
      var head = document.getElementsByTagName('head')[0];
      head.appendChild(script);
    },

    respond: function(json) {
      if ( this.id != json.id ) {
        this.id = json.id;
      }
      if (json.action) {
        if (typeof window.location.replace === 'function') {
          window.location.replace(json.action.body);
        } else {
          window.location.href=json.action.body;
        }
      }
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

respond = function(json) {
  hive_mind_com.respond(json);
}

hive_mind_com.init('Blob', 'http://titantv-dev.dev.pod.bbc/titantv/');
hive_mind_com.start();
