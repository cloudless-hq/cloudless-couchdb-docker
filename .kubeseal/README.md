# This is an example!!! :-)

Contained within this `.kubeseal` directory is a `master.key` for a **local** Minikube install.

Once the cluster is started and everything is deployed, here is how you apply the key:

```
$ make kubeseal-deploy
```

In case you want to backup/replace the key:

```
$ make kubeseal-backup
```

## Verification

This is the `example-sealed-secret`:

```
bar bar, bar, maybe foo, also foobar
```

This is the contents of our "secret" foobar.

```
$ kubectl get secret foobar
NAME      TYPE      DATA      AGE
foobar    Opaque    1         1m
```

To verify we can decrypt:

```
$ kubectl get secret foobar -o json|jq '.data.foobar|@base64d'
... :-)
```

_Requires jq 1.6+._

## Production

For a production setup, don't commit the `master.key` to a public repository, but instead
put it into a secure file store, or print it. Backing up the key could be beneficial so
you don't have to _re-seal_ your secrets in case your cluster breaks.
