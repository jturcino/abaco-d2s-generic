# abaco-d2s-generic
A [Docker container](https://hub.docker.com/r/jturcino/abaco-d2s-generic/) for registering a [docker2singularity](https://github.com/TACC/docker2singularity) actor with [Abaco](https://github.com/TACC/abaco) that stores the produced [Singularity](http://singularity.lbl.gov/) images on the [Stampede2](https://www.tacc.utexas.edu/systems/stampede2) work filesystem.

**If you do not have access to Docker, but you do have access to Agave, please use the [abaco-d2s-agave](https://github.com/jturcino/abaco-d2s-agave) repo instead.**

## Overview

The contents of this repo describe the `abaco-d2s-generic` Docker container that can be registered as an Abaco actor. When run as such an actor, the container will transform another, user-provided Docker container to a Singularity image before storing the image in a specified location on the Stampede2 work filesystem. The actor requires two inputs:
* **the Docker container** to transform to a Singularity image
* **the file path** at which to save the Singularity image

You will need the [Abaco CLI](https://github.com/johnfonner/abaco-cli) to interface with Abaco and walk through the tutorial below. 

## Tutorial

In this tutorial, we will create our own personalized version of the `abaco-d2s-generic` Docker container using this repo, register an Abaco actor using the container, and submit a sample job with the actor. The Abaco CLI commands for each step are below. Please note that a SD2E access token, JQ, getopts, and the [Agave CLI](https://bitbucket.org/agaveapi/cli) are required.

### 1. Obtain some info we'll need in the future
SSH onto Stampede2 and look up your username, uid, gid, primary group, and the absolute path on the work filesystem where you'd like your Singularity images to be saved. Then, save these to variables on your local machine and pull a SD2E access token. This will make future steps much less confusing.

**Stampede2**
```
$ whoami
jturcino
$ id -u
111111
$ id -g
gid: 222222
$ id -gn
G-222222
$ echo $WORK/abaco/d2s/
/work/03761/jturcino/stampede2/abaco/d2s/
```
**Local**
```
$ user="jturcino"
$ uid=111111
$ gid=222222
$ group="G-222222"
$ outdir="/work/03761/jturcino/stampede2/abaco/d2s/"
$ auth-tokens-create -S
```

### 2. Build a personalized Docker container
Pull this repo to a directory on your local machine and use the `user`, `uid`, `gid`, and `group` variables that we defined earlier to create a personal version of the Docker container.
```
$ git clone https://github.com/jturcino/abaco-d2s-generic.git
$ cd abaco-d2s-generic
$ # CHANGE "jturcino" BELOW TO YOUR DOCKER USERNAME
$ d2s_container="jturcino/abaco-d2s-generic:latest" 
$ docker build --build-arg user=$user --build-arg uid=$uid \
  --build-arg gid=$gid --build-arg group=$group \
  -t $d2s_container .
$ docker push $d2s_container
```

### 3. Create the actor
Move to a directory where you have access to the Abaco CLI. Use `abaco create` to create a privileged actor for the docker container you just made, adding the `outdir` previously defined as an environmental variable. Once run, make note of the actor ID (`WrPZake5ZWmaR`)
```
$ ./abaco create -p -u -e "{\"outdir\": \"$outdir\"}" -n d2s-generic-tutorial $d2s_container
d2s-generic-tutorial    WrPZake5ZWmaR
```

### 4. Check the actor's status
Use  `abaco list` to check that the actor has `READY` status. If the status is stil `SUBMITTED`, wait a few moments before checking again.
```
$ ./abaco list
d2s-generic-tutorial    WrPZake5ZWmaR    READY
```

### 5. Submit the job
Use `abaco submit` to run the actor once its status is `READY`. Be sure to provide the Docker container you wish to transform with the `-m` flag. Here, we are using the `docker/whalesay` sample container. Once, run, make note of the execution ID (`NNy8LrbNkzpWQ`)
```
$ ./abaco submit -m 'docker/whalesay:latest' WrPZake5ZWmaR
NNy8LrbNkzpWQ
'docker/whalesay:latest'
```

### 6. Check the job's status
Use `abaco executions` to see if the job has finished. Be sure to provide both the actor ID (`WrPZake5ZWmaR`) and the execution ID (`NNy8LrbNkzpWQ`).
```
$ ./abaco executions -e NNy8LrbNkzpWQ WrPZake5ZWmaR
JK3WjNrR4WwqZ    COMPLETE
```

### 7. Check the job's logs
Use `abaco logs` to check that the job ran properly by providing the actor ID and execution ID. The example logfile below has been cleaned up for clarity.
```
$ ./abaco logs -e NNy8LrbNkzpWQ WrPZake5ZWmaR
Logs for execution NNy8LrbNkzpWQ:
Unable to find image 'docker/whalesay:latest' locally
latest: Pulling from jturcino/docker-whale
...
Status: Downloaded newer image for jturcino/docker-whale:latest
Size: 469 MB for the singularity container
(1/9) Creating an empty image...
(2/9) Importing filesystem...
(3/9) Bootstrapping...
(4/9) Adding run script...
(5/9) Setting ENV variables...
(6/9) Adding mount points...
(7/9) Fixing permissions...
(8/9) Stopping and removing the container...
(9/9) Moving the image to the output folder...

MOVING IMAGE VIA WORK MOUNT
(1/4) Checking inputs...
(2/4) Copying image file to work mount...
(3/4) Setting permissions...
(4/4) Removing original image file...

CLEANING UP
```

### 8. View the image
SSH back to Stampede2 and move to the directory you specified as `outdir` in the actor setup. The directory in this example was `/work/03761/jturcino/stampede2/abaco/d2s/`.
```
$ cd /work/03761/jturcino/stampede2/abaco/d2s/
$ ls
whalesay_latest.img
```
You can now use the image on Stampede2, or move it to any other system you'd like!