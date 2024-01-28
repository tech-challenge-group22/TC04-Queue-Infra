resource "aws_sqs_queue" "order_queue_finished" {
    name                        = "order-queue-finished.fifo"
    delay_seconds               = 0
    visibility_timeout_seconds  = 30
    max_message_size            = 2048
    message_retention_seconds   = 86400
    receive_wait_time_seconds   = 2
    fifo_queue                  = true
    content_based_deduplication = true
    policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
      }
    ]
  })
}

resource "aws_sqs_queue" "payment_response_deadletter_queue" {
  name                        = "order-queue-finished-dlq.fifo"
  fifo_queue                  = true
  content_based_deduplication = aws_sqs_queue.order_queue_finished.content_based_deduplication
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_queue_finished.arn,
    maxReceiveCount     = 5  # Adjust as needed
  })
}