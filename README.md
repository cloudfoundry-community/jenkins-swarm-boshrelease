# jenkins-swarm-boshrelease

## Build It

This bosh release does not download its blobs from AWS S3. Instead you will need to run the build script to download the blobs before creating the release using the following script.

```
./build-local.sh help

    USAGE: ./build-local.sh [help | clean-blobs | clean-build | clean-all ]
    
        clean-blobs: force re-download of all blobs
        clean-build: reset dev build number
        clean-all: do both clean-blobs and clean-build
```

Before you run the build script ensure that you have the [Bosh CLI installed](https://bosh.io/docs/bosh-cli.html) and target a Bosh Director. 

> A 'clean-build' or 'clean-all' build will not only delete you release from Bosh Director but also delete your deployment

# Deploy It

You can use the sample manifest file to deploy this release to a [Bosh-Lite](https://github.com/cloudfoundry/bosh-lite) environment. Make sure that before you set the deployment and deploy, you update the manifest's ```director_uuid``` to match you Bosh Director's UUID.

To build and deploy simply run.

```
bosh deployment example-manifests/jenkins-swarm-bosh-lite.yml
./build-local.sh
bosh deploy
```
