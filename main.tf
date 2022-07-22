resource "aws_elastic_beanstalk_application" "laravel_beanstalk" {
  name = "laravel_beanstalk"
}

resource "aws_elastic_beanstalk_environment" "laravel_beanstalk_env" {
  name                = "laravel_beanstalk"
  application         = aws_elastic_beanstalk_application.laravel_beanstalk.name
  solution_stack_name = "64bit Amazon Linux 2 v3.3.12 running PHP 8.0"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = "aws-personnel"
  }

  setting {
    namespace = "aws:elasticbeanstalk:container:php:phpini"
    name      = "document_root"
    value     = "/public"
  }

  setting {
    namespace = "aws:elasticbeanstalk:container:php:phpini"
    name      = "memory_limit"
    value     = "512M"
  }
}

resource "aws_codepipeline" "codepipeline" {
  name     = "laravel_beanstalk-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = "arn:aws:codestar-connections:eu-central-1:111205789458:connection/44440b8a-a79a-46a3-9ba9-df30408949bd"
        FullRepositoryId = "hmada15/laravel_beanstalk"
        BranchName       = "master"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ElasticBeanstalk"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ApplicationName = aws_elastic_beanstalk_application.laravel_beanstalk.name
        EnvironmentName = aws_elastic_beanstalk_environment.laravel_beanstalk_env.name
      }
    }
  }
}

resource "aws_codestarconnections_connection" "git-hup" {
  name          = "git-hup"
  provider_type = "GitHub"
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "hmada15-codepipeline"
}

resource "aws_s3_bucket_acl" "codepipeline_bucket_acl" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  acl    = "private"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "laravel_beanstalk-role"

  assume_role_policy = data.aws_iam_policy_document.codepipeline-assume-role-policy.json
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = aws_iam_role.codepipeline_role.id

  policy = data.aws_iam_policy_document.codepipeline-policy.json
}
