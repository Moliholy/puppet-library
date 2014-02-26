# Puppet Library
# Copyright (C) 2014 drrb
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'spec_helper'

module PuppetLibrary::Forge
    describe Directory do
        include ModuleSpecHelper

        let(:module_dir) { Tempdir.create("module_dir") }
        let(:forge) { Directory.new(module_dir) }

        after do
            rm_rf module_dir
        end

        describe "#configure" do
            it "exposes a configuration API" do
                forge = Directory.configure do |forge|
                    forge.path = module_dir
                end
                expect(forge.instance_eval "@module_dir").to eq module_dir
            end
        end

        describe "#initialize" do
            context "when the module directory doesn't exist" do
                before do
                    rm_rf module_dir
                end

                it "raises an error" do
                    expect {
                        Directory.new(module_dir)
                    }.to raise_error /Module directory .* doesn't exist/
                end
            end

            context "when the module directory isn't readable" do
                before do
                    chmod 0400, module_dir
                end

                after do
                    chmod 0777, module_dir
                end

                it "raises an error" do
                    expect {
                        Directory.new(module_dir)
                    }.to raise_error /Module directory .* isn't readable/
                end
            end
        end

        describe "#get_module" do
            context "when the module archive exists" do
                before do
                    add_module("puppetlabs", "apache", "1.0.0")
                end

                it "returns a the module archive as a file buffer" do
                    buffer = forge.get_module("puppetlabs", "apache", "1.0.0")

                    expect(buffer.path).to end_with("puppetlabs-apache-1.0.0.tar.gz")
                end
            end

            context "when the module file doesn't exist" do
                it "returns nil" do
                    buffer = forge.get_module("puppetlabs", "noneixstant", "1.0.0")

                    expect(buffer).to be_nil
                end
            end
        end

        describe "#get_all_metadata" do
            context "when modules exist" do
                before do
                    add_module("puppetlabs", "apache", "1.0.0")
                    add_module("puppetlabs", "apache", "2.0.0")
                end

                it "returns a the module archive as a file buffer" do
                    metadata = forge.get_all_metadata

                    v1 = metadata.find {|m| m["version"] == "1.0.0" }
                    v2 = metadata.find {|m| m["version"] == "2.0.0" }
                    expect(v1).not_to be_nil
                    expect(v2).not_to be_nil
                end
            end

            context "when no modules exist" do
                it "returns an empty array" do
                    result = forge.get_all_metadata

                    expect(result).to be_empty
                end
            end
        end

        describe "#get_metadata" do
            context "when the module directory is empty" do
                it "returns an empty array" do
                    metadata_list = forge.get_metadata("puppetlabs", "apache")
                    expect(metadata_list).to be_empty
                end
            end

            context "when the module directory contains the requested module" do
                before do
                    add_module("puppetlabs", "apache", "1.0.0")
                    add_module("puppetlabs", "apache", "1.1.0")
                end

                it "returns an array containing the module's versions' metadata" do
                    metadata_list = forge.get_metadata("puppetlabs", "apache")
                    expect(metadata_list.size).to eq 2
                    metadata_list = metadata_list.sort_by {|m| m["version"] }
                    expect(metadata_list[0]["name"]).to eq "puppetlabs-apache"
                    expect(metadata_list[0]["version"]).to eq "1.0.0"
                    expect(metadata_list[1]["name"]).to eq "puppetlabs-apache"
                    expect(metadata_list[1]["version"]).to eq "1.1.0"
                end
            end
        end
    end
end
