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

## Production

For a production setup, don't commit the `master.key` to a public repository, but instead
put it into a secure file store, or print it. Backing up the key could be beneficial so
you don't have to _re-seal_ your secrets in case your cluster breaks.
