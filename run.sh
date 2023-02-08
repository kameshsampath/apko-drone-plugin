#!/usr/bin/env bash

set -exo pipefail

configure_gcr() {
 printf "Configure GCR Docker Credential Helper \n"
 set -x
 if [ -z "$PLUGIN_GOOGLE_APPLICATION_CREDENTIALS" ];
 then
   printf "unable to find the credentails, set 'google_application_credentials'"
   exit 1
 fi
 echo -n "$PLUGIN_GOOGLE_APPLICATION_CREDENTIALS" | base64 -d - > "$HOME/sa.json"
 export GOOGLE_APPLICATION_CREDENTIALS="$HOME/sa.json"
 docker-credential-gcr configure-docker --registries="$_image_registry"
 set +
}

configure_ecr() {
  printf "Configure ECR Docker Credential Helper \n"
  set -x
  if [[ -z "$PLUGIN_AWS_ACCESS_KEY_ID" ]] || [[ -z "$PLUGIN_AWS_SECRET_ACCESS_KEY" ]];
  then
   printf "unable to AWS credentials, set 'aws_access_key_id' and 'aws_secret_access_key'"
   exit 1
  fi
  export AWS_ACCESS_KEY_ID="$PLUGIN_AWS_ACCESS_KEY_ID"
  export AWS_SECRET_ACCESS_KEY="$PLUGIN_AWS_SECRET_ACCESS_KEY"
  set +x
}

configure_other_registries() {
  printf "Configure Other Registries \n"
  set -x
  _image_registry_username=${PLUGIN_IMAGE_REGISTRY_USERNAME:?"'image_registry_username' configuration is missing"}
  _image_registry_password=${PLUGIN_IMAGE_REGISTRY_PASSWORD:?"'image_registry_password' configuration is missing"}
  echo -n "$_image_registry_password" | apko login "$_image_registry" -u "$_image_registry_username" --password-stdin
  set +x
}

_image_repo=${PLUGIN_IMAGE_REPO:?"'image_repo' configuration is missing"}
_image_publish=${PLUGIN_PUBLISH:-false}
_config_file=${PLUGIN_CONFIG_FILE:-image.yaml}

# extract the image registry
_count=$(grep -o "/" <<< "$_image_repo" | wc -l)

if [ "$_count" -ge 2 ];
then
  _image_registry=$(echo "$_image_repo" | cut -d '/' -f 1)
elif [ "$_count" -le 1 ];
then
  _image_registry=docker.io
fi

if "$_image_publish" ;
then
  _gcr_regex='^(.*)-(docker.pkg.dev)(.*)$'
  if echo -n "$_image_registry" | grep -qE "$_gcr_regex" ;
  then
    configure_gcr
  else
   configure_other_registries
  fi
  printf "\n Running publish \n"
  if [ -n "$PLUGIN_ARCHS" ];
  then 
    exec sh -c "apko publish --arch=$PLUGIN_ARCHS --debug $_config_file $_image_repo"
  else 
    exec sh -c "apko publish --arch=$(uname -m) --debug $_config_file $_image_repo"
  fi
else
  # Manipulate architectures to build
  _archs=()
  if [ -n "$PLUGIN_ARCHS" ];
  then 
  IFS=',' read -r -a _archs <<< "$PLUGIN_ARCHS"
  fi
  # defaults to the current image arch
  if [ ${#_archs[@]} -eq 0 ]; 
  then
    _archs+=("$(uname -m)")
  fi
  printf "\n Running build \n"
  _build_file="$HOME/build.sh"
  [[ -f "$_build_file" ]] && echo "" > "$_build_file"
  {
    printf "#!/usr/bin/env bash\n"
    printf "set -eo pipefail\n"
  } >> "$_build_file"
  for _arch in "${_archs[@]}"
  do
    if [ "$_arch" = "aarch64" ];
    then
      _arch="arm64"
    elif [ "$_arch" = "x86_64" ];
    then
      _arch="amd64" 
    fi
    _output_image_tar_filename="${_image_repo/:/-}_$_arch.tar"
    # make the docker.io to be docker-io, asia-south1-docker.pkg.dev to asia-south1-docker-pkg-dev to have a friendly folder names
    _output_dir="${PLUGIN_BUILD_OUTPUT_DIR:-dist}/${_image_registry//\./-}"
    _output_tar_filename="$_output_dir/$_output_image_tar_filename"
    _output_dir="$(dirname "$_output_tar_filename")"
    # clean any existing dir
    [[ -d  "$_output_dir" ]] && rm -rf  "$_output_dir" 
    [[ ! -d  "$_output_dir" ]] && mkdir -p "$_output_dir"
    { 
      printf "apko build --debug %s %s %s\n" "$_config_file"  "$_image_repo" "$_output_tar_filename"
    } >> "$_build_file"
  done
  chmod +x "$_build_file"
  exec bash -c "$_build_file"
fi
