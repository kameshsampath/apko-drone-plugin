# Push to Google Artifact Registry

Create a file `secrets` with following values,

```shell
image_repo: <your google artifact registry repo>
google_application_credentials: <base64 encoded value of Google key.json>
```

```shell
drone exec --secret-file secrets
```

>**IMPORTANT**:
> On macOS: When generating the base64 encoding of the key.json make sure you use GNU base64(on mac) with `--wrap=0` option. GNU base64 can be installed on mac using `brew install coreutils`
>
> ```shell
> cat "$GOOGLE_APPLICATION_CREDENTIALS" | jq -r -c . | gbase64 --wrap=0 | pbcopy
> ```
