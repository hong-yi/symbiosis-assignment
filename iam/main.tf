provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_iam_role" "iamrole-webapp" {
  name = "iamrole-webapp"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "iampolicy-dbauth" {
    name = "iampolicy-dbauth"
    policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Action": [
             "rds-db:connect"
         ],
         "Resource": [
             "arn:aws:rds-db:ap-southeast-1:dbadmin:cluster-U2BGVDVCKSUI7VZWVP2WMQ55RQ/db_user"
         ]
      }
   ]
}
EOF
}

resource "aws_iam_policy" "iampolicy-webapp" {
  name = "iampolicy-webapp"
  policy = <<EOF
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Action":[
            "s3:Get*"
         ],
         "Effect":"Allow",
         "Resource":"arn:aws:s3:::s3-app-symbiosis/*"
      }
   ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "iam-attachment-webapp" {
    role = aws_iam_role.iamrole-webapp.name
    policy_arn = aws_iam_policy.iampolicy-webapp.arn
}

resource "aws_iam_role_policy_attachment" "iam-attachment-webapp-dbiam" {
  role = aws_iam_role.iamrole-webapp.name
  policy_arn = aws_iam_policy.iampolicy-dbauth.arn
}

resource "aws_iam_instance_profile" "iam-instanceprofile-webapp" {
    name = "iam-instanceprofile-webapp"
    role = aws_iam_role.iamrole-webapp.name
}