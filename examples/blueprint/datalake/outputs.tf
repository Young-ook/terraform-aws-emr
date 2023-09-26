output "policy" {
  description = "IAM policy to allow agent to put records to kinesis firehose"
  value = {
    kinesis-firehose-write = aws_iam_policy.put-record-to-firehose.arn
  }
}
