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

## Deploy It

You can use the sample manifest file to deploy this release to a [Bosh-Lite](https://github.com/cloudfoundry/bosh-lite) environment. Make sure that before you set the deployment and deploy, you update the manifest's ```director_uuid``` to match you Bosh Director's UUID. 

You also need to upload the [docker bosh-release](https://github.com/cloudfoundry-community/docker-boshrelease) before you deploy using the given sample manifest.

```
bosh upload release https://bosh.io/d/github.com/cf-platform-eng/docker-boshrelease
```

To build and deploy simply run.

```
bosh deployment example-manifests/jenkins-swarm-bosh-lite.yml
./build-local.sh
bosh deploy
```

## Test It

To test simply login to [Jenkins](http://10.244.0.2:8080/) using admin/password as the login credentials and create a "pipeline" project. Use the following script to test the pipeline with docker.

```
node("docker") {
    stage "Parallel Docker Pull"
    def tasks = [:]
    tasks["PullMavenImage"] = {
        docker.image("maven").pull()
    }
    tasks["PullGoLangImage"] = {
        docker.image("golang").pull()
    }
    parallel tasks
    
    stage "Checkout"
    sh "docker run maven bash -c \"echo 'Checkouting the code' && ping -c 20 localhost\""

    stage "Build"
    sh "docker run golang echo 'Building the code'"
}

node("docker") {
    stage "Deployment"
    sh "docker run maven echo 'Deploying the code'"
    
    stage "Integration Tests"
    sh "docker run maven echo 'Integration tests are running'"
}
```
