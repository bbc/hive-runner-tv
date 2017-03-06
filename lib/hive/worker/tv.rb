require 'hive/worker'
require 'hive/messages/tv_job'
require 'mind_meld/tv'
require 'talkshow'

module Hive
  class Worker
    # The TV worker
    class Tv < Worker
      class FailedRedirect < StandardError
      end

      def initialize(config)
        @brand = config['brand'].downcase.gsub(/\s/, '_')
        @model = config['model'].downcase.gsub(/\s/, '_')

        if config['ir_blaster_clients'] and config['ir_blaster_clients'].has_key?(config['id'])
          require 'device_api/tv'
          DeviceAPI::RatBlaster.configure do |rb_config|
            rb_config.host = Hive.config.network.tv.ir_blaster_host if Hive.config.network.tv.ir_blaster_host?
            rb_config.port = Hive.config.network.tv.ir_blaster_port if Hive.config.network.tv.ir_blaster_port?
          end

          config.merge!({"device_api" => DeviceAPI::TV::Device.new(
            id: config['id'],
            ir: {
              type: config['ir_blaster_clients'][config['id']].type,
              mac: config['ir_blaster_clients'][config['id']].mac,
              dataset: config['ir_blaster_clients'][config['id']].dataset,
              output: config['ir_blaster_clients'][config['id']].output
            }
          )})
          config['ir_blaster_clients'][config['id']].sequences.each do |name, pattern|
            config['device_api'].set_sequence(name.to_sym, pattern)
          end
        end
        super(config)
      end

      # Prepare the TV
      def pre_script(job, job_paths, script)
        url = job.application_url
        @log.info("Application url: #{url}")
        # TODO Set device as busy in Hive mind

        params = ""

        # 'cross_network_restriction' means that the device requires Talkshow
        # on the same network as the application.
        # For the moment, assume networks are '10.10.*.*' and'*.bbc.co.uk'
        # TODO Make this more general
        if @options['features'] && @options['features'].include?('cross_network_restriction') and /bbc.co.uk/.match url
          ts_address = Hive.config.network.remote_talkshow_address
          ts_port = @ts_port = Hive.config.network.remote_talkshow_port_offset + @options['id']
          @log.info("Using remote talkshow on port #{ts_port}")
          script.set_env 'TALKSHOW_REMOTE_URL', "http://#{ts_address}:#{ts_port}"
          # Not actually required but talkshow fails without it set
          script.set_env 'TALKSHOW_PORT', ts_port
        else
          ts_port = @ts_port = @port_allocator.allocate_port
          @log.info("Using talkshow on port #{ts_port}")
          # TODO Move this more centrally
          ip = Socket.ip_address_list.detect { |intf| intf.ipv4_private? }
          ts_address = ip.ip_address
          script.set_env 'TALKSHOW_PORT', ts_port
        end
        @log.info("Talkshow server address is: #{ts_address}")

        if job.application_url_parameters.present?
          params = "?#{job.application_url_parameters}&talkshowurl=#{ts_address}:#{ts_port}"
        else
          params = "?talkshowurl=#{ts_address}:#{ts_port}"
        end
        url += params

        self.redirect(
          url: url,
          old_app: Hive.config.network.tv.titantv_name,
          skip_first_load: true
        )
        load_hive_mind ts_port, url

        @log.info("Starting TV Application monitor")
        @monitor = Thread.new do
          loop do
            poll_response = Hive.hive_mind.poll(@device_id)
#            if poll_response.is_a? Array and poll_response.length > 0
#              @log.debug("[TV app monitor] Polled TV. Application = #{poll_response.first['application']}")
#        #    if @hive_mind.device_details(refresh: true)['application'] == Hive.config.network.tv.titantv_name
#              if poll_response.first['application'] == Hive.config.network.tv.titantv_name
#                # TV has returned to the holding app
#                # Put back in the app under test
#                self.redirect(
#                  url: url,
#                  old_app: Hive.config.network.tv.titantv_name,
#                  log_prefix: '[TV app monitor] '
#                )
#              end
#            else
#              @log.warn("[TV app monitor] Failed to poll TV")
#            end
            sleep 20
          end
        end

        return nil
      end

      def job_message_klass
        Hive::Messages::TvJob
      end

      def mind_meld_klass
        MindMeld::Tv
      end

      def post_script(job, job_paths, script)
        @port_allocator.release_port(@ts_port) if @ts_port

        signal_safe_post_script(job, job_paths, script)
      end

      def signal_safe_post_script(job, job_paths, script)
        @log.info('Terminating TV Application monitor')
        @monitor.exit if @monitor

        self.redirect(url: Hive.config.network.tv.titantv_url, new_app: Hive.config.network.tv.titantv_name, skip_last_load: true)
        # TODO Set device as idle in Hive Mind

      end

      def device_status
        @hive_mind.device_details['status']
      end

      def set_device_status(status)
        # TODO Set status from Hive Mind
        # At the moment the device state cannot be changed
        device_status
      end

      def autogenerated_queues
        [ "#{@brand}-#{@model}" ]
      end

      def redirect(opts)
        raise ArgumentError if ! ( opts.has_key?(:url) && ( opts.has_key?(:old_app) || opts.has_key?(:new_app) ) )
        load_hive_mind(@ts_port, opts[:old_app] || "Trying to redirect ...") if ! opts[:skip_first_load]
        opts[:log_prefix] ||= ''
        @log.info("#{opts[:log_prefix]}Redirecting to #{opts[:url]}")
        @hive_mind.create_action(action_type: 'redirect', body: opts[:url])
        sleep 5
        load_hive_mind(@ts_port, opts[:url]) if ! opts[:skip_last_load]

        max_wait_count = 10
        wait_count = 0
        max_retry_count = 15
        retry_count = 0

        forced_redirect(opts)

        app_name = @hive_mind.device_details(refresh: true)['application']
        @log.debug("#{opts[:log_prefix]}Current app: #{app_name}")
        while (opts.has_key?(:new_app) && app_name != opts[:new_app]) || (opts.has_key?(:old_app) && app_name == opts[:old_app])
          if wait_count >= max_wait_count
            if retry_count >= max_retry_count
              raise FailedRedirect
            else
              retry_count += 1
              wait_count = 0
              @log.info("#{opts[:log_prefix]}Redirecting to #{opts[:url]} [#{retry_count}]")
              @hive_mind.create_action(action_type: 'redirect', body: opts[:url])
              sleep 2
            end
          else
            wait_count += 1
            @log.info("#{opts[:log_prefix]}  . [#{wait_count}]")
            load_hive_mind(@ts_port, opts[:url]) if ! opts[:skip_last_load]
            sleep 1
          end
          app_name = @hive_mind.device_details(refresh: true)['application']
          @log.debug("#{opts[:log_prefix]}Current app: #{app_name}")
        end
      end

      # Between tests the TV must be in the holding app
      def diagnostics
        app_name = @hive_mind.device_details(refresh: true)['application']
        if app_name != Hive.config.network.tv.titantv_name
          @log.error("Repairing: TV is not on holding app")
          raise DeviceNotReady.new("Current application: '#{app_name}'") if repair != Hive.config.network.tv.titantv_name
        end
        super
      end

      def repair
        app_name = @hive_mind.device_details(refresh: true)['application']
        count = 0
        while app_name != Hive.config.network.tv.titantv_name or count < 3
          self.redirect(url: Hive.config.network.tv.titantv_url, new_app: Hive.config.network.tv.titantv_name, skip_last_load: true)
          count += 1
          app_name = @hive_mind.device_details(refresh: true)['application']
        end
        app_name 
      end
     

      def load_hive_mind ts_port, app_name
        system("lsof -t -i :#{ts_port} | xargs kill -9")
        tmp = false
        ts = Talkshow.new
        @log.info("Port: #{ts_port}")
        @log.info("App: #{app_name}")
        if !@file_system
          tmp = true
          @file_system = Hive::FileSystem.new(rand(10000), "/tmp", @log)
        end
        @log.info("Logfile: #{@file_system.results_path}/talkshowserver.log")
        @log.info("titantv_url: #{Hive.config.network.tv.titantv_url}")
        ts.start_server(port: ts_port, logfile: "#{@file_system.results_path}/talkshowserver.log")
        5.times do
          begin
            ts.execute <<JS
(function(){
  var load_script = document.createElement('script');
  load_script.type = 'text/javascript';
  load_script.charset = 'utf-8';
  load_script.src = '#{Hive.config.network.tv.titantv_url}/script/hive_mind_com.js';
  document.getElementsByTagName('head')[0].appendChild(load_script);
  // Give it 10 seconds to load
  // TODO Do this with a retry
  setTimeout(function() {
    hive_mind_com.init('#{app_name}', '#{Hive.config.network.tv.titantv_url}');
    hive_mind_com.start();
  }, 10000);
  return true;
})()
JS
            break
          rescue Talkshow::Timeout
            @log.info("Talkshow timeout")
            sleep 1
          end
        end
        if tmp
          FileUtils.rm_r(@file_system.home_path)
          @file_system = nil
        end
        ts.stop_server
      end

      def forced_redirect(opts)
        current_app = @hive_mind.device_details(refresh: true)['application']
        @log.info("Current App: #{current_app}")
        @log.info("Opts URL: #{opts[:url]}")
        if opts[:url] == Hive.config.network.tv.titantv_url && opts[:url] != current_app && current_app != Hive.config.network.tv.titantv_name
           @log.info("Redirecting to TitanTV by exiting application")
           ts = Talkshow.new
           ts.start_server(port: @ts_port, logfile: "#{@file_system.results_path}/talkshowserver.log")
             begin
               ts.execute <<JS
require(
    [
        "antie/application",
        "antie/events/keyevent",
        "antie/widgets/carousel"
    ],
    function( Application, KeyEvent, Carousel ) {

        //require the Application Class - so we can get access the current application
        TVAPI = {};
        TVAPI.application  = Application.getCurrentApplication();
        TVAPI.device       = TVAPI.application.getDevice();

        TVAPI.exitApp = function() {
          return TVAPI.application.exit();
        };
    }
);
JS
               ts.execute("TVAPI.exitApp();")
               @log.info("Exited out of the application")
             rescue
               sleep 15
               current_app = @hive_mind.device_details(refresh: true)['application']
               if current_app == Hive.config.network.tv.titantv_name
                 @log.info("Exited out of the application successfully")
               else
                 @log.error("Forced redirect unsuccessful")
               end
             end
             current_app = @hive_mind.device_details(refresh: true)['application']
             @log.info("Current App: #{current_app}")
             ts.stop_server
             load_hive_mind(@ts_port, opts[:url]) if ! opts[:skip_last_load]
        else
           @log.info("Already on Titan TV. Skipped forced redirect.")
        end

      end
    end
  end
end
