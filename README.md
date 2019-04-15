# Sample repo template for creating ElasticBeanstalk app

This repo contains templates for building/deploying an EB application.
- [app/.ebextensions/](app/.ebextensions)
- [app/.elasticbeanstalk/](app/.elasticbeanstalk)
- [app/sample_service/](app/sample_service)
- [app/.dockerignore](app/.dockerignore)
- [app/.ebignore](app/.ebignore)
- [app/.gitignore](app/.gitignore)
- [app/Dockerfile](app/Dockerfile)
- [aws/cloudformation/EB-CloudWatchPolicy.template ](aws/cloudformation/EB-CloudWatchPolicy.template)
- [aws/cloudformation/EB-IAM-Deploy.template](aws/cloudformation/EB-IAM-Deploy.template)
- [deploy/eb_deployment_helper.sh](deploy/eb_deployment_helper.sh)
- [deploy/requirements-deploy.txt](deploy/requirements-deploy.txt)
- [deploy/setup_aws_profile.py](deploy/setup_aws_profile.py)

## Initialise EB Application and generate .elasticbeanstalk and .gitignore
Only need to do it once

```
$ pip install awsebcli six

# Change to the source directory
$ cd app

$ eb init --profile ${AWS_PROFILE}
# - Region: sydney
# - Application name: SampleService
# - Platform version: Docker 17.03.1-ce (or latest)
# - ssh key: my-sampleservice-key

$ eb create SampleService-dev --cname sampleservice-dev --vpc
# See also http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-getting-started.html
# - Environment Name: SampleService-dev
# - DNS CNAME prefix: sampleservice-dev
# - Load balancer type: application
```

## Zip Dockerfile and deploy it to EB

```
eb deploy [environment-name]
```

#### Other useful commands

```
eb logs --all
```

## Deploy application and update Elastic Beanstalk Environment

See also [EB CLI Reference: `eb config`](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb3-config.html).

1. To build and test the Docker image for the application. 
   You need to install `docker` if you want to run it locally:

       $ cd deploy
       $ ./update_eb_config.sh --build-image 

2. To also deploy the application and update settings/configurations within EC2 instances:
  
       $ cd deploy
       $ ./update_eb_config.sh --build-image \
             [--push-image] \
             --eb-deploy --eb-env [EB_ENV_NAME]

3. To update Elastic Beanstalk Environment for instant change in After Creation state:

    1. Make sure you have the latest EB environment first. 
       Because `aws:elasticbeanstalk:managedactions:platformupdate` is enabled, the Docker/platform version in
       `Platform:PlatformArn` can be different from the last saved `*.cfg.yml` file.
    
           $ cd app
           $ eb config save [EB_ENV_NAME]
    
    2. Edit `app/.elasticbeanstalk/saved_configs/[EB_ENV_NAME].cfg.yml`.

    3. Create Pull Request for review.

    4. Apply the change 

           $ cd deploy
           $ ./update_eb_config.sh --eb-config-update --eb-env [EB_ENV_NAME]


## To ssh to the EC2 using EB CLI

Use: `eb ssh [environment-name] --profile [profile-name]`


## HTTPS / SSL Certificate

You can use a certificate stored in IAM with Elastic Load Balancing load balancers and CloudFront distributions.

Otherwise create yours:

1. Your profile should have the following permissions
    1. `iam:UploadServerCertificate`
    1. `iam:ListServerCertificates`

```
CALL aws iam upload-server-certificate ^
  --server-certificate-name elastic-beanstalk-x509 ^
  --certificate-body file://example.com.crt ^
  --private-key file://example.com.key ^
  --certificate-chain file://intermediate.crt ^
  --profile k-eb-deploy

:: Show all certificates
CALL aws iam list-server-certificates --profile k-eb-deploy
```

For details see [Update a certificate to IAM](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/configuring-https-ssl-upload.html).

    
## Ignore files

If no .ebignore is present, but a .gitignore is, the EB CLI will ignore files
specified in the .gitignore. If an .ebignore file is present, the EB CLI will
not read the .gitignore.

For details see [EB .ebignore](
http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-configuration.html#eb-cli3-ebignore).