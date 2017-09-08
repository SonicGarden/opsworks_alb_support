name             "opsworks_alb_support"
maintainer       "ruzia"
maintainer_email "ruzia@sonicgarden.jp"
license          "Apache 2.0"
description      "ALB Support"
version          "0.1"

recipe 'opsworks_alb_support', 'ALB Support'
recipe 'opsworks_alb_support::attach_to_alb.rb', 'attach to ALB'
recipe 'opsworks_alb_support::detach_from_alb', 'detach from ALB'
