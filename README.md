# hive-runner-tv
TV module for Hive Runner

## Configuration file

```
controllers:
  tv:
    ir_blaster_clients:
      <devicedb id>:
        type: <Blaster type, eg rat_blaster>
        mac: <IR blaster mac address, eg 00-11-22-33-44-55>
        dataset: <IR blaster dataset name>
        output: <IP blaster output id>
        sequences:
          launch_titantv:
            - signal:Power
            - sleep:2
            - signal:Power

network:
  remote_talkshow_address: <talkshow url, eg talkshow.remote>
  remote_talkshow_port_offset: <minimum port number>
  tv:
    titantv_url: <eg http://titantv.url/titantv>
    titantv_name: <Application name reported by Titan TV>
    ir_blaster_host: <ip address of IR blaster hub, eg, 10.20.30.40>
    ir_blaster_port: <port number of IR blaster hub>

diagnostics:
  tv:
    uptime:
      reboot_time: <seconds between reboots>
    dead:
```

Note, the `ir\_blaster\_clients` section under `controllers` may ultimately
move to the information provided by the Device Database.

## IR Blaster

To use an IR blaster with `hive-runner` add the line

    gem 'device_api-tv', git: 'git@github.com:bbc/device_api-tv'

to the Hive's Gemfile and add the configuration as shown above.
