#
# Cookbook Name:: alb_support
# Recipe:: attach_to_alb
#
# Copyright 2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.
#

# NOTE: aws-sdk-core のインストールについて
# aws-sdk-core の依存関係ツリーは以下のようになっている:
#
#     aws-sdk-core
#      |- aws-sigv4
#      |   `- aws-eventstream
#      `- jmespath
#
# このうち aws-sigv4 (1.7.0) と aws-eventstream (1.3.0) で Ruby 2.3 のサポートが drop されてしまった。
# 素朴に aws-sdk-core (~> 2.6) をインストールすると、これらのバージョンがインストールされてしまい、
# Ruby 2.3 で動く Chef 12 環境でエラーが発生してしまう。
# このエラーを回避するため、aws-sigv4 と aws-eventstream のバージョンに上限をつけつつ、aws-sdk-core を
# インストールできるように、オプションを添えて個別に gem をインストールしている。

chef_gem "aws-eventstream" do
  version "< 1.3"
  action :install
end

chef_gem "aws-sigv4" do
  version "< 1.7"
  action :install
  options "--ignore-dependencies"
end

chef_gem "jmespath" do
  version "~> 1.0"
  action :install
end

chef_gem "aws-sdk-core" do
  version "~> 2.6"
  action :install
  options "--ignore-dependencies"
end

ruby_block "attach to ALB" do
  block do
    require "aws-sdk-core"

    raise "alb_helper block not specified in layer JSON" if node[:alb_helper].nil?
    raise "Target group ARN not specified in layer JSON" if node[:alb_helper][:target_group_arn].nil? && node[:alb_helper][:target_group_arns].nil?

    stack = search("aws_opsworks_stack").first
    instance = search("aws_opsworks_instance", "self:true").first

    stack_region = stack[:region]
    ec2_instance_id = instance[:ec2_instance_id]
    target_group_arns = if !node[:alb_helper][:target_group_arn].nil?
                          [node[:alb_helper][:target_group_arn]]
                        else !node[:alb_helper][:target_group_arns].nil?
                          node[:alb_helper][:target_group_arns]
                        end

    Chef::Log.info("Creating ELB client in region #{stack_region}")
    client = Aws::ElasticLoadBalancingV2::Client.new(region: stack_region)

    Chef::Log.info("Registering EC2 instance #{ec2_instance_id} with target group #{target_group_arns}")

    target_group_arns.each do |arn|
      target_to_attach = {
        target_group_arn: arn,
        targets: [{ id: ec2_instance_id }]
      }

      client.register_targets(target_to_attach)
    end
  end
  action :run
end
