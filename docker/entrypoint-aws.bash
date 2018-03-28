#!/bin/bash

echo "---------------------------------------------------------------"
echo "AWS ENVIRONMENT VARIABLES"
echo ""
echo "AWS_BATCH_JOB_ID:         $AWS_BATCH_JOB_ID"
echo "AWS_BATCH_JQ_NAME:        $AWS_BATCH_JQ_NAME"
echo "AWS_BATCH_CE_NAME:        $AWS_BATCH_CE_NAME"
echo "AWS_ACCESS_KEY_ID:        $AWS_ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY:    `echo $AWS_SECRET_ACCESS_KEY | sed 's/./X/g'`"
echo "---------------------------------------------------------------"
echo "entrypoint-aws.bash ENVIRONMENT VARIABLES"
echo ""
echo "FS_KEY:                   $FS_KEY"
echo "FS_SUB_S3_IN:             $FS_SUB_S3_IN"
echo "FS_SUB_S3_OUT:            $FS_SUB_S3_OUT"
echo "FS_SUB_NAME:              $FS_SUB_NAME"
echo "---------------------------------------------------------------"

if [ -n "${FS_KEY}" ]; then
  echo "---------------------------------------------------------------"
  echo "FS_KEY detected. Creating $FREESURFER_HOME/license.txt."
  echo $FS_KEY | base64 -d > $FREESURFER_HOME/license.txt
  echo "The file $FREESURFER_HOME/license.txt now looks like:"
  cat $FREESURFER_HOME/license.txt
  echo "---------------------------------------------------------------"
else
  echo "No FS_KEY detected. Not creating license.txt file. Freesurfer probably wont work."
fi

if [ -n "${FS_SUB_S3_IN}" ] && [ -n "${FS_SUB_NAME}" ]; then
  echo "---------------------------------------------------------------"
  echo "FS_SUB_S3_IN *and* FS_SUB_NAME detected. Attempting to run"
  echo "aws s3 cp --recursive ${FS_SUB_S3_IN}/${FS_SUB_NAME} /subjects/${FS_SUB_NAME}"
  aws s3 cp --recursive ${FS_SUB_S3_IN}/${FS_SUB_NAME} ${SUBJECTS_DIR}/${FS_SUB_NAME}
  echo "The /subjects directory now looks like"
  ls -R1 /subjects/
  echo "---------------------------------------------------------------"
fi

eval "$@"

if [ -n "${FS_SUB_S3_OUT}" ] && [ -n "${FS_SUB_NAME}" ]; then
  echo "---------------------------------------------------------------"
  echo "FS_SUB_S3_OUT *and* FS_SUB_NAME detected. Attempting to run:"
  echo "aws s3 cp --recursive /subjects/${FS_SUB_NAME} ${FS_SUB_S3_OUT}/${FS_SUB_NAME}"
  aws s3 cp --recursive /subjects/${FS_SUB_NAME} ${FS_SUB_S3_OUT}/${FS_SUB_NAME}
  echo "The bucket ${FS_SUB_S3_OUT}/${FS_SUB_NAME} now looks like"
  aws s3 ls --recursive ${FS_SUB_S3_OUT}/${FS_SUB_NAME}	
  echo "---------------------------------------------------------------"
fi
