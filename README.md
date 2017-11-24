# Sample repo template for creating ElasticBeanstalk app

## Elastic Beanstalk Deployment and Configurations

### Initialise EB Application

Only need to do it once

#### Prerequisites

```
pip install awsebcli six
```

#### Change profile name to yours

```
APP_NAME="SampleService"
AWS_PROFILE="k-eb-deploy"

echo "Changing to the source directory ..."
pushd ../../app
```

#### Initialise EB Application and generate .elasticbeanstalk and .gitignore

```
eb init --profile ${AWS_PROFILE}

# - Region: sydney
# - Application name: ${SampleService}
# - Platform version: Docker 17.03.1-ce (or latest)
# - ssh key: my-sampleservice-key
```

#### Creating EB Environments

```
eb create SampleService-dev --cname sampleservice-dev --vpc

# See also http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-getting-started.html
# - Environment Name: SampleService-dev
# - DNS CNAME prefix: sampleservice-dev
# - Load balancer type: application
```

#### Zip Dockerfile and deploy it to EB

```
eb deploy [environment-name]
```

#### Other useful commands

```
eb logs --all
```


### EB configurations and maintenance

Use `eb config` to change the environment configuration settings.
This command saves the environment configuration settings as well as uploads,
downloads, or lists saved configurations.

For details see [EB CLI Reference: `eb config`](
http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb3-config.html).

#### Manage and maintain *saved configuratons*

Elastic Beanstalk stores the **saved configurations** in S3.
You can see the saved configurations from AWS Console or using EB CLI.

1. AWS Console: Elastic Beanstalk > All Applications > SampleService > Saved configurations
1. EB CLI:

   ```
   ~/app$ eb config list
   SampleService-v1
   SampleService-dev-v1

**To download a saved configuration from S3 using EB CLI**

Use: `eb config get [configuration-name]`
   
```   
~/app$ eb config get SampleService-dev-v1
~/app$ eb config get SampleService-v1
```

**To save the saves configuration settings from the current running environment to S3 using EB CLI**

`eb config save`:

1. Save the environment configuration settings for the current running
   environment to S3.

1. Also save it locally to `.elasticbeanstalk/saved_configs/[configuration-name].cfg.yml`.

  Modify the saved configuration locally if needed.

**To create a saved configuration using EB CLI**

Use: `eb config save --cfg [configuration-name] [environment-name]`
   
```   
~/app$ eb config save --cfg SampleService-dev-v1 SampleService-dev
~/app$ eb config save --cfg SampleService-v1 SampleService
```

`eb config save`:

1. Save the environment configuration settings for the current running
   environment to S3.

1. Also save it locally to `.elasticbeanstalk/saved_configs/[configuration-name].cfg.yml`.

  Modify the saved configuration locally if needed.

**To upload the local copy of saved configuration to S3**

Use: `eb config put [configuration-name]`

```
~/app eb config put SampleService-dev-v1
~/app eb config put SampleService-v1
```

**To ssh to the EC2 using EB CLI**

Use: `eb ssh [environment-name] --profile [profile-name]`


### HTTPS / SSL Certificate

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

    
### Ignore files

If no .ebignore is present, but a .gitignore is, the EB CLI will ignore files
specified in the .gitignore. If an .ebignore file is present, the EB CLI will
not read the .gitignore.

For details see [EB .ebignore](
http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-configuration.html#eb-cli3-ebignore).