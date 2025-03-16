output "prj_lb_dns" {
  description = "dns name"
  value       = aws_lb.prj_loadbalancer.dns_name

}
