# Local VRM test model

Place your private test model at:

`apps/native/LocalAssets/TestAvatar.vrm`

The model stays ignored by Git. When this file exists, the optional VRM parsing
and rendering checks run as part of `make test`.

This file is only a private test fixture; it is not bundled into the app. To
test the import screen, also copy the model into the Simulator's Files app and
choose it with **Choose VRM File**.

Use only a model you own or have permission to test.
