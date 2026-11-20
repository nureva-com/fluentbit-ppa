# fluentbit-ppa

Flat APT repository for the `fluentbit` package, which installs `/usr/bin/fluent-bit` on arm64 and armhf.

## Usage

To use this repository:

```bash
curl -s --compressed "https://nureva-com.github.io/fluentbit-ppa/KEY.gpg" \
| gpg --dearmor \
| sudo tee /usr/share/keyrings/fluentbit-archive-keyring.gpg >/dev/null
sudo curl -s --compressed \
-o /etc/apt/sources.list.d/fluentbit.list \
"https://nureva-com.github.io/fluentbit-ppa/fluentbit.list"
sudo apt update
sudo apt install fluentbit
fluent-bit --version
```

## Building the packages

The `fluent-bit` binary is built from the Fluent Bit 5.0.9 source (commit `a1e05fc1f703fe0ab0373578896f395a04a7eeb5`)
with only the plugins we need, since we want to keep the memory usage low. The `build/fluent-bit-native-minimal.cmake`
and `build/fluent-bit-native-minimal.patch` are used to modify the fluentbit compilation for that usecase.

`bin/build_deb.sh` builds the binary and packages it into a deb in the repo root. `FLUENTBIT_VERSION` in the script
needs to be bumped for a new package, since it won't overwrite an existing deb.

### arm64 (Docker)

As of now arm64 (Core 24) is cross compiled with Docker using the same cross-rs image as our Rust snaps in iotplatform,
so Docker needs to be logged in to `nurevaromedev.azurecr.io` (ex. `just az-docker-login` in iotplatform).

```bash
./bin/build_deb.sh arm64
```

### armhf (Real RPi)

Building the armhf in a docker is trickier due to having to install cmake and such, so for now only built on a real
device.

As of now armhf (Core 20) is built on an armhf device running Ubuntu 20.04. CMake needs to be 3.20.6 or newer, so you
would need to install a newer version since the one from apt is too old.

```bash
sudo apt install -y build-essential bison flex patch pkg-config libssl-dev libsystemd-dev libyaml-dev zlib1g-dev
./bin/build_deb.sh armhf
```

## Updating/adding new packages

Put the new .deb files in the repo root and run `./bin/generate.sh <gpg-key>` (you would need the key's passphrase) to
update `Packages`, `Packages.gz`, `Release`, `Release.gpg`, `InRelease` and `KEY.gpg`. Then commit and push to `main`,
since GitHub Pages serves the repo from there.