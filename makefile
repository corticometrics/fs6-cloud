all: fs6-base fs6-aws

fs6-base: docker/dockerfile--fs6-base
	docker build --no-cache -f ./docker/dockerfile--fs6-base -t corticometrics/fs6-base .

fs6-aws: fs6-base docker/dockerfile--fs6-aws
	docker build --no-cache -f ./docker/dockerfile--fs6-aws  -t corticometrics/fs6-aws .


