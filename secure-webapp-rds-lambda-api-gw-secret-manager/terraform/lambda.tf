resource "aws_lambda_function" "app" {
  function_name = "secure-api"

  handler = "app.lambda_handler"
  runtime = "python3.10"

  role     = aws_iam_role.lambda_role.arn
  filename = "../lambda/function.zip"

  source_code_hash = filebase64sha256("../lambda/function.zip")

  timeout = 10

  vpc_config {
    subnet_ids = [
      aws_subnet.private1.id,
      aws_subnet.private2.id
    ]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      SECRET_NAME = aws_secretsmanager_secret.db_secret.name
    }
  }
}
