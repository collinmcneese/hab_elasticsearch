pkg_name=elasticsearch
pkg_origin=collinmcneese
pkg_version=6.8.19
pkg_maintainer="Collin McNeese <cmcneese@chef.io>"
pkg_description="Elasticsearch - Open Source, Distributed, RESTful Search Engine.  Based on upstream core/elasticsearch package."
pkg_upstream_url="https://elastic.co"
pkg_license=('Apache-2.0')
pkg_source="https://artifacts.elastic.co/downloads/${pkg_name}/${pkg_name}-${pkg_version}.tar.gz"
pkg_shasum=67f86019deffbc54aa64f806579aec434667596857918ca71addf12d3b246576

pkg_build_deps=(
  core/patchelf
)
pkg_deps=(
  core/coreutils-static
  core/busybox-static
  core/glibc
  core/zlib
  collinmcneese/openjdk11
  core/wget
)
pkg_bin_dirs=(es/bin)
pkg_binds_optional=(
  [elasticsearch]="http-port transport-port"
)
pkg_lib_dirs=(es/lib)
pkg_exports=(
  [http-port]=network.port
  [transport-port]=transport.port
)
pkg_exposes=(http-port transport-port)

do_build() {
  return 0
}

do_install() {
  install -vDm644 README.textile "${pkg_prefix}/README.textile"
  install -vDm644 LICENSE.txt "${pkg_prefix}/LICENSE.txt"
  install -vDm644 NOTICE.txt "${pkg_prefix}/NOTICE.txt"

  # Elasticsearch is greedy when grabbing config files from /bin/..
  # so we need to put the untemplated config dir out of reach
  mkdir -p "${pkg_prefix}/es"
  cp -a ./* "${pkg_prefix}/es"

  # jvm.options needs to live relative to the binary.
  # mkdir -p "$pkg_prefix/es/config"
  # install -vDm644 config/jvm.options "$pkg_prefix/es/config/jvm.options"

  # Delete unused binaries to save space
  rm "${pkg_prefix}/es/bin/"*.bat "${pkg_prefix}/es/bin/"*.exe

  LD_RUN_PATH=$LD_RUN_PATH:${pkg_prefix}/es/modules/x-pack-ml/platform/linux-x86_64/lib
  export LD_RUN_PATH

  _es_ml_bins=( "autoconfig" "autodetect" "categorize" "controller" "normalize" )
  for bin in "${_es_ml_bins[@]}"; do
    build_line "patch ${pkg_prefix}/es/modules/x-pack-ml/platform/linux-x86_64/bin/${bin}"
    patchelf --interpreter "$(pkg_path_for glibc)/lib/ld-linux-x86-64.so.2" --set-rpath "${LD_RUN_PATH}" \
      "${pkg_prefix}/es/modules/x-pack-ml/platform/linux-x86_64/bin/${bin}"

    find "${pkg_prefix}/es/modules/x-pack-ml/platform/linux-x86_64/lib" -type f -name "*.so" \
      -exec patchelf --set-rpath "${LD_RUN_PATH}" {} \;
  done
}

do_strip() {
  return 0
}
