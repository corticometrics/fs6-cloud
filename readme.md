# How to run FreeSurfer 6.0 in the cloud

This guide describes how to run [FreeSurfer 6.0](https://surfer.nmr.mgh.harvard.edu/fswiki/ReleaseNotes) inside a [docker](https://www.docker.com/) container on 
  - [AWS batch](https://aws.amazon.com/batch/).

Other cloud providers and deployment options to come.

## Setup

- See [Setting up with AWS batch](http://docs.aws.amazon.com/batch/latest/userguide/get-set-up-for-aws-batch.html)
- See [Install Docker](https://docs.docker.com/engine/installation/)

The built containers live [here](https://hub.docker.com/u/corticometrics/).  You can pull it using
```
docker pull corticometrics/fs6-aws:latest 
```
This will trigger a 5.8Gb download

## Using the `fs6-aws` container

The [entrypoint](./docker/entrypoint-aws.bash) for the `corticometrics/fs6-aws` container will perform some pre- and post-processing steps, depending on certain environment variables.

### The `FS_KEY` environment variable

If `FS_KEY` is set.  The string is decoded from base64, and written to the file `$FREESURFER_HOME/license.txt`.  This occurs before the commands passed to the container are executed.

Most of FreeSurfer will not work if this key is not set.  Liceneses are distributed for free by the FreeSurfer team.  You can apply for one [here](https://surfer.nmr.mgh.harvard.edu/registration.html).

Once you have your license, use the output of the following command to set the `FS_KEY` variable:
```
cat $FREESURFER_HOME/license.txt | base64 -w 0
```

### The `FS_SUB_NAME` environment variable

This environment varibale is only used in conjunction with `FS_SUB_S3_IN` and `FS_SUB_S3_OUT` (see below)

### The `FS_SUB_S3_IN` environment variable

If this variable *and* `FS_SUB_NAME` are set.  The container will attempt to recursivly copy the contents of `${FS_SUB_S3_IN}/${FS_SUB_NAME}` to `${SUBJECTS_DIR}/${FS_SUB_NAME}` (`SUBJECTS_DIR` is set to `/subjects` by the docker container).  This occurs before the commands passed to the container are executed.  

If either `FS_SUB_S3_IN` *or* `FS_SUB_NAME` is not defined, this action wont be performed.  So, alternatively, you could mount a docker-volume or an external directory to `/subjects` to get your subject data into the container.

### The `FS_SUB_S3_OUT` environment variable

If this variable *and* `FS_SUB_NAME` are set.  The container will attempt to recursivly copy the contents of `${SUBJECTS_DIR}/${FS_SUB_NAME}` to `${FS_SUB_S3_OUT}/${FS_SUB_NAME}` (`SUBJECTS_DIR` is set to `/subjects` by the docker container).  This occurs after the commands passed to the container are executed.  

If either `FS_SUB_S3_OUT` *or* `FS_SUB_NAME` is not defined, this action wont be performed.  

### Access to AWS services

The container also accepts standard AWS access key environment variables (`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`) to grant access to AWS services.  This is useful to give the container S3 acess for testing locally.  See [Creating an IAM User in Your AWS Account](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)

When running though AWS batch.  You either use these environment variables, or configure a role and attach it to the container when launching.  See [IAM Roles for Tasks](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html) for more info.

## Example usage

### Launch the container locally, drop into a bash shell.

```
docker run -it --rm \
corticometrics/fs6-aws:latest \
/bin/bash
```

This doesn't have a FreeSurfer license or any subject data, so it's not particularily interesting.  You can confirm that FreeSurfer wont work by trying something like:

```
mri_convert /opt/freesurfer/subjects/sample-001.mgz ~/test.nii.gz
```

### Launch the container locally with a license, drop into a bash shell.

```
docker run -it --rm \
-e FS_KEY='xxx' \
corticometrics/fs6-aws:latest \
/bin/bash
```

Replace `xxx` with the output of `cat $FREESURFER_HOME/license.txt|base64`.  You can get a `license.txt` file for free [here](https://surfer.nmr.mgh.harvard.edu/registration.html)

You can confirm that FreeSurfer works by trying something like:

```
mri_convert /opt/freesurfer/subjects/sample-001.mgz ~/test.nii.gz
```

### Launch the container locally with a FreeSurfer license and mount the subject data from a local drive; drop into a bash shell.

```
docker run -it --rm \
-e FS_KEY='xxx' \
-v /path/to/my/subject_data:/subjects \
corticometrics/fs6-aws:latest \
/bin/bash
```

`/path/to/my/subject_data` is where your subject data is kept on your local machine.  Subject data should always be mapped to `/subjects` inside the container

You can confirm that your data is available in the container by trying:
```
ls -lR /subjects
```

### Launch the container locally with a FreeSurfer license and mount the subject data from a local drive; run a recon-all of the subject bert.
  
```
docker run -it --rm \
-e FS_KEY='xxx' \
-v /path/to/my/subject_data:/subjects \
corticometrics/fs6-aws:latest \
recon-all -s bert -all -parallel
```

This assumes the subject bert lives in a standard FreeSurfer subject directory structure under `/path/to/my/subject_data`. It will take a while to run, so if you want to kill it, from another terminal (outside the container) run `docker ps` to find the containerID, then run `docker kill <containerID>`

### Launch the container locally with a FreeSurfer license and AWS permissions; Drop into a bash shell.

```
docker run -it --rm \
-e FS_KEY='xxx' \
-e AWS_ACCESS_KEY_ID='xxx' \
-e AWS_SECRET_ACCESS_KEY='xxx' \
corticometrics/fs6-aws /bin/bash
```

See [Creating an IAM User in Your AWS Account](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html) to get values for `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.  If you just want to do a quick test, create a user and give it `AmazonS3FullAccess` but note this is not best practice.  See AWS docs for more info.  You can test it by trying to run

```
aws s3 ls
```

Or try copying data to/from your bucket:
```
mkdir -p /subjects/bert
aws s3 cp --recursive s3://my-bucket/subjects/bert /subjects/bert/
ls -lR /subjects/bert/
```

See [Working with Amazon S3 Buckets](http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingBucket.html) on how to create/use S3 bukets.

### Launch the container locally with a FreeSurfer license and AWS permissions. Copy over a subject from S3, run recon-all, Copy results back to S3

```
docker run -it --rm \
-e FS_KEY='xxx' \
-e AWS_ACCESS_KEY_ID='xxx' \
-e AWS_SECRET_ACCESS_KEY='xxx' \
-e FS_SUB_S3_IN='s3://my-bucket/subjects/' \
-e FS_SUB_S3_OUT='s3://my-bucket/subjects-fs6-recon/' \
-e FS_SUB_NAME='bert' \
corticometrics/fs6-aws \
recon-all -s bert -all -parallel
```

This will take a while, so you can kill it from another terminal (outside the container) with `docker ps` to find the containerID, then run `docker kill <containerID>`.

If this step works, then you're ready to submit jobs to AWS batch!

## References and Inspiration:
  - AWS fetch and run script ([article](https://aws.amazon.com/blogs/compute/creating-a-simple-fetch-and-run-aws-batch-job/) | [github](https://github.com/awslabs/aws-batch-helpers/tree/master/fetch-and-run) )
  - [BIDS fs6 container](https://github.com/BIDS-Apps/freesurfer/blob/master/Dockerfile)
  - [AWS batch manual](http://docs.aws.amazon.com/batch/latest/userguide/batch_user.pdf)
  - [Learn Docker](https://docs.docker.com/learn/)


