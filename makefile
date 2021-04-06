all: fs6-payload fs6-base fs6-aws

fs6-payload: docker/dockerfile--fs6-payload
	docker build --no-cache -f ./docker/dockerfile--fs6-payload -t corticometrics/fs6-payload .

fs6-base: docker/dockerfile--fs6-base
	docker build --no-cache -f ./docker/dockerfile--fs6-base -t corticometrics/fs6-base .

fs6-aws: fs6-base docker/dockerfile--fs6-aws
	docker build --no-cache -f ./docker/dockerfile--fs6-aws  -t corticometrics/fs6-aws .


fs7: fs7-payload fs7-base fs7-aws

fs7-payload: docker/dockerfile--fs7-payload
	docker build --no-cache -f ./docker/dockerfile--fs7-payload -t corticometrics/fs7-payload .

fs7-base: docker/dockerfile--fs7-base
	docker build --no-cache -f ./docker/dockerfile--fs7-base -t corticometrics/fs7-base .

fs7-aws: fs7-base docker/dockerfile--fs7-aws
	docker build --no-cache -f ./docker/dockerfile--fs7-aws  -t corticometrics/fs7-aws .

PUSH_VERSION ?= fs7
push:
	docker push corticometrics/${PUSH_VERSION}-payload
	docker push corticometrics/${PUSH_VERSION}-base
	docker push corticometrics/${PUSH_VERSION}-aws
