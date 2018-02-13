#
# Cookbook Name:: newrelic_monitoring
# Recipe:: default
#
# Copyright 2018.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

directory '/usr/local/newrelic/' do
  mode '0755'
  action :create
end

remote_file '/usr/local/newrelic/v1.0.1.zip' do
  source 'https://github.com/kenjij/newrelic_redis_plugin/archive/v1.0.1.zip'
  mode '0755'
  action :create
end

execute 'extract_redis_agent' do
  command 'unzip v1.0.1.zip'
  cwd '/usr/local/newrelic/'
end

execute 'move_file' do
  command 'mv newrelic_redis_plugin-1.0.1 /usr/local/newrelic/newrelic_redis_plugin'
  cwd '/usr/local/newrelic/'
end

file '/usr/local/newrelic/v1.0.1.zip' do
  action :delete
end

package %w(gcc ruby-devel rubygems)
gem_package 'bundler'

gem_package 'dante' do
  version '0.2.0'
end

gem_package 'json' do
  version '2.1.0'
end

gem_package 'newrelic_plugin' do
  version '1.3.1'
end

gem_package 'redis' do
  version '3.3.5'
end

gem_package 'rubygems-update'

execute 'update_rubygems' do
  command 'update_rubygems'
  cwd '/usr/local/newrelic/newrelic_redis_plugin/'
end

template "/usr/local/newrelic/newrelic_redis_plugin/config/newrelic_plugin.yml" do
  source "newrelic_plugin.yml.erb"
  mode "0775"
end

template "/etc/init.d/redis-newrelic-agent" do
  source "redis-newrelic-agent.erb"
  mode "0775"
end

service 'redis-newrelic-agent' do
  action [ :enable, :start ]
  supports :reload => true, :restart => true, :status => true, :stop => true
  subscribes :restart, 'file[/usr/local/newrelic/newrelic_mongodb_agent/config/newrelic_plugin.yml]', :immediately
  subscribes :restart, 'file[/etc/init.d/redis-newrelic-agent]', :immediately
end