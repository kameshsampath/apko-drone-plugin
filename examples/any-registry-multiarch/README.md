# Push to any Docker v2 registry

Create a file `secrets` with following values,

```shell
image_repo: <your Docker v2 repo>
image_registry_username: <your registry username>
image_registry_password: <your  registry user password>
```

```shell
drone exec --secret-file secrets
```
