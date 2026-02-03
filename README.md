# webanimal_mobile

build play store:

- create file android/key.properties
```
storePassword=
keyPassword=
keyAlias=
keyStore=
```

- build command:
```flutter build appbundle --no-tree-shake-icons```

- generate output in:
```build/app/outputs/bundle/release/app-release.aab```