# Log.io: Real-Time Log Monitoring in Your Browser

This is a Radial Wheel repository for the [Log.io Web App][log.io].  Log.io is a
log stream collecting and viewing tool with a web interface for viewing the log
data. It comes in two parts: a harvester for watching logs for changes, and a
server for collecting and viewing the stream data.

Since this is a log viewing application, running by itself is pretty useless as
it will only view it's own logs. So if you already use fig to start up a
collection of images (let's assume other Radial Spokes) then you may combine the
contents of all the `fig.yml` files to produce a hybrid Wheel. If all the
images keep to the Radial topology guidelines, then they should work
out-of-the-box.

This image, by default, runs both harvester and server in the same container. It
is meant to function as an add-on to any wheel for viewing the logs contained in
`/log`. To split this application up and use multiple harvesters in separate
wheels, modify the `hub/config/supervisor/conf.d/logio.ini` file to run one or
the other. All other port/IP customizations are done via environment variables.

[log.io]: https://github.com/NarrativeScience/Log.io

## Tunables

Tunable environment variables; modify at runtime. Italics are defaults.

  - **WHEEL_NAME**: {_random_} Unique name to associate to the Wheel logs being
    harvested; what Log.io calls a "node".
  - **SERVER_LISTEN_ADDRESS**: {_"0.0.0.0"_} Listening address of server.
  - **SERVER_LISTEN_PORT**: {_"28777"_} Listening port of server.
  - **SERVER_ADDRESS**: {_"0.0.0.0"_} Server address for harvester to send
    stream data to.
  - **WEB_PORT**: {_"28778"_} Port to access web interface on.
  - **DELAY**: {_"5"_} Log.io needs to explicitly name log files, but Radial
    Wheels are dynamic regarding Spokes and log files. So the entrypoint script
    generates them dynamincally and this number delays the harvester in seconds
    before searching and generating the log file manifest. **Note:** you don't need
    to wait for all container startup processes to finish before searching for
    logs, just for the supervisor daemon on each to start up and create the
    actual log file. Under normal circumstances, this isn't very long.
  - **MODE**: [__"default"__|"server"|"harvester"] Specialty options to allow this
    Spoke to run detached from any Wheel and without the use of a Hub. The "default"
    mode is to look for configuration via the Hub container, which, could very
    well run as just a server or harvester, but will still need that defined via
    configuration in the Hub. "server" and "harvester" modes will run as one or
    the other, but independently to allow for one-off use on already running
    Wheels or as stand-alone services. When using "server" or "harvester" modes,
    the followling variables Spoke variables must be set as well:
    - **SPOKE_DETACH_MODE**: {True|__False__} Enable Spoke-detach mode.
    - **WHEEL_REPO**: {__empty__} Location of Wheel repo to look for configuration.

## Radial

[Radial][radial] is a [Docker][docker] container topology strategy that
seeks to put the canon of Docker best-practices into simple, re-usable, and
scalable images, dockerfiles, and repositories. Radial categorizes containers
into 3 types: Axles, Hubs, and Spokes. A Wheel is a repository used to recreate
an application stack consisting of any combination of all three types of
containers. Check out the [Radial documentation][radialdocs] for more.

One of the main design goals of Radial containers is simple and painless
modularity. All Spoke (application/binary) containers are designed to be run by
themselves as a service (a Wheel consisting of a Hub container for configuration
and a Spoke container for the running binary) or as part of a larger stack as a
Wheel of many Spokes all joined by the Hub container (database, application
code, web server, backend services etc.). Check out the [Wheel
tutorial][wheel-template] for some more details on how this works.

Note also that for now, Radial makes use of [Fig][fig] for all orchestration,
demonstration, and testing. Radial is just a collection of images and
strategies, so technically, any orchestration tool can work. But Fig was the
leanest and most logical to use for now. 

[wheel-template]: https://github.com/radial/template-wheel
[fig]: http://www.fig.sh
[docker]: http://docker.io/
[radial]: https://github.com/radial
[radialdocs]: http://radial.viewdocs.io/docs

## How to Use
### Static Build

In case you need to modify the entrypoint script, the Dockerfile itself, create
your "config" branch for dynamic building, or just prefer to build your own from
scratch, then you can do the following:

1. Clone this repository
2. Make whatever changes needed to configuration and add whatever files
3. `fig up`

### Dynamic Build

A standard feature of all Radial images is their ability to be used dynamically.
This means that since great care is made to separate the application code from
it's configuration, as long as you make your application configuration available
as a git repository, and in it's own "config" branch as per the guidelines in
the [Wheel template][wheel-template], no building of any images will be
necessary at deploy time. This has many benefits as it allows rapid deployment
and configuration without any wait time in the building process. However:

**Dynamic builds will not commit your configuration files into any
resulting images like static builds.**

Static builds do a "COPY" of files into the image before exposing the
directories as volumes. Dynamic builds do a `git fetch` at run time and the
resulting data is downloaded to an already existing volume location, which is
now free from Docker versioning. Both methods have their advantages and
disadvantages. Deploying the same exact configuration might benefit from a
single image built statically whereas deploying many different disposable 
configurations rapidly are best done dynamically with no building.

To run dynamically:

1. Modify the `fig-dynamic.yml` file to point at your own Wheel repository
   location by setting the `$WHEEL_REPO` variable. When run, the Hub container
   will pull the "config" branch of that repository and use it to run the Spoke
   container with your own configuration.
3. `fig -f fig-dynamic.yml up`
