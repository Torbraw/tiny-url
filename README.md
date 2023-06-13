# tiny-url

Application to shorten urls that is meant to be deployed to AWS. Inspired by [this article](https://aws.amazon.com/blogs/compute/build-a-serverless-private-url-shortener/).

## Disclaimer

This application is not meant to be used in production. The ressources created by terraform are only created with basic settings and are not suitable for production.
This application is only meant to be used as a demo and give some insights on how to create a serverless tiny-url application on AWS.
  
You can refer to the [What's missing / What can be improved](#whats-missing--what-can-be-improved) section to see what can be improved to make this application production ready.

### Pre-requisites

- Terraform >= 1.0.0
- Node.js >= 18 & npm >= 9
- AWS account
- AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY environment variables set so terraform can create the ressources on your AWS account

### What's included

- A s3 bucket that host a static website with public read access and a 7 days lifecycle policy.
- A basic http api gateway with a single POST endpoint that call a lambda function.
- A lambda function that takes a url as input and return a link to a s3 object that redirect to the original url.
- All created by terraform.

### How it works

When you call the `tiny-url` endpoint, the lambda function is called with the url you want to shorten as input.
The lambda function then create a new empty object in the s3 bucket with a random name and a custom metadata, `x-amz-website-redirect-location`, that contains the original url.
S3 bucket that have static website hosting enable have the ability to treat objects with this metadata as a redirect. When you call the url of the object, you are redirected to the original url.

### Usage

- Clone the repository
- Run `npm install` to install the dependencies
- Run `npm run build` to build the lambda function
- Go into the terraform folder
- Run `terraform init` to initialize terraform
- Run `terraform apply` to create the AWS ressources
  - If you have an error that says the s3 bucket already exists, change the bucket name in the `s3.tf` file (line 2) and run `terraform apply` again. S3 bucket name are unique across AWS.
- Find the url of your api gateway in AWS and call the `API_GATEWAY_URL/tiny-url` endpoint with a POST request and a body like this: `{ "url": "https://www.google.com" }`
- You should get a response like this: `{ "url": "http://tiny-url-bucket-dev.s3-website-us-east-1.amazonaws.com/gG_n2" }`
- Go to the url you got in the response and you should be redirected to the original url.
- When you are done, delete all the files in your s3 bucket then run `terraform destroy` to destroy the AWS ressources.

### What's missing / What can be improved

- Change the http api gateway to a rest api gateway with full configuration and custom domain name.
- A cloudfront distribution in front of the s3 bucket to serve the static website.
- A custom Route53 domain name to the cloudfront distribution that serve the s3 bucket to shorten the url.
- A protection to the endpoint that create the shortened url to avoid abuse ([docs](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html)).
