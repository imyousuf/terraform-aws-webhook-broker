output "es_endpoint" {
  value       = element(concat(aws_elasticsearch_domain.es_domain.*.endpoint, list("")), 0)
  description = "Elasticsearch API Endpoint"
}

output "es_kibana" {
  value       = element(concat(aws_elasticsearch_domain.es_domain.*.kibana_endpoint, list("")), 0)
  description = "Elasticsearch Kibana URL"
}
