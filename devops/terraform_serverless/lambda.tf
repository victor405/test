# resource "aws_iam_role" "lambda" {
#   name = "${var.app_name}-lambda-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = { Service = "lambda.amazonaws.com" }
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "lambda" {
#   role       = aws_iam_role.lambda.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

# resource "aws_lambda_function" "lambda" {
#   function_name = "${var.app_name}-lambda"
#   role          = aws_iam_role.lambda.arn
#   package_type  = "Image"

#   image_uri = "${aws_ecr_repository.prompt_gemini.repository_url}:latest"

#   timeout      = 10
#   memory_size  = 512
# }

# resource "aws_lambda_function_url" "lambda" {
#   function_name      = aws_lambda_function.lambda.function_name
#   authorization_type = "NONE"
# }
