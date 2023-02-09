# Drone APKO Plugin

Drone plugin to built OCI container image using [apko](https://github.com/chainguard-dev/apko)

> **IMPORTANT:** This plugin is under development and the parameters are subject to change

## Usage

The following settings changes this plugin's behavior,

- `config_file`: The apko configuration YAML file, path relative to drone pipeline.
- `image_repo`: The fully qualified image repository where the built OCI image will be pushed.
- `publish`: Whether to publish the image to `image_repo`. Defaults to `false` which will just build the image tarball.
- `archs`: The `linux` architecture for which the images will be built. Defaults `$(uname -m)`. Valid values are: `amd64`, `arm64`.
- `build_output_dir`: The output directory relative to `config_file` where the build artifacts will be generated.
- `insecure`: Push to insecure registry.

### Container Registry Credentials

- `image_registry_username`: The user name that will be used to push the image to `image_repo`. Applicable when the `image_repo` is not GAR, ECR.
- `image_registry_password`: The user password that will be used to push the image to `image_repo`. Applicable when the `image_repo` is not GAR, ECR.

### Google Artifact Registry Credentials

- `google_application_credentials`: The base64 encoded Google application credentials i.e. SA key.json. This parameter is useful only when your `image_repo` is [Google Artifact registry](https://cloud.google.com/artifact-registry/docs)

### Elastic Container Registry Credentials

- `aws_access_key_id`: The AWS `AWS_ACCESS_KEY_ID`
- `aws_secret_access_key`: The AWS `AWS_SECRET_ACCESS_KEY`

```yaml
kind: pipeline
type: docker
name: default

steps:
  - name: build image
    image: kameshsampath/apko-drone-plugin
    settings:
      config_file: image.yaml
      image_repo: example/hello-world:0.0.1
      publish: false
      archs:
        - amd64
        - arm64
```

Now load the image using the command,

```shell
docker load < ./dist/hello-world-0.0.1_$(uname -m).tar
```

## Examples

Checkout examples in folder [examples](./examples/). You need to have [drone](https://docs.drone.io/cli/install/) CLI to execute the examples locally.

| Example                                                                            | Description                                                                |
| :--------------------------------------------------------------------------------- | :------------------------------------------------------------------------- |
| [Any OCI Registry](./examples/any-registry/README.md)                              | Build and deploy to any OCI compliant registry                             |
| [Any OCI Registry Multi Architecture](./examples/any-registry-multiarch/README.md) | Build and deploy multi architecture images to any OCI compliant registry   |
| [Elastic Container Registry](./examples/ecr/README.md)                             | Build and deploy to Elastic Container Registry(ECR)                        |
| [Google Artifact Registry](./examples/gar/README.md)                               | Build and deploy to Google Artifact registry(GAR)                          |
| [No Push](./examples/tarball/README.md)                                            | Build OCI tarball without pushing to remote repository.                    |
| [Multi Architecture](./examples/tarball-multiarch/README.md)                       | Build multi architecture OCI tarball without pushing to remote repository. |

## Building Plugin

The plugin relies on [apko](https://github.com/chainguard-dev/apko) and [melange](https://github.com/chainguard-dev/melange) for build.

The plugin build relies on:

- [crane](https://github.com/google/go-containerregistry)
- [limactl](https://github.com/lima-vm/lima)
- [taskfile](https://taskfile.dev)

Start `lima-vm` environment,

```shell
task build_env
```

Build plugin packages,

```shell
task build_plugin_packages
```

Build plugin container image,

```shell
task build_plugin
```

To publish the plugin to remote repository use,

```shell
task publish_plugin
```

## Testing

Build plugin packages,

```shell
task build_plugin load
```

Build plugin container image,

```shell
task build_plugin
```

Create `.env`

```shell
cat<<EOF | tee .env
PLUGIN_PUBLISH=false
PLUGIN_CONFIG_FILE=image.yaml
PLUGIN_IMAGE_REPO=example/my-image
PLUGIN_IMAGE_REGISTRY_USERNAME=$DOCKERHUB_USERNAME
PLUGIN_IMAGE_REGISTRY_PASSWORD=$DOCKERHUB_PASSWORD
EOF
```

Create a `image.yaml`,

```shell
cat<<EOF | tee image.yaml
---
contents:
  repositories:
    - https://dl-cdn.alpinelinux.org/alpine/edge/main
  packages:
    - alpine-base
    - busybox

entrypoint:
  command: /bin/sh "echo 'Hello, welcome to apko world'"

# optional environment configuration
environment:
  PATH: /usr/sbin:/sbin:/usr/bin:/bin
EOF
```

```shell
docker run --rm \
  --env-file=.env \
  --volume "$PWD:/workspace" \
  kameshsampath/apko-drone-plugin:latest
```

After the successful build you can load the image on to the local docker daemon,

> **NOTE**: the command generates the OCI image tarball in director dist

```shell
docker load < "$PWD/dist/example/my-image_$(uname -m).tar
```

Now run the image to see the text **Hello, welcome to apko world**,

```shell
docker run -it --rm example/my-image
```
