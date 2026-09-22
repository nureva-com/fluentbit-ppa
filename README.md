# fluentbit-ppa

Flat APT repository for Nureva Fluent Bit packages. Packages are built for
`arm64` by default, with `armhf` also supported. The checked-in
`fluentbit.list` source entry supports both architectures. The `fluentbit`
package installs the standalone `/usr/bin/fluent-bit` executable.

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

## Updating/adding new packages

Place validated prebuilt `.deb` artifacts in the repository root. To inspect an
artifact's package metadata before publishing, run:

```bash
dpkg-deb --info <package>.deb
```

Generate and sign the flat-repository metadata with an authorized local GPG key
selector:

```bash
./bin/generate.sh <authorized-key-selector>
```

This updates the package indexes, release metadata, signatures, and public
key. Publish the package and generated metadata together through the established
process.
