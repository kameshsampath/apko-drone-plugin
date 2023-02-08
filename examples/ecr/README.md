# Push to Elastic Container Registry

Create a file `secrets` with following values,

```shell
image_repo: <your ecr repo>
aws_access_key_id: <your aws secret access key id>
aws_secret_access_key: <your  aws secret key>
```

```shell
drone exec --secret-file secrets
```
