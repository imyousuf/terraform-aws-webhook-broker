output "es_endpoint" {
  value       = element(concat(aws_elasticsearch_domain.test_w7b6.*.endpoint, list("")), 0)
  description = "Elasticsearch API Endpoint"
}

output "es_kibana" {
  value       = element(concat(aws_elasticsearch_domain.test_w7b6.*.kibana_endpoint, list("")), 0)
  description = "Elasticsearch Kibana URL"
}
