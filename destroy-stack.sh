#!/bin/sh

terraform destroy -auto-approve -target=module.webhook_broker
terraform destroy -auto-approve -target=module.goodies
terraform destroy -auto-approve
