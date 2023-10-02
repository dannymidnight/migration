# Buildkite Migration tool

A tool to transform pipelines from other CI providers to Buildkite.

```shell
$ buildkite-compat examples/circleci/legacy.yml
---
steps:
- commands:
  - "# No need for checkout, the agent takes care of that"
  - pip install -r requirements/dev.txt
  plugins:
  - docker#v5.7.0:
      image: circleci/python:3.6.2-stretch-browsers
  agents:
    executor_type: docker
  key: build
```

Note that setting the environment variable `BUILDKITE_PLUGIN_<UPPERCASE_NAME>_VERSION` will override the default version of the plugins used. For example:

```shell
$ BUILDKITE_PLUGIN_DOCKER_VERSION=testing-branch buildkite-compat examples/circleci/legacy.yml
---
steps:
- commands:
  - "# No need for checkout, the agent takes care of that"
  - pip install -r requirements/dev.txt
  plugins:
  - docker#testing-branch:
      image: circleci/python:3.6.2-stretch-browsers
  agents:
    executor_type: docker
  key: build
```

## Web Service/API

Buildkite Compat can also be used via a HTTP API using `rackup` from the `app` folder of this repository.

Note that if you are using the docker image you will have to override the entrypoint:
```shell
$ docker run --rm -ti -p 9292:9292 --entrypoint '' --workdir /app $IMAGE:$TAG rackup --port 9292
```

After that you should be able to access a very simple web interface at http://localhost:9292 

![Web UI](docs/images/web-ui.png)

You could also programatically interact with it (maybe even pipe the output directly to `buildkite-agent pipeline upload`!):

```shell
$ curl -X POST -F 'file=@app/examples/circleci/legacy.yml' http://localhost:9292
---
steps:
- commands:
  - "# No need for checkout, the agent takes care of that"
  - pip install -r requirements/dev.txt
  plugins:
  - docker#v5.7.0:
      image: circleci/python:3.6.2-stretch-browsers
  agents:
    executor_type: docker
  key: build
```

## Translation results

BuildKite has its own suggestions and best practices that are probably different to those of other providers so you should review and use the results of this tool as your first stepping stone into your adoption of BuildKite.